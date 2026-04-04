import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/job_entity.dart';
import '../models/localized_string.dart';
import '../models/order_feedback_entity.dart';
import '../models/remote_order_dto.dart';

/// Supabase client + `public.orders` CRUD/realtime for cross-device order sync.
class SupabaseOrderService {
  SupabaseClient get client => Supabase.instance.client;

  /// Storage bucket for parcel photos (public read). Create in Supabase Dashboard if missing.
  static const String orderProductImagesBucket = 'order-product-images';

  static String _storageFileExtension(String contentType) {
    final c = contentType.toLowerCase();
    if (c.contains('png')) return 'png';
    if (c.contains('webp')) return 'webp';
    if (c.contains('gif')) return 'gif';
    return 'jpg';
  }

  static bool _isHttpUrl(String s) {
    final t = s.trim().toLowerCase();
    return t.startsWith('https://') || t.startsWith('http://');
  }

  /// Uploads bytes and returns a **public** URL (bucket must allow public read).
  Future<String> uploadOrderProductImageAndGetPublicUrl({
    required String jobId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError('order image bytes empty');
    }
    final ct = contentType.trim().isEmpty ? 'image/jpeg' : contentType.trim();
    final ext = _storageFileExtension(ct);
    final path = 'orders/$jobId/photo.$ext';
    if (kDebugMode) {
      debugPrint(
        '[order-image] upload start bucket=$orderProductImagesBucket path=$path '
        'bytes=${bytes.length} contentType=$ct',
      );
    }
    await client.storage.from(orderProductImagesBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: ct,
            upsert: true,
          ),
        );
    final publicUrl =
        client.storage.from(orderProductImagesBucket).getPublicUrl(path);
    if (kDebugMode) {
      debugPrint('[order-image] upload success url=$publicUrl');
    }
    return publicUrl;
  }

  String _localizedUz(LocalizedString s) {
    final t = s.uz.trim();
    if (t.isNotEmpty) return t;
    final r = s.ru.trim();
    if (r.isNotEmpty) return r;
    return s.en.trim();
  }

  /// Inserts a row using the same [job.id] as SQLite so devices correlate orders.
  ///
  /// Writes production columns plus legacy `price` (same as [JobEntity.startPriceCents])
  /// for databases that have not migrated off `price` yet.
  ///
  /// Supabase ustunlari: `20260410120000_orders_flutter_remote_schema_align.sql` va
  /// `20260403120000_orders_extend_cross_device.sql` bilan mos (`cold_storage`, …).
  Future<void> createOrderRemote(JobEntity job) async {
    final row = <String, dynamic>{
      'id': job.id,
      'sender_id': job.senderId,
      'title': _localizedUz(job.title),
      'description': _localizedUz(job.description),
      'pickup_address': _localizedUz(job.pickupAddress),
      'dropoff_address': _localizedUz(job.dropoffAddress),
      'pickup_lat': job.pickupLat,
      'pickup_lng': job.pickupLng,
      'dropoff_lat': job.dropoffLat,
      'dropoff_lng': job.dropoffLng,
      'pickup_region': job.pickupRegion,
      'pickup_district': job.pickupDistrictOrCity,
      'dropoff_region': job.dropoffRegion,
      'dropoff_district': job.dropoffDistrictOrCity,
      'transport_type': job.transportType,
      'recipient_name': job.recipientName,
      'recipient_phone': job.recipientPhone,
      'start_price_cents': job.startPriceCents,
      'floor_price_cents': job.floorPriceCents,
      'auction_step': job.auctionStep,
      'leading_courier_id': job.leadingCourierId,
      'winner_courier_id': job.winnerCourierId,
      'status': job.status.toStorage(),
      'created_at': job.createdAt.toUtc().toIso8601String(),
      'price': job.startPriceCents,
      'product_type': _localizedUz(job.productType),
      'delivery_speed': job.deliverySpeed.toStorage(),
      'product_weight_kg': job.productWeightKg,
      'product_volume_l': job.productVolumeL,
      'dimensions_mm': job.dimensionsMm.trim().isEmpty ? null : job.dimensionsMm.trim(),
      'payment_type': job.paymentType.toStorage(),
      'fragile': job.fragile,
      'cold_storage': job.coldChain,
    };

    final rc = job.regionCode.trim();
    if (rc.isNotEmpty) row['region_code'] = rc;
    final dc = job.districtCode.trim();
    if (dc.isNotEmpty) row['district_code'] = dc;

    final vck = job.volumeCategoryKey.trim();
    if (vck.isNotEmpty) row['volume_category'] = vck;

    final dws = job.deliveryWindowStart?.trim();
    if (dws != null && dws.isNotEmpty) {
      row['delivery_window_start'] = dws;
    }
    final dwe = job.deliveryWindowEnd?.trim();
    if (dwe != null && dwe.isNotEmpty) {
      row['delivery_window_end'] = dwe;
    }

    final oc = job.orderComments?.trim();
    if (oc != null && oc.isNotEmpty) {
      row['comments'] = oc;
    }

    if (_isHttpUrl(job.imagePath)) {
      row['image_url'] = job.imagePath.trim();
    }
    if (job.auctionEndsAt != null) {
      row['auction_ends_at'] = job.auctionEndsAt!.toUtc().toIso8601String();
    }
    if (kDebugMode && _isHttpUrl(job.imagePath)) {
      debugPrint('[order-image] remote insert image_url=${job.imagePath.trim()}');
    }
    if (kDebugMode) {
      final keys = row.keys.toList()..sort();
      debugPrint('[remote-order] create payload keys=$keys');
      debugPrint(
        '[order-comments] payload comments='
        '${row.containsKey('comments') ? row['comments'] : '(omit)'}',
      );
      debugPrint(
        '[crossPlatformOrder] Supabase insert row id=${row['id']} status=${row['status']} '
        'sender_id=${row['sender_id']} pickup_region=${row['pickup_region']} '
        'pickup_district=${row['pickup_district']} region_code=${row['region_code']} '
        'district_code=${row['district_code']} transport_type=${row['transport_type']} '
        'start_price_cents=${row['start_price_cents']} floor_price_cents=${row['floor_price_cents']} '
        'created_at=${row['created_at']} image_url=${row['image_url']}',
      );
    }
    await client.from('orders').insert(row);
    developer.log(
      'orders insert success id=${job.id}',
      name: 'SupabaseRemote',
    );
    if (kDebugMode) {
      debugPrint('[remote-order] insert success id=${job.id}');
    }
  }

  /// Open marketplace orders: posted + live auction.
  Future<List<RemoteOrderDto>> fetchOrdersRemote() async {
    final response = await client
        .from('orders')
        .select()
        .inFilter('status', ['posted', 'auction_live'])
        .order('created_at', ascending: false) as List<dynamic>;

    final out = <RemoteOrderDto>[];
    for (final e in response) {
      out.add(
        RemoteOrderDto.fromSupabaseMap(
          Map<String, dynamic>.from(e as Map),
        ),
      );
    }
    final filtered =
        out.where((d) => d.id.isNotEmpty && d.senderId.isNotEmpty).toList();
    developer.log(
      'fetchOrdersRemote count=${filtered.length}',
      name: 'SupabaseRemote',
    );
    if (kDebugMode) {
      debugPrint(
        '[remote-order] cross-device fetch count=${filtered.length}',
      );
    }
    return filtered;
  }

  /// Authoritative auction bid log (`public.bids`).
  Future<void> insertBidRemote({
    required String id,
    required String orderId,
    required String courierId,
    required int stepIndex,
    required int priceCents,
    required DateTime createdAt,
  }) async {
    await client.from('bids').insert({
      'id': id,
      'order_id': orderId,
      'courier_id': courierId,
      'step_index': stepIndex,
      'price_cents': priceCents,
      'created_at': createdAt.toUtc().toIso8601String(),
    });
  }

  Future<void> patchOrderAuctionRemote({
    required String orderId,
    required Map<String, dynamic> fields,
  }) async {
    if (fields.isEmpty) return;
    await client.from('orders').update(fields).eq('id', orderId);
  }

  /// Yetkazib berish holati (`picked_up`, `delivered`, `completed`, …).
  /// TODO(security): RLS bilan faqat tegishli sender/kuryer `UPDATE` qila olishi kerak.
  Future<void> patchOrderLifecycleRemote({
    required String orderId,
    required Map<String, dynamic> fields,
  }) async {
    if (fields.isEmpty) return;
    await client.from('orders').update(fields).eq('id', orderId);
  }

  /// `report_order_courier_location` — faqat g‘olib, `assigned` / `picked_up` / `delivered`.
  Future<void> reportOrderCourierLocation({
    required String orderId,
    required double lat,
    required double lng,
    double? heading,
    double? speed,
    double? accuracy,
  }) async {
    final params = <String, dynamic>{
      'p_order_id': orderId,
      'p_lat': lat,
      'p_lng': lng,
    };
    if (heading != null) params['p_heading'] = heading;
    if (speed != null) params['p_speed'] = speed;
    if (accuracy != null) params['p_accuracy'] = accuracy;

    final raw = await client.rpc(
      'report_order_courier_location',
      params: params,
    );
    if (raw is Map && raw['ok'] == true) return;
    final err = raw is Map ? raw['error'] : raw;
    throw StateError('report_order_courier_location_failed:$err');
  }

  Future<void> finalizeAuctionWinnerRemote({
    required String orderId,
    required String winnerCourierId,
    required int finalPriceCents,
  }) async {
    await client.from('orders').update({
      'status': 'assigned',
      'winner_courier_id': winnerCourierId,
      'final_price_cents': finalPriceCents,
      'auction_ends_at': null,
      'leading_courier_id': winnerCourierId,
    }).eq('id', orderId);
  }

  /// [public.orders] + [public.bids] on one channel (single subscribe); two table bindings.
  RealtimeChannel listenMarketplaceRealtime({
    required void Function(PostgresChangePayload payload) onOrderPayload,
    required void Function(PostgresChangePayload payload) onBidPayload,
  }) {
    final channel = client.channel('marketplace_sync');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.insert ||
                payload.eventType == PostgresChangeEvent.update) {
              onOrderPayload(payload);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'bids',
          callback: onBidPayload,
        )
        .subscribe((status, err) {
          developer.log(
            'marketplace realtime status=$status err=$err',
            name: 'SupabaseRealtime',
          );
          if (kDebugMode) {
            debugPrint('[supabase] marketplace realtime status=$status err=$err');
          }
        });
    return channel;
  }

  /// Full row for realtime UPDATE payloads that only carry changed columns.
  Future<Map<String, dynamic>?> fetchOrderRowById(String id) async {
    if (id.isEmpty) return null;
    final row = await client.from('orders').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row as Map);
  }

  /// Atomik auksion: `posted`da boshlash yoki `auction_live`da qadam (5%, 30s, floor).
  Future<Map<String, dynamic>> startOrStepAuctionRpc({
    required String orderId,
    required String courierId,
  }) async {
    final raw = await client.rpc(
      'start_or_step_auction',
      params: {
        'p_order_id': orderId,
        'p_courier_id': courierId,
      },
    );
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw StateError('auction_rpc_bad_response');
  }

  /// Muddati o‘tgan `auction_live` qatorlarni serverda yakunlaydi (g‘olib / posted).
  Future<int> finalizeExpiredAuctionsRpc() async {
    final raw = await client.rpc('finalize_expired_auctions');
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 0;
  }

  Future<Map<String, dynamic>> submitOrderFeedbackRpc({
    required String orderId,
    required String toUserId,
    required int rating,
    required String feedbackType,
    String? complaintCategory,
    String? praiseCategory,
    String? comment,
  }) async {
    final params = <String, dynamic>{
      'p_order_id': orderId,
      'p_to_user_id': toUserId,
      'p_rating': rating,
      'p_feedback_type': feedbackType,
    };
    final cc = complaintCategory?.trim();
    if (cc != null && cc.isNotEmpty) params['p_complaint_category'] = cc;
    final pc = praiseCategory?.trim();
    if (pc != null && pc.isNotEmpty) params['p_praise_category'] = pc;
    final cm = comment?.trim();
    if (cm != null && cm.isNotEmpty) params['p_comment'] = cm;

    final raw = await client.rpc('submit_order_feedback', params: params);
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw StateError('submit_order_feedback_bad_response');
  }

  Future<OrderFeedbackEntity?> fetchMyOrderFeedbackRemote({
    required String orderId,
    required String fromUserId,
  }) async {
    if (orderId.isEmpty || fromUserId.isEmpty) return null;
    final row = await client
        .from('order_feedback')
        .select()
        .eq('order_id', orderId)
        .eq('from_user_id', fromUserId)
        .maybeSingle();
    if (row == null) return null;
    return OrderFeedbackEntity.fromSupabaseMap(
      Map<String, dynamic>.from(row as Map),
    );
  }

  Future<Map<String, dynamic>?> fetchUserFeedbackSummaryRemote(
    String userId,
  ) async {
    if (userId.trim().isEmpty) return null;
    final raw = await client.rpc(
      'get_user_feedback_summary',
      params: {'p_user_id': userId.trim()},
    );
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<void> disposeRealtimeChannel(RealtimeChannel channel) async {
    try {
      await client.removeChannel(channel);
    } catch (e, st) {
      debugPrint('[supabase] removeChannel failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  /// Push navbatiga yozish (masalan `new_matching_order` — kuryer feed clientdan).
  Future<String?> enqueueNotificationEvent({
    required String type,
    required String targetUserId,
    String? orderId,
    Map<String, dynamic>? payload,
    String? dedupeKey,
    DateTime? scheduledAt,
  }) async {
    final params = <String, dynamic>{
      'p_type': type,
      'p_target_user_id': targetUserId,
      'p_order_id': orderId ?? '',
      'p_payload': payload ?? <String, dynamic>{},
      'p_scheduled_at':
          (scheduledAt ?? DateTime.now().toUtc()).toIso8601String(),
    };
    if (dedupeKey != null && dedupeKey.trim().isNotEmpty) {
      params['p_dedupe_key'] = dedupeKey.trim();
    }

    final raw = await client.rpc(
      'enqueue_notification_event',
      params: params,
    );
    if (raw == null) {
      if (kDebugMode) {
        debugPrint('[push] dedup skip reason=enqueue_returned_null type=$type');
      }
      return null;
    }
    return raw.toString();
  }
}

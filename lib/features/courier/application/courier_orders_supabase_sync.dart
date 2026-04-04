import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart'
    show debugPrint, debugPrintStack, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/core_providers.dart';
import '../../../features/jobs/application/job_poll_provider.dart';
import '../../../features/sender/application/sender_jobs_provider.dart';
import '../../../models/remote_order_dto.dart';
import '../../../models/remote_order_mapper.dart';
import '../../../models/user_role.dart';
import '../../../repositories/job_repository.dart' show logAuctionSourceTruth;

bool _ordersMergedRowMissingAuctionTruth(Map<String, dynamic> map) {
  final st = map['status']?.toString().trim();
  if (st != 'auction_live') return false;
  return map['auction_step'] == null || map['current_price_cents'] == null;
}

bool _isOrdersCourierSnapshotOnlyUpdate(PostgresChangePayload payload) {
  if (payload.eventType != PostgresChangeEvent.update) return false;
  const allowed = {
    'courier_lat',
    'courier_lng',
    'courier_heading',
    'courier_speed',
    'courier_accuracy',
    'courier_location_updated_at',
    'id',
  };
  final keys = payload.newRecord.keys.map((k) => k.toString()).toSet();
  if (keys.isEmpty) return false;
  return keys.every(allowed.contains);
}

DateTime _parseBidCreatedAt(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  if (v is String) {
    return DateTime.tryParse(v) ?? DateTime.now();
  }
  return DateTime.now();
}

/// Bid INSERT and orders row INSERT/UPDATE for the same [orderId] can arrive in
/// either order; without serialization they interleave and SQLite can briefly
/// (or persistently if order UPDATE is delayed) hold bid step N while `jobs`
/// still has step N-1 — breaking isLeading / price on one device.
final Map<String, Future<void>> _auctionOrderRealtimeTail = {};

Future<void> _runSerializedAuctionOrderSync(
  String orderId,
  Future<void> Function() work,
) async {
  final prev = _auctionOrderRealtimeTail[orderId] ?? Future<void>.value();
  final done = Completer<void>();
  _auctionOrderRealtimeTail[orderId] = done.future;
  await prev.catchError((_) {});
  try {
    await work();
  } finally {
    done.complete();
    if (identical(_auctionOrderRealtimeTail[orderId], done.future)) {
      _auctionOrderRealtimeTail.remove(orderId);
    }
  }
}

/// Remote marketplace sync: orders + bid inserts. Watches [authSessionProvider].
///
/// Use [marketplaceSupabaseSyncProvider] from app root so senders see live auctions too.
final marketplaceSupabaseSyncProvider = Provider.autoDispose<void>((ref) {
  final user = ref.watch(authSessionProvider).valueOrNull;
  if (user == null) {
    return;
  }

  developer.log(
    'marketplace sync starting user=${user.id} role=${user.role?.name}',
    name: 'SupabaseSync',
  );
  ref.keepAlive();

  final svc = ref.watch(supabaseOrderServiceProvider);
  RealtimeChannel? channel;

  ref.onDispose(() {
    final c = channel;
    if (c != null) {
      unawaited(svc.disposeRealtimeChannel(c));
    }
  });

  Map<String, dynamic> mergeOrdersRow(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        return Map<String, dynamic>.from(payload.newRecord);
      case PostgresChangeEvent.update:
        final merged = Map<String, dynamic>.from(payload.oldRecord);
        merged.addAll(payload.newRecord);
        return merged;
      default:
        return const {};
    }
  }

  Future<void> applyBidPayload(PostgresChangePayload payload) async {
    if (payload.eventType != PostgresChangeEvent.insert) return;
    final map = payload.newRecord;
    if (map.isEmpty) return;
    final orderId = map['order_id']?.toString();
    final bidId = map['id']?.toString();
    final courierId = map['courier_id']?.toString();
    if (orderId == null ||
        orderId.isEmpty ||
        bidId == null ||
        bidId.isEmpty ||
        courierId == null ||
        courierId.isEmpty) {
      return;
    }
    final step = (map['step_index'] as num?)?.toInt() ?? 0;
    final price = (map['price_cents'] as num?)?.toInt() ?? 0;
    final createdAt = _parseBidCreatedAt(map['created_at']);
    if (kDebugMode) {
      debugPrint(
        '[auction] realtime bid insert order=$orderId id=$bidId step=$step price=$price',
      );
    }
    try {
      await _runSerializedAuctionOrderSync(orderId, () async {
        final repo = await ref.read(jobRepositoryProvider.future);
        final sqliteStepBefore = (await repo.getJob(orderId))?.auctionStep;
        var orderRowConsistent = false;

        await repo.applyRemoteBidInsert(
          id: bidId,
          orderId: orderId,
          courierId: courierId,
          stepIndex: step,
          priceCents: price,
          createdAt: createdAt,
        );

        final sqliteStepAfterBidOnly = (await repo.getJob(orderId))?.auctionStep;

        final full = await svc.fetchOrderRowById(orderId);
        int? incomingOrderStep;
        if (full != null && full.isNotEmpty) {
          final dto = RemoteOrderDto.fromSupabaseMap(full);
          incomingOrderStep = dto.auctionStep;
          await repo.upsertPostedOrderFromRemote(dto);
          orderRowConsistent = true;
          final j = await repo.getJob(orderId);
          if (j != null) {
            logAuctionSourceTruth(
              source: 'realtime',
              orderId: orderId,
              job: j,
            );
          }
        }

        final sqliteStepAfter = (await repo.getJob(orderId))?.auctionStep;
        final wouldHaveBeenStaleUiIfInvalidatedEarly =
            sqliteStepAfterBidOnly != null && sqliteStepAfterBidOnly < step;

        if (kDebugMode) {
          debugPrint(
            '[auctionSequenceFix] event=bid_insert '
            'orderId=$orderId bid_step=$step '
            'incoming_order_step=$incomingOrderStep '
            'sqlite_step_before=$sqliteStepBefore '
            'sqlite_step_after_bid_only=$sqliteStepAfterBidOnly '
            'sqlite_step_after=$sqliteStepAfter '
            'fetch_merged=${full != null && full.isNotEmpty} '
            'orderRowConsistent=$orderRowConsistent '
            'wouldHaveBeenStaleUiIfInvalidatedEarly=$wouldHaveBeenStaleUiIfInvalidatedEarly '
            'invalidatePhase=${orderRowConsistent ? "after_order_upsert" : "skipped_stale_job_row"}',
          );
        }

        if (orderRowConsistent) {
          ref.invalidate(courierJobsProvider);
          ref.invalidate(jobPollProvider(orderId));
          final job = await repo.getJob(orderId);
          if (job != null) {
            ref.invalidate(senderJobsProvider(job.senderId));
          }
        }
      });
    } catch (e, st) {
      debugPrint('[auction] realtime bid apply failed: $e');
      if (kDebugMode) debugPrintStack(stackTrace: st);
    }
  }

  Future<void> applyOrderPayload(PostgresChangePayload payload) async {
    final ev = payload.eventType;
    if (ev != PostgresChangeEvent.insert && ev != PostgresChangeEvent.update) {
      if (kDebugMode) {
        debugPrint(
          '[order-sync] realtime event type=${ev.name} id= (ignored)',
        );
      }
      return;
    }

    final idFromNew = payload.newRecord['id']?.toString();
    if (kDebugMode) {
      final evName = ev == PostgresChangeEvent.insert ? 'insert' : 'update';
      debugPrint(
        '[order-sync] realtime event type=$evName id=${idFromNew ?? "null"}',
      );
      debugPrint(
        '[supabase] realtime callback fired event=$ev id=${idFromNew ?? "null"} '
        'new_keys=${payload.newRecord.length} old_keys=${payload.oldRecord.length}',
      );
    }

    final mapPrecheck = mergeOrdersRow(payload);
    if (mapPrecheck.isEmpty) {
      if (kDebugMode) {
        debugPrint('[supabase] realtime skip empty merged row event=$ev');
      }
      return;
    }
    final orderId = mapPrecheck['id']?.toString();
    if (orderId == null || orderId.isEmpty) {
      return;
    }

    final seqEvent =
        ev == PostgresChangeEvent.insert ? 'order_insert' : 'order_update';

    await _runSerializedAuctionOrderSync(orderId, () async {
      final repo = await ref.read(jobRepositoryProvider.future);
      final sqliteStepBefore = (await repo.getJob(orderId))?.auctionStep;

      var map = mergeOrdersRow(payload);
      if (map.isEmpty) {
        return;
      }

      final idForRefetch = map['id']?.toString();
      if (idForRefetch != null &&
          idForRefetch.isNotEmpty &&
          _ordersMergedRowMissingAuctionTruth(map)) {
        final full = await svc.fetchOrderRowById(idForRefetch);
        if (full != null && full.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
              '[auction-sync] refetch full row id=$idForRefetch '
              '(realtime merge missed auction_step/current_price_cents)',
            );
          }
          map = full;
        }
      }

      if (kDebugMode) {
        debugPrint(
          '[supabase] remote row pre-map id=${map['id']} status=${map['status']} '
          'pickup_region=${map['pickup_region']} pickup_district=${map['pickup_district']} '
          'start_price_cents=${map['start_price_cents']}',
        );
        debugPrint(
          '[crossPlatformOrder] realtime/bootstrap map id=${map['id']} sender_id=${map['sender_id']} '
          'region_code=${map['region_code']} district_code=${map['district_code']} '
          'transport_type=${map['transport_type']} created_at=${map['created_at']}',
        );
      }

      try {
        var dto = RemoteOrderDto.fromSupabaseMap(map);
        if (dto.senderId.isEmpty && dto.id.isNotEmpty) {
          final full = await svc.fetchOrderRowById(dto.id);
          if (full != null && full.isNotEmpty) {
            if (kDebugMode) {
              debugPrint(
                '[supabase] realtime refetched full row id=${dto.id} (partial payload)',
              );
            }
            map = full;
            dto = RemoteOrderDto.fromSupabaseMap(map);
          }
        }

        if (dto.id.isEmpty || dto.senderId.isEmpty) {
          if (kDebugMode) {
            debugPrint(
              '[supabase] realtime skip map/DTO missing id or sender_id '
              'id=${dto.id} sender_empty=${dto.senderId.isEmpty}',
            );
          }
          return;
        }

        if (kDebugMode) {
          final st = dto.status ?? '';
          if (st == 'auction_live' || st == 'assigned') {
            debugPrint(
              '[auction] realtime order update id=${dto.id} status=$st '
              'step=${dto.auctionStep} ends=${dto.auctionEndsAt} '
              'leader=${dto.leadingCourierId} winner=${dto.winnerCourierId}',
            );
          }
          if (st == 'auction_live') {
            debugPrint(
              '[auction-sync] remote row id=${dto.id} current=${dto.currentPriceCents} '
              'start=${dto.effectiveStartPriceCents} final=${dto.finalPriceCents} '
              'step=${dto.auctionStep} bids=${dto.auctionBidCount}',
            );
          }
        }

        if (kDebugMode) {
          final mapped = RemoteOrderMapper.toJobEntity(
            dto,
            syncedFromSupabase: true,
          );
          debugPrint(
            '[crossPlatformOrder] after DTO map id=${dto.id} pickupRegionKey=${mapped.pickupRegionKey} '
            'pickupDistrictKey=${mapped.pickupDistrictKey} region_code=${mapped.regionCode} '
            'district_code=${mapped.districtCode}',
          );
        }
        final incomingOrderStep = dto.auctionStep;
        await repo.upsertPostedOrderFromRemote(dto);
        final sqliteStepAfter = (await repo.getJob(dto.id))?.auctionStep;

        if (kDebugMode && (dto.status ?? '').trim() == 'auction_live') {
          debugPrint(
            '[auctionSequenceFix] event=$seqEvent '
            'orderId=${dto.id} bid_step=(n/a) '
            'incoming_order_step=$incomingOrderStep '
            'sqlite_step_before=$sqliteStepBefore sqlite_step_after=$sqliteStepAfter '
            'invalidatePhase=after_order_upsert '
            'uiUsesMergedJobRow=true',
          );
        }

        final trackingOnly = _isOrdersCourierSnapshotOnlyUpdate(payload);
        ref.invalidate(jobPollProvider(dto.id));
        if (!trackingOnly) {
          ref.invalidate(courierJobsProvider);
          ref.invalidate(senderJobsProvider(dto.senderId));
        }
        if (kDebugMode) {
          if (trackingOnly) {
            final at = dto.courierLocationUpdatedAt;
            final ageSec =
                at == null ? -1 : DateTime.now().difference(at).inSeconds;
            debugPrint(
              '[tracking] sender update order=${dto.id} age=${ageSec}s '
              'scope=detail_only',
            );
          }
          debugPrint(
            '[order-sync] invalidate providers id=${dto.id} '
            'tracking_only=$trackingOnly',
          );
          debugPrint(
            '[supabase] realtime insert/update handling done event=$ev id=${dto.id}',
          );
        }
      } catch (e, st) {
        debugPrint('[supabase] realtime apply failed: $e');
        if (kDebugMode) debugPrintStack(stackTrace: st);
      }
    });
  }

  Future<void> bootstrap() async {
    if (user.role != UserRole.courier) {
      return;
    }
    try {
      final rows = await svc.fetchOrdersRemote();
      if (kDebugMode) {
        debugPrint(
          '[order-sync] bootstrap courier remote fetch count=${rows.length}',
        );
        debugPrint('[supabase] courier remote fetch ok count=${rows.length}');
      }
      final repo = await ref.read(jobRepositoryProvider.future);
      for (final dto in rows) {
        await repo.upsertPostedOrderFromRemote(dto);
      }
      if (kDebugMode) {
        debugPrint('[supabase] invalidate(courierJobsProvider) after remote fetch');
      }
      ref.invalidate(courierJobsProvider);
    } catch (e, st) {
      developer.log(
        'courier remote fetch failed: $e',
        name: 'SupabaseSync',
        error: e,
        stackTrace: st,
      );
      debugPrint('[supabase] courier remote fetch failed: $e');
      if (kDebugMode) debugPrintStack(stackTrace: st);
    }
  }

  unawaited(bootstrap());

  channel = svc.listenMarketplaceRealtime(
    onOrderPayload: (payload) {
      unawaited(applyOrderPayload(payload));
    },
    onBidPayload: (payload) {
      unawaited(applyBidPayload(payload));
    },
  );
  developer.log(
    'marketplace realtime channel subscribed (marketplace_sync)',
    name: 'SupabaseSync',
  );
});

/// @nodoc — prefer [marketplaceSupabaseSyncProvider].
final courierOrdersSupabaseSyncProvider = marketplaceSupabaseSyncProvider;

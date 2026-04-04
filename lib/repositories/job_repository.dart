import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../core/web/job_local_persistence.dart';
import '../core/geo/work_area_keys.dart';
import '../core/utils/auction_math.dart';
import '../core/utils/location_normalizer.dart';
import '../core/utils/phone_validator.dart';
import '../data/regions_seed.dart';
import '../features/sender/data/sender_notifications_storage.dart';
import '../models/bid_entity.dart';
import '../models/delivery_speed.dart';
import '../models/job_entity.dart';
import '../models/job_status.dart';
import '../models/job_transport_type.dart';
import '../models/localized_string.dart';
import '../models/payment_type.dart';
import '../models/remote_order_dto.dart';
import '../models/remote_order_mapper.dart';
import '../models/sender_in_app_notification.dart';
import '../models/volume_category.dart';
import '../services/sms/sms_dispatch_log.dart';
import '../services/supabase_service.dart';
import '../services/translation/translation_service.dart';
import 'auth_repository.dart';
import 'order_image_read_stub.dart'
    if (dart.library.io) 'order_image_read_io.dart' as order_image_read;
import 'user_repository.dart';

/// Rasm Supabase Storage ga yuklanmagan yoki mahalliy saqlab bo‘lmagan.
class OrderImageUploadException implements Exception {
  const OrderImageUploadException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Buyurtma mahalliy saqlandi, lekin Supabase `orders` jadvaliga yozilmadi.
class OrderRemoteSyncException implements Exception {
  const OrderRemoteSyncException(this.message, {this.cause});
  final String message;
  final Object? cause;
  @override
  String toString() => message;
}

/// Realtime can reorder events. Auction fields must move as **one bundle** from the
/// row with the **higher** [auctionStep] (tie: prefer [incoming] as remote).
/// Mixing `max(step)` with `min(price)` left Windows on step‑1 price while phone had step‑2.
class _AuctionLiveBundle {
  const _AuctionLiveBundle({
    required this.step,
    required this.bidCount,
    required this.leadingCourierId,
    required this.currentPriceCents,
    required this.auctionEndsAt,
  });

  final int step;
  final int bidCount;
  final String? leadingCourierId;
  final int currentPriceCents;
  final DateTime? auctionEndsAt;
}

_AuctionLiveBundle _mergeAuctionLiveAtomicBundle(
  JobEntity existing,
  JobEntity incoming,
) {
  final step = math.max(existing.auctionStep, incoming.auctionStep);

  final JobEntity auth;
  final JobEntity other;
  if (incoming.auctionStep > existing.auctionStep) {
    auth = incoming;
    other = existing;
  } else if (existing.auctionStep > incoming.auctionStep) {
    auth = existing;
    other = incoming;
  } else {
    auth = incoming;
    other = existing;
  }

  final bidCount = incoming.auctionStep != existing.auctionStep
      ? auth.auctionBidCount
      : math.max(existing.auctionBidCount, incoming.auctionBidCount);

  final leader = auth.leadingCourierId ?? other.leadingCourierId;
  final ends = auth.auctionEndsAt ?? other.auctionEndsAt;

  var price = auth.currentPriceCents;
  if (price == null || price <= 0) {
    price = AuctionMath.committedPriceCents(
      auth.startPriceCents,
      step,
      auth.floorPriceCents,
    );
  }

  if (kDebugMode) {
    final localDisp = existing.effectiveAuctionLivePriceCentsOrDerived;
    final incomingDisp = incoming.effectiveAuctionLivePriceCentsOrDerived;
    debugPrint(
      '[auctionStateBundle] order=${existing.id} '
      'local_step=${existing.auctionStep} incoming_step=${incoming.auctionStep} '
      'chosen_step=$step '
      'local_lead=${existing.leadingCourierId} incoming_lead=${incoming.leadingCourierId} '
      'chosen_lead=$leader '
      'local_cur=${existing.currentPriceCents} incoming_cur=${incoming.currentPriceCents} '
      'local_display=$localDisp incoming_display=$incomingDisp '
      'chosen_cur=$price '
      'local_ends=${existing.auctionEndsAt} incoming_ends=${incoming.auctionEndsAt} '
      'chosen_ends=$ends '
      'local_bids=${existing.auctionBidCount} incoming_bids=${incoming.auctionBidCount} '
      'chosen_bids=$bidCount',
    );
  }

  return _AuctionLiveBundle(
    step: step,
    bidCount: bidCount,
    leadingCourierId: leader,
    currentPriceCents: price,
    auctionEndsAt: ends,
  );
}

bool _localizedAnyNonEmpty(LocalizedString x) =>
    x.uz.trim().isNotEmpty ||
    x.ru.trim().isNotEmpty ||
    x.en.trim().isNotEmpty;

LocalizedString _pickLocalizedPreferRemote(
  LocalizedString remote,
  LocalizedString local,
) {
  return _localizedAnyNonEmpty(remote) ? remote : local;
}

/// Remote (Supabase) + mahalliy qatorni birlashtirish.
/// `src` ustunlari mavjud bo‘lsa remote ustun; yo‘q bo‘lsa mahalliy saqlanadi.
/// Qaytaradi: (birlashtirilgan job, taxminiy yangilangan maydonlar soni).
(JobEntity, int) _mergeRemoteJobOntoExisting(
  JobEntity local,
  JobEntity remote,
  RemoteOrderDto src,
) {
  var n = 0;
  void bumpIf(bool changed) {
    if (changed) n++;
  }

  final title = _pickLocalizedPreferRemote(remote.title, local.title);
  bumpIf(title.uz != local.title.uz);

  final description =
      _pickLocalizedPreferRemote(remote.description, local.description);
  bumpIf(description.uz != local.description.uz);

  final pickup =
      _pickLocalizedPreferRemote(remote.pickupAddress, local.pickupAddress);
  bumpIf(pickup.uz != local.pickupAddress.uz);

  final dropoff =
      _pickLocalizedPreferRemote(remote.dropoffAddress, local.dropoffAddress);
  bumpIf(dropoff.uz != local.dropoffAddress.uz);

  final productType = remote.productType.uz.trim().isNotEmpty
      ? remote.productType
      : local.productType;
  bumpIf(productType.uz != local.productType.uz);

  final productWeightKg =
      remote.productWeightKg > 0 ? remote.productWeightKg : local.productWeightKg;
  bumpIf(productWeightKg != local.productWeightKg);

  final productVolumeL =
      remote.productVolumeL > 0 ? remote.productVolumeL : local.productVolumeL;
  bumpIf(productVolumeL != local.productVolumeL);

  final dimensionsMm = remote.dimensionsMm.trim().isNotEmpty
      ? remote.dimensionsMm
      : local.dimensionsMm;
  bumpIf(dimensionsMm != local.dimensionsMm);

  final volumeCategoryKey = remote.volumeCategoryKey.trim().isNotEmpty
      ? remote.volumeCategoryKey
      : local.volumeCategoryKey;
  bumpIf(volumeCategoryKey != local.volumeCategoryKey);

  final regionCode = remote.regionCode.trim().isNotEmpty
      ? remote.regionCode
      : local.regionCode;
  bumpIf(regionCode != local.regionCode);

  final districtCode = remote.districtCode.trim().isNotEmpty
      ? remote.districtCode
      : local.districtCode;
  bumpIf(districtCode != local.districtCode);

  final pickupRegionKey = remote.pickupRegionKey.trim().isNotEmpty
      ? remote.pickupRegionKey
      : local.pickupRegionKey;
  bumpIf(pickupRegionKey != local.pickupRegionKey);

  final pickupDistrictKey = remote.pickupDistrictKey.trim().isNotEmpty
      ? remote.pickupDistrictKey
      : local.pickupDistrictKey;
  bumpIf(pickupDistrictKey != local.pickupDistrictKey);

  final deliverySpeed = src.hasDeliverySpeed
      ? DeliverySpeed.fromStorage(src.deliverySpeed!)
      : local.deliverySpeed;
  bumpIf(deliverySpeed != local.deliverySpeed);

  final deliveryWindowStart = src.hasDeliveryWindowStart
      ? remote.deliveryWindowStart
      : local.deliveryWindowStart;
  bumpIf(deliveryWindowStart != local.deliveryWindowStart);

  final deliveryWindowEnd = src.hasDeliveryWindowEnd
      ? remote.deliveryWindowEnd
      : local.deliveryWindowEnd;
  bumpIf(deliveryWindowEnd != local.deliveryWindowEnd);

  final paymentType = src.hasPaymentType
      ? PaymentType.fromStorage(src.paymentType!)
      : local.paymentType;
  bumpIf(paymentType != local.paymentType);

  final fragile = src.fragile != null ? src.fragile! : local.fragile;
  bumpIf(fragile != local.fragile);

  final coldChain = src.coldStorage != null ? src.coldStorage! : local.coldChain;
  bumpIf(coldChain != local.coldChain);

  final orderComments = src.hasComments ? remote.orderComments : local.orderComments;
  bumpIf(orderComments != local.orderComments);

  final pickupRegion = remote.pickupRegion ?? local.pickupRegion;
  final pickupDistrictOrCity =
      remote.pickupDistrictOrCity ?? local.pickupDistrictOrCity;
  final dropoffRegion = remote.dropoffRegion ?? local.dropoffRegion;
  final dropoffDistrictOrCity =
      remote.dropoffDistrictOrCity ?? local.dropoffDistrictOrCity;

  final recipientName = (remote.recipientName.trim().isNotEmpty &&
          remote.recipientName.trim() != '—')
      ? remote.recipientName
      : local.recipientName;
  bumpIf(recipientName != local.recipientName);

  final recipientPhone = remote.recipientPhone.trim().isNotEmpty
      ? remote.recipientPhone
      : local.recipientPhone;
  bumpIf(recipientPhone != local.recipientPhone);

  final imagePath = remote.imagePath.trim().isNotEmpty
      ? remote.imagePath
      : local.imagePath;
  bumpIf(imagePath != local.imagePath);

  final transportType = remote.transportType.trim().isNotEmpty
      ? remote.transportType
      : local.transportType;
  bumpIf(transportType != local.transportType);

  bumpIf(remote.startPriceCents != local.startPriceCents);
  bumpIf(remote.floorPriceCents != local.floorPriceCents);
  bumpIf(remote.finalPriceCents != local.finalPriceCents);
  bumpIf(remote.status != local.status);
  bumpIf(remote.currentPriceCents != local.currentPriceCents);
  bumpIf(remote.auctionStep != local.auctionStep);
  bumpIf(remote.auctionBidCount != local.auctionBidCount);
  bumpIf(remote.auctionEndsAt != local.auctionEndsAt);
  bumpIf(remote.leadingCourierId != local.leadingCourierId);
  bumpIf(remote.winnerCourierId != local.winnerCourierId);
  bumpIf(remote.winnerSelectedAt != local.winnerSelectedAt);

  final int mergedAuctionStep;
  final int mergedAuctionBidCount;
  final int? mergedCurrentPriceCents;
  final DateTime? mergedAuctionEndsAt;
  final String? mergedLeadingCourierId;
  if (local.status == JobStatus.auctionLive &&
      remote.status == JobStatus.auctionLive) {
    final b = _mergeAuctionLiveAtomicBundle(local, remote);
    mergedAuctionStep = b.step;
    mergedAuctionBidCount = b.bidCount;
    mergedCurrentPriceCents = b.currentPriceCents;
    mergedAuctionEndsAt = b.auctionEndsAt;
    mergedLeadingCourierId = b.leadingCourierId;
  } else {
    mergedAuctionStep = remote.auctionStep;
    mergedAuctionBidCount = remote.auctionBidCount;
    mergedCurrentPriceCents = remote.status == JobStatus.auctionLive
        ? (remote.currentPriceCents ?? local.currentPriceCents)
        : remote.currentPriceCents;
    mergedAuctionEndsAt = remote.auctionEndsAt;
    mergedLeadingCourierId = remote.leadingCourierId;
  }

  var j = local.copyWith(
    id: remote.id,
    senderId: remote.senderId,
    title: title,
    description: description,
    pickupAddress: pickup,
    dropoffAddress: dropoff,
    productType: productType,
    productWeightKg: productWeightKg,
    productVolumeL: productVolumeL,
    dimensionsMm: dimensionsMm,
    volumeCategoryKey: volumeCategoryKey,
    transportType: transportType,
    recipientName: recipientName,
    recipientPhone: recipientPhone,
    imagePath: imagePath,
    deliverySpeed: deliverySpeed,
    deliveryWindowStart: deliveryWindowStart,
    deliveryWindowEnd: deliveryWindowEnd,
    startPriceCents: remote.startPriceCents,
    floorPriceCents: remote.floorPriceCents,
    finalPriceCents: remote.finalPriceCents,
    fragile: fragile,
    coldChain: coldChain,
    orderComments: orderComments,
    paymentType: paymentType,
    regionCode: regionCode,
    districtCode: districtCode,
    pickupLat: remote.pickupLat ?? local.pickupLat,
    pickupLng: remote.pickupLng ?? local.pickupLng,
    dropoffLat: remote.dropoffLat ?? local.dropoffLat,
    dropoffLng: remote.dropoffLng ?? local.dropoffLng,
    pickupRegion: pickupRegion,
    pickupDistrictOrCity: pickupDistrictOrCity,
    pickupRegionOriginal:
        local.pickupRegionOriginal ?? remote.pickupRegionOriginal,
    pickupDistrictOriginal:
        local.pickupDistrictOriginal ?? remote.pickupDistrictOriginal,
    pickupRegionKey: pickupRegionKey,
    pickupDistrictKey: pickupDistrictKey,
    dropoffRegion: dropoffRegion,
    dropoffDistrictOrCity: dropoffDistrictOrCity,
    status: remote.status,
    auctionEndsAt: mergedAuctionEndsAt,
    auctionStep: mergedAuctionStep,
    auctionBidCount: mergedAuctionBidCount,
    currentPriceCents: mergedCurrentPriceCents,
    leadingCourierId: mergedLeadingCourierId,
    winnerCourierId: remote.winnerCourierId,
    winnerSelectedAt: remote.winnerSelectedAt,
    createdAt: remote.createdAt,
  );
  final courierBeforeLat = j.courierLat;
  final courierBeforeLng = j.courierLng;
  final courierBeforeAt = j.courierLocationAt;
  j = _mergeCourierSnapshotOnto(j, remote);
  if (j.courierLat != courierBeforeLat ||
      j.courierLng != courierBeforeLng ||
      j.courierLocationAt != courierBeforeAt) {
    n++;
  }
  return (j, n);
}

/// Remote kuryer snapshot: yangiroq `courier_location_updated_at` ustun qiladi.
JobEntity _mergeCourierSnapshotOnto(JobEntity base, JobEntity incomingRemote) {
  final rLat = incomingRemote.courierLat;
  final rLng = incomingRemote.courierLng;
  final rAt = incomingRemote.courierLocationAt;
  if (rLat == null || rLng == null) return base;

  final lAt = base.courierLocationAt;
  if (rAt != null && lAt != null && rAt.isBefore(lAt)) {
    return base;
  }

  return base.copyWith(
    courierLat: rLat,
    courierLng: rLng,
    courierLocationAt: rAt ?? base.courierLocationAt,
    courierHeading: incomingRemote.courierHeading ?? base.courierHeading,
    courierSpeedMps: incomingRemote.courierSpeedMps ?? base.courierSpeedMps,
    courierAccuracyM: incomingRemote.courierAccuracyM ?? base.courierAccuracyM,
  );
}

DateTime? _parseAuctionRpcDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

String? _stringFromRpc(dynamic v) {
  if (v == null) return null;
  if (v is String) {
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

bool _isDeliveryLifecycleStatus(JobStatus s) {
  return s == JobStatus.assigned ||
      s == JobStatus.pickedUp ||
      s == JobStatus.delivered ||
      s == JobStatus.completed;
}

int _deliveryLifecycleRank(JobStatus s) {
  switch (s) {
    case JobStatus.assigned:
      return 10;
    case JobStatus.pickedUp:
      return 20;
    case JobStatus.delivered:
      return 30;
    case JobStatus.completed:
      return 40;
    default:
      return 0;
  }
}

/// Debug: auction field provenance (SQLite read vs remote upsert vs RPC vs skips).
void logAuctionSourceTruth({
  required String source,
  required String orderId,
  required JobEntity job,
}) {
  if (!kDebugMode) return;
  final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
  debugPrint(
    '[auctionSourceTruth] platform=$platform source=$source orderId=$orderId '
    'status=${job.status} auctionStep=${job.auctionStep} '
    'leadingCourierId=${job.leadingCourierId} currentPriceCents=${job.currentPriceCents} '
    'auctionEndsAt=${job.auctionEndsAt} auctionBidCount=${job.auctionBidCount} '
    'syncedFromSupabase=${job.syncedFromSupabase}',
  );
}

void logAuctionSourceTruthIncomingDto({
  required String source,
  required String orderId,
  required RemoteOrderDto dto,
}) {
  if (!kDebugMode) return;
  final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
  debugPrint(
    '[auctionSourceTruth] platform=$platform source=$source orderId=$orderId '
    'status=${dto.status} auctionStep=${dto.auctionStep} '
    'leadingCourierId=${dto.leadingCourierId} currentPriceCents=${dto.currentPriceCents} '
    'auctionEndsAt=${dto.auctionEndsAt} auctionBidCount=${dto.auctionBidCount} '
    '(incoming_remote_dto)',
  );
}

StateError _auctionRpcError(String code) {
  switch (code) {
    case 'auction_expired':
      return StateError('auction_timer_ended');
    case 'already_leading':
      return StateError('already_leading');
    case 'at_floor':
      return StateError('at_floor');
    case 'auction_not_live':
    case 'bad_status':
    case 'not_found':
    case 'invalid_start_price':
      return StateError('job_not_posted');
    case 'forbidden':
    case 'not_authenticated':
      return StateError('auction_forbidden');
    default:
      return StateError('auction_rpc_$code');
  }
}

double _courierProximityKm(
  double courierLat,
  double courierLng,
  double targetLat,
  double targetLng,
) {
  const d = Distance();
  return d.as(
    LengthUnit.Kilometer,
    LatLng(courierLat, courierLng),
    LatLng(targetLat, targetLng),
  );
}

class _CourierPushThrottle {
  _CourierPushThrottle();

  DateTime? lastAt;
  double? lastLat;
  double? lastLng;

  static final Map<String, _CourierPushThrottle> _byKey = {};

  /// True: interval tugagan yoki [minMoveM] dan ortiq siljigan.
  static bool shouldEmit({
    required String jobId,
    required String courierId,
    required double lat,
    required double lng,
    Duration minInterval = const Duration(seconds: 8),
    double minMoveM = 35,
  }) {
    final key = '$jobId|$courierId';
    final t = _byKey.putIfAbsent(key, _CourierPushThrottle.new);
    final now = DateTime.now();
    if (t.lastAt == null) {
      t.lastAt = now;
      t.lastLat = lat;
      t.lastLng = lng;
      return true;
    }
    final dt = now.difference(t.lastAt!);
    const d = Distance();
    final moved = d.as(
      LengthUnit.Meter,
      LatLng(t.lastLat!, t.lastLng!),
      LatLng(lat, lng),
    );
    if (dt < minInterval && moved < minMoveM) {
      return false;
    }
    t.lastAt = now;
    t.lastLat = lat;
    t.lastLng = lng;
    return true;
  }
}

class CreateJobInput {
  CreateJobInput({
    required this.senderId,
    required this.productName,
    required this.productType,
    required this.weightKg,
    required this.volumeL,
    required this.dimensionsMm,
    required this.transportType,
    required this.pickupText,
    required this.dropoffText,
    this.pickupRegion,
    this.pickupDistrictOrCity,
    this.dropoffRegion,
    this.dropoffDistrictOrCity,
    required this.recipientName,
    required this.recipientPhone,
    required this.imagePath,
    this.imageBytes,
    this.imageContentType,
    required this.deliverySpeed,
    this.deliveryWindowStart,
    this.deliveryWindowEnd,
    required this.volumeCategory,
    required this.startPrice,
    required this.description,
    required this.fragile,
    required this.coldChain,
    required this.paymentType,
    required this.regionCode,
    required this.districtCode,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.pickupRegionOriginal,
    this.pickupDistrictOriginal,
    required this.sourceLanguageCode,
    this.orderComments,
  });

  final String senderId;
  final String productName;
  final String productType;
  final double weightKg;
  final double volumeL;
  final String dimensionsMm;
  final String transportType;
  final String pickupText;
  final String dropoffText;
  final String? pickupRegion;
  final String? pickupDistrictOrCity;
  final String? dropoffRegion;
  final String? dropoffDistrictOrCity;
  final String recipientName;
  final String recipientPhone;
  final String imagePath;
  /// Tanlangan rasm (asosan web); null bo‘lsa [imagePath] dan o‘qiladi.
  final Uint8List? imageBytes;
  /// Masalan `image/jpeg` (image_picker [XFile.mimeType]).
  final String? imageContentType;
  final DeliverySpeed deliverySpeed;
  final String? deliveryWindowStart;
  final String? deliveryWindowEnd;
  final VolumeCategory volumeCategory;
  final double startPrice;
  final String description;
  final bool fragile;
  final bool coldChain;
  final PaymentType paymentType;
  final String regionCode;
  final String districtCode;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  /// Geocoder viloyat matni (audit).
  final String? pickupRegionOriginal;
  /// Geocoder tuman qatlamlari (audit).
  final String? pickupDistrictOriginal;
  final String sourceLanguageCode;
  /// Supabase `comments`; bo‘sh bo‘lsa yuborilmaydi.
  final String? orderComments;
}

class JobRepository {
  JobRepository({
    required JobLocalPersistence localPersistence,
    required TranslationService translationService,
    required UserRepository userRepository,
    required AuthRepository authRepository,
    SupabaseOrderService? supabaseOrderService,
  })  : _local = localPersistence,
        _translation = translationService,
        _users = userRepository,
        _auth = authRepository,
        _remoteOrders = supabaseOrderService;

  final JobLocalPersistence _local;
  final TranslationService _translation;
  final UserRepository _users;
  final AuthRepository _auth;
  final SupabaseOrderService? _remoteOrders;
  final _uuid = const Uuid();

  static String? _seedRegionUz(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    try {
      return RegionsSeed.regions.firstWhere((e) => e.code == code).name.uz;
    } catch (_) {
      return null;
    }
  }

  static String? _seedDistrictUz(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    try {
      return RegionsSeed.districts.firstWhere((e) => e.code == code).name.uz;
    } catch (_) {
      return null;
    }
  }

  Future<void> _assertCourierJobTransportMatch({
    required JobEntity job,
    required String courierId,
  }) async {
    final keys = await _auth.effectiveCourierTransportKeys(courierId);
    if (keys.isEmpty) {
      throw StateError('courier_transport_not_configured');
    }
    final jobKeys =
        JobTransportType.normalizedJobTransportKeysFromStored(job.transportType);
    if (jobKeys.isEmpty) {
      throw StateError('job_transport_invalid');
    }
    if (!jobKeys.any(keys.contains)) {
      throw StateError('transport_mismatch');
    }
  }

  Future<void> tickAuctions() async {
    final remote = _remoteOrders;
    if (remote != null) {
      try {
        final n = await remote.finalizeExpiredAuctionsRpc();
        if (kDebugMode && n > 0) {
          debugPrint('[auction] finalize rpc rows=$n');
        }
      } catch (e, st) {
        debugPrint('[auction] finalizeExpiredAuctionsRpc failed: $e');
        if (kDebugMode) debugPrintStack(stackTrace: st);
      }
    }

    final assignedIds = await _local.processExpiredAuctions();
    if (remote == null || assignedIds.isEmpty) return;
    for (final id in assignedIds) {
      final job = await _local.getJobById(id);
      if (job == null) continue;
      logAuctionSourceTruth(
        source: 'local_sqlite_after_expired_tick',
        orderId: id,
        job: job,
      );
      if (!job.syncedFromSupabase) continue;
      final w = job.winnerCourierId;
      final fp = job.finalPriceCents;
      if (w == null || fp == null) continue;
      try {
        if (kDebugMode) {
          debugPrint(
            '[auction] winner selected local id=$id winner=$w final_cents=$fp → Supabase',
          );
        }
        await remote.finalizeAuctionWinnerRemote(
          orderId: id,
          winnerCourierId: w,
          finalPriceCents: fp,
        );
      } catch (e, st) {
        debugPrint('[auction] finalizeAuctionWinnerRemote failed: $e');
        if (kDebugMode) debugPrintStack(stackTrace: st);
      }
    }
  }

  /// Supabase RPC javobidan SQLite + tarix (bir xil bid id — idempotent).
  Future<JobEntity> _finishAuctionRpcAndPersist(
    JobEntity job,
    Map<String, dynamic> r,
    String courierId,
  ) async {
    if (r['ok'] != true) {
      final e = r['error']?.toString() ?? 'unknown';
      throw _auctionRpcError(e);
    }
    final action = r['action']?.toString() ?? '';
    final bidId = r['bid_id']?.toString() ?? '';
    final step = (r['auction_step'] as num?)?.toInt() ?? job.auctionStep;
    final bidCount = (r['auction_bid_count'] as num?)?.toInt() ?? job.auctionBidCount;
    final priceAfter = (r['price_after_cents'] as num?)?.toInt() ??
        (r['current_price_cents'] as num?)?.toInt() ??
        AuctionMath.committedPriceCents(
          job.startPriceCents,
          step,
          job.floorPriceCents,
        );
    final priceBefore = (r['price_before_cents'] as num?)?.toInt();
    final minFloor = (r['minimum_price_cents'] as num?)?.toInt();
    final ends = _parseAuctionRpcDate(r['auction_ends_at']) ??
        _parseAuctionRpcDate(r['auction_expires_at']);
    var leading = _stringFromRpc(r['leading_courier_id']);
    if (leading == null || leading.isEmpty) leading = courierId;

    if (kDebugMode) {
      final beforeCur = job.currentPriceCents ?? job.startPriceCents;
      final minRef = minFloor ?? job.floorPriceCents;
      debugPrint(
        '[auction-rpc] before order=${job.id} current=$beforeCur min=$minRef '
        'start=${job.startPriceCents} step=${job.auctionStep} bids=${job.auctionBidCount}',
      );
      if (action == 'start') {
        debugPrint(
          '[auction] start order=${job.id} courier=$courierId startPrice=${job.startPriceCents}',
        );
      } else {
        debugPrint(
          '[auction] bid order=${job.id} courier=$courierId before=$priceBefore after=$priceAfter',
        );
      }
      final floorRef = minFloor ?? job.floorPriceCents;
      if (priceAfter <= floorRef) {
        debugPrint('[auction] floor applied order=${job.id} price=$priceAfter');
      }
      debugPrint('[auction] leader order=${job.id} courier=$leading');
      debugPrint('[auction] expiresAt=$ends');
      debugPrint(
        '[auction-rpc] after order=${job.id} newPrice=$priceAfter bidCount=$bidCount '
        'step=$step leader=$leading',
      );
    }

    if (bidId.isNotEmpty) {
      await _local.insertAuctionStepIfAbsent(
        id: bidId,
        jobId: job.id,
        courierId: courierId,
        stepIndex: step,
        priceCents: priceAfter,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
    }

    final floor = minFloor ?? job.floorPriceCents;
    // RPC response is server-confirmed for this action; mark row as remote-backed
    // so auction UI is not treated as unsynced local-only state.
    final next = job.copyWith(
      syncedFromSupabase: true,
      status: JobStatus.auctionLive,
      auctionStep: step,
      auctionBidCount: bidCount,
      auctionEndsAt: ends,
      leadingCourierId: leading,
      floorPriceCents: floor,
      currentPriceCents: priceAfter,
    );
    await _local.updateJob(next);
    logAuctionSourceTruth(
      source: 'rpc_persisted_sqlite',
      orderId: job.id,
      job: next,
    );
    if (kDebugMode) {
      debugPrint(
        '[auction-merge] localPersist order=${job.id} current=${next.currentPriceCents} '
        'step=${next.auctionStep}',
      );
      debugPrint(
        '[auctionCrossDevice] rpcPersist order=${job.id} callerCourier=$courierId '
        'persistedLead=${next.leadingCourierId} step=${next.auctionStep} '
        'current=${next.currentPriceCents} ends=${next.auctionEndsAt}',
      );
    }
    return next;
  }

  Future<JobEntity> createPostedJob(CreateJobInput input) async {
    final title = await _translation.localizeUserText(
      text: input.productName,
      sourceLanguageCode: input.sourceLanguageCode,
    );
    final description = await _translation.localizeUserText(
      text: input.description,
      sourceLanguageCode: input.sourceLanguageCode,
    );
    final productType = await _translation.localizeUserText(
      text: input.productType,
      sourceLanguageCode: input.sourceLanguageCode,
    );
    final pickup = await _translation.localizeUserText(
      text: input.pickupText,
      sourceLanguageCode: input.sourceLanguageCode,
    );
    final dropoff = await _translation.localizeUserText(
      text: input.dropoffText,
      sourceLanguageCode: input.sourceLanguageCode,
    );

    final startCents = (input.startPrice * 100).round();
    final floorCents = AuctionMath.floorPriceCents(startCents);

    final dispKeys = WorkAreaKeys.fromPickupDisplay(
      input.pickupRegion,
      input.pickupDistrictOrCity,
    );
    final codeKeys = WorkAreaKeys.fromAdminCodes(
      input.regionCode,
      input.districtCode,
    );
    final pickupRegionKey = codeKeys.regionKey.isNotEmpty
        ? codeKeys.regionKey
        : dispKeys.regionKey;
    final pickupDistrictKey = codeKeys.districtKey.isNotEmpty
        ? codeKeys.districtKey
        : dispKeys.districtKey;

    // Xaritadan kelgan matn (bo‘lsa) ustun: noto‘g‘ri fallback kodlar seed nomi bilan
    // pickup matnini bosib yubormasin; kuryer tasmasi va Supabase `pickup_*` bilan mos.
    final String? displayRegion =
        (input.pickupRegion?.trim().isNotEmpty ?? false)
            ? input.pickupRegion!.trim()
            : _seedRegionUz(input.regionCode);
    final String? displayDistrict =
        (input.pickupDistrictOrCity?.trim().isNotEmpty ?? false)
            ? input.pickupDistrictOrCity!.trim()
            : _seedDistrictUz(input.districtCode);

    final mappedCanonDistrict =
        LocationKeyNormalizer.districtKeyFromRaw(displayDistrict);

    if (kDebugMode) {
      debugPrint(
        '[orderArea] geocoder region=${input.pickupRegionOriginal} '
        'geocoder district raw=${input.pickupDistrictOriginal}',
      );
      debugPrint(
        '[orderArea] resolver admin=${input.regionCode}/${input.districtCode} '
        'displayDistrict=$displayDistrict',
      );
      debugPrint(
        '[orderArea] mapped canonical district key=$mappedCanonDistrict '
        'saved pickupDistrictKey=$pickupDistrictKey pickupRegionKey=$pickupRegionKey',
      );
    }

    final id = _uuid.v4();

    Uint8List? imgBytes = input.imageBytes;
    if (imgBytes == null || imgBytes.isEmpty) {
      final p = input.imagePath.trim();
      if (p.isNotEmpty) {
        imgBytes = await order_image_read.readLocalImageBytes(p);
      }
    }
    final hasImage = imgBytes != null && imgBytes.isNotEmpty;

    var resolvedImage = '';
    if (hasImage) {
      final ctRaw = input.imageContentType?.trim() ?? '';
      final ct = ctRaw.isEmpty ? 'image/jpeg' : ctRaw;
      final bytesNonNull = imgBytes;
      if (kDebugMode) {
        debugPrint(
          '[order-image] resolve image jobId=$id bytes=${bytesNonNull.length} '
          'localPath=${input.imagePath}',
        );
      }
      final remoteOrders = _remoteOrders;
      if (remoteOrders != null) {
        try {
          resolvedImage =
              await remoteOrders.uploadOrderProductImageAndGetPublicUrl(
            jobId: id,
            bytes: bytesNonNull,
            contentType: ct,
          );
          if (kDebugMode) {
            debugPrint('[order-image] payload imageUrl=$resolvedImage');
          }
        } catch (e, st) {
          debugPrint('[order-image] upload fail error=$e');
          if (kDebugMode) debugPrintStack(stackTrace: st);
          throw OrderImageUploadException(
            'Rasm yuklanmadi. Internet yoki Supabase Storage ni tekshiring.\n$e',
          );
        }
      } else {
        final localPath = input.imagePath.trim();
        if (kIsWeb) {
          throw const OrderImageUploadException(
            'Brauzerda rasmni saqlash uchun Supabase (Storage) ulangan bo‘lishi kerak.',
          );
        }
        if (localPath.isEmpty) {
          throw const OrderImageUploadException(
            'Rasm fayli topilmadi. Iltimos, qayta tanlang.',
          );
        }
        resolvedImage = localPath;
        if (kDebugMode) {
          debugPrint('[order-image] payload imageUrl=(local) $resolvedImage');
        }
      }
    }

    final job = JobEntity(
      id: id,
      senderId: input.senderId,
      title: title,
      description: description,
      productType: productType,
      pickupAddress: pickup,
      dropoffAddress: dropoff,
      productWeightKg: input.weightKg,
      productVolumeL: input.volumeL,
      dimensionsMm: input.dimensionsMm,
      transportType: input.transportType,
      recipientName: input.recipientName,
      recipientPhone: input.recipientPhone,
      imagePath: resolvedImage,
      deliverySpeed: input.deliverySpeed,
      deliveryWindowStart: input.deliveryWindowStart,
      deliveryWindowEnd: input.deliveryWindowEnd,
      volumeCategoryKey: input.volumeCategory.storageKey,
      startPriceCents: startCents,
      floorPriceCents: floorCents,
      fragile: input.fragile,
      coldChain: input.coldChain,
      orderComments: () {
        final t = input.orderComments?.trim() ?? '';
        return t.isEmpty ? null : t;
      }(),
      paymentType: input.paymentType,
      regionCode: input.regionCode,
      districtCode: input.districtCode,
      pickupLat: input.pickupLat,
      pickupLng: input.pickupLng,
      dropoffLat: input.dropoffLat,
      dropoffLng: input.dropoffLng,
      pickupRegion: displayRegion,
      pickupDistrictOrCity: displayDistrict,
      pickupRegionOriginal: input.pickupRegionOriginal,
      pickupDistrictOriginal: input.pickupDistrictOriginal,
      pickupRegionKey: pickupRegionKey,
      pickupDistrictKey: pickupDistrictKey,
      dropoffRegion: input.dropoffRegion,
      dropoffDistrictOrCity: input.dropoffDistrictOrCity,
      status: JobStatus.posted,
      createdAt: DateTime.now(),
    );
    await _local.insertJob(job);
    debugPrint('[job] created posted job ${job.id}');
    if (kDebugMode) {
      debugPrint(
        '[order-image] order created id=${job.id} imageRef=${job.imagePath}',
      );
      debugPrint(
        '[crossPlatformOrder] createPostedJob before remote id=${job.id} '
        'status=${job.status.toStorage()} sender_id=${job.senderId} '
        'pickup_region=${job.pickupRegion} pickup_district=${job.pickupDistrictOrCity} '
        'region_code=${job.regionCode} district_code=${job.districtCode} '
        'pickupRegionKey=${job.pickupRegionKey} pickupDistrictKey=${job.pickupDistrictKey} '
        'transport_type=${job.transportType} start_price_cents=${job.startPriceCents} '
        'floor_price_cents=${job.floorPriceCents} created_at=${job.createdAt.toUtc().toIso8601String()} '
        'image_url=${job.imagePath} synced_from_supabase=${job.syncedFromSupabase}',
      );
    }
    var out = job;
    final remote = _remoteOrders;
    if (remote != null) {
      try {
        await remote.createOrderRemote(job);
        if (kDebugMode) {
          debugPrint('[order-create] remote insert ok id=${job.id}');
        }
        out = job.copyWith(syncedFromSupabase: true);
        await _local.updateJob(out);
      } catch (e, st) {
        await _local.deleteJobById(job.id);
        if (kDebugMode) {
          debugPrint(
            '[order-create] remote insert failed id=${job.id} error=$e',
          );
          debugPrintStack(stackTrace: st);
        }
        throw OrderRemoteSyncException(
          'Buyurtma serverga yuborilmadi. Internet yoki Supabase sozlamalarini tekshirib, qayta urinib ko‘ring.',
          cause: e,
        );
      }
    }
    return out;
  }

  /// Realtime may deliver an old `posted` row while the server is already
  /// `auction_live`. We skip applying that payload to protect the local timer,
  /// then fetch the canonical row once to converge SQLite with Supabase.
  Future<void> _reconcileCanonicalOrderAfterStalePostedSkip(
    String orderId,
  ) async {
    final remote = _remoteOrders;
    if (remote == null || orderId.isEmpty) return;
    try {
      if (kDebugMode) {
        debugPrint(
          '[auction-reconcile] canonical fetch after stale_posted_skip orderId=$orderId',
        );
      }
      final map = await remote.fetchOrderRowById(orderId);
      if (map == null || map.isEmpty) return;
      final fresh = RemoteOrderDto.fromSupabaseMap(map);
      if (fresh.id.isEmpty || fresh.senderId.isEmpty) return;
      logAuctionSourceTruthIncomingDto(
        source: 'canonical_fetch_reconcile',
        orderId: fresh.id,
        dto: fresh,
      );
      await upsertPostedOrderFromRemote(
        fresh,
        isCanonicalReconcileFetch: true,
      );
    } catch (e, st) {
      debugPrint('[auction-reconcile] failed orderId=$orderId error=$e');
      if (kDebugMode) debugPrintStack(stackTrace: st);
    }
  }

  /// Courier cache: insert/update from Supabase without overwriting sender-canonical rows.
  ///
  /// **Merge rule (local `syncedFromSupabase == false`):**
  /// - **Promote** when the row is the same logical order: same `id`, compatible
  ///   `senderId` (if both sides non-empty they must match), and we are not in a
  ///   protected skip case below. Remote fields from [dto] overwrite the SQLite row;
  ///   `synced_from_supabase` is set to 1.
  /// - **Skip (sender conflict):** local and remote both have non-empty `senderId`
  ///   and they differ — likely wrong/colliding data, do not merge.
  /// - **Skip (in-progress local):** local `assigned` / `pickedUp` / `delivered` —
  ///   courier/sender workflow state must not be replaced from a stale remote row.
  /// - **Skip (terminal local):** local `completed` / `cancelled`.
  /// - **Skip (stale remote vs local auction):** local `auctionLive` but remote
  ///   status is only `posted` — keeps local auction timer/bids from being wiped.
  ///   Realtime can deliver an out-of-order `posted` snapshot; we then **fetch**
  ///   the canonical `orders` row once ([isCanonicalReconcileFetch] guards
  ///   against recursive reconcile) so SQLite can match Supabase when the
  ///   server is actually `auction_live` or ahead.
  Future<void> upsertPostedOrderFromRemote(
    RemoteOrderDto dto, {
    bool isCanonicalReconcileFetch = false,
  }) async {
    if (kDebugMode) {
      debugPrint('[supabase-upsert] incoming id=${dto.id} sender=${dto.senderId}');
    }
    if (dto.id.isEmpty || dto.senderId.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[supabase-upsert] action=skip reason=empty_id_or_sender '
          'synced_from_supabase written=0',
        );
      }
      return;
    }

    final existing = await _local.getJobById(dto.id);
    final remoteStatus = dto.statusAsJobStatus;

    if (kDebugMode) {
      final ex = existing;
      debugPrint('[supabase-upsert] remote senderId=${dto.senderId}');
      debugPrint(
        '[supabase-upsert] existingLocal=${ex == null ? "null" : "id=${ex.id} status=${ex.status} syncedFromSupabase=${ex.syncedFromSupabase} senderId=${ex.senderId}"}',
      );
    }

    var promoteLocalToRemote = false;
    if (existing != null && !existing.syncedFromSupabase) {
      final localSid = existing.senderId.trim();
      final remoteSid = dto.senderId.trim();
      if (localSid.isNotEmpty &&
          remoteSid.isNotEmpty &&
          localSid != remoteSid) {
        if (kDebugMode) {
          debugPrint(
            '[supabase-upsert] action=skip reason=sender_id_mismatch_local_vs_remote '
            'synced_from_supabase written=0',
          );
        }
        return;
      }

      if (existing.status == JobStatus.assigned ||
          existing.status == JobStatus.pickedUp ||
          existing.status == JobStatus.delivered) {
        if (kDebugMode) {
          debugPrint(
            '[supabase-upsert] action=skip reason=in_progress_local_status=${existing.status} '
            'synced_from_supabase written=0',
          );
        }
        return;
      }

      if (existing.status == JobStatus.completed ||
          existing.status == JobStatus.cancelled) {
        if (kDebugMode) {
          debugPrint(
            '[supabase-upsert] action=skip reason=local_terminal_status=${existing.status} '
            'synced_from_supabase written=0',
          );
        }
        return;
      }

      if (existing.status == JobStatus.auctionLive &&
          remoteStatus == JobStatus.posted) {
        logAuctionSourceTruth(
          source: 'local_sqlite_unchanged',
          orderId: dto.id,
          job: existing,
        );
        logAuctionSourceTruthIncomingDto(
          source: 'remote_upsert_skipped_stale_remote_posted',
          orderId: dto.id,
          dto: dto,
        );
        if (kDebugMode) {
          debugPrint(
            '[supabase-upsert] action=skip reason=stale_remote_posted_while_local_auction_live '
            'synced_from_supabase written=0',
          );
        }
        if (!isCanonicalReconcileFetch) {
          await _reconcileCanonicalOrderAfterStalePostedSkip(dto.id);
        }
        return;
      }

      promoteLocalToRemote = true;
      if (kDebugMode) {
        debugPrint(
          '[supabase-upsert] promote_local_to_remote eligible id=${dto.id} '
          'localStatus=${existing.status} remoteStatus=$remoteStatus',
        );
      }
    }

    await _users.ensureRemoteSenderStub(dto.senderId);
    final incoming =
        RemoteOrderMapper.toJobEntity(dto, syncedFromSupabase: true);
    if (kDebugMode) {
      debugPrint(
        '[remote-order] dto parsed id=${dto.id} region=${dto.regionCode ?? ""} '
        'district=${dto.districtCode ?? ""}',
      );
    }

    if (existing == null) {
      await _local.insertJob(incoming);
      if (kDebugMode) {
        debugPrint('[order-sync] local cache upsert id=${dto.id}');
        debugPrint(
          '[supabase-upsert] action=insert id=${dto.id} synced_from_supabase written=1',
        );
      }
      return;
    }

    final winnerRemote = incoming.winnerCourierId?.trim();
    if (incoming.status == JobStatus.assigned &&
        winnerRemote != null &&
        winnerRemote.isNotEmpty &&
        (existing.status == JobStatus.auctionLive ||
            existing.status == JobStatus.posted)) {
      final fp = incoming.finalPriceCents ??
          AuctionMath.committedPriceCents(
            existing.startPriceCents,
            incoming.auctionStep,
            existing.floorPriceCents,
          );
      await _local.updateJob(
        existing.copyWith(
          syncedFromSupabase: true,
          status: JobStatus.assigned,
          winnerCourierId: incoming.winnerCourierId,
          finalPriceCents: fp,
          auctionEndsAt: null,
          auctionStep: incoming.auctionStep,
          auctionBidCount: incoming.auctionBidCount,
          leadingCourierId:
              incoming.leadingCourierId ?? incoming.winnerCourierId,
          winnerSelectedAt: incoming.winnerSelectedAt ??
              existing.winnerSelectedAt ??
              DateTime.now(),
          currentPriceCents: null,
        ),
      );
      if (kDebugMode) {
        debugPrint(
          '[winner] order=${dto.id} winner=$winnerRemote finalPrice=$fp',
        );
        debugPrint('[order-sync] local cache upsert id=${dto.id}');
        debugPrint(
          '[supabase-upsert] action=update branch=remote_assigned_winner id=${dto.id} '
          'winner=$winnerRemote final_cents=$fp',
        );
      }
      return;
    }

    if (existing.status == JobStatus.auctionLive &&
        incoming.status == JobStatus.auctionLive) {
      final bundle = _mergeAuctionLiveAtomicBundle(existing, incoming);
      if (kDebugMode) {
        debugPrint(
          '[auction-merge] upsert id=${dto.id} atomic step=${bundle.step} '
          'price=${bundle.currentPriceCents} leader=${bundle.leadingCourierId}',
        );
        debugPrint('[order-sync] local cache upsert id=${dto.id}');
        debugPrint(
          '[supabase-upsert] action=${promoteLocalToRemote ? "promote_local_to_remote" : "update"} '
          'branch=auction_live_remote id=${dto.id} step=${bundle.step} '
          'ends=${bundle.auctionEndsAt} leader=${bundle.leadingCourierId}',
        );
      }
      await _local.updateJob(
        existing.copyWith(
          syncedFromSupabase: true,
          status: JobStatus.auctionLive,
          auctionEndsAt: bundle.auctionEndsAt,
          auctionStep: bundle.step,
          auctionBidCount: bundle.bidCount,
          currentPriceCents: bundle.currentPriceCents,
          leadingCourierId: bundle.leadingCourierId,
          winnerCourierId: incoming.winnerCourierId ?? existing.winnerCourierId,
        ),
      );
      final merged = await _local.getJobById(dto.id);
      if (merged != null) {
        logAuctionSourceTruth(
          source: 'remote_upsert_sqlite',
          orderId: dto.id,
          job: merged,
        );
      }
      return;
    }

    if (existing.status == JobStatus.auctionLive &&
        incoming.status == JobStatus.posted) {
      logAuctionSourceTruth(
        source: 'local_sqlite_unchanged',
        orderId: dto.id,
        job: existing,
      );
      logAuctionSourceTruthIncomingDto(
        source: 'remote_upsert_skipped_stale_remote_posted',
        orderId: dto.id,
        dto: dto,
      );
      if (kDebugMode) {
        debugPrint(
          '[supabase-upsert] action=skip reason=stale_remote_posted_while_local_auction_live '
          'synced_from_supabase written=0',
        );
      }
      if (!isCanonicalReconcileFetch) {
        await _reconcileCanonicalOrderAfterStalePostedSkip(dto.id);
      }
      return;
    }

    if (_isDeliveryLifecycleStatus(existing.status)) {
      if (!_isDeliveryLifecycleStatus(incoming.status)) {
        if (kDebugMode) {
          debugPrint(
            '[supabase-upsert] action=skip reason=local_delivery_remote_other_status '
            'local=${existing.status} remote=${incoming.status}',
          );
        }
        return;
      }
      final incomingSid = incoming.senderId.trim();
      final existingSid = existing.senderId.trim();
      if (incomingSid.isNotEmpty &&
          existingSid.isNotEmpty &&
          incomingSid != existingSid) {
        if (kDebugMode) {
          debugPrint(
            '[supabase-upsert] action=skip reason=sender_mismatch_in_delivery',
          );
        }
        return;
      }
      final wIn = incoming.winnerCourierId?.trim() ?? '';
      final wEx = existing.winnerCourierId?.trim() ?? '';
      if (wEx.isNotEmpty && wIn.isNotEmpty && wIn != wEx) {
        if (kDebugMode) {
          debugPrint(
            '[supabase-upsert] action=skip reason=winner_mismatch_in_delivery',
          );
        }
        return;
      }
      final rR = _deliveryLifecycleRank(incoming.status);
      final rL = _deliveryLifecycleRank(existing.status);
      if (rR > rL) {
        await _local.updateJob(
          existing.copyWith(
            syncedFromSupabase: true,
            status: incoming.status,
            winnerCourierId:
                incoming.winnerCourierId ?? existing.winnerCourierId,
            finalPriceCents: incoming.finalPriceCents ?? existing.finalPriceCents,
            winnerSelectedAt:
                incoming.winnerSelectedAt ?? existing.winnerSelectedAt,
            courierCompletionNote: incoming.courierCompletionNote ??
                existing.courierCompletionNote,
            courierLat: incoming.courierLat ?? existing.courierLat,
            courierLng: incoming.courierLng ?? existing.courierLng,
            courierLocationAt:
                incoming.courierLocationAt ?? existing.courierLocationAt,
            courierHeading: incoming.courierHeading ?? existing.courierHeading,
            courierSpeedMps:
                incoming.courierSpeedMps ?? existing.courierSpeedMps,
            courierAccuracyM:
                incoming.courierAccuracyM ?? existing.courierAccuracyM,
          ),
        );
        if (kDebugMode) {
          debugPrint(
            '[supabase-upsert] action=update branch=delivery_lifecycle_progress '
            'id=${dto.id} ${existing.status}->${incoming.status}',
          );
        }
        return;
      }
      if (rR == rL) {
        await _local.updateJob(
          existing.copyWith(
            syncedFromSupabase: true,
            courierLat: incoming.courierLat ?? existing.courierLat,
            courierLng: incoming.courierLng ?? existing.courierLng,
            courierLocationAt:
                incoming.courierLocationAt ?? existing.courierLocationAt,
            courierHeading: incoming.courierHeading ?? existing.courierHeading,
            courierSpeedMps:
                incoming.courierSpeedMps ?? existing.courierSpeedMps,
            courierAccuracyM:
                incoming.courierAccuracyM ?? existing.courierAccuracyM,
            courierCompletionNote: incoming.courierCompletionNote ??
                existing.courierCompletionNote,
            winnerSelectedAt:
                incoming.winnerSelectedAt ?? existing.winnerSelectedAt,
          ),
        );
        if (kDebugMode) {
          debugPrint(
            '[supabase-upsert] action=update branch=delivery_same_rank_patch '
            'id=${dto.id} status=${existing.status}',
          );
        }
        return;
      }
      if (kDebugMode) {
        debugPrint(
          '[supabase-upsert] action=skip reason=stale_remote_delivery_rank '
          'local=${existing.status} remote=${incoming.status}',
        );
      }
      return;
    }

    final (mergedCore, mergeFields) =
        _mergeRemoteJobOntoExisting(existing, incoming, dto);
    var postedMerged = mergedCore.copyWith(
      syncedFromSupabase: true,
      winnerCourierId: existing.winnerCourierId,
      finalPriceCents: existing.finalPriceCents,
      courierCompletionNote: existing.courierCompletionNote,
    );
    postedMerged = _mergeCourierSnapshotOnto(postedMerged, incoming);
    await _local.updateJob(postedMerged);
    if (kDebugMode) {
      debugPrint(
        '[remote-order] merge applied id=${dto.id} fieldsUpdated=$mergeFields',
      );
      debugPrint('[order-sync] local cache upsert id=${dto.id}');
      debugPrint(
        '[supabase-upsert] action=${promoteLocalToRemote ? "promote_local_to_remote" : "update"} '
        'branch=posted_merge id=${dto.id} synced_from_supabase written=1',
      );
    }
  }

  /// Cache a bid row from Supabase realtime (idempotent by bid id).
  Future<void> applyRemoteBidInsert({
    required String id,
    required String orderId,
    required String courierId,
    required int stepIndex,
    required int priceCents,
    required DateTime createdAt,
  }) async {
    if (id.isEmpty || orderId.isEmpty || courierId.isEmpty) return;
    if (kDebugMode) {
      debugPrint(
        '[auction-bids] insert id=$id order=$orderId step=$stepIndex '
        'after=$priceCents courier=$courierId',
      );
    }
    await _local.insertAuctionStepIfAbsent(
      id: id,
      jobId: orderId,
      courierId: courierId,
      stepIndex: stepIndex,
      priceCents: priceCents,
      createdAtMs: createdAt.millisecondsSinceEpoch,
    );
  }

  Future<JobEntity> joinAuction({
    required String jobId,
    required String courierId,
  }) async {
    final job = await _local.getJobById(jobId);
    if (job == null) throw StateError('job_not_found');
    await _assertCourierJobTransportMatch(job: job, courierId: courierId);
    final remote = _remoteOrders;

    if (remote != null) {
      if (job.status != JobStatus.posted) {
        throw StateError('job_not_posted');
      }
      if (kDebugMode) {
        debugPrint(
          '[auction] bid start job=$jobId courier=$courierId branch=rpc_join',
        );
        debugPrint(
          '[auctionCrossDevice] joinAuction order=$jobId effectiveCourier=$courierId '
          'localLead=${job.leadingCourierId} step=${job.auctionStep} '
          'currentPrice=${job.currentPriceCents} status=${job.status}',
        );
      }
      final r = await remote.startOrStepAuctionRpc(
        orderId: jobId,
        courierId: courierId,
      );
      return _finishAuctionRpcAndPersist(job, r, courierId);
    }

    if (kDebugMode) {
      debugPrint(
        '[auction] bid start job=$jobId courier=$courierId branch=join_posted_local',
      );
    }
    if (job.status != JobStatus.posted) {
      throw StateError('job_not_posted');
    }
    final ends = DateTime.now().add(const Duration(seconds: 30));
    final committed = AuctionMath.committedPriceCents(
      job.startPriceCents,
      0,
      job.floorPriceCents,
    );
    final bidId = _uuid.v4();
    final createdAt = DateTime.now();
    await _local.insertAuctionStepIfAbsent(
      id: bidId,
      jobId: jobId,
      courierId: courierId,
      stepIndex: 0,
      priceCents: committed,
      createdAtMs: createdAt.millisecondsSinceEpoch,
    );
    final next = job.copyWith(
      status: JobStatus.auctionLive,
      leadingCourierId: courierId,
      auctionStep: 0,
      auctionBidCount: 1,
      auctionEndsAt: ends,
      currentPriceCents: committed,
    );
    await _local.updateJob(next);
    logAuctionSourceTruth(
      source: 'optimistic_local_sqlite_no_remote',
      orderId: jobId,
      job: next,
    );
    if (kDebugMode) {
      debugPrint(
        '[auction] bid accepted local job=$jobId step=0 price=$committed ends=$ends',
      );
    }
    return next;
  }

  Future<JobEntity> acceptLowerAuctionPrice({
    required String jobId,
    required String courierId,
  }) async {
    final job = await _local.getJobById(jobId);
    if (job == null) throw StateError('job_not_found');
    await _assertCourierJobTransportMatch(job: job, courierId: courierId);
    if (job.status != JobStatus.auctionLive) {
      throw StateError('auction_not_live');
    }
    final alreadyLeading = courierId == job.leadingCourierId;
    if (alreadyLeading) {
      if (kDebugMode) {
        debugPrint(
          '[auctionCrossDevice] acceptLower BLOCK already_leading order=$jobId '
          'courier=$courierId localLead=${job.leadingCourierId} step=${job.auctionStep}',
        );
      }
      throw StateError('already_leading');
    }

    final remote = _remoteOrders;
    if (remote != null) {
      if (kDebugMode) {
        debugPrint(
          '[auction] bid start job=$jobId courier=$courierId branch=rpc_accept_lower',
        );
        debugPrint(
          '[auctionCrossDevice] acceptLower order=$jobId effectiveCourier=$courierId '
          'localLead=${job.leadingCourierId} alreadyLeading=false '
          'step=${job.auctionStep} current=${job.currentPriceCents}',
        );
      }
      final r = await remote.startOrStepAuctionRpc(
        orderId: jobId,
        courierId: courierId,
      );
      return _finishAuctionRpcAndPersist(job, r, courierId);
    }

    if (kDebugMode) {
      debugPrint(
        '[auction] bid start job=$jobId courier=$courierId branch=accept_lower_local',
      );
    }
    if (!job.auctionTimerActive) {
      throw StateError('auction_timer_ended');
    }
    if (!AuctionMath.canDecreaseStep(
      job.startPriceCents,
      job.auctionStep,
      job.floorPriceCents,
    )) {
      throw StateError('at_floor');
    }
    final newStep = job.auctionStep + 1;
    final price = AuctionMath.committedPriceCents(
      job.startPriceCents,
      newStep,
      job.floorPriceCents,
    );
    final bidId = _uuid.v4();
    final createdAt = DateTime.now();
    final ends = DateTime.now().add(const Duration(seconds: 30));
    await _local.insertAuctionStepIfAbsent(
      id: bidId,
      jobId: jobId,
      courierId: courierId,
      stepIndex: newStep,
      priceCents: price,
      createdAtMs: createdAt.millisecondsSinceEpoch,
    );
    final next = job.copyWith(
      auctionStep: newStep,
      auctionBidCount: job.auctionBidCount + 1,
      leadingCourierId: courierId,
      auctionEndsAt: ends,
      currentPriceCents: price,
    );
    await _local.updateJob(next);
    logAuctionSourceTruth(
      source: 'optimistic_local_sqlite_no_remote',
      orderId: jobId,
      job: next,
    );
    if (kDebugMode) {
      debugPrint(
        '[auction] bid accepted local job=$jobId step=$newStep price=$price ends=$ends',
      );
    }
    return next;
  }

  Future<JobEntity> markPickedUp({
    required String jobId,
    required String courierId,
  }) async {
    final job = await _local.getJobById(jobId);
    if (job == null) throw StateError('job_not_found');
    if (job.winnerCourierId != courierId) {
      throw StateError('not_winner');
    }
    if (job.status != JobStatus.assigned) {
      throw StateError('wrong_status');
    }
    final next = job.copyWith(status: JobStatus.pickedUp);
    await _local.updateJob(next);
    final remote = _remoteOrders;
    if (remote != null && job.syncedFromSupabase) {
      try {
        await remote.patchOrderLifecycleRemote(
          orderId: jobId,
          fields: {'status': JobStatus.pickedUp.toStorage()},
        );
      } catch (e, st) {
        debugPrint('[delivery] remote markPickedUp failed: $e');
        if (kDebugMode) debugPrintStack(stackTrace: st);
      }
    }
    if (kDebugMode) {
      debugPrint('[delivery] picked_up order=$jobId by=$courierId');
    }
    return next;
  }

  Future<JobEntity> updateCourierLocation({
    required String jobId,
    required String reportingCourierId,
    required double lat,
    required double lng,
    double? heading,
    double? speedMps,
    double? accuracyM,
  }) async {
    final job = await _local.getJobById(jobId);
    if (job == null) throw StateError('job_not_found');
    if (job.winnerCourierId?.trim() != reportingCourierId.trim()) {
      if (kDebugMode) {
        debugPrint(
          '[tracking] skip push order=$jobId reason=not_winner reporter=$reportingCourierId',
        );
      }
      return job;
    }
    if (job.status != JobStatus.assigned &&
        job.status != JobStatus.pickedUp &&
        job.status != JobStatus.delivered) {
      if (kDebugMode) {
        debugPrint(
          '[tracking] skip push order=$jobId reason=invalid_status status=${job.status}',
        );
      }
      return job;
    }
    if (!_CourierPushThrottle.shouldEmit(
      jobId: jobId,
      courierId: reportingCourierId,
      lat: lat,
      lng: lng,
    )) {
      return job;
    }

    if (kDebugMode) {
      debugPrint(
        '[tracking] location sample lat=$lat lng=$lng order=$jobId',
      );
    }

    final remote = _remoteOrders;
    if (remote != null && job.syncedFromSupabase) {
      try {
        await remote.reportOrderCourierLocation(
          orderId: jobId,
          lat: lat,
          lng: lng,
          heading: heading,
          speed: speedMps,
          accuracy: accuracyM,
        );
        if (kDebugMode) {
          debugPrint('[tracking] remote push ok order=$jobId');
        }
      } catch (e, st) {
        debugPrint('[tracking] remote push fail order=$jobId error=$e');
        if (kDebugMode) debugPrintStack(stackTrace: st);
        return job;
      }
    }

    final now = DateTime.now();
    var next = job.copyWith(
      courierLat: lat,
      courierLng: lng,
      courierLocationAt: now,
      courierHeading: heading ?? job.courierHeading,
      courierSpeedMps: speedMps ?? job.courierSpeedMps,
      courierAccuracyM: accuracyM ?? job.courierAccuracyM,
    );
    next = await _applyProximityMilestones(next);
    await _local.updateJob(next);
    return next;
  }

  Future<void> _appendUserInAppNotification(
    String userId,
    SenderInAppNotification notification,
  ) async {
    final existing = await SenderNotificationsStorage.load(userId);
    final updated = [notification, ...existing].take(50).toList(growable: false);
    await SenderNotificationsStorage.save(userId, updated);
  }

  Future<void> _deliverProximityBundle({
    required String jobId,
    required String senderId,
    required String recipientPhoneRaw,
    required SenderNotificationKind kind,
    required String senderMessage,
    String? recipientMessage,
    required bool notifyRecipientInApp,
    required bool smsSender,
    required bool smsRecipient,
  }) async {
    await _appendUserInAppNotification(
      senderId,
      SenderInAppNotification(
        id: _uuid.v4(),
        kind: kind,
        jobId: jobId,
        createdAt: DateTime.now(),
        read: false,
        displayMessage: senderMessage,
      ),
    );

    if (smsSender) {
      final su = await _users.getUser(senderId);
      final msisdn = su != null
          ? PhoneValidator.normalizeTo998Msisdn(su.phone)
          : null;
      if (msisdn != null) {
        SmsDispatchLog.send(toPhone: msisdn, body: senderMessage);
      }
    }

    final recMsisdn =
        PhoneValidator.normalizeTo998Msisdn(recipientPhoneRaw);
    if (recMsisdn == null) return;

    if (notifyRecipientInApp) {
      final recId = await _users.findUserIdByNormalizedPhone(recMsisdn);
      final body = (recipientMessage ?? senderMessage).trim();
      if (recId != null && body.isNotEmpty) {
        await _appendUserInAppNotification(
          recId,
          SenderInAppNotification(
            id: _uuid.v4(),
            kind: kind,
            jobId: jobId,
            createdAt: DateTime.now(),
            read: false,
            displayMessage: body,
          ),
        );
      }
    }

    if (smsRecipient) {
      final smsBody = (recipientMessage ?? senderMessage).trim();
      if (smsBody.isNotEmpty) {
        SmsDispatchLog.send(toPhone: recMsisdn, body: smsBody);
      }
    }
  }

  Future<JobEntity> _applyProximityMilestones(JobEntity job) async {
    final clat = job.courierLat;
    final clng = job.courierLng;
    if (clat == null || clng == null) return job;
    if (job.winnerCourierId == null) return job;

    var j = job;
    final productLabel =
        job.title.uz.trim().isNotEmpty ? job.title.uz : job.title.en;

    if (j.status == JobStatus.assigned &&
        !j.notifiedPickup1Km &&
        j.pickupLat != null &&
        j.pickupLng != null) {
      final km = _courierProximityKm(clat, clng, j.pickupLat!, j.pickupLng!);
      if (km <= 1.0) {
        j = j.copyWith(notifiedPickup1Km: true);
        final msg =
            'Kuryer buyurtmangiz ($productLabel) uchun olib ketish manziliga taxminan 1 km qoldi.';
        await _deliverProximityBundle(
          jobId: j.id,
          senderId: j.senderId,
          recipientPhoneRaw: j.recipientPhone,
          kind: SenderNotificationKind.courierNearPickup1Km,
          senderMessage: msg,
          recipientMessage: null,
          notifyRecipientInApp: false,
          smsSender: true,
          smsRecipient: false,
        );
      }
    }

    if (j.status == JobStatus.pickedUp &&
        j.dropoffLat != null &&
        j.dropoffLng != null) {
      final km =
          _courierProximityKm(clat, clng, j.dropoffLat!, j.dropoffLng!);

      if (!j.notifiedDropoff5Km && km <= 5.0) {
        j = j.copyWith(notifiedDropoff5Km: true);
        final senderMsg =
            'Kuryer buyurtmangiz ($productLabel) uchun yetkazish manziliga taxminan 5 km qoldi.';
        final recMsg =
            "Sizga yuborilayotgan jo'natma ($productLabel) kuryer tomonidan yetkazilmoqda — manzilga taxminan 5 km qoldi.";
        await _deliverProximityBundle(
          jobId: j.id,
          senderId: j.senderId,
          recipientPhoneRaw: j.recipientPhone,
          kind: SenderNotificationKind.courierNearDropoff5Km,
          senderMessage: senderMsg,
          recipientMessage: recMsg,
          notifyRecipientInApp: true,
          smsSender: true,
          smsRecipient: true,
        );
      }

      if (!j.notifiedDropoff2Km && km <= 2.0) {
        j = j.copyWith(notifiedDropoff2Km: true);
        final senderMsg2 =
            'Kuryer buyurtmangiz ($productLabel) uchun yetkazish manziliga taxminan 2 km qoldi.';
        final recMsg2 =
            "Sizga yuborilayotgan jo'natma ($productLabel) kuryer tomonidan yetkazilmoqda — manzilga taxminan 2 km qoldi.";
        await _deliverProximityBundle(
          jobId: j.id,
          senderId: j.senderId,
          recipientPhoneRaw: j.recipientPhone,
          kind: SenderNotificationKind.courierNearDropoff2Km,
          senderMessage: senderMsg2,
          recipientMessage: recMsg2,
          notifyRecipientInApp: true,
          smsSender: true,
          smsRecipient: true,
        );
      }
    }

    return j;
  }

  Future<JobEntity> markDelivered({
    required String jobId,
    required String courierId,
    String? note,
  }) async {
    final job = await _local.getJobById(jobId);
    if (job == null) throw StateError('job_not_found');
    if (job.winnerCourierId != courierId) {
      throw StateError('not_winner');
    }
    if (job.status != JobStatus.pickedUp) {
      throw StateError('wrong_status');
    }
    final next = job.copyWith(
      status: JobStatus.delivered,
      courierCompletionNote: note,
    );
    await _local.updateJob(next);
    final remote = _remoteOrders;
    if (remote != null && job.syncedFromSupabase) {
      try {
        final fields = <String, dynamic>{
          'status': JobStatus.delivered.toStorage(),
        };
        await remote.patchOrderLifecycleRemote(
          orderId: jobId,
          fields: fields,
        );
      } catch (e, st) {
        debugPrint('[delivery] remote markDelivered failed: $e');
        if (kDebugMode) debugPrintStack(stackTrace: st);
      }
    }
    if (kDebugMode) {
      debugPrint('[delivery] delivered order=$jobId by=$courierId');
    }
    return next;
  }

  Future<JobEntity> markCompleted({
    required String jobId,
    required String senderId,
  }) async {
    final job = await _local.getJobById(jobId);
    if (job == null) throw StateError('job_not_found');
    if (job.senderId != senderId) throw StateError('not_sender');
    if (job.status != JobStatus.delivered) {
      throw StateError('wrong_status');
    }
    final next = job.copyWith(status: JobStatus.completed);
    await _local.updateJob(next);
    final remote = _remoteOrders;
    if (remote != null && job.syncedFromSupabase) {
      try {
        await remote.patchOrderLifecycleRemote(
          orderId: jobId,
          fields: {'status': JobStatus.completed.toStorage()},
        );
      } catch (e, st) {
        debugPrint('[delivery] remote markCompleted failed: $e');
        if (kDebugMode) debugPrintStack(stackTrace: st);
      }
    }
    final w = job.winnerCourierId;
    if (w != null) {
      await _users.incrementCompletedJobs(w);
    }
    if (kDebugMode) {
      debugPrint('[delivery] completed order=$jobId by=$senderId');
    }
    return next;
  }

  Future<List<JobEntity>> senderJobs(String senderId) {
    return _local.listJobsForSender(senderId);
  }

  /// [courierTransportKeys]: `null` yoki bo‘sh — transport bo‘yicha filtrlash yo‘q.
  ///
  /// [requireRemoteBackedJobs]: courier feed — faqat Supabase orqali kelgan qatorlar
  /// (`synced_from_supabase = 1`). Sender boshqa API lar bilan o‘zgarishsiz.
  Future<List<JobEntity>> courierFeed({
    required String? regionCode,
    required String? districtCode,
    required String courierWorkingRegionKey,
    required String courierWorkingDistrictKey,
    required bool courierWholeRegionDistrict,
    List<String>? courierTransportKeys,
    String? winnerCourierId,
    bool requireRemoteBackedJobs = false,
  }) {
    return _local.listJobsForCourierFeed(
      regionCode: regionCode,
      districtCode: districtCode,
      courierWorkingRegionKey: courierWorkingRegionKey,
      courierWorkingDistrictKey: courierWorkingDistrictKey,
      courierWholeRegionDistrict: courierWholeRegionDistrict,
      courierTransportKeys: courierTransportKeys,
      winnerCourierId: winnerCourierId,
      requireRemoteBackedJobs: requireRemoteBackedJobs,
    );
  }

  Future<JobEntity?> getJob(String id) => _local.getJobById(id);

  List<JobEntity> filterJobs(
    List<JobEntity> jobs,
    String query,
    String languageCode,
  ) {
    if (query.trim().isEmpty) return jobs;
    final q = query.trim().toLowerCase();
    return jobs.where((j) {
      final title = j.title.resolveLang(languageCode).toLowerCase();
      final type = j.productType.resolveLang(languageCode).toLowerCase();
      final pickup = j.pickupAddress.resolveLang(languageCode).toLowerCase();
      final drop = j.dropoffAddress.resolveLang(languageCode).toLowerCase();
      final st = j.status.toStorage();
      return title.contains(q) ||
          type.contains(q) ||
          pickup.contains(q) ||
          drop.contains(q) ||
          st.contains(q);
    }).toList();
  }

  Future<void> placeBid({
    required String jobId,
    required String courierId,
    required double amount,
  }) async {
    final job = await _local.getJobById(jobId);
    if (job == null) throw StateError('job_not_found');
    await _assertCourierJobTransportMatch(job: job, courierId: courierId);
    await _local.insertBid(
      BidEntity(
        id: _uuid.v4(),
        jobId: jobId,
        courierId: courierId,
        amountCents: (amount * 100).round(),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<List<BidEntity>> bidsForJob(String jobId) {
    return _local.listBidsForJob(jobId);
  }

  Future<List<Map<String, Object?>>> auctionHistory(String jobId) {
    return _local.listAuctionSteps(jobId);
  }
}

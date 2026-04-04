import '../core/geo/work_area_keys.dart';
import '../core/utils/auction_math.dart';
import 'delivery_speed.dart';
import 'job_entity.dart';
import 'job_status.dart';
import 'job_transport_type.dart';
import 'localized_string.dart';
import 'payment_type.dart';
import 'remote_order_dto.dart';
import 'volume_category.dart';

/// Maps Supabase `orders` rows into [JobEntity] for SQLite cache + UI.
abstract final class RemoteOrderMapper {
  RemoteOrderMapper._();

  static String _allTransportCsv() =>
      JobTransportType.encodeTransportTypesToStorage(
        JobTransportType.values.map((e) => e.storageKey),
      );

  static LocalizedString _triple(String? raw) {
    final t = (raw ?? '').trim();
    return LocalizedString(uz: t, ru: t, en: t);
  }

  static double _effectiveVolumeLiters(RemoteOrderDto dto) {
    final v = dto.productVolumeL;
    if (v != null && v > 0) return v;
    final vc = VolumeCategory.tryFromStorageKey(dto.volumeCategory);
    if (vc != null) return vc.representativeLiters;
    return 0;
  }

  static JobEntity toJobEntity(
    RemoteOrderDto dto, {
    required bool syncedFromSupabase,
  }) {
    final title = _triple(dto.title);
    final description = _triple(dto.description);
    final pickup = _triple(dto.pickupAddress);
    final dropoff = _triple(dto.dropoffAddress);
    final productType = _triple(dto.productType);

    final startCents = dto.effectiveStartPriceCents;
    final floorCents =
        dto.floorPriceCents ?? AuctionMath.floorPriceCents(startCents);

    final codeKeys = WorkAreaKeys.fromAdminCodes(
      dto.regionCode,
      dto.districtCode,
    );
    final dispKeys = WorkAreaKeys.fromPickupDisplay(
      dto.pickupRegion,
      dto.pickupDistrict,
    );
    final regionKey = codeKeys.regionKey.isNotEmpty
        ? codeKeys.regionKey
        : dispKeys.regionKey;
    final districtKey = codeKeys.districtKey.isNotEmpty
        ? codeKeys.districtKey
        : dispKeys.districtKey;

    final transportStored = (dto.transportType?.trim().isNotEmpty ?? false)
        ? dto.transportType!.trim()
        : _allTransportCsv();

    final st = dto.statusAsJobStatus;
    final created = dto.createdAt ?? DateTime.now();

    final int? liveCurrentCents =
        st == JobStatus.auctionLive ? dto.currentPriceCents : null;

    final recipientName = (dto.recipientName?.trim().isNotEmpty ?? false)
        ? dto.recipientName!.trim()
        : '—';
    final recipientPhone = (dto.recipientPhone?.trim() ?? '').trim();

    final deliverySpeed = dto.hasDeliverySpeed
        ? DeliverySpeed.fromStorage(dto.deliverySpeed)
        : DeliverySpeed.fast;

    final paymentType = dto.hasPaymentType
        ? PaymentType.fromStorage(dto.paymentType)
        : PaymentType.cash;

    final volL = _effectiveVolumeLiters(dto);
    final weightKg = dto.productWeightKg ?? 0;
    final dims = dto.dimensionsMm?.trim() ?? '';
    final volKey = dto.volumeCategory?.trim() ?? '';

    final comments = dto.comments?.trim();
    final orderComments =
        comments != null && comments.isNotEmpty ? comments : null;

    return JobEntity(
      id: dto.id,
      senderId: dto.senderId,
      title: title,
      description: description,
      productType: productType,
      pickupAddress: pickup,
      dropoffAddress: dropoff,
      productWeightKg: weightKg,
      productVolumeL: volL,
      dimensionsMm: dims,
      volumeCategoryKey: volKey,
      transportType: transportStored,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      imagePath: (dto.imageUrl != null && dto.imageUrl!.trim().isNotEmpty)
          ? dto.imageUrl!.trim()
          : '',
      deliverySpeed: deliverySpeed,
      deliveryWindowStart: dto.deliveryWindowStart?.trim().isNotEmpty == true
          ? dto.deliveryWindowStart!.trim()
          : null,
      deliveryWindowEnd: dto.deliveryWindowEnd?.trim().isNotEmpty == true
          ? dto.deliveryWindowEnd!.trim()
          : null,
      startPriceCents: startCents,
      floorPriceCents: floorCents,
      currentPriceCents: liveCurrentCents,
      fragile: dto.fragile ?? false,
      coldChain: dto.coldStorage ?? false,
      orderComments: orderComments,
      paymentType: paymentType,
      regionCode: dto.regionCode?.trim() ?? '',
      districtCode: dto.districtCode?.trim() ?? '',
      pickupLat: dto.pickupLat,
      pickupLng: dto.pickupLng,
      dropoffLat: dto.dropoffLat,
      dropoffLng: dto.dropoffLng,
      pickupRegion: _emptyToNull(dto.pickupRegion),
      pickupDistrictOrCity: _emptyToNull(dto.pickupDistrict),
      pickupRegionOriginal: null,
      pickupDistrictOriginal: null,
      pickupRegionKey: regionKey,
      pickupDistrictKey: districtKey,
      dropoffRegion: _emptyToNull(dto.dropoffRegion),
      dropoffDistrictOrCity: _emptyToNull(dto.dropoffDistrict),
      status: st,
      auctionStep: dto.auctionStep ?? 0,
      auctionBidCount: dto.auctionBidCount ?? 0,
      leadingCourierId: _emptyToNull(dto.leadingCourierId),
      winnerCourierId: _emptyToNull(dto.winnerCourierId),
      auctionEndsAt: dto.auctionEndsAt,
      winnerSelectedAt: dto.winnerSelectedAt,
      finalPriceCents: dto.finalPriceCents,
      createdAt: created,
      syncedFromSupabase: syncedFromSupabase,
      courierLat: dto.courierLat,
      courierLng: dto.courierLng,
      courierLocationAt: dto.courierLocationUpdatedAt,
      courierHeading: dto.courierHeading,
      courierSpeedMps: dto.courierSpeed,
      courierAccuracyM: dto.courierAccuracy,
    );
  }

  static String? _emptyToNull(String? s) {
    final t = s?.trim() ?? '';
    if (t.isEmpty) return null;
    return t;
  }
}

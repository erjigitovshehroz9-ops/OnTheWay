import '../core/utils/auction_math.dart';
import 'delivery_speed.dart';
import 'job_status.dart';
import 'localized_string.dart';
import 'payment_type.dart';

class JobEntity {
  const JobEntity({
    required this.id,
    required this.senderId,
    required this.title,
    required this.description,
    required this.productType,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.productWeightKg,
    required this.productVolumeL,
    required this.dimensionsMm,
    /// Hajm kategoriyasi kaliti (`small`, `medium`, `very_large`, …); bo‘sh = noma’lum.
    this.volumeCategoryKey = '',
    /// Mos keladigan transport kalitlari, vergul bilan (`piyoda`, `mototsikl`, …).
    required this.transportType,
    required this.recipientName,
    required this.recipientPhone,
    required this.imagePath,
    required this.deliverySpeed,
    this.deliveryWindowStart,
    this.deliveryWindowEnd,
    required this.startPriceCents,
    required this.floorPriceCents,
    /// Supabase `auction_live` uchun joriy taklif (server `current_price_cents`).
    this.currentPriceCents,
    this.finalPriceCents,
    required this.fragile,
    required this.coldChain,
    /// Qo‘shimcha izoh (Supabase `comments`).
    this.orderComments,
    required this.paymentType,
    required this.regionCode,
    required this.districtCode,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.pickupRegion,
    this.pickupDistrictOrCity,
    this.pickupRegionOriginal,
    this.pickupDistrictOriginal,
    this.pickupRegionKey = '',
    this.pickupDistrictKey = '',
    this.dropoffRegion,
    this.dropoffDistrictOrCity,
    required this.status,
    this.auctionEndsAt,
    this.auctionStep = 0,
    /// Server `auction_bid_count` (Supabase RPC); mahalliy tarix bilan moslashtirish.
    this.auctionBidCount = 0,
    this.leadingCourierId,
    this.winnerCourierId,
    this.courierLat,
    this.courierLng,
    this.courierLocationAt,
    this.courierHeading,
    this.courierSpeedMps,
    this.courierAccuracyM,
    this.courierCompletionNote,
    this.notifiedPickup1Km = false,
    this.notifiedDropoff5Km = false,
    this.notifiedDropoff2Km = false,
    this.syncedFromSupabase = false,
    required this.createdAt,
    /// Supabase `winner_selected_at` (g‘olib tanlangan vaqt).
    this.winnerSelectedAt,
  });

  final String id;
  final String senderId;
  final LocalizedString title;
  final LocalizedString description;
  final LocalizedString productType;
  final LocalizedString pickupAddress;
  final LocalizedString dropoffAddress;
  final double productWeightKg;
  final double productVolumeL;
  /// Uzunlik × kenglik × balandlik, mm (masalan: 1000x500x200).
  final String dimensionsMm;
  final String volumeCategoryKey;
  final String transportType;
  final String recipientName;
  final String recipientPhone;
  final String imagePath;
  final DeliverySpeed deliverySpeed;
  final String? deliveryWindowStart;
  final String? deliveryWindowEnd;
  final int startPriceCents;
  final int floorPriceCents;
  final int? currentPriceCents;
  final int? finalPriceCents;
  final bool fragile;
  final bool coldChain;
  final String? orderComments;
  final PaymentType paymentType;
  final String regionCode;
  final String districtCode;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final String? pickupRegion;
  final String? pickupDistrictOrCity;
  /// Geocoder / xarita `region` (audit, UI).
  final String? pickupRegionOriginal;
  /// Geocoder qatlamlari (audit).
  final String? pickupDistrictOriginal;
  final String pickupRegionKey;
  final String pickupDistrictKey;
  final String? dropoffRegion;
  final String? dropoffDistrictOrCity;
  final JobStatus status;
  final DateTime? auctionEndsAt;
  final int auctionStep;
  final int auctionBidCount;
  final String? leadingCourierId;
  final String? winnerCourierId;
  final double? courierLat;
  final double? courierLng;
  final DateTime? courierLocationAt;
  /// GPS heading (0–360), ixtiyoriy.
  final double? courierHeading;
  /// Tezlik m/s (platformadan kelishi mumkin).
  final double? courierSpeedMps;
  /// Aniqlik metrda (ixtiyoriy).
  final double? courierAccuracyM;
  final String? courierCompletionNote;
  /// Kuryer lokatsiyasi yangilanganda bir marta yuborilgan yaqinlik bildirishnomalari.
  final bool notifiedPickup1Km;
  final bool notifiedDropoff5Km;
  final bool notifiedDropoff2Km;
  /// True when this row was hydrated from Supabase for courier cache (not sender canonical).
  final bool syncedFromSupabase;
  final DateTime createdAt;
  final DateTime? winnerSelectedAt;

  bool get _afterWinnerAssigned {
    return winnerCourierId != null &&
        (status == JobStatus.assigned ||
            status == JobStatus.pickedUp ||
            status == JobStatus.delivered ||
            status == JobStatus.completed);
  }

  bool contactsBetweenSenderAndWinner(String? viewerId) {
    if (viewerId == null || !_afterWinnerAssigned) return false;
    return viewerId == senderId || viewerId == winnerCourierId;
  }

  bool recipientVisibleToWinnerCourier(String? viewerId) {
    return viewerId != null &&
        viewerId == winnerCourierId &&
        _afterWinnerAssigned;
  }

  /// Sender yoki g‘olib kuryer jonli kuzatuvni ko‘radi (biriktirilgan → olish, keyin yetkazish).
  bool liveTrackingVisibleTo(String? viewerId) {
    if (viewerId == null || winnerCourierId == null) return false;
    if (viewerId != senderId && viewerId != winnerCourierId) return false;
    return status == JobStatus.assigned ||
        status == JobStatus.pickedUp ||
        status == JobStatus.delivered;
  }

  /// Marketplace: barcha kuryerlar manzilni ko‘radi. Keyin — faqat g‘olib.
  bool courierSeesOrderAddresses(String courierUserId) {
    switch (status) {
      case JobStatus.posted:
      case JobStatus.auctionLive:
        return true;
      case JobStatus.assigned:
      case JobStatus.pickedUp:
      case JobStatus.delivered:
      case JobStatus.completed:
        return winnerCourierId == courierUserId;
      case JobStatus.cancelled:
        return false;
    }
  }

  bool get auctionTimerActive {
    if (status != JobStatus.auctionLive || auctionEndsAt == null) {
      return false;
    }
    return DateTime.now().isBefore(auctionEndsAt!);
  }

  /// Jonli auksion: server `current_price_cents` bo‘lsa shu; bo‘lmasa [auctionStep]
  /// bo‘yicha hisoblangan narx — barcha qurilmalar va merge keyin bir xil manba.
  int get effectiveAuctionLivePriceCentsOrDerived {
    if (status != JobStatus.auctionLive) {
      return AuctionMath.committedPriceCents(
        startPriceCents,
        auctionStep,
        floorPriceCents,
      );
    }
    final c = currentPriceCents;
    if (c != null && c > 0) return c;
    return AuctionMath.committedPriceCents(
      startPriceCents,
      auctionStep,
      floorPriceCents,
    );
  }

  Duration? auctionTimeRemaining() {
    if (auctionEndsAt == null) return null;
    final d = auctionEndsAt!.difference(DateTime.now());
    if (d.isNegative) return Duration.zero;
    return d;
  }

  double get startPrice => startPriceCents / 100;
  double get floorPrice => floorPriceCents / 100;

  static const Symbol _kUnspecifiedCurrentPrice =
      Symbol('jobEntity.currentPriceCents');

  JobEntity copyWith({
    String? id,
    String? senderId,
    LocalizedString? title,
    LocalizedString? description,
    LocalizedString? productType,
    LocalizedString? pickupAddress,
    LocalizedString? dropoffAddress,
    double? productWeightKg,
    double? productVolumeL,
    String? dimensionsMm,
    String? volumeCategoryKey,
    String? transportType,
    String? recipientName,
    String? recipientPhone,
    String? imagePath,
    DeliverySpeed? deliverySpeed,
    String? deliveryWindowStart,
    String? deliveryWindowEnd,
    int? startPriceCents,
    int? floorPriceCents,
    Object? currentPriceCents = _kUnspecifiedCurrentPrice,
    int? finalPriceCents,
    bool? fragile,
    bool? coldChain,
    String? orderComments,
    PaymentType? paymentType,
    String? regionCode,
    String? districtCode,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    String? pickupRegion,
    String? pickupDistrictOrCity,
    String? pickupRegionOriginal,
    String? pickupDistrictOriginal,
    String? pickupRegionKey,
    String? pickupDistrictKey,
    String? dropoffRegion,
    String? dropoffDistrictOrCity,
    JobStatus? status,
    DateTime? auctionEndsAt,
    int? auctionStep,
    int? auctionBidCount,
    String? leadingCourierId,
    String? winnerCourierId,
    double? courierLat,
    double? courierLng,
    DateTime? courierLocationAt,
    double? courierHeading,
    double? courierSpeedMps,
    double? courierAccuracyM,
    String? courierCompletionNote,
    bool? notifiedPickup1Km,
    bool? notifiedDropoff5Km,
    bool? notifiedDropoff2Km,
    bool? syncedFromSupabase,
    DateTime? createdAt,
    DateTime? winnerSelectedAt,
  }) {
    return JobEntity(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      title: title ?? this.title,
      description: description ?? this.description,
      productType: productType ?? this.productType,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      productWeightKg: productWeightKg ?? this.productWeightKg,
      productVolumeL: productVolumeL ?? this.productVolumeL,
      dimensionsMm: dimensionsMm ?? this.dimensionsMm,
      volumeCategoryKey: volumeCategoryKey ?? this.volumeCategoryKey,
      transportType: transportType ?? this.transportType,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      imagePath: imagePath ?? this.imagePath,
      deliverySpeed: deliverySpeed ?? this.deliverySpeed,
      deliveryWindowStart: deliveryWindowStart ?? this.deliveryWindowStart,
      deliveryWindowEnd: deliveryWindowEnd ?? this.deliveryWindowEnd,
      startPriceCents: startPriceCents ?? this.startPriceCents,
      floorPriceCents: floorPriceCents ?? this.floorPriceCents,
      currentPriceCents: identical(currentPriceCents, _kUnspecifiedCurrentPrice)
          ? this.currentPriceCents
          : currentPriceCents as int?,
      finalPriceCents: finalPriceCents ?? this.finalPriceCents,
      fragile: fragile ?? this.fragile,
      coldChain: coldChain ?? this.coldChain,
      orderComments: orderComments ?? this.orderComments,
      paymentType: paymentType ?? this.paymentType,
      regionCode: regionCode ?? this.regionCode,
      districtCode: districtCode ?? this.districtCode,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      pickupRegion: pickupRegion ?? this.pickupRegion,
      pickupDistrictOrCity:
          pickupDistrictOrCity ?? this.pickupDistrictOrCity,
      pickupRegionOriginal: pickupRegionOriginal ?? this.pickupRegionOriginal,
      pickupDistrictOriginal:
          pickupDistrictOriginal ?? this.pickupDistrictOriginal,
      pickupRegionKey: pickupRegionKey ?? this.pickupRegionKey,
      pickupDistrictKey: pickupDistrictKey ?? this.pickupDistrictKey,
      dropoffRegion: dropoffRegion ?? this.dropoffRegion,
      dropoffDistrictOrCity:
          dropoffDistrictOrCity ?? this.dropoffDistrictOrCity,
      status: status ?? this.status,
      auctionEndsAt: auctionEndsAt ?? this.auctionEndsAt,
      auctionStep: auctionStep ?? this.auctionStep,
      auctionBidCount: auctionBidCount ?? this.auctionBidCount,
      leadingCourierId: leadingCourierId ?? this.leadingCourierId,
      winnerCourierId: winnerCourierId ?? this.winnerCourierId,
      courierLat: courierLat ?? this.courierLat,
      courierLng: courierLng ?? this.courierLng,
      courierLocationAt: courierLocationAt ?? this.courierLocationAt,
      courierHeading: courierHeading ?? this.courierHeading,
      courierSpeedMps: courierSpeedMps ?? this.courierSpeedMps,
      courierAccuracyM: courierAccuracyM ?? this.courierAccuracyM,
      courierCompletionNote:
          courierCompletionNote ?? this.courierCompletionNote,
      notifiedPickup1Km: notifiedPickup1Km ?? this.notifiedPickup1Km,
      notifiedDropoff5Km: notifiedDropoff5Km ?? this.notifiedDropoff5Km,
      notifiedDropoff2Km: notifiedDropoff2Km ?? this.notifiedDropoff2Km,
      syncedFromSupabase: syncedFromSupabase ?? this.syncedFromSupabase,
      createdAt: createdAt ?? this.createdAt,
      winnerSelectedAt: winnerSelectedAt ?? this.winnerSelectedAt,
    );
  }
}

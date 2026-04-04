import 'job_status.dart';

/// Row shape for Supabase `public.orders` (online sync layer).
///
/// Supports full production fields and legacy minimal rows (`price`, addresses only).
class RemoteOrderDto {
  const RemoteOrderDto({
    required this.id,
    required this.senderId,
    this.title,
    this.description,
    this.pickupAddress,
    this.dropoffAddress,
    this.price,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.pickupRegion,
    this.pickupDistrict,
    this.dropoffRegion,
    this.dropoffDistrict,
    this.transportType,
    this.recipientName,
    this.recipientPhone,
    this.startPriceCents,
    this.floorPriceCents,
    this.currentPriceCents,
    this.minimumPriceCents,
    this.auctionStep,
    this.auctionBidCount,
    this.leadingCourierId,
    this.winnerCourierId,
    this.status,
    this.createdAt,
    this.imageUrl,
    this.auctionEndsAt,
    this.winnerSelectedAt,
    this.finalPriceCents,
    this.productType,
    this.deliverySpeed,
    this.deliveryWindowStart,
    this.deliveryWindowEnd,
    this.regionCode,
    this.districtCode,
    this.volumeCategory,
    this.productWeightKg,
    this.productVolumeL,
    this.dimensionsMm,
    this.paymentType,
    this.comments,
    this.fragile,
    this.coldStorage,
    this.courierLat,
    this.courierLng,
    this.courierHeading,
    this.courierSpeed,
    this.courierAccuracy,
    this.courierLocationUpdatedAt,
  });

  final String id;
  final String senderId;
  final String? title;
  final String? description;
  final String? pickupAddress;
  final String? dropoffAddress;
  final int? price;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final String? pickupRegion;
  final String? pickupDistrict;
  final String? dropoffRegion;
  final String? dropoffDistrict;
  final String? transportType;
  final String? recipientName;
  final String? recipientPhone;
  final int? startPriceCents;
  final int? floorPriceCents;
  final int? currentPriceCents;
  final int? minimumPriceCents;
  final int? auctionStep;
  final int? auctionBidCount;
  final String? leadingCourierId;
  final String? winnerCourierId;
  final String? status;
  final DateTime? createdAt;
  final String? imageUrl;
  final DateTime? auctionEndsAt;
  final DateTime? winnerSelectedAt;
  final int? finalPriceCents;

  final String? productType;
  final String? deliverySpeed;
  final String? deliveryWindowStart;
  final String? deliveryWindowEnd;
  final String? regionCode;
  final String? districtCode;
  final String? volumeCategory;
  final double? productWeightKg;
  final double? productVolumeL;
  final String? dimensionsMm;
  final String? paymentType;
  final String? comments;
  final bool? fragile;
  final bool? coldStorage;
  final double? courierLat;
  final double? courierLng;
  final double? courierHeading;
  /// Supabase `courier_speed` (m/s).
  final double? courierSpeed;
  final double? courierAccuracy;
  final DateTime? courierLocationUpdatedAt;

  bool get hasDeliverySpeed =>
      deliverySpeed != null && deliverySpeed!.trim().isNotEmpty;
  bool get hasPaymentType =>
      paymentType != null && paymentType!.trim().isNotEmpty;
  bool get hasRegionCode => regionCode != null && regionCode!.trim().isNotEmpty;
  bool get hasDistrictCode =>
      districtCode != null && districtCode!.trim().isNotEmpty;
  bool get hasDeliveryWindowStart =>
      deliveryWindowStart != null && deliveryWindowStart!.trim().isNotEmpty;
  bool get hasDeliveryWindowEnd =>
      deliveryWindowEnd != null && deliveryWindowEnd!.trim().isNotEmpty;
  bool get hasVolumeCategory =>
      volumeCategory != null && volumeCategory!.trim().isNotEmpty;
  bool get hasComments => comments != null && comments!.trim().isNotEmpty;

  static int? _readInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString());
  }

  static double? _readDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime? _readDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static bool? _readBoolNullable(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is int) return v != 0;
    final s = v.toString().toLowerCase();
    if (s == 'true' || s == 't' || s == '1') return true;
    if (s == 'false' || s == 'f' || s == '0') return false;
    return null;
  }

  static String? _readTransportType(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is List) {
      return v.map((e) => e.toString()).join(',');
    }
    return v.toString();
  }

  static RemoteOrderDto fromSupabaseMap(Map<String, dynamic> map) {
    final idRaw = map['id'];
    final sidRaw = map['sender_id'];
    final id = idRaw?.toString() ?? '';
    final senderId = sidRaw?.toString() ?? '';

    final start = _readInt(map['start_price_cents']);
    final legacyPrice = _readInt(map['price']);

    return RemoteOrderDto(
      id: id,
      senderId: senderId,
      title: map['title'] as String?,
      description: map['description'] as String?,
      pickupAddress: map['pickup_address'] as String?,
      dropoffAddress: map['dropoff_address'] as String?,
      price: legacyPrice,
      pickupLat: _readDouble(map['pickup_lat']),
      pickupLng: _readDouble(map['pickup_lng']),
      dropoffLat: _readDouble(map['dropoff_lat']),
      dropoffLng: _readDouble(map['dropoff_lng']),
      pickupRegion: map['pickup_region'] as String?,
      pickupDistrict: map['pickup_district'] as String?,
      dropoffRegion: map['dropoff_region'] as String?,
      dropoffDistrict: map['dropoff_district'] as String?,
      transportType: _readTransportType(map['transport_type']),
      recipientName: map['recipient_name'] as String?,
      recipientPhone: map['recipient_phone'] as String?,
      startPriceCents: start ?? legacyPrice,
      floorPriceCents: _readInt(map['floor_price_cents']),
      currentPriceCents: _readInt(map['current_price_cents']),
      minimumPriceCents: _readInt(map['minimum_price_cents']),
      auctionStep: _readInt(map['auction_step']),
      auctionBidCount: _readInt(map['auction_bid_count']),
      leadingCourierId: map['leading_courier_id'] as String?,
      winnerCourierId: map['winner_courier_id'] as String?,
      status: map['status'] as String?,
      createdAt: _readDateTime(map['created_at']),
      imageUrl: map['image_url'] as String?,
      auctionEndsAt: _readDateTime(map['auction_ends_at']),
      winnerSelectedAt: _readDateTime(map['winner_selected_at']),
      finalPriceCents: _readInt(map['final_price_cents']),
      productType: map['product_type'] as String?,
      deliverySpeed: map['delivery_speed'] as String?,
      deliveryWindowStart: map['delivery_window_start'] as String?,
      deliveryWindowEnd: map['delivery_window_end'] as String?,
      regionCode: map['region_code'] as String?,
      districtCode: map['district_code'] as String?,
      volumeCategory: map['volume_category'] as String?,
      productWeightKg: _readDouble(map['product_weight_kg']),
      productVolumeL: _readDouble(map['product_volume_l']),
      dimensionsMm: map['dimensions_mm'] as String?,
      paymentType: map['payment_type'] as String?,
      comments: map['comments'] as String?,
      fragile: _readBoolNullable(map['fragile']),
      coldStorage: _readBoolNullable(map['cold_storage']),
      courierLat: _readDouble(map['courier_lat']),
      courierLng: _readDouble(map['courier_lng']),
      courierHeading: _readDouble(map['courier_heading']),
      courierSpeed: _readDouble(map['courier_speed']),
      courierAccuracy: _readDouble(map['courier_accuracy']),
      courierLocationUpdatedAt:
          _readDateTime(map['courier_location_updated_at']),
    );
  }

  /// Effective start price in cents (new column or legacy `price`).
  int get effectiveStartPriceCents => startPriceCents ?? price ?? 0;

  JobStatus get statusAsJobStatus =>
      JobStatus.fromStorage((status ?? 'posted').trim());
}

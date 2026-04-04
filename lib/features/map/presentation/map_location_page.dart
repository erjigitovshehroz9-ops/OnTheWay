import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/route_distance_format.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/geocoding/nominatim_service.dart';
import '../../../shared/map/map_camera_policy.dart';
import '../../../shared/map/premium_map_style.dart';
import '../../../shared/map/premium_map_widgets.dart';

class MapPickerResult {
  const MapPickerResult({
    required this.lat,
    required this.lng,
    required this.label,
    required this.streetOrPlace,
    required this.city,
    required this.district,
    required this.region,
    this.neighborhood,
    this.districtGeocoderRaw,
    this.routeDistanceKm,
  });

  final double lat;
  final double lng;
  final String label;
  final String streetOrPlace;
  final String city;
  /// Ma’muriy tuman (matching uchun).
  final String district;
  final String region;

  /// Mahalla / suburb (audit).
  final String? neighborhood;

  /// Geocoder qatlamlari (DB `pickup_district_original` uchun).
  final String? districtGeocoderRaw;

  /// Yetkazish xaritasida marshrut hisoblangan bo‘lsa, km.
  final double? routeDistanceKm;
}

/// Bir marta xarita ochib ketma-ket olish va yetkazish nuqtalarini tanlash.
class MapDualPickerResult {
  const MapDualPickerResult({
    required this.pickup,
    required this.dropoff,
  });

  final MapPickerResult pickup;
  final MapPickerResult dropoff;
}

class MapLocationPage extends ConsumerStatefulWidget {
  const MapLocationPage({super.key});

  @override
  ConsumerState<MapLocationPage> createState() => _MapLocationPageState();
}

class _MapLocationPageState extends ConsumerState<MapLocationPage>
    with SingleTickerProviderStateMixin {
  /// flutter_map: 2D tiles — real 3D pitch/tilt yo'q; bearing (rotation) darajada.
  static const double _pseudoTiltRad = 0.068;
  static const double _perspectiveSlop = 0.00105;

  final MapController _mapController = MapController();
  LatLng _center = const LatLng(41.2995, 69.2401);
  /// true: markaz-pin — surishda tanlov xarita markazi bilan.
  /// false: uzoq bosishda qo‘yilgan nuqta (kamera qimirlamaydi).
  bool _markerFollowsMapCenter = true;
  /// Map camera bearing, degrees (0 = north). [MapCamera.rotation]
  double _bearingDeg = 0;
  String _label = '';
  String _streetOrPlace = '';
  String _city = '';
  String _district = '';
  String _region = '';
  String _neighborhood = '';
  String _districtGeocoderRaw = '';
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchOpen = false;
  List<NominatimResult> _suggestions = [];
  bool _loading = false;
  bool _reverseLoading = false;
  Timer? _reverseDebounce;
  Timer? _routeDebounce;
  bool _isMoving = false;
  late final AnimationController _selectFx;
  late final Animation<double> _fx;

  bool _didBootstrap = false;
  LatLng? _gpsLatLng;
  LatLng? _pickupAnchor;
  bool _isDropoffWithPickup = false;
  /// `kind=both`: birinchi bosqichdan keyin `true` — A belgilangan, B tanlanmoqda.
  bool _dualFlow = false;
  bool _dualAwaitingDropoff = false;
  MapPickerResult? _dualPickupResult;
  List<LatLng> _routePolyline = [];
  double? _routeKm;
  bool _routeDistanceApproximate = false;
  bool _routeFetchLoading = false;

  static const Distance _distance = Distance();

  @override
  void initState() {
    super.initState();
    _selectFx = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fx = CurvedAnimation(parent: _selectFx, curve: Curves.easeOutCubic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didBootstrap) return;
    _didBootstrap = true;
    _readRouteArguments();
    unawaited(_bootstrapMap());
  }

  void _readRouteArguments() {
    final q = GoRouterState.of(context).uri.queryParameters;
    final kind = q['kind'] ?? 'pickup';
    final plat = double.tryParse(q['pickupLat'] ?? '');
    final plng = double.tryParse(q['pickupLng'] ?? '');
    final validPick = plat != null &&
        plng != null &&
        plat >= -90 &&
        plat <= 90 &&
        plng >= -180 &&
        plng <= 180;
    _dualFlow = kind == 'both';
    _isDropoffWithPickup = kind == 'dropoff' && validPick;
    _pickupAnchor = _isDropoffWithPickup ? LatLng(plat!, plng!) : null;
  }

  /// A nuqta belgilangan va B tanlanmoqda (URL `dropoff` yoki `both` 2-bosqich).
  bool get _secondLeg =>
      _pickupAnchor != null &&
      (_isDropoffWithPickup || _dualAwaitingDropoff);

  Future<void> _bootstrapMap() async {
    await _initPos();
    if (!mounted) return;
    _scheduleReverseGeocode();
    if (_secondLeg) {
      _scheduleRouteFetch();
    }
  }

  /// B nuqta (dropoff) ham A (pickup) kabi: GPS bo‘lsa xarita **turgan joy** markazda;
  /// GPS yo‘q bo‘lsa dropoffda A nuqtaga tushadi.
  Future<void> _initPos() async {
    try {
      final p = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      _gpsLatLng = LatLng(p.latitude, p.longitude);
      setState(() {
        _markerFollowsMapCenter = true;
        _center = _gpsLatLng!;
      });
      _mapController.moveAndRotate(_center, 17, 0);
    } catch (_) {
      if (!mounted) return;
      if (_secondLeg) {
        setState(() {
          _markerFollowsMapCenter = true;
          _center = _pickupAnchor!;
        });
        _mapController.moveAndRotate(_center, 14, 0);
      } else {
        _mapController.moveAndRotate(_center, 17, 0);
      }
    }
  }

  Future<void> _recenterToGps() async {
    await _initPos();
    if (!mounted) return;
    _mapController.moveAndRotate(_center, 17, 0);
    if (_secondLeg) {
      _scheduleRouteFetch();
    }
  }

  void _scheduleRouteFetch() {
    if (!_secondLeg) return;
    _routeDebounce?.cancel();
    _routeDebounce = Timer(const Duration(milliseconds: 520), () {
      unawaited(_fetchRouteNow());
    });
  }

  Future<void> _fetchRouteNow() async {
    if (!_secondLeg || !mounted) return;
    final drop = _center;
    setState(() => _routeFetchLoading = true);
    final svc = ref.read(osrmRouteServiceProvider);
    final r = await svc.drivingRoute(from: _pickupAnchor!, to: drop);
    if (!mounted) return;
    if (r != null) {
      setState(() {
        _routePolyline = r.points;
        _routeKm = r.distanceMeters / 1000.0;
        _routeDistanceApproximate = false;
        _routeFetchLoading = false;
      });
      return;
    }
    final m = _distance.as(LengthUnit.Meter, _pickupAnchor!, drop);
    setState(() {
      _routePolyline = [_pickupAnchor!, drop];
      _routeKm = m / 1000.0;
      _routeDistanceApproximate = true;
      _routeFetchLoading = false;
    });
  }

  @override
  void dispose() {
    _reverseDebounce?.cancel();
    _routeDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _selectFx.dispose();
    super.dispose();
  }

  void _toggleSearchPanel() {
    final opening = !_searchOpen;
    setState(() => _searchOpen = opening);
    if (opening) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _searchFocus.requestFocus();
      });
    } else {
      _searchFocus.unfocus();
    }
  }

  /// Qidiruv natijalari xarita markazi (buyurtmachi ko‘rayotgan joy) bo‘yicha yaqinlik tartibida.
  LatLng _searchBiasPoint() {
    try {
      return _mapController.camera.center;
    } catch (_) {
      return _center;
    }
  }

  Future<void> _runSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.length < 3) return;
    setState(() => _loading = true);
    final svc = ref.read(nominatimServiceProvider);
    final list = await svc.search(q, near: _searchBiasPoint());
    if (!mounted) return;
    setState(() {
      _suggestions = list;
      _loading = false;
    });
  }

  void _pickSuggestion(NominatimResult r) {
    setState(() {
      _markerFollowsMapCenter = true;
      _center = LatLng(r.lat, r.lon);
      _label = r.displayName;
      _streetOrPlace = '';
      _city = '';
      _district = '';
      _region = '';
      _neighborhood = '';
      _districtGeocoderRaw = '';
      _suggestions = [];
      _searchOpen = false;
    });
    _searchFocus.unfocus();
    _mapController.moveAndRotate(_center, 17, 0);
    _scheduleReverseGeocode();
    _scheduleRouteFetch();
  }

  void _scheduleReverseGeocode() {
    _reverseDebounce?.cancel();
    _reverseDebounce = Timer(const Duration(milliseconds: 650), () async {
      if (!mounted) return;
      setState(() => _reverseLoading = true);
      try {
        final svc = ref.read(nominatimServiceProvider);
        final r = await svc.reverse(
          lat: _center.latitude,
          lon: _center.longitude,
        );
        if (!mounted) return;
        if (r == null) {
          setState(() {
            _label = '';
            _streetOrPlace = '';
            _city = '';
            _district = '';
            _region = '';
            _neighborhood = '';
            _districtGeocoderRaw = '';
            _reverseLoading = false;
          });
          return;
        }
        setState(() {
          _label = r.displayAddress;
          _streetOrPlace = r.streetOrPlace;
          _city = r.city;
          _district = r.district;
          _region = r.region;
          _neighborhood = r.neighborhood;
          _districtGeocoderRaw = r.districtGeocoderRaw;
          _reverseLoading = false;
        });
      } catch (e, st) {
        debugPrint('[map] reverse geocode failed: $e\n$st');
        if (!mounted) return;
        setState(() => _reverseLoading = false);
      }
    });
  }

  MapPickerResult _snapshotPickerResult() {
    return MapPickerResult(
      lat: _center.latitude,
      lng: _center.longitude,
      label: _label.isEmpty
          ? '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}'
          : _label,
      streetOrPlace: _streetOrPlace,
      city: _city,
      district: _district,
      region: _region,
      neighborhood: _neighborhood.isEmpty ? null : _neighborhood,
      districtGeocoderRaw:
          _districtGeocoderRaw.isEmpty ? null : _districtGeocoderRaw,
      routeDistanceKm: null,
    );
  }

  void _backToPickupPhaseFromDual() {
    final saved = _dualPickupResult;
    if (saved == null) return;
    setState(() {
      _dualAwaitingDropoff = false;
      _dualPickupResult = null;
      _pickupAnchor = null;
      _routePolyline = [];
      _routeKm = null;
      _routeFetchLoading = false;
      _routeDistanceApproximate = false;
      _center = LatLng(saved.lat, saved.lng);
      _markerFollowsMapCenter = true;
      _label = saved.label;
      _streetOrPlace = saved.streetOrPlace;
      _city = saved.city;
      _district = saved.district;
      _region = saved.region;
      _neighborhood = saved.neighborhood ?? '';
      _districtGeocoderRaw = saved.districtGeocoderRaw ?? '';
    });
    _mapController.moveAndRotate(_center, 17, 0);
    _scheduleReverseGeocode();
  }

  Future<void> _moveToDropoffStartPosition() async {
    try {
      final p = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      _gpsLatLng = LatLng(p.latitude, p.longitude);
      setState(() {
        _markerFollowsMapCenter = true;
        _center = _gpsLatLng!;
      });
      _mapController.moveAndRotate(_center, 17, 0);
    } catch (_) {
      if (!mounted) return;
      final pick = _pickupAnchor!;
      setState(() {
        _markerFollowsMapCenter = true;
        _center = LatLng(
          pick.latitude + 0.004,
          pick.longitude + 0.004,
        );
      });
      _mapController.moveAndRotate(_center, 16, 0);
    }
    if (!mounted) return;
    _scheduleReverseGeocode();
    _scheduleRouteFetch();
  }

  Future<void> _commitDualPickupAndGoToDropoff() async {
    final snap = _snapshotPickerResult();
    setState(() {
      _dualPickupResult = snap;
      _dualAwaitingDropoff = true;
      _pickupAnchor = LatLng(snap.lat, snap.lng);
      _markerFollowsMapCenter = true;
      _label = '';
      _streetOrPlace = '';
      _city = '';
      _district = '';
      _region = '';
      _neighborhood = '';
      _districtGeocoderRaw = '';
      _searchCtrl.clear();
      _suggestions = [];
      _searchOpen = false;
      _searchFocus.unfocus();
      _routePolyline = [];
      _routeKm = null;
      _routeFetchLoading = false;
      _routeDistanceApproximate = false;
    });
    await _moveToDropoffStartPosition();
  }

  void _setMoving(bool moving) {
    if (_isMoving == moving) return;
    setState(() => _isMoving = moving);
    if (!moving) {
      // Movement finished → update address (debounced to avoid flicker).
      _scheduleReverseGeocode();
      _selectFx.forward(from: 0);
      _scheduleRouteFetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final kind =
        GoRouterState.of(context).uri.queryParameters['kind'] ?? 'pickup';
    final mapTitle = _dualFlow
        ? (_dualAwaitingDropoff
            ? l10n.dropoffLocation
            : l10n.pickupLocation)
        : (kind == 'dropoff' ? l10n.dropoffLocation : l10n.pickupLocation);
    final primaryLabel = _dualFlow
        ? (_dualAwaitingDropoff
            ? l10n.mapPickerConfirmBoth
            : l10n.mapPickerNextDropoff)
        : l10n.continueWord;

    return Theme(
      data: AppTheme.light(),
      child: PopScope(
        canPop: !(_dualFlow && _dualAwaitingDropoff),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _dualFlow && _dualAwaitingDropoff) {
            _backToPickupPhaseFromDual();
          }
        },
        child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: const Color(0xFF0F172A),
          iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
          title: Text(
            mapTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF0F172A),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: _toggleSearchPanel,
            ),
          ],
        ),
        body: Stack(
        children: [
          // Map: pseudo-3D plane (tilt illusion) + real bearing via flutter_map rotation.
          Positioned.fill(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
    child: AnimatedScale(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      scale: _isMoving ? 1.012 : 1.0,
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Transform(
              alignment: const Alignment(0, 0.14),
              transform: Matrix4.identity()
                ..setEntry(3, 2, _perspectiveSlop)
                ..rotateX(_pseudoTiltRad),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: 17,
                      initialRotation: 0,
                      backgroundColor: PremiumMapStyle.mapBackground,
                      cameraConstraint:
                          MapCameraPolicy.creationPicker.constraint,
                      minZoom: MapCameraPolicy.creationPicker.minZoom,
                      maxZoom: MapCameraPolicy.creationPicker.maxZoom,
                      onPositionChanged: (camera, _) {
                        setState(() {
                          _bearingDeg = camera.rotation;
                          if (_markerFollowsMapCenter) {
                            _center = camera.center;
                          }
                        });
                      },
                      onLongPress: (_, latLng) {
                        _reverseDebounce?.cancel();
                        setState(() {
                          _markerFollowsMapCenter = false;
                          _center = latLng;
                        });
                        _scheduleReverseGeocode();
                        _selectFx.forward(from: 0);
                        _scheduleRouteFetch();
                      },
                      onMapEvent: (event) {
                        if (event is MapEventMoveStart ||
                            event is MapEventFlingAnimationStart) {
                          _reverseDebounce?.cancel();
                          setState(() {
                            _markerFollowsMapCenter = true;
                            _center = event.camera.center;
                            _isMoving = true;
                          });
                        }
                        if (event is MapEventMoveEnd ||
                            event is MapEventFlingAnimationEnd) {
                          _setMoving(false);
                        }
                      },
                    ),
                    children: [
                      PremiumMapStyle.lightTileLayer(),
                      if (_routePolyline.length >= 2)
                        PremiumMapStyle.routePolylineLayer(_routePolyline),
                      if (_pickupAnchor != null || !_markerFollowsMapCenter)
                        MarkerLayer(
                          markers: [
                            if (_pickupAnchor != null)
                              Marker(
                                point: _pickupAnchor!,
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                child: Tooltip(
                                  message: l10n.mapPickupMarkerHint,
                                  child: PremiumRouteLetterMarker(
                                    label: l10n.jobMapMarkerA,
                                  ),
                                ),
                              ),
                            if (!_markerFollowsMapCenter)
                              Marker(
                                point: _center,
                                width: 68,
                                height: 84,
                                alignment: Alignment.center,
                                child: AnimatedBuilder(
                                  animation: _fx,
                                  builder: (context, _) {
                                    return _CenterMarker(
                                      lifted: _isMoving,
                                      fx: _fx.value,
                                      isEndDropoff: _secondLeg,
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),

                  // Lighting tied to map plane (tilts with pseudo-3D).
                  IgnorePointer(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0, -0.18),
                                radius: 1.2,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.05),
                                ],
                                stops: const [0.62, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          height: 170,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.04),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 240,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.06),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
),
          // Screen-space polish: edge vignette + depth (does not rotate with map).
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 1.05,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.04),
                    ],
                    stops: const [0.72, 1.0],
                  ),
                ),
              ),
            ),
          ),
          if (_markerFollowsMapCenter)
            IgnorePointer(
              child: Center(
                child: AnimatedBuilder(
                  animation: _fx,
                  builder: (context, _) {
                    return _CenterMarker(
                      lifted: _isMoving,
                      fx: _fx.value,
                      isEndDropoff: _secondLeg,
                    );
                  },
                ),
              ),
            ),
          if (_searchOpen)
            Positioned(
              top: 0,
              left: 8,
              right: 72,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _FloatingMapChrome(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocus,
                        keyboardType: TextInputType.streetAddress,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _runSearch(),
                        decoration: InputDecoration(
                          hintText: l10n.mapSearch,
                          border: InputBorder.none,
                          suffixIcon: _loading
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.send_rounded),
                                  onPressed: _runSearch,
                                ),
                        ),
                        onChanged: (_) {
                          if (_searchCtrl.text.trim().length >= 3) {
                            _runSearch();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_suggestions.isNotEmpty && _searchOpen)
            Positioned(
              top: 0,
              left: 8,
              right: 8,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 62),
                  child: _FloatingMapChrome(
                    padding: EdgeInsets.zero,
                    maxHeight: MediaQuery.sizeOf(context).height * 0.38,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, i) {
                        final r = _suggestions[i];
                        return ListTile(
                          title: Text(
                            r.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _pickSuggestion(r),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 16,
            bottom: 280,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_bearingDeg.abs() > 0.85)
                    _MapControlRoundButton(
                      tooltip: 'Shimolga',
                      onPressed: () => _mapController.rotate(0),
                      child: Transform.rotate(
                        angle: -_bearingDeg * math.pi / 180,
                        child: const Icon(
                          Icons.navigation_rounded,
                          color: PremiumMapStyle.routeBlue,
                        ),
                      ),
                    ),
                  if (_bearingDeg.abs() > 0.85) const SizedBox(height: 10),
                  _MapControlRoundButton(
                    tooltip: l10n.recenterMap,
                    onPressed: () => unawaited(_recenterToGps()),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: PremiumMapStyle.routeBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SelectedAddressPanel(
                    title: mapTitle,
                    streetOrPlace:
                        _streetOrPlace.isNotEmpty ? _streetOrPlace : _label,
                    city: _city,
                    district: _district,
                    region: _region,
                    lat: _center.latitude,
                    lng: _center.longitude,
                    loading: _reverseLoading,
                    moving: _isMoving,
                    fx: _fx,
                  ),
                  if (_secondLeg &&
                      (_routeFetchLoading || _routeKm != null)) ...[
                    const SizedBox(height: 8),
                    _RouteDistanceBar(
                      distanceLabel: _routeKm != null
                          ? formatRouteDistanceKm(_routeKm!)
                          : '…',
                      approximate: _routeDistanceApproximate,
                      loading: _routeFetchLoading && _routeKm == null,
                      l10n: l10n,
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      if (_dualFlow && !_dualAwaitingDropoff) {
                        await _commitDualPickupAndGoToDropoff();
                        return;
                      }
                      if (_dualFlow && _dualAwaitingDropoff) {
                        final pickup = _dualPickupResult;
                        if (pickup == null) return;
                        if (!context.mounted) return;
                        context.pop(
                          MapDualPickerResult(
                            pickup: pickup,
                            dropoff: MapPickerResult(
                              lat: _center.latitude,
                              lng: _center.longitude,
                              label: _label.isEmpty
                                  ? '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}'
                                  : _label,
                              streetOrPlace: _streetOrPlace,
                              city: _city,
                              district: _district,
                              region: _region,
                              neighborhood: _neighborhood.isEmpty
                                  ? null
                                  : _neighborhood,
                              districtGeocoderRaw:
                                  _districtGeocoderRaw.isEmpty
                                      ? null
                                      : _districtGeocoderRaw,
                              routeDistanceKm: _routeKm,
                            ),
                          ),
                        );
                        return;
                      }
                      context.pop(
                        MapPickerResult(
                          lat: _center.latitude,
                          lng: _center.longitude,
                          label: _label.isEmpty
                              ? '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}'
                              : _label,
                          streetOrPlace: _streetOrPlace,
                          city: _city,
                          district: _district,
                          region: _region,
                          neighborhood:
                              _neighborhood.isEmpty ? null : _neighborhood,
                          districtGeocoderRaw: _districtGeocoderRaw.isEmpty
                              ? null
                              : _districtGeocoderRaw,
                          routeDistanceKm:
                              _secondLeg ? _routeKm : null,
                        ),
                      );
                    },
                    child: Text(primaryLabel),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }
}

/// Floating search / sheet chrome (Yandex-like: surface + hairline + shadow).
class _FloatingMapChrome extends StatelessWidget {
  const _FloatingMapChrome({
    required this.child,
    this.padding,
    this.maxHeight,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget body = child;
    if (maxHeight != null) {
      body = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        child: body,
      );
    }
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: cs.surface.withValues(alpha: 0.94),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: body,
      ),
    );
  }
}

class _MapControlRoundButton extends StatelessWidget {
  const _MapControlRoundButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 50,
            height: 50,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _RouteDistanceBar extends StatelessWidget {
  const _RouteDistanceBar({
    required this.distanceLabel,
    required this.approximate,
    required this.loading,
    required this.l10n,
  });

  final String distanceLabel;
  final bool approximate;
  final bool loading;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.route_rounded,
                color: PremiumMapStyle.routeBlue, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.mapDistanceLabel}: $distanceLabel',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (approximate)
                    Text(
                      l10n.mapDistanceApproximate,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}

class _CenterMarker extends StatelessWidget {
  const _CenterMarker({
    required this.lifted,
    required this.fx,
    this.isEndDropoff = false,
  });

  final bool lifted;
  final double fx;
  final bool isEndDropoff;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pinColor =
        isEndDropoff ? PremiumMapStyle.routeBlue : cs.primary;
    final onPin = isEndDropoff ? Colors.white : cs.onPrimary;
    final baseLift = lifted ? -14.0 : 0.0;
    // Tiny settle when selection happens (only when not moving).
    final settle = lifted ? 0.0 : (-2.0 * (1 - fx));
    final lift = baseLift + settle;

    final shadowOpacity = lifted ? 0.30 : 0.18;
    final shadowBlur = lifted ? 30.0 : 18.0;
    final shadowOffsetY = lifted ? 18.0 : 13.0;
    final shadowW = lifted ? 44.0 : 34.0;
    final shadowH = lifted ? 16.0 : 12.0;

    final pulseT = lifted ? 0.0 : fx;
    final ringOpacity = (0.22 * (1 - pulseT)).clamp(0.0, 0.22);
    final ringScale = 1.0 + 0.65 * pulseT;

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, lift, 0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Shadow pool (layers) + pulse ring on selection.
            Stack(
              alignment: Alignment.center,
              children: [
                if (ringOpacity > 0)
                  Transform.scale(
                    scale: ringScale,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: pinColor.withValues(alpha: ringOpacity),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  curve: Curves.easeOut,
                  width: shadowW,
                  height: shadowH,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: shadowOpacity),
                        blurRadius: shadowBlur,
                        offset: Offset(0, shadowOffsetY),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: (shadowOpacity * 0.45).clamp(0.0, 0.20),
                        ),
                        blurRadius: shadowBlur * 0.55,
                        offset: Offset(0, shadowOffsetY * 0.55),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 3D pin body (custom paint).
            SizedBox(
              width: 68,
              height: 84,
              child: CustomPaint(
                painter: _PinPainter(
                  color: pinColor,
                  onColor: onPin,
                  lifted: lifted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  _PinPainter({
    required this.color,
    required this.onColor,
    required this.lifted,
  });

  final Color color;
  final Color onColor;
  final bool lifted;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final headR = w * 0.26;
    final headCenter = ui.Offset(cx, h * 0.30);
    final tip = ui.Offset(cx, h * 0.92);

    // Main pin path (drop shape).
    final path = ui.Path()
      ..addOval(
        ui.Rect.fromCircle(center: headCenter, radius: headR * 1.18),
      )
      ..moveTo(cx - headR * 0.95, h * 0.46)
      ..quadraticBezierTo(cx - headR * 0.35, h * 0.70, tip.dx, tip.dy)
      ..quadraticBezierTo(
          cx + headR * 0.35, h * 0.70, cx + headR * 0.95, h * 0.46)
      ..close();

    // Subtle drop shadow behind pin itself (depth).
    final shadowPaint = ui.Paint()
      ..color = Colors.black.withValues(alpha: lifted ? 0.22 : 0.18)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10);
    canvas.save();
    canvas.translate(0, 2);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Base gradient.
    final baseRect = ui.Rect.fromLTWH(0, 0, w, h);
    final grad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(color, Colors.white, 0.22)!,
        color,
        Color.lerp(color, Colors.black, 0.22)!,
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    final paint = ui.Paint()..shader = grad.createShader(baseRect);
    canvas.drawPath(path, paint);

    // Inner gloss highlight (3D illusion).
    final gloss = ui.Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.55),
        radius: 0.95,
        colors: [
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(baseRect);
    canvas.drawPath(path, gloss);

    // Rim stroke.
    final stroke = ui.Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.black.withValues(alpha: 0.10);
    canvas.drawPath(path, stroke);

    // Inner "lens" circle.
    final lensR = headR * 0.58;
    final lensPaint = ui.Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35),
        radius: 0.9,
        colors: [
          Colors.white.withValues(alpha: 0.55),
          onColor.withValues(alpha: 0.92),
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        ui.Rect.fromCircle(center: headCenter, radius: lensR),
      );
    canvas.drawCircle(headCenter, lensR, lensPaint);

    final lensStroke = ui.Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.black.withValues(alpha: 0.10);
    canvas.drawCircle(headCenter, lensR, lensStroke);

    // Tiny specular dot.
    final dot = ui.Paint()..color = Colors.white.withValues(alpha: 0.78);
    canvas.drawCircle(
      headCenter.translate(-lensR * 0.28, -lensR * 0.30),
      2.2,
      dot,
    );
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.onColor != onColor ||
        oldDelegate.lifted != lifted;
  }
}

class _SelectedAddressPanel extends StatelessWidget {
  const _SelectedAddressPanel({
    required this.title,
    required this.streetOrPlace,
    required this.city,
    required this.district,
    required this.region,
    required this.lat,
    required this.lng,
    required this.loading,
    required this.moving,
    required this.fx,
  });

  final String title;
  final String streetOrPlace;
  final String city;
  final String district;
  final String region;
  final double lat;
  final double lng;
  final bool loading;
  final bool moving;
  final Animation<double> fx;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final street = streetOrPlace.trim();
    final c = city.trim();
    final d = district.trim();
    final r = region.trim();
    final lineStreet = street.isEmpty ? '—' : street;

    return AnimatedBuilder(
      animation: fx,
      builder: (context, _) {
        final pulse = moving ? 0.0 : fx.value;
        final glowAlpha = (0.22 * (1 - pulse)).clamp(0.0, 0.22);
        final scale = moving ? 0.985 : (1.0 + 0.008 * (1 - pulse));

        return Transform.scale(
          scale: scale,
          child: Card(
            elevation: 10,
            surfaceTintColor: Colors.transparent,
            color: cs.surface.withValues(alpha: 0.94),
            shadowColor: Colors.black.withValues(alpha: 0.18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.primary.withValues(alpha: glowAlpha),
                  width: 1.2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.place_outlined,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lineStreet,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (loading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            Icons.check_circle_rounded,
                            color: cs.primary,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _AddrLine(
                      icon: Icons.location_city_outlined,
                      text: c.isEmpty ? (loading ? '…' : '—') : c,
                      label: l10n.mapAddressCity,
                    ),
                    const SizedBox(height: 4),
                    _AddrLine(
                      icon: Icons.map_outlined,
                      text: d.isEmpty ? '—' : d,
                      label: l10n.mapAddressDistrict,
                    ),
                    if (r.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.mapAddressRegion}: $r',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AddrLine extends StatelessWidget {
  const _AddrLine({
    required this.icon,
    required this.text,
    required this.label,
  });

  final IconData icon;
  final String text;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

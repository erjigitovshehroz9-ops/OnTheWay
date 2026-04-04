import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/utils/route_distance_format.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/job_transport_type.dart';
import '../../../shared/map/map_camera_policy.dart';
import '../../../shared/map/premium_map_style.dart';
import '../../../shared/map/premium_map_widgets.dart';

/// Kuryer jarayonidagi marshrut: avval joriy joy → A (olib ketish), keyin A → B.
enum JobMapCourierNavLeg {
  /// GPS dan olish nuqtasi (A) gacha yo‘l.
  toPickup,

  /// Olish (A) dan yetkazish (B) gacha yo‘l.
  toDropoff,
}

class JobPickupDropoffMapPage extends ConsumerStatefulWidget {
  const JobPickupDropoffMapPage({
    super.key,
    this.pickup,
    this.dropoff,
    this.courierNavLeg,
    this.embedHeight,
    this.serverCourierLatLng,
    this.allowDeviceCourierGps = true,
  });

  final LatLng? pickup;
  final LatLng? dropoff;

  /// `null` — oddiy A–B xarita (yuboruvchi / batafsil).
  final JobMapCourierNavLeg? courierNavLeg;

  /// Berilsa — faqat xarita (marshrut logikasi bir xil); tashqi [InkWell] orqali to‘liq ekran.
  final double? embedHeight;

  /// Server/job dan kuryer nuqtasi (yuboruvchi tomonida marshrut boshlanishi / marker).
  final LatLng? serverCourierLatLng;

  /// `false` — qurilma GPS ishlatilmaydi; kuryer faqat [serverCourierLatLng] orqali.
  final bool allowDeviceCourierGps;

  @override
  ConsumerState<JobPickupDropoffMapPage> createState() =>
      _JobPickupDropoffMapPageState();
}

class _JobPickupDropoffMapPageState
    extends ConsumerState<JobPickupDropoffMapPage> {
  final MapController _mapController = MapController();
  List<LatLng> _polyline = [];
  double? _distanceKm;
  bool _approximate = false;
  bool _loading = true;
  /// Kuryer marshruti (`courierNavLeg`) — GPS; markerda transport ikonkasi.
  LatLng? _courierLatLng;
  /// Yo‘l bo‘yicha taxminiy vaqt (s); to‘liq ekran panelida ko‘rsatiladi.
  double? _durationSec;

  static const Distance _geo = Distance();

  static double? _durationFromDistanceM(double meters) {
    if (meters <= 0) return null;
    const avgKmh = 28.0;
    return (meters / 1000.0) / avgKmh * 3600.0;
  }

  String? _etaDrivingLabel(AppLocalizations l10n) {
    final sec = _durationSec;
    if (sec == null || sec <= 0) return null;
    final totalMin = (sec / 60).ceil().clamp(1, 99999);
    if (totalMin < 60) {
      return l10n.senderTrackingEtaApproxMinutes(totalMin);
    }
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return l10n.senderTrackingEtaHoursMinutes(h, m);
  }

  IconData _courierTransportIcon() {
    final user = ref.watch(authSessionProvider).valueOrNull;
    final repo = ref.watch(authRepositoryProvider).valueOrNull;
    if (user == null || repo == null) {
      return Icons.two_wheeler_rounded;
    }
    for (final k in repo.resolvedCourierTransportKeys(user)) {
      final t = JobTransportType.tryParse(k);
      if (t != null) return t.icon;
    }
    return Icons.two_wheeler_rounded;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initRoute());
    });
  }

  @override
  void didUpdateWidget(covariant JobPickupDropoffMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courierNavLeg != widget.courierNavLeg) {
      _resetRouteAndReload();
      return;
    }
    if (oldWidget.allowDeviceCourierGps != widget.allowDeviceCourierGps) {
      _resetRouteAndReload();
      return;
    }
    if (!_sameLatLng(oldWidget.pickup, widget.pickup) ||
        !_sameLatLng(oldWidget.dropoff, widget.dropoff) ||
        !_sameLatLng(oldWidget.serverCourierLatLng, widget.serverCourierLatLng)) {
      _resetRouteAndReload();
    }
  }

  bool _sameLatLng(LatLng? a, LatLng? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    return a.latitude == b.latitude && a.longitude == b.longitude;
  }

  void _resetRouteAndReload() {
    setState(() {
      _loading = true;
      _polyline = [];
      _distanceKm = null;
      _approximate = false;
      _courierLatLng = null;
      _durationSec = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_initRoute());
    });
  }

  Future<void> _applyRoute(LatLng from, LatLng to) async {
    final svc = ref.read(osrmRouteServiceProvider);
    final route = await svc.drivingRoute(from: from, to: to);
    if (!mounted) return;
    if (route != null && route.points.length >= 2) {
      final dur = route.durationSeconds ?? _durationFromDistanceM(route.distanceMeters);
      setState(() {
        _polyline = route.points;
        _distanceKm = route.distanceMeters / 1000.0;
        _approximate = false;
        _loading = false;
        _durationSec = dur;
        if (widget.courierNavLeg == JobMapCourierNavLeg.toPickup) {
          _courierLatLng = from;
        }
      });
    } else {
      final m = _geo.as(LengthUnit.Meter, from, to);
      setState(() {
        _polyline = [from, to];
        _distanceKm = m / 1000.0;
        _approximate = true;
        _loading = false;
        _durationSec = _durationFromDistanceM(m);
        if (widget.courierNavLeg == JobMapCourierNavLeg.toPickup) {
          _courierLatLng = from;
        }
      });
    }
    _scheduleFit();
  }

  Future<void> _refreshCourierGpsMarker() async {
    if (widget.courierNavLeg == null) return;
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() => _courierLatLng = LatLng(p.latitude, p.longitude));
      _scheduleFit();
    } catch (_) {}
  }

  Future<void> _initRoute() async {
    final leg = widget.courierNavLeg;
    final a = widget.pickup;
    final b = widget.dropoff;

    if (leg == JobMapCourierNavLeg.toPickup) {
      if (a == null) {
        if (mounted) setState(() => _loading = false);
        _scheduleFit();
        return;
      }
      final server = widget.serverCourierLatLng;
      if (server != null) {
        setState(() => _courierLatLng = server);
        await _applyRoute(server, a);
        return;
      }
      if (!widget.allowDeviceCourierGps) {
        if (mounted) {
          setState(() {
            _polyline = [];
            _distanceKm = null;
            _approximate = false;
            _loading = false;
            _courierLatLng = null;
            _durationSec = null;
          });
        }
        _scheduleFit();
        return;
      }
      LatLng? origin;
      try {
        final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        origin = LatLng(p.latitude, p.longitude);
      } catch (_) {}
      if (origin != null) {
        setState(() => _courierLatLng = origin);
        await _applyRoute(origin, a);
        return;
      }
      if (mounted) {
        setState(() {
          _polyline = [];
          _distanceKm = null;
          _approximate = false;
          _loading = false;
          _courierLatLng = null;
          _durationSec = null;
        });
      }
      _scheduleFit();
      return;
    }

    if (leg == JobMapCourierNavLeg.toDropoff) {
      if (a != null && b != null) {
        await _applyRoute(a, b);
        final srv = widget.serverCourierLatLng;
        if (srv != null) {
          if (mounted) setState(() => _courierLatLng = srv);
          _scheduleFit();
        } else if (widget.allowDeviceCourierGps) {
          unawaited(_refreshCourierGpsMarker());
        }
        return;
      }
      if (mounted) setState(() => _loading = false);
      _scheduleFit();
      return;
    }

    if (a != null && b != null) {
      await _applyRoute(a, b);
      return;
    }

    if (mounted) setState(() => _loading = false);
    _scheduleFit();
  }

  void _scheduleFit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final a = widget.pickup;
      final b = widget.dropoff;
      final points = <LatLng>[];
      if (_polyline.length >= 2) {
        points.addAll(_polyline);
      } else {
        if (a != null) points.add(a);
        if (b != null) points.add(b);
      }
      if (widget.courierNavLeg != null && _courierLatLng != null) {
        points.add(_courierLatLng!);
      }
      if (points.isEmpty) return;
      final embed = widget.embedHeight != null;
      premiumFitBounds(
        _mapController,
        points: points,
        padding: embed
            ? const EdgeInsets.fromLTRB(16, 16, 16, 40)
            : const EdgeInsets.fromLTRB(56, 96, 56, 200),
        maxZoom: 15,
      );
    });
  }

  Future<void> _onMyLocationPressed() async {
    if (!widget.allowDeviceCourierGps) return;
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final here = LatLng(p.latitude, p.longitude);
      if (widget.courierNavLeg != null && mounted) {
        setState(() => _courierLatLng = here);
      }
      _mapController.move(here, 15);
      if (widget.courierNavLeg == JobMapCourierNavLeg.toPickup &&
          widget.pickup != null &&
          mounted) {
        setState(() => _loading = true);
        await _applyRoute(here, widget.pickup!);
      }
    } catch (_) {
      _scheduleFit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final a = widget.pickup;
    final b = widget.dropoff;
    final leg = widget.courierNavLeg;
    final mapCam = MapCameraPolicy.forPickupDropoffMap(a, b);
    final both = a != null && b != null;

    final panelTitle = switch (leg) {
      JobMapCourierNavLeg.toPickup => l10n.courierJobMapToPickupTitle,
      JobMapCourierNavLeg.toDropoff => l10n.courierJobMapToDropoffTitle,
      null => l10n.jobRouteMapTitle,
    };

    final showDistance = !_loading &&
        _distanceKm != null &&
        _polyline.length >= 2 &&
        (leg == null ? both : true);

    final singleCoord =
        leg == null && ((a != null) ^ (b != null));

    final showGpsHint = leg == JobMapCourierNavLeg.toPickup &&
        widget.allowDeviceCourierGps &&
        !_loading &&
        _polyline.length < 2 &&
        a != null;

    final etaDrivingText = _etaDrivingLabel(l10n);

    final embedH = widget.embedHeight;
    final embedded = embedH != null;

    final map = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: a ?? b ?? const LatLng(41.31, 69.28),
        initialZoom: both ? 11 : 13,
        backgroundColor: PremiumMapStyle.mapBackground,
        cameraConstraint: mapCam.constraint,
        minZoom: mapCam.minZoom,
        maxZoom: mapCam.maxZoom,
        interactionOptions: InteractionOptions(
          flags: embedded ? InteractiveFlag.none : InteractiveFlag.all,
        ),
      ),
      children: [
        PremiumMapStyle.lightTileLayer(),
        if (_polyline.length >= 2)
          PremiumMapStyle.routePolylineLayer(_polyline),
        MarkerLayer(
          markers: [
            if (a != null)
              Marker(
                point: a,
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: PremiumRouteLetterMarker(label: l10n.jobMapMarkerA),
              ),
            if (b != null)
              Marker(
                point: b,
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: PremiumRouteLetterMarker(label: l10n.jobMapMarkerB),
              ),
            if (leg != null && _courierLatLng != null)
              Marker(
                point: _courierLatLng!,
                width: 56,
                height: 56,
                alignment: Alignment.center,
                child: PremiumCourierMarker(
                  size: 52,
                  icon: _courierTransportIcon(),
                ),
              ),
          ],
        ),
      ],
    );

    if (embedded) {
      // Xarita bosishni o‘zi yutmasin — tashqi [InkWell] kattalashtirishni ochadi.
      return SizedBox(
        height: embedH,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: IgnorePointer(child: map),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(child: PremiumMapAttribution()),
              ),
              if (_loading)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Color(0x33FFFFFF),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: PremiumMapStyle.routeBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: PremiumMapStyle.mapBackground,
      body: Stack(
        children: [
          Positioned.fill(child: map),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 198,
            child: PremiumMapAttribution(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PremiumMapFloatingBackButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          if (widget.allowDeviceCourierGps)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 16, 200),
                  child: PremiumMapLocationButton(
                    tooltip: l10n.recenterMap,
                    onPressed: _onMyLocationPressed,
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Material(
                  elevation: 12,
                  shadowColor: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          panelTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                        ),
                        const SizedBox(height: 10),
                        if (_loading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: PremiumMapStyle.routeBlue,
                                ),
                              ),
                            ),
                          )
                        else if (showGpsHint)
                          Text(
                            l10n.courierJobMapGpsUnavailable,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF475569),
                                  height: 1.35,
                                ),
                            textAlign: TextAlign.center,
                          )
                        else if (showDistance) ...[
                          Text(
                            '${l10n.mapDistanceLabel}: ${formatRouteDistanceKm(_distanceKm!)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                            textAlign: TextAlign.center,
                          ),
                          if (etaDrivingText != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              etaDrivingText,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF334155),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (_approximate) ...[
                            const SizedBox(height: 6),
                            Text(
                              l10n.mapDistanceApproximate,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF64748B),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ] else if (singleCoord)
                          Text(
                            l10n.jobMapOneCoordinateOnly,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF475569),
                                ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

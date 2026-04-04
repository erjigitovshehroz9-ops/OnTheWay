import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/job_entity.dart';
import '../../../../models/job_transport_type.dart';
import '../../../../shared/map/map_camera_policy.dart';
import '../../../../shared/map/premium_map_style.dart';
import '../../../../shared/map/premium_map_widgets.dart';
import '../../../../shared/utils/job_status_l10n.dart';

/// Kuryer → olish yoki kuryer → yetkazish bo‘yicha marshrut.
enum CourierRouteLeg {
  /// Biriktirilgan, kuryer olish nuqtasiga yo‘l olgan.
  toPickup,

  /// Olib ketilgan, kuryer yetkazish manziliga.
  toDropoff,
}

/// Kuryer yo‘nalishi, masofa/VAQTaxmin va kattalashtirish (to‘liq ekran).
class JobCourierRouteTrackingCard extends ConsumerStatefulWidget {
  const JobCourierRouteTrackingCard({
    super.key,
    required this.job,
    required this.locale,
    required this.l10n,
    required this.leg,
    this.isFullscreen = false,
    this.trackingViewerId,
  });

  final JobEntity job;
  final Locale locale;
  final AppLocalizations l10n;
  final CourierRouteLeg leg;
  final bool isFullscreen;
  /// Sender / g‘olib kuryer: jonli badge va “so‘nggi yangilanish”.
  final String? trackingViewerId;

  @override
  ConsumerState<JobCourierRouteTrackingCard> createState() =>
      _JobCourierRouteTrackingCardState();
}

class _JobCourierRouteTrackingCardState
    extends ConsumerState<JobCourierRouteTrackingCard> {
  final MapController _map = MapController();
  List<LatLng> _polyline = [];
  bool _routeLoading = false;
  String? _routeKey;
  double? _distanceM;
  double? _durationSec;

  static const Distance _geo = Distance();

  LatLng get _courier =>
      LatLng(widget.job.courierLat!, widget.job.courierLng!);

  LatLng? get _destination {
    final j = widget.job;
    switch (widget.leg) {
      case CourierRouteLeg.toPickup:
        if (j.pickupLat == null ||
            j.pickupLng == null ||
            j.pickupLat! < -90 ||
            j.pickupLat! > 90 ||
            j.pickupLng! < -180 ||
            j.pickupLng! > 180) {
          return null;
        }
        return LatLng(j.pickupLat!, j.pickupLng!);
      case CourierRouteLeg.toDropoff:
        if (j.dropoffLat == null ||
            j.dropoffLng == null ||
            j.dropoffLat! < -90 ||
            j.dropoffLat! > 90 ||
            j.dropoffLng! < -180 ||
            j.dropoffLng! > 180) {
          return null;
        }
        return LatLng(j.dropoffLat!, j.dropoffLng!);
    }
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_syncRoute());
    });
  }

  @override
  void didUpdateWidget(covariant JobCourierRouteTrackingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_routeIdentity(widget.job, widget.leg) != _routeKey) {
      unawaited(_syncRoute());
    }
  }

  String _routeIdentity(JobEntity j, CourierRouteLeg leg) {
    final dest = switch (leg) {
      CourierRouteLeg.toPickup => '${j.pickupLat}_${j.pickupLng}',
      CourierRouteLeg.toDropoff => '${j.dropoffLat}_${j.dropoffLng}',
    };
    return '${j.courierLat}_${j.courierLng}_${leg.name}_$dest';
  }

  void _applyStraightLineFallback(LatLng courier, LatLng dest) {
    final meters = _geo.as(LengthUnit.Meter, courier, dest);
    setState(() {
      _polyline = [courier, dest];
      _distanceM = meters;
      _durationSec = _estimateDurationFromDistance(meters);
      _routeKey = _routeIdentity(widget.job, widget.leg);
      _routeLoading = false;
    });
    _fitCamera();
  }

  /// Taxminiy: ~28 km/soat o‘rtacha tezlik.
  double _estimateDurationFromDistance(double meters) {
    const kmh = 28.0;
    final hours = (meters / 1000) / kmh;
    return hours * 3600;
  }

  Future<void> _syncRoute() async {
    final job = widget.job;
    if (job.courierLat == null || job.courierLng == null) return;
    final dest = _destination;
    if (dest == null) {
      if (!mounted) return;
      setState(() {
        _polyline = [];
        _distanceM = null;
        _durationSec = null;
        _routeKey = _routeIdentity(job, widget.leg);
        _routeLoading = false;
      });
      return;
    }

    final courier = _courier;

    if (!mounted) return;
    setState(() => _routeLoading = true);

    final svc = ref.read(osrmRouteServiceProvider);
    final route = await svc.drivingRoute(from: courier, to: dest);
    if (!mounted) return;

    if (route != null && route.points.length >= 2) {
      final dist = route.distanceMeters;
      final dur = route.durationSeconds ??
          _estimateDurationFromDistance(dist);
      setState(() {
        _polyline = route.points;
        _distanceM = dist;
        _durationSec = dur;
        _routeKey = _routeIdentity(job, widget.leg);
        _routeLoading = false;
      });
    } else {
      _applyStraightLineFallback(courier, dest);
      return;
    }
    _fitCamera();
  }

  void _fitCamera() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final courier = _courier;
      final pts = <LatLng>[courier];
      final dest = _destination;
      if (dest != null) pts.add(dest);
      if (widget.leg == CourierRouteLeg.toDropoff) {
        final j = widget.job;
        if (j.pickupLat != null &&
            j.pickupLng != null &&
            j.pickupLat! >= -90 &&
            j.pickupLat! <= 90 &&
            j.pickupLng! >= -180 &&
            j.pickupLng! <= 180) {
          pts.add(LatLng(j.pickupLat!, j.pickupLng!));
        }
      }
      if (_polyline.length >= 2) {
        premiumFitBounds(
          _map,
          points: _polyline,
          padding: EdgeInsets.fromLTRB(
            48,
            widget.isFullscreen ? 56 : 56,
            48,
            widget.isFullscreen ? 24 : 100,
          ),
          maxZoom: 16,
        );
        return;
      }
      premiumFitBounds(
        _map,
        points: pts,
        padding: EdgeInsets.fromLTRB(48, 56, 48, widget.isFullscreen ? 24 : 100),
        maxZoom: 16,
      );
    });
  }

  String? _formatDistance(AppLocalizations l10n) {
    final m = _distanceM;
    if (m == null) return null;
    if (m < 1000) {
      return l10n.senderTrackingDistanceMeters(m.round());
    }
    return l10n.senderTrackingDistanceKm(
      (m / 1000).toStringAsFixed(m < 10000 ? 1 : 0),
    );
  }

  String? _formatEta(AppLocalizations l10n) {
    final s = _durationSec;
    if (s == null) return null;
    final minutes = (s / 60).ceil().clamp(1, 24 * 60);
    if (minutes < 90) {
      return l10n.senderTrackingEtaApproxMinutes(minutes);
    }
    final h = minutes ~/ 60;
    final min = minutes % 60;
    return l10n.senderTrackingEtaHoursMinutes(h, min);
  }

  String _lastUpdatedLine(JobEntity job, AppLocalizations l10n) {
    final t = job.courierLocationAt;
    if (t == null) {
      return '${l10n.trackingLastUpdatedPrefix} —';
    }
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 50) {
      return '${l10n.trackingLastUpdatedPrefix} ${l10n.senderNotificationsTimeJustNow}';
    }
    if (d.inMinutes < 60) {
      return '${l10n.trackingLastUpdatedPrefix} ${l10n.senderNotificationsTimeMinutesAgo(d.inMinutes.clamp(1, 59))}';
    }
    if (d.inHours < 72) {
      return '${l10n.trackingLastUpdatedPrefix} ${l10n.senderNotificationsTimeHoursAgo(d.inHours.clamp(1, 71))}';
    }
    return '${l10n.trackingLastUpdatedPrefix} ${l10n.senderNotificationsTimeHoursAgo(72)}';
  }

  void _openFullscreen(BuildContext context) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (ctx) => _CourierRouteFullscreenPage(
            job: widget.job,
            locale: widget.locale,
            l10n: widget.l10n,
            leg: widget.leg,
            trackingViewerId: widget.trackingViewerId,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final l10n = widget.l10n;
    final locale = widget.locale;
    final showLiveChrome = widget.trackingViewerId != null &&
        job.liveTrackingVisibleTo(widget.trackingViewerId);
    if (kDebugMode) {
      debugPrint(
        '[tracking-ui] visible=$showLiveChrome order=${job.id} leg=${widget.leg.name}',
      );
    }

    if (job.courierLat == null || job.courierLng == null) {
      return const SizedBox.shrink();
    }

    final dest = _destination;
    if (dest == null) {
      return Text(
        l10n.senderTrackingNoCoordinatesForLeg,
        style: const TextStyle(
          fontSize: 13,
          height: 1.35,
          color: Color(0xFF7D8592),
        ),
      );
    }

    final pickupOk = job.pickupLat != null &&
        job.pickupLng != null &&
        job.pickupLat! >= -90 &&
        job.pickupLat! <= 90 &&
        job.pickupLng! >= -180 &&
        job.pickupLng! <= 180;
    final dropOk = job.dropoffLat != null &&
        job.dropoffLng != null &&
        job.dropoffLat! >= -90 &&
        job.dropoffLat! <= 90 &&
        job.dropoffLng! >= -180 &&
        job.dropoffLng! <= 180;

    final markers = <Marker>[
      if (pickupOk)
        Marker(
          point: LatLng(job.pickupLat!, job.pickupLng!),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: PremiumRouteLetterMarker(
            label: l10n.jobMapMarkerA,
            diameter: 36,
            fontSize: 15,
          ),
        ),
      if (dropOk)
        Marker(
          point: LatLng(job.dropoffLat!, job.dropoffLng!),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: PremiumRouteLetterMarker(label: l10n.jobMapMarkerB),
        ),
      Marker(
        point: _courier,
        width: 56,
        height: 56,
        alignment: Alignment.center,
        child: PremiumCourierMarker(
          size: 52,
          icon: JobTransportType.iconForStoredSummary(job.transportType),
        ),
      ),
    ];

    final destLabel = widget.leg == CourierRouteLeg.toPickup
        ? job.pickupAddress.resolveLang(locale.languageCode)
        : job.dropoffAddress.resolveLang(locale.languageCode);

    final mapCam = MapCameraPolicy.forCourierTrackingJob(job);

    final mapStack = Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _courier,
            initialZoom: 14,
            backgroundColor: PremiumMapStyle.mapBackground,
            cameraConstraint: mapCam.constraint,
            minZoom: mapCam.minZoom,
            maxZoom: mapCam.maxZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onTap: widget.isFullscreen
                ? null
                : (_, __) => _openFullscreen(context),
            onMapReady: _fitCamera,
          ),
          children: [
            PremiumMapStyle.lightTileLayer(),
            if (_polyline.length >= 2)
              PremiumMapStyle.routePolylineLayer(_polyline),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.94),
                  ],
                ),
              ),
              child: const SizedBox(height: 56),
            ),
          ),
        ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 6,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      jobStatusLabel(job.status, l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      destLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (_routeLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: PremiumMapStyle.routeBlue,
                  ),
                ),
            ],
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 2,
          child: PremiumMapAttribution(),
        ),
      ],
    );

    final distStr = _formatDistance(l10n);
    final etaStr = _formatEta(l10n);
    if (kDebugMode) {
      debugPrint(
        '[tracking-ui] eta=$etaStr distance=$distStr order=${job.id}',
      );
    }

    final liveHeader = showLiveChrome
        ? Padding(
            padding: EdgeInsets.only(bottom: widget.isFullscreen ? 12 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.liveTrackingBadge,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.teal.shade900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _lastUpdatedLine(job, l10n),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final stats = Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (distStr != null || etaStr != null)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (etaStr != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: Colors.teal.shade800,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          etaStr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A1629),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (distStr != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.route_rounded,
                        size: 18,
                        color: Colors.blue.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        distStr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A1629),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          if (!widget.isFullscreen)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.senderTrackingTapToEnlarge,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF13635B),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.isFullscreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          liveHeader,
          Expanded(child: mapStack),
          Material(
            elevation: 10,
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: stats,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        liveHeader,
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 228,
            child: mapStack,
          ),
        ),
        stats,
      ],
    );
  }
}

class _CourierRouteFullscreenPage extends StatelessWidget {
  const _CourierRouteFullscreenPage({
    required this.job,
    required this.locale,
    required this.l10n,
    required this.leg,
    this.trackingViewerId,
  });

  final JobEntity job;
  final Locale locale;
  final AppLocalizations l10n;
  final CourierRouteLeg leg;
  final String? trackingViewerId;

  @override
  Widget build(BuildContext context) {
    final title = leg == CourierRouteLeg.toPickup
        ? l10n.senderTrackingFullscreenTitlePickup
        : l10n.senderTrackingFullscreenTitleDropoff;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0A1629),
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: JobCourierRouteTrackingCard(
        job: job,
        locale: locale,
        l10n: l10n,
        leg: leg,
        isFullscreen: true,
        trackingViewerId: trackingViewerId,
      ),
    );
  }
}

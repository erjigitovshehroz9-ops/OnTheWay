import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../data/uz_admin_geo.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/job_entity.dart';
import '../../../../models/job_status.dart';
import '../../../../shared/map/map_camera_policy.dart';
import '../../../../shared/map/premium_map_style.dart';
import '../../../../shared/utils/job_status_l10n.dart';
import '../../../../shared/widgets/job_image.dart';

/// Kuryer paneli: tanlangan viloyat/tuman bo‘yicha xarita, markerlar, bottom sheet.
class CourierJobsMap extends StatefulWidget {
  const CourierJobsMap({
    super.key,
    required this.jobs,
    required this.locale,
    required this.l10n,
    required this.regionCode,
    this.districtCode,
  });

  final List<JobEntity> jobs;
  final Locale locale;
  final AppLocalizations l10n;
  final String regionCode;
  final String? districtCode;

  @override
  State<CourierJobsMap> createState() => _CourierJobsMapState();
}

class _CourierJobsMapState extends State<CourierJobsMap> {
  final MapController _map = MapController();
  static const Distance _distance = Distance();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !kDebugMode) return;
      debugPrint('[order-map] markers count=${widget.jobs.length}');
    });
  }

  String _fmtPrice(int cents) {
    final v = (cents / 100).round();
    final fmt = NumberFormat('#,###', widget.locale.toString());
    return '${fmt.format(v)} UZS';
  }

  LatLng _focusPoint() =>
      UzAdminGeo.districtFocus(widget.districtCode, widget.regionCode);

  List<({JobEntity job, LatLng point})> _markerPoints() {
    final focus = _focusPoint();
    final raw = <({JobEntity job, LatLng point})>[];
    for (final j in widget.jobs) {
      final LatLng p;
      if (_validPick(j)) {
        p = LatLng(j.pickupLat!, j.pickupLng!);
      } else {
        p = UzAdminGeo.scatterFromAnchor(j.id, focus);
      }
      raw.add((job: j, point: p));
    }
    return _spreadOverlaps(raw);
  }

  bool _validPick(JobEntity j) {
    if (j.pickupLat == null || j.pickupLng == null) return false;
    final la = j.pickupLat!;
    final ln = j.pickupLng!;
    return la >= -90 && la <= 90 && ln >= -180 && ln <= 180;
  }

  List<({JobEntity job, LatLng point})> _spreadOverlaps(
    List<({JobEntity job, LatLng point})> items,
  ) {
    if (items.length <= 1) return items;
    const minM = 46.0;
    final out = <({JobEntity job, LatLng point})>[];
    for (var idx = 0; idx < items.length; idx++) {
      final origin = items[idx].point;
      var p = origin;
      for (var tries = 0; tries < 28; tries++) {
        var conflict = false;
        for (final o in out) {
          if (_distance.as(LengthUnit.Meter, p, o.point) < minM) {
            conflict = true;
            break;
          }
        }
        if (!conflict) break;
        final ang = (idx * 73 + tries * 41) * math.pi / 180;
        final meters = (tries + 1) * 40.0;
        final dLat = meters / 111320 * math.cos(ang);
        final dLng = meters /
            (111320 * math.cos(origin.latitude * math.pi / 180)) *
            math.sin(ang);
        p = LatLng(origin.latitude + dLat, origin.longitude + dLng);
      }
      out.add((job: items[idx].job, point: p));
    }
    return out;
  }

  void _fitCamera() {
    if (!mounted) return;
    final focus = _focusPoint();
    final placed = _markerPoints();
    if (placed.isEmpty) {
      _map.move(focus, 11.8);
      return;
    }
    if (placed.length == 1) {
      _map.move(placed.first.point, 14);
      return;
    }
    final pts = placed.map((e) => e.point).toList();
    final b = LatLngBounds.fromPoints(pts);
    _map.fitCamera(
      CameraFit.bounds(
        bounds: b,
        padding: const EdgeInsets.fromLTRB(44, 52, 44, 72),
        maxZoom: 15,
      ),
    );
  }

  @override
  void didUpdateWidget(CourierJobsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kDebugMode &&
        (oldWidget.jobs.length != widget.jobs.length ||
            !_sameJobSet(oldWidget.jobs, widget.jobs))) {
      debugPrint('[order-map] markers count=${widget.jobs.length}');
    }
    if (oldWidget.regionCode != widget.regionCode ||
        oldWidget.districtCode != widget.districtCode ||
        !_sameJobSet(oldWidget.jobs, widget.jobs)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
    }
  }

  bool _sameJobSet(List<JobEntity> a, List<JobEntity> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _openJobSheet(JobEntity job) {
    final l10n = widget.l10n;
    final loc = widget.locale;
    final pickupLine = _pickupSummary(job, l10n);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (job.imagePath.trim().isNotEmpty) ...[
                Center(
                  child: JobImageThumbnail(
                    imageRef: job.imagePath.trim(),
                    size: 112,
                    borderRadius: 14,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                job.title.resolveLang(loc.languageCode),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                '${l10n.auctionStartPriceLabel}: ${_fmtPrice(job.startPriceCents)}',
                style: const TextStyle(
                  color: Color(0xFF7DD3FC),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pickupLine,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 13,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (job.orderComments != null &&
                  job.orderComments!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  job.orderComments!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              _StatusPill(status: job.status, l10n: l10n),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF22D3EE),
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.jobDetail(job.id));
                },
                child: Text(l10n.courierMapOpenDetail),
              ),
            ],
          ),
        );
      },
    );
  }

  String _pickupSummary(JobEntity job, AppLocalizations l10n) {
    if (_validPick(job)) {
      return l10n.courierMapCoordsShort(
        job.pickupLat!.toStringAsFixed(5),
        job.pickupLng!.toStringAsFixed(5),
      );
    }
    final t = job.pickupAddress.resolveLang(widget.locale.languageCode).trim();
    if (t.isEmpty) return '—';
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final placed = _markerPoints();
    final empty = widget.jobs.isEmpty;
    final ov = MapCameraPolicy.courierJobsOverview;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: PremiumMapStyle.mapBackground,
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _focusPoint(),
                    initialZoom: 11.5,
                    backgroundColor: PremiumMapStyle.mapBackground,
                    cameraConstraint: ov.constraint,
                    minZoom: ov.minZoom,
                    maxZoom: ov.maxZoom,
                    onMapReady: _fitCamera,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    PremiumMapStyle.lightTileLayer(),
                    MarkerLayer(
                      markers: placed
                          .map(
                            (e) => Marker(
                              point: e.point,
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _openJobSheet(e.job),
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: PremiumMapStyle.routeBlue
                                            .withValues(alpha: 0.35),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.12),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: PremiumMapStyle.routeBlue,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              if (empty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0F172A).withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Text(
                        widget.l10n.courierMapNoOrdersInDistrict,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.l10n});

  final JobStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      JobStatus.delivered || JobStatus.completed => (
          const Color(0xFF065F46).withValues(alpha: 0.9),
          const Color(0xFF22D3EE),
        ),
      JobStatus.cancelled => (
          Colors.white24,
          Colors.white70,
        ),
      _ => (
          const Color(0xFFB45309).withValues(alpha: 0.85),
          const Color(0xFFFEF3C7),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        jobStatusLabel(status, l10n),
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

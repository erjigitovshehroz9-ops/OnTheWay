import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/debug/provider_error_screen.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/job_entity.dart';
import '../../../models/job_transport_type.dart';
import '../../../shared/map/map_camera_policy.dart';
import '../../../shared/map/premium_map_style.dart';
import '../../../shared/map/premium_map_widgets.dart';
import '../../../shared/widgets/app_primary_scaffold.dart';
import 'widgets/admin_surface_card.dart';

final _trackingJobsProvider = FutureProvider<List<JobEntity>>((ref) async {
  if (kIsWeb) return [];
  final db = await ref.watch(appDatabaseProvider.future);
  if (db == null) return [];
  return db.listActiveTrackingJobs();
});

class AdminMapPage extends ConsumerStatefulWidget {
  const AdminMapPage({super.key});

  @override
  ConsumerState<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends ConsumerState<AdminMapPage> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  LatLng _centroid(Iterable<LatLng> pts) {
    final list = pts.toList();
    var lat = 0.0;
    var lng = 0.0;
    for (final p in list) {
      lat += p.latitude;
      lng += p.longitude;
    }
    final n = list.length;
    return LatLng(lat / n, lng / n);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    final c = _mapController.camera;
    _mapController.move(
      c.center,
      (c.zoom + delta).clamp(3, 18),
    );
  }

  void _recenter(LatLng center, double zoom) {
    if (!_mapReady) return;
    _mapController.moveAndRotate(center, zoom, 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final jobsAsync = ref.watch(_trackingJobsProvider);

    return Theme(
      data: AppTheme.dark(),
      child: AppPrimaryScaffold(
        title: l10n.adminLiveMap,
        showLanguageSwitcher: true,
        body: jobsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ProviderErrorScreen(
            error: error,
            stackTrace: stack,
            onRetry: () {
              ref.invalidate(_trackingJobsProvider);
              ref.invalidate(appDatabaseProvider);
            },
          ),
          data: (jobs) {
            final withPos = jobs
                .where(
                  (j) => j.courierLat != null && j.courierLng != null,
                )
                .toList();

            if (jobs.isEmpty) {
              return _AdminMapEmpty(
                icon: Icons.layers_clear_rounded,
                title: l10n.adminMapEmptyNoJobsTitle,
                body: l10n.adminMapEmptyNoJobsBody,
                onRefresh: () => ref.invalidate(_trackingJobsProvider),
              );
            }

            if (withPos.isEmpty) {
              return _AdminMapEmpty(
                icon: Icons.location_off_rounded,
                title: l10n.adminMapEmptyNoGpsTitle,
                body: l10n.adminMapEmptyNoGpsBody,
                onRefresh: () => ref.invalidate(_trackingJobsProvider),
              );
            }

            final points =
                withPos.map((j) => LatLng(j.courierLat!, j.courierLng!)).toList();
            final center = _centroid(points);
            final locale = Localizations.localeOf(context);
            final mapCam = MapCameraPolicy.adminTrackingOverview;

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: center,
                            initialZoom: 11,
                            initialRotation: 0,
                            backgroundColor: PremiumMapStyle.mapBackground,
                            cameraConstraint: mapCam.constraint,
                            minZoom: mapCam.minZoom,
                            maxZoom: mapCam.maxZoom,
                            onMapReady: () {
                              if (mounted) {
                                setState(() => _mapReady = true);
                              }
                            },
                          ),
                          children: [
                            PremiumMapStyle.lightTileLayer(),
                            MarkerLayer(
                              markers: withPos.map((j) {
                                final pt =
                                    LatLng(j.courierLat!, j.courierLng!);
                                return Marker(
                                  point: pt,
                                  width: 52,
                                  height: 52,
                                  alignment: Alignment.center,
                                  child: Tooltip(
                                    message: j.title.resolveLang(locale.languageCode),
                                    child: PremiumCourierMarkerStatic(
                                      size: 48,
                                      icon: JobTransportType.iconForStoredSummary(
                                        j.transportType,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 0,
                  child: SafeArea(
                    bottom: false,
                    child: AdminSurfaceCard(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  scheme.primary,
                                  scheme.primary.withValues(alpha: 0.62),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      scheme.primary.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.map_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.adminLiveMap,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.adminNavMapSubtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: scheme.primary.withValues(alpha: 0.14),
                              border: Border.all(
                                color: scheme.primary.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Text(
                              l10n.adminMapMarkerCount(withPos.length),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 28,
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AdminMapControlButton(
                          icon: Icons.add_rounded,
                          scheme: scheme,
                          tooltip: 'Zoom in',
                          onPressed: () => _zoomBy(1),
                        ),
                        const SizedBox(height: 10),
                        _AdminMapControlButton(
                          icon: Icons.remove_rounded,
                          scheme: scheme,
                          tooltip: 'Zoom out',
                          onPressed: () => _zoomBy(-1),
                        ),
                        const SizedBox(height: 10),
                        _AdminMapControlButton(
                          icon: Icons.my_location_rounded,
                          scheme: scheme,
                          tooltip: l10n.recenterMap,
                          onPressed: () => _recenter(center, 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminMapControlButton extends StatelessWidget {
  const _AdminMapControlButton({
    required this.icon,
    required this.scheme,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final ColorScheme scheme;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.surface.withValues(alpha: 0.94),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: scheme.primary, size: 22),
          ),
        ),
      ),
    );
  }
}

class _AdminMapEmpty extends StatelessWidget {
  const _AdminMapEmpty({
    required this.icon,
    required this.title,
    required this.body,
    required this.onRefresh,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AdminSurfaceCard(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.14),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 18),
                FilledButton.tonalIcon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

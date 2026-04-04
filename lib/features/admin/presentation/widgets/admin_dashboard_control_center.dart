import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/admin_operational_snapshot.dart';
import '../../application/admin_operational_snapshot_provider.dart';
import 'admin_panel_metric_palette.dart';
import 'admin_section_title.dart';
import 'admin_surface_card.dart';

/// Dashboard A–D bloklari: overview, sifat, geografiya, auksion/yetkazish.
class AdminDashboardControlCenter extends ConsumerWidget {
  const AdminDashboardControlCenter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(adminOperationalSnapshotProvider);

    return async.when(
      data: (s) => _Body(l10n: l10n, s: s),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          e.toString(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFDC2626),
              ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.l10n, required this.s});

  final AppLocalizations l10n;
  final AdminOperationalSnapshot s;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionTitle(title: l10n.adminControlOverviewTitle),
        const SizedBox(height: 10),
        _metricGrid(context, [
          _MetricSpec(
            l10n.adminControlUsersTotal,
            s.usersTotal.toString(),
            Icons.groups_outlined,
            AdminPanelMetricPalette.usersTotal,
          ),
          _MetricSpec(
            l10n.adminControlSenders,
            s.senders.toString(),
            Icons.storefront_outlined,
            AdminPanelMetricPalette.senders,
          ),
          _MetricSpec(
            l10n.adminControlCouriers,
            s.couriers.toString(),
            Icons.two_wheeler_outlined,
            AdminPanelMetricPalette.couriers,
          ),
          _MetricSpec(
            l10n.adminControlOrdersTotal,
            s.jobsTotal.toString(),
            Icons.inventory_2_outlined,
            AdminPanelMetricPalette.ordersTotal,
          ),
          _MetricSpec(
            l10n.adminControlPosted,
            s.jobsPosted.toString(),
            Icons.campaign_outlined,
            AdminPanelMetricPalette.posted,
          ),
          _MetricSpec(
            l10n.adminControlAuctionLive,
            s.jobsAuctionLive.toString(),
            Icons.gavel_rounded,
            AdminPanelMetricPalette.auctionLive,
          ),
          _MetricSpec(
            l10n.adminControlAssigned,
            s.jobsAssigned.toString(),
            Icons.assignment_ind_outlined,
            AdminPanelMetricPalette.assigned,
          ),
          _MetricSpec(
            l10n.adminControlPickedUp,
            s.jobsPickedUp.toString(),
            Icons.shopping_bag_outlined,
            AdminPanelMetricPalette.pickedUp,
          ),
          _MetricSpec(
            l10n.adminControlDelivered,
            s.jobsDelivered.toString(),
            Icons.check_circle_outline_rounded,
            AdminPanelMetricPalette.delivered,
          ),
          _MetricSpec(
            l10n.adminControlCompleted,
            s.jobsCompleted.toString(),
            Icons.verified_outlined,
            AdminPanelMetricPalette.completed,
          ),
          _MetricSpec(
            l10n.adminControlCancelled,
            s.jobsCancelled.toString(),
            Icons.cancel_outlined,
            AdminPanelMetricPalette.cancelled,
          ),
          _MetricSpec(
            l10n.adminControlBlocked,
            s.blockedUsers.toString(),
            Icons.block_rounded,
            AdminPanelMetricPalette.blocked,
          ),
        ]),
        const SizedBox(height: 18),
        AdminSectionTitle(title: l10n.adminControlFeedbackTitle),
        const SizedBox(height: 8),
        AdminSurfaceCard(
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv(t, l10n.adminControlRatingsTotal, '${s.orderFeedbackTotal}'),
              _kv(t, l10n.adminControlAvgRating,
                  s.orderFeedbackAvgRating.toStringAsFixed(2)),
              _kv(t, l10n.adminControlComplaintsNew, '${s.orderFeedbackComplaints}'),
              _kv(t, l10n.adminControlPraises, '${s.orderFeedbackPraises}'),
              _kv(t, l10n.adminControlLegacyComplaints, '${s.legacyComplaints}'),
              const Divider(height: 20),
              Text(
                l10n.adminControlTopComplaintTargets,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              if (s.topComplaintUserIds.isEmpty)
                Text('—', style: t.bodySmall)
              else
                ...s.topComplaintUserIds.take(5).map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${_shortId(e.userId)} · ${e.count}',
                          style: t.bodySmall,
                        ),
                      ),
                    ),
              const SizedBox(height: 10),
              Text(
                l10n.adminControlTopCouriersRating,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              if (s.topCourierRatings.isEmpty)
                Text('—', style: t.bodySmall)
              else
                ...s.topCourierRatings.take(5).map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${_shortId(e.userId)} · ${e.rating.toStringAsFixed(1)}',
                          style: t.bodySmall,
                        ),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AdminSectionTitle(title: l10n.adminControlGeoTitle),
        const SizedBox(height: 8),
        AdminSurfaceCard(
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.adminControlUsersByRegion,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ..._topPairs(s.usersByRegion, t),
              const SizedBox(height: 12),
              Text(
                l10n.adminControlJobsByRegion,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ..._topPairs(s.jobsByRegion, t),
              const SizedBox(height: 12),
              Text(
                l10n.adminControlDistrictsHint,
                style: t.bodySmall?.copyWith(color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              ..._topPairs(s.usersByDistrict, t, max: 6),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AdminSectionTitle(title: l10n.adminControlAuctionTitle),
        const SizedBox(height: 8),
        AdminSurfaceCard(
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv(t, l10n.adminControlAuctionsTouched,
                  '${s.auctionsTouchedCount}'),
              _kv(t, l10n.adminControlAvgBids,
                  s.avgAuctionBidCount.toStringAsFixed(1)),
              _kv(
                t,
                l10n.adminControlAvgDiscount,
                (s.avgFinalDiscountCents / 100).toStringAsFixed(2),
              ),
              _kv(t, l10n.adminControlCompletedDeliveries,
                  '${s.jobsCompleted}'),
              _kv(t, l10n.adminControlActiveTracking,
                  '${s.activeDeliveryTrackingCount}'),
            ],
          ),
        ),
      ],
    );
  }

  static String _shortId(String id) {
    final c = id.replaceAll('-', '');
    if (c.length >= 8) return c.substring(0, 8).toUpperCase();
    return id.length > 8 ? id.substring(0, 8) : id;
  }

  static Widget _kv(TextTheme? t, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(k, style: t?.bodyMedium)),
          Text(v, style: t?.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  static List<Widget> _topPairs(
    List<({String code, int count})> rows,
    TextTheme? t, {
    int max = 8,
  }) {
    if (rows.isEmpty) {
      return [Text('—', style: t?.bodySmall)];
    }
    return rows
        .take(max)
        .map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    e.code.isEmpty ? '—' : e.code,
                    style: t?.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${e.count}',
                  style: t?.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  static Widget _metricGrid(
    BuildContext context,
    List<_MetricSpec> items,
  ) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = c.maxWidth >= 520 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: n,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 92,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) => _AdminMetricTile(spec: items[i]),
        );
      },
    );
  }
}

class _MetricSpec {
  const _MetricSpec(this.label, this.value, this.icon, this.accent);

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
}

class _AdminMetricTile extends StatelessWidget {
  const _AdminMetricTile({required this.spec});

  final _MetricSpec spec;

  @override
  Widget build(BuildContext context) {
    final accent = spec.accent;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color.lerp(Colors.white, accent, 0.07)!,
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: 0.22),
                    accent.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Icon(spec.icon, color: accent, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    spec.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spec.value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          color: const Color(0xFF0F172A),
                          height: 1.05,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

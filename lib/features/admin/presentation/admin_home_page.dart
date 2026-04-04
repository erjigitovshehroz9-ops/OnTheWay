import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_panel_light_theme.dart';
import 'widgets/admin_panel_bottom_bar.dart';
import 'widgets/admin_panel_dashboard_tab.dart';
import 'widgets/admin_panel_feedback_tab.dart';
import 'widgets/admin_panel_header.dart';
import 'widgets/admin_panel_orders_tab.dart';
import 'widgets/admin_panel_regions_tab.dart';
import 'widgets/admin_users_manage_content.dart';

/// Admin panel — pastki navigatsiya: Dashboard, Orders, Users, Feedback, Regions.
class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key, this.initialTabQuery});

  /// Masalan: `feedback` — push deep link.
  final String? initialTabQuery;

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = _tabFromQuery(widget.initialTabQuery);
  }

  @override
  void didUpdateWidget(covariant AdminHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabQuery != widget.initialTabQuery) {
      final n = _tabFromQuery(widget.initialTabQuery);
      if (n != _tab) setState(() => _tab = n);
    }
  }

  int _tabFromQuery(String? q) {
    final t = q?.trim().toLowerCase() ?? '';
    if (t == 'orders' || t == '1') return 1;
    if (t == 'users' || t == '2') return 2;
    if (t == 'feedback' || t == '3') return 3;
    if (t == 'regions' || t == '4') return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildAdminPanelLightTheme(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFDBEAFE),
                Color(0xFFE0F2F1),
                Color(0xFFF1F5F9),
                Color(0xFFF8FAFC),
              ],
              stops: [0.0, 0.35, 0.72, 1.0],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminPanelHeader(
                  onSearchTap: () => setState(() => _tab = 1),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _tab,
                    children: [
                      AdminPanelDashboardTab(
                        onSwitchTab: (i) => setState(() => _tab = i),
                      ),
                      const AdminPanelOrdersTab(),
                      const AdminUsersManageContent(),
                      const AdminPanelFeedbackTab(),
                      const AdminPanelRegionsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: AdminPanelBottomBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
        ),
      ),
    );
  }
}

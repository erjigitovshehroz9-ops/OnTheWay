import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/courier_district_filter.dart';
import '../../../core/courier/courier_feed_selection.dart';
import '../../../core/courier/courier_gps_feed_resolver.dart';
import '../../../core/debug/provider_error_screen.dart';
import '../../../core/geo/work_area_keys.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/utils/route_distance_format.dart';
import '../../../data/regions_seed.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/app_user.dart';
import '../../../models/job_entity.dart';
import '../../../models/job_status.dart';
import '../../../models/job_transport_type.dart';
import '../../../models/region_record.dart';
import '../../../models/user_role.dart';
import '../../../shared/flow/courier_role_switch_flow.dart';
import '../../../shared/widgets/premium_monogram_avatar.dart';
import '../../../shared/widgets/role_switch_confirm_dialog.dart';
import '../../../shared/widgets/courier_transport_setup_sheet.dart';
import '../../../shared/widgets/job_image.dart';
import '../../sender/application/sender_in_app_notifications_provider.dart';
import '../../sender/application/sender_jobs_provider.dart';
import '../../sender/presentation/widgets/sender_home_settings_menu.dart';
import '../../sender/presentation/widgets/sender_notifications_sheet.dart'
    show PulsingNotificationDot, showSenderNotificationsSheet;
import '../../sender/presentation/widgets/sender_profile_tab_content.dart';
import 'widgets/courier_bottom_nav.dart';
import 'widgets/courier_jobs_map.dart';
import 'widgets/courier_orders_status_tabs.dart';

enum _CourierOrdersTab { auction, inProgress, completed }

List<JobEntity> _jobsForCourierOrdersTab(
  List<JobEntity> jobs,
  String courierId,
  _CourierOrdersTab tab,
) {
  switch (tab) {
    case _CourierOrdersTab.auction:
      return jobs
          .where(
            (j) =>
                j.status == JobStatus.posted ||
                j.status == JobStatus.auctionLive,
          )
          .toList();
    case _CourierOrdersTab.inProgress:
      return jobs
          .where(
            (j) =>
                j.winnerCourierId == courierId &&
                (j.status == JobStatus.assigned ||
                    j.status == JobStatus.pickedUp ||
                    j.status == JobStatus.delivered),
          )
          .toList();
    case _CourierOrdersTab.completed:
      return jobs
          .where(
            (j) =>
                j.winnerCourierId == courierId &&
                j.status == JobStatus.completed,
          )
          .toList();
  }
}

List<int> _courierOrdersTabCounts(List<JobEntity> jobs, String courierId) => [
      _jobsForCourierOrdersTab(jobs, courierId, _CourierOrdersTab.auction)
          .length,
      _jobsForCourierOrdersTab(jobs, courierId, _CourierOrdersTab.inProgress)
          .length,
      _jobsForCourierOrdersTab(jobs, courierId, _CourierOrdersTab.completed)
          .length,
    ];

String _fmtCourierListPrice(int cents, Locale locale) {
  final v = (cents / 100).round();
  final fmt = NumberFormat('#,###', locale.toString());
  return '${fmt.format(v)} UZS';
}

String _courierFilterRegionLabelUz(String? code) {
  if (code == null || code.isEmpty) return '(empty)';
  try {
    return RegionsSeed.regions.firstWhere((e) => e.code == code).name.uz;
  } catch (_) {
    return code;
  }
}

String _courierFilterDistrictLabelUz(String? code) {
  if (code == null || code.isEmpty) return '(empty)';
  if (code == CourierDistrictFilter.allDistrictsValue) {
    return 'Barcha tumanlar';
  }
  try {
    return RegionsSeed.districts.firstWhere((e) => e.code == code).name.uz;
  } catch (_) {
    return code;
  }
}

void _logCourierFilterSelectionDebug({
  required String source,
  required AppUser user,
  required String? selR,
  required String? selD,
}) {
  if (!kDebugMode) return;
  final feed = resolveCourierFeedSelection(
    user: user,
    selRegionCode: selR,
    selDistrictCode: selD,
  );
  final eff = WorkAreaKeys.effectiveCourierKeys(
    workingRegionKey: user.workingRegionKey,
    workingDistrictKey: user.workingDistrictKey,
    regionCode: feed.regionCode,
    districtCode: feed.districtCode,
  );
  debugPrint(
    '[$source] UI selected region label = ${_courierFilterRegionLabelUz(selR)}',
  );
  debugPrint(
    '[$source] UI selected district label = ${_courierFilterDistrictLabelUz(selD)}',
  );
  debugPrint('[$source] effective selected region key = ${eff.regionKey}');
  debugPrint('[$source] effective selected district key = ${eff.districtKey}');
  debugPrint('[$source] wholeRegion = ${feed.wholeRegion}');
  debugPrint(
    '[$source] feed region_code=${feed.regionCode} district_code=${feed.districtCode}',
  );
}

/// Kuryer fonlari — monoxromatik ko‘k–indigo + cyan analog aksent (rang uyg‘unligi).
abstract final class _CourierUi {
  static const deepBlue = Color(0xFF0B1220);
  static const softBlue = Color(0xFF3B82F6);
  static const bgGradientTop = Color(0xFF0F172A);
  static const bgGradientMid = Color(0xFF1E3A8A);
  static const bgGradientBlend = Color(0xFF2563EB);
  /// Pastki qism bottom nav bilan uyg‘un, ortiqcha yorqin ko‘k massasiz.
  static const bgGradientBottom = Color(0xFF111827);
  static const blobCore = Color(0xFF312E81);
  static const mint = Color(0xFF22D3EE);
  static const glassFill = Color(0x38FFFFFF);
  static const glassBorder = Color(0x5EFFFFFF);
  static const cardGradientTop = Color(0xFFFFFFFF);
  static const cardGradientBottom = Color(0xFFEFF6FF);
  static const pillSelectedFg = Color(0xFF0C4A6E);
  static const glassInputFg = Color(0xFF1E293B);
  static const glassInputMuted = Color(0xFF64748B);
  /// Shisha dropdown: ikonka va kichik matn (fon qorong‘i — yuqori kontrast).
  static const glassDropdownIcon = Color(0xFF7DD3FC);
  static const glassDropdownLabel = Color(0xE6FFFFFF);
}

const Distance _kCourierDistance = Distance();

/// Asosiy gradient + o‘ngda indigo “blob” (chuqurlik).
class _CourierOrdersBackground extends StatelessWidget {
  const _CourierOrdersBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _CourierUi.bgGradientTop,
                _CourierUi.bgGradientMid,
                _CourierUi.bgGradientBlend,
                _CourierUi.bgGradientBottom,
              ],
              stops: [0.0, 0.28, 0.52, 1.0],
            ),
          ),
        ),
        Positioned(
          right: -110,
          top: 48,
          child: IgnorePointer(
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _CourierUi.blobCore.withValues(alpha: 0.48),
                    _CourierUi.blobCore.withValues(alpha: 0.2),
                    const Color(0x00000000),
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
          ),
        ),
        // Stack ichidagi Column cheksiz balandlik olmasin — Expanded ishlashi shart.
        Positioned.fill(child: child),
      ],
    );
  }
}

class CourierHomePage extends ConsumerStatefulWidget {
  const CourierHomePage({super.key});

  @override
  ConsumerState<CourierHomePage> createState() => _CourierHomePageState();
}

class _CourierHomePageState extends ConsumerState<CourierHomePage> {
  int _view = 0;
  CourierBottomNavTab _bottomSelected = CourierBottomNavTab.orders;
  final _listScroll = ScrollController();
  bool _roleSwitchBusy = false;
  _CourierOrdersTab _courierOrdersTab = _CourierOrdersTab.auction;
  Timer? _courierJobsPollTimer;
  String? _polledCourierUserId;
  List<JobEntity>? _lastCourierJobsForEvents;

  int get _courierOrdersTabIndex => switch (_courierOrdersTab) {
        _CourierOrdersTab.auction => 0,
        _CourierOrdersTab.inProgress => 1,
        _CourierOrdersTab.completed => 2,
      };

  void _setCourierOrdersTabIndex(int i) {
    setState(() {
      final next = switch (i) {
        0 => _CourierOrdersTab.auction,
        1 => _CourierOrdersTab.inProgress,
        _ => _CourierOrdersTab.completed,
      };
      if (_courierOrdersTab == _CourierOrdersTab.auction &&
          next != _CourierOrdersTab.auction) {
        _view = 0;
      }
      _courierOrdersTab = next;
    });
  }

  void _emitCourierJobTransitions(
    String courierId,
    List<JobEntity> prior,
    List<JobEntity> latest,
  ) {
    final oldById = {for (final j in prior) j.id: j};
    for (final j in latest) {
      final old = oldById[j.id];
      if (old == null) continue;
      if (old.status == j.status && old.winnerCourierId == j.winnerCourierId) {
        continue;
      }
      final wasOpen = old.status == JobStatus.posted ||
          old.status == JobStatus.auctionLive;
      if (wasOpen &&
          j.status == JobStatus.assigned &&
          j.winnerCourierId == courierId) {
        setState(() => _courierOrdersTab = _CourierOrdersTab.inProgress);
      }
      if (old.winnerCourierId == courierId &&
          old.status != JobStatus.completed &&
          j.status == JobStatus.completed) {
        setState(() => _courierOrdersTab = _CourierOrdersTab.completed);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapCourierFeedFromGps());
    });
  }

  /// Joylashuv + geocoder → filtr viloyat/tuman; xato bo‘lsa profil; keyin foydalanuvchi o‘zi o‘zgartiradi.
  Future<void> _bootstrapCourierFeedFromGps() async {
    final u = ref.read(authSessionProvider).valueOrNull;
    if (u == null || !mounted) return;
    final nom = ref.read(nominatimServiceProvider);
    final r = await resolveCourierFeedFromGps(
      nominatim: nom,
      fallbackRegionCode: u.regionCode,
      fallbackDistrictCode: u.districtCode,
    );
    if (!mounted) return;
    ref.read(courierRegionCodeProvider.notifier).state = r.regionCode;
    if (r.districtCode != null && r.districtCode!.isNotEmpty) {
      ref.read(courierDistrictCodeProvider.notifier).state = r.districtCode;
    } else {
      ref.read(courierDistrictCodeProvider.notifier).state =
          CourierDistrictFilter.allDistrictsValue;
    }
    ref.invalidate(courierJobsProvider);
    if (kDebugMode) {
      debugPrint(
        '[courierPanel] bootstrap region=${r.regionCode} district=${r.districtCode}',
      );
    }
  }

  @override
  void dispose() {
    _courierJobsPollTimer?.cancel();
    _listScroll.dispose();
    super.dispose();
  }

  void _syncBottomWithView(int v) {
    setState(() => _view = v);
  }

  /// Jarayondagi buyurtma: batafsil sahifa (ustida tafsilotlar, pastda kichik xarita).
  void _onCourierOrderCardOpen(JobEntity job) {
    context.push(AppRoutes.jobDetail(job.id));
  }

  CourierBottomNavTab get _effectiveBottomTab =>
      _bottomSelected == CourierBottomNavTab.roleSwitch
          ? CourierBottomNavTab.orders
          : _bottomSelected;

  Future<void> _onRoleSwitchPressed() async {
    if (_roleSwitchBusy) return;
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authSessionProvider).valueOrNull;
    if (user == null || !mounted) return;

    final currentRole = user.role ?? UserRole.courier;
    if (currentRole == UserRole.admin) {
      if (mounted) context.push(AppRoutes.settings);
      return;
    }

    final nextRole =
        currentRole == UserRole.sender ? UserRole.courier : UserRole.sender;

    final router = GoRouter.of(context);
    final ok = await showRoleSwitchConfirmDialog(
      context: context,
      title: 'Rolni almashtirmoqchimisiz?',
      contentLine:
          '${currentRole == UserRole.sender ? l10n.roleSender : l10n.roleCourier}'
          ' → '
          '${nextRole == UserRole.sender ? l10n.roleSender : l10n.roleCourier}',
    );
    if (ok != true || !context.mounted) return;

    setState(() => _roleSwitchBusy = true);
    try {
      if (nextRole == UserRole.courier) {
        final switched = await ensureCourierTransportAndSwitchRole(
          ref: ref,
          userId: user.id,
          callerIsSystemAdmin: user.isSystemAdmin,
        );
        if (!context.mounted) return;
        if (!switched) return;
        router.go(AppRoutes.courier);
      } else {
        final users = await ref.read(userRepositoryProvider.future);
        await users.switchAppRole(
          userId: user.id,
          newRole: nextRole,
          callerIsSystemAdmin: user.isSystemAdmin,
        );
        await ref.read(authSessionProvider.notifier).refresh();
        ref.invalidate(courierJobsProvider);
        ref.invalidate(senderJobsProvider(user.id));
        if (!context.mounted) return;
        router.go(AppRoutes.sender);
      }
    } finally {
      if (mounted) setState(() => _roleSwitchBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale =
        ref.watch(localeControllerProvider).valueOrNull ?? const Locale('uz');
    final user = ref.watch(authSessionProvider).valueOrNull;

    if (user == null) {
      return Scaffold(
        backgroundColor: _CourierUi.deepBlue,
        body: Center(
          child: Text(l10n.signInRequired, style: const TextStyle(color: Colors.white70)),
        ),
      );
    }

    ref.listen(authSessionProvider, (prev, next) {
      if (next.valueOrNull == null) {
        _courierJobsPollTimer?.cancel();
        _courierJobsPollTimer = null;
        _polledCourierUserId = null;
        _lastCourierJobsForEvents = null;
      }
    });

    if (_polledCourierUserId != user.id) {
      _polledCourierUserId = user.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _courierJobsPollTimer?.cancel();
        _courierJobsPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
          if (!mounted) return;
          final uid = ref.read(authSessionProvider).valueOrNull?.id;
          if (uid != null) ref.invalidate(courierJobsProvider);
        });
      });
    }

    ref.listen<AsyncValue<List<JobEntity>>>(
      courierJobsProvider,
      (prev, next) {
        if (!next.hasValue) return;
        final list = next.requireValue;
        if (!mounted) return;
        final prior = _lastCourierJobsForEvents;
        if (prior != null) {
          _emitCourierJobTransitions(user.id, prior, list);
        }
        _lastCourierJobsForEvents = [...list];
      },
    );

    final jobsAsync = ref.watch(courierJobsProvider);
    final regionsAsync = ref.watch(regionsListProvider);
    final selR = ref.watch(courierRegionCodeProvider);
    final selD = ref.watch(courierDistrictCodeProvider);
    final regionsList = regionsAsync.valueOrNull;
    final feedSel = resolveCourierFeedSelection(
      user: user,
      selRegionCode: selR,
      selDistrictCode: selD,
    );
    final resolvedRegion = feedSel.regionCode ??
        user.regionCode ??
        (regionsList != null && regionsList.isNotEmpty
            ? regionsList.first.code
            : 'TK');
    final resolvedDistrict = feedSel.districtCode;
    final jobsSnapshot = jobsAsync.valueOrNull ?? [];
    final courierOrdersCounts = _courierOrdersTabCounts(jobsSnapshot, user.id);

    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: _CourierUi.mint,
        onPrimary: Color(0xFF0F172A),
        surface: _CourierUi.deepBlue,
        onSurface: Colors.white,
        onSurfaceVariant: Color(0xFFCBD5E1),
      ),
      dividerColor: Colors.white24,
      iconTheme: const IconThemeData(color: Colors.white),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        extendBody: false,
        // Bottom nav bilan bir xil fon — oq bo‘shliq va keskin o‘tish yo‘q.
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _effectiveBottomTab == CourierBottomNavTab.orders
                    ? _CourierOrdersBackground(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CourierTopBar(
                              l10n: l10n,
                              user: user,
                              onLogout: () async {
                                final repo = await ref.read(authRepositoryProvider.future);
                                await repo.logout();
                                await ref.read(authSessionProvider.notifier).refresh();
                              },
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 8),
                                    regionsAsync.when(
                                      loading: () => SizedBox(
                                        height: 88,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(18),
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(18),
                                              border: Border.all(color: Colors.white24),
                                            ),
                                            child: const Center(
                                              child: SizedBox(
                                                width: 28,
                                                height: 28,
                                                child: CircularProgressIndicator(
                                                  color: _CourierUi.mint,
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      error: (e, st) => SizedBox(
                                        height: 72,
                                        child: Center(
                                          child: Text(
                                            '$e',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white70),
                                          ),
                                        ),
                                      ),
                                      data: (regions) => _CourierRegionDistrictFilterSection(
                                        l10n: l10n,
                                        locale: locale,
                                        user: user,
                                        regions: regions,
                                        selR: selR,
                                        selD: selD,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    CourierOrdersStatusTabs(
                                      l10n: l10n,
                                      selectedIndex: _courierOrdersTabIndex,
                                      counts: courierOrdersCounts,
                                      onSelect: _setCourierOrdersTabIndex,
                                    ),
                                    if (_courierOrdersTab ==
                                        _CourierOrdersTab.auction) ...[
                                      const SizedBox(height: 10),
                                      _CourierListMapToggle(
                                        l10n: l10n,
                                        listLabel: l10n.courierOrdersSubtabList,
                                        view: _view,
                                        onChanged: _syncBottomWithView,
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Expanded(
                                      child: jobsAsync.when(
                                  data: (jobs) {
                                    final tabJobs = _jobsForCourierOrdersTab(
                                      jobs,
                                      user.id,
                                      _courierOrdersTab,
                                    );
                                    final authRepo =
                                        ref.watch(authRepositoryProvider).valueOrNull;
                                    final courierTransportKeys = user.role ==
                                            UserRole.courier
                                        ? (authRepo != null
                                            ? authRepo.resolvedCourierTransportKeys(
                                                user,
                                              )
                                            : JobTransportType.normalizeCourierKeyList(
                                                user.courierTransportTypes,
                                              ))
                                        : const <String>[];
                                    final showTransportEmpty = user.role ==
                                            UserRole.courier &&
                                        courierTransportKeys.isEmpty &&
                                        _courierOrdersTab ==
                                            _CourierOrdersTab.auction &&
                                        tabJobs.isEmpty;

                                    if (_courierOrdersTab !=
                                        _CourierOrdersTab.auction) {
                                      if (tabJobs.isEmpty) {
                                        return Center(
                                          key: ValueKey<String>(
                                            'only_empty_${_courierOrdersTab.name}',
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                            ),
                                            child: Text(
                                              _courierOrdersTab ==
                                                      _CourierOrdersTab.inProgress
                                                  ? l10n.courierOrdersEmptyInProgress
                                                  : l10n.courierOrdersEmptyCompleted,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.82,
                                                ),
                                                fontSize: 15,
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return ListView.separated(
                                        key: ValueKey<String>(
                                          'only_list_${_courierOrdersTab.name}',
                                        ),
                                        controller: _listScroll,
                                        padding: EdgeInsets.only(
                                          bottom: 16 +
                                              MediaQuery.paddingOf(context)
                                                  .bottom,
                                        ),
                                        itemCount: tabJobs.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, i) {
                                          return _CourierOrderCard(
                                            job: tabJobs[i],
                                            locale: locale,
                                            l10n: l10n,
                                            user: user,
                                            onOpen: () =>
                                                _onCourierOrderCardOpen(tabJobs[i]),
                                          );
                                        },
                                      );
                                    }

                                    return AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 260),
                                      switchInCurve: Curves.easeOut,
                                      switchOutCurve: Curves.easeIn,
                                      layoutBuilder:
                                          (Widget? currentChild, List<Widget> previousChildren) {
                                        return Stack(
                                          fit: StackFit.expand,
                                          clipBehavior: Clip.hardEdge,
                                          children: <Widget>[
                                            for (final w in previousChildren)
                                              Positioned.fill(child: w),
                                            if (currentChild != null)
                                              Positioned.fill(child: currentChild),
                                          ],
                                        );
                                      },
                                      child: _view == 1
                                          ? CourierJobsMap(
                                              key: ValueKey<String>(
                                                'map_${_courierOrdersTab.name}_$_view',
                                              ),
                                              jobs: tabJobs,
                                              locale: locale,
                                              l10n: l10n,
                                              regionCode: resolvedRegion,
                                              districtCode: resolvedDistrict,
                                            )
                                          : tabJobs.isEmpty
                                              ? Center(
                                                  key: ValueKey<String>(
                                                    'empty_${_courierOrdersTab.name}_$_view',
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                    ),
                                                    child: showTransportEmpty
                                                        ? Column(
                                                            mainAxisSize:
                                                                MainAxisSize.min,
                                                            children: [
                                                              Text(
                                                                l10n
                                                                    .courierTransportEmptyTitle,
                                                                textAlign:
                                                                    TextAlign.center,
                                                                style:
                                                                    const TextStyle(
                                                                      color: Colors.white,
                                                                      fontWeight:
                                                                          FontWeight.w800,
                                                                      fontSize: 17,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                height: 10,
                                                              ),
                                                              Text(
                                                                l10n
                                                                    .courierTransportEmptySubtitle,
                                                                textAlign:
                                                                    TextAlign.center,
                                                                style: TextStyle(
                                                                  color: Colors.white
                                                                      .withValues(
                                                                        alpha: 0.82,
                                                                      ),
                                                                  fontSize: 14,
                                                                  height: 1.35,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 20,
                                                              ),
                                                              FilledButton(
                                                                onPressed:
                                                                    () async {
                                                                  final saved =
                                                                      await showCourierTransportSetupBottomSheet(
                                                                    context:
                                                                        context,
                                                                    userId:
                                                                        user.id,
                                                                  );
                                                                  if (saved ==
                                                                          true &&
                                                                      context
                                                                          .mounted) {
                                                                    ref.invalidate(
                                                                      courierJobsProvider,
                                                                    );
                                                                  }
                                                                },
                                                                style: FilledButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                      _CourierUi
                                                                          .mint,
                                                                  foregroundColor:
                                                                      _CourierUi
                                                                          .deepBlue,
                                                                ),
                                                                child: Text(
                                                                  l10n
                                                                      .courierTransportChooseAction,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w800,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          )
                                                        : Text(
                                                            l10n.noOpenAuctions,
                                                            textAlign:
                                                                TextAlign.center,
                                                            style: TextStyle(
                                                              color: Colors.white
                                                                  .withValues(
                                                                    alpha: 0.82,
                                                                  ),
                                                              fontSize: 15,
                                                            ),
                                                          ),
                                                  ),
                                                )
                                              : ListView.separated(
                                                  key: ValueKey<String>(
                                                    'list_${_courierOrdersTab.name}_$_view',
                                                  ),
                                                  controller: _listScroll,
                                                  padding: EdgeInsets.only(
                                                    bottom: 16 +
                                                        MediaQuery.paddingOf(context)
                                                            .bottom,
                                                  ),
                                                  itemCount: tabJobs.length,
                                                  separatorBuilder: (_, __) =>
                                                      const SizedBox(height: 12),
                                                  itemBuilder: (context, i) {
                                                    return _CourierOrderCard(
                                                      job: tabJobs[i],
                                                      locale: locale,
                                                      l10n: l10n,
                                                      user: user,
                                                      onOpen: () =>
                                                          _onCourierOrderCardOpen(
                                                              tabJobs[i]),
                                                    );
                                                  },
                                                ),
                                    );
                                  },
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(color: _CourierUi.mint),
                                  ),
                                  error: (error, stack) => ProviderErrorScreen(
                                    error: error,
                                    stackTrace: stack,
                                    onRetry: () {
                                      ref.invalidate(courierJobsProvider);
                                      ref.invalidate(jobRepositoryProvider);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    : ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CourierTopBar(
                              l10n: l10n,
                              user: user,
                              onLightSurface: true,
                              onLogout: () async {
                                final repo = await ref.read(authRepositoryProvider.future);
                                await repo.logout();
                                await ref.read(authSessionProvider.notifier).refresh();
                              },
                            ),
                            Expanded(
                              child: _effectiveBottomTab == CourierBottomNavTab.wallet
                                  ? _CourierWalletTabBody(l10n: l10n)
                                  : Theme(
                                      data: AppTheme.light(),
                                      child: SenderProfileTabContent(user: user),
                                    ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CourierBottomNav(
          selected: _bottomSelected,
          onSelected: (t) => setState(() {
            _bottomSelected = t;
            if (t == CourierBottomNavTab.orders && _listScroll.hasClients) {
              _listScroll.animateTo(
                0,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
              );
            }
          }),
          onRoleSwitch: _onRoleSwitchPressed,
        ),
      ),
    );
  }
}

class _CourierTopBar extends ConsumerWidget {
  const _CourierTopBar({
    required this.l10n,
    required this.user,
    required this.onLogout,
    this.onLightSurface = false,
  });

  final AppLocalizations l10n;
  final AppUser user;
  final Future<void> Function() onLogout;
  final bool onLightSurface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fg = onLightSurface ? context.tokens.textPrimary : context.tokens.textOnDark;
    final currentLocale =
        ref.watch(localeControllerProvider).valueOrNull ?? const Locale('uz');
    final menuTheme = Theme.of(context);
    final notifAsync = ref.watch(senderInAppNotificationsProvider(user.id));
    final unreadCount =
        notifAsync.valueOrNull?.where((n) => !n.read).length ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 12, 12),
      child: IconTheme.merge(
        data: IconThemeData(color: fg.withValues(alpha: onLightSurface ? 0.88 : 1)),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () =>
                      showSenderNotificationsSheet(context, ref, user.id),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: fg.withValues(alpha: onLightSurface ? 0.88 : 1),
                        size: 26,
                      ),
                      if (unreadCount > 0)
                        const Positioned(
                          right: 4,
                          top: 4,
                          child: PulsingNotificationDot(size: 10),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                l10n.courierPanelBannerTitle,
                textAlign: TextAlign.center,
                style: AppTheme.panelTopBarTitle(fg),
              ),
            ),
            MenuAnchor(
              menuChildren: buildHomeOverflowMenuChildren(
                context: context,
                ref: ref,
                theme: menuTheme,
                l10n: l10n,
                currentLocale: currentLocale,
                onLogout: onLogout,
                includeAppSettingsRoute: true,
                userPhoneForSettingsGate: user.phone,
              ),
              builder: (context, menuController, _) {
                return Tooltip(
                  message: l10n.createJobMenuMore,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        if (menuController.isOpen) {
                          menuController.close();
                        } else {
                          menuController.open();
                        }
                      },
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: PremiumMonogramAvatar(
                            initial: _courierMenuInitial(user),
                            profileImagePath: ref
                                .watch(profileImagePathProvider(user.id))
                                .valueOrNull,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _courierMenuInitial(AppUser user) {
  final d = user.displayName.trim();
  if (d.isEmpty) return '?';
  return String.fromCharCode(d.runes.first).toUpperCase();
}

/// [ref.watch] for districts runs only here at the top of [build], not inside
/// [regionsAsync.when] callbacks.
class _CourierRegionDistrictFilterSection extends ConsumerWidget {
  const _CourierRegionDistrictFilterSection({
    required this.l10n,
    required this.locale,
    required this.user,
    required this.regions,
    required this.selR,
    required this.selD,
  });

  final AppLocalizations l10n;
  final Locale locale;
  final AppUser user;
  final List<RegionRecord> regions;
  final String? selR;
  final String? selD;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rGuess = selR ??
        user.regionCode ??
        (regions.isNotEmpty ? regions.first.code : '');
    final rOk = rGuess.isNotEmpty && regions.any((r) => r.code == rGuess);
    final rCode =
        rOk ? rGuess : (regions.isNotEmpty ? regions.first.code : '');
    final distAsync = rCode.isEmpty
        ? const AsyncValue<List<DistrictRecord>>.data(<DistrictRecord>[])
        : ref.watch(districtsForRegionProvider(rCode));
    return _CourierFilterGlassCard(
      l10n: l10n,
      locale: locale,
      regions: regions,
      regionCode: rCode,
      districtsAsync: distAsync,
      user: user,
      selectedDistrict: selD,
      onRegionChanged: (v) {
        ref.read(courierRegionCodeProvider.notifier).state = v;
        ref.read(courierDistrictCodeProvider.notifier).state =
            CourierDistrictFilter.allDistrictsValue;
        _logCourierFilterSelectionDebug(
          source: 'CourierPanel.onRegionChanged',
          user: user,
          selR: v,
          selD: CourierDistrictFilter.allDistrictsValue,
        );
        ref.invalidate(courierJobsProvider);
      },
      onDistrictChanged: (v) {
        ref.read(courierDistrictCodeProvider.notifier).state = v;
        final rNow = ref.read(courierRegionCodeProvider);
        _logCourierFilterSelectionDebug(
          source: 'CourierPanel.onDistrictChanged',
          user: user,
          selR: rNow,
          selD: v,
        );
        ref.invalidate(courierJobsProvider);
      },
    );
  }
}

class _CourierFilterGlassCard extends StatelessWidget {
  const _CourierFilterGlassCard({
    required this.l10n,
    required this.locale,
    required this.regions,
    required this.regionCode,
    required this.districtsAsync,
    required this.user,
    required this.selectedDistrict,
    required this.onRegionChanged,
    required this.onDistrictChanged,
  });

  final AppLocalizations l10n;
  final Locale locale;
  final List<RegionRecord> regions;
  final String regionCode;
  final AsyncValue<List<DistrictRecord>> districtsAsync;
  final AppUser user;
  final String? selectedDistrict;
  final ValueChanged<String?> onRegionChanged;
  final ValueChanged<String?> onDistrictChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: _CourierUi.glassFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _CourierUi.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Builder(
            builder: (context) {
              final regionOk = regionCode.isNotEmpty &&
                  regions.any((r) => r.code == regionCode);
              final regionValue = regionOk ? regionCode : null;
              final regionDropdown = _GlassDropdown<String>(
                label: l10n.regionLabel,
                icon: Icons.public_rounded,
                value: regionValue,
                items: regions
                    .map(
                      (r) => DropdownMenuItem<String>(
                        value: r.code,
                        child: Text(
                          r.name.resolveLang(locale.languageCode),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onRegionChanged,
              );
              final districtSection = districtsAsync.when(
                loading: () => const SizedBox(
                  height: 50,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _CourierUi.mint,
                      ),
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox(
                  height: 50,
                  child: Center(
                    child: Text(
                      'Tumanlar yuklanmadi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                ),
                data: (districts) {
                  final all = CourierDistrictFilter.allDistrictsValue;
                  if (districts.isEmpty) {
                    return _GlassDropdown<String>(
                      key: ValueKey<String>('district_${regionCode}_empty'),
                      label: l10n.districtLabel,
                      icon: Icons.location_city_rounded,
                      value: all,
                      items: [
                        DropdownMenuItem<String>(
                          value: all,
                          child: Text(
                            l10n.courierFilterAllDistricts,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: onDistrictChanged,
                    );
                  }
                  final profileInList = user.districtCode != null &&
                      districts.any((d) => d.code == user.districtCode);
                  final String? value;
                  if (selectedDistrict == all) {
                    value = all;
                  } else if (selectedDistrict != null &&
                      selectedDistrict!.isNotEmpty) {
                    final inList =
                        districts.any((d) => d.code == selectedDistrict);
                    value = inList ? selectedDistrict : all;
                  } else if (profileInList) {
                    value = user.districtCode;
                  } else {
                    value = all;
                  }
                  final items = <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: all,
                      child: Text(
                        l10n.courierFilterAllDistricts,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...districts.map(
                      (d) => DropdownMenuItem<String>(
                        value: d.code,
                        child: Text(
                          d.name.resolveLang(locale.languageCode),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ];
                  return _GlassDropdown<String>(
                    key: ValueKey<String>('district_$regionCode'),
                    label: l10n.districtLabel,
                    icon: Icons.location_city_rounded,
                    value: value,
                    items: items,
                    onChanged: onDistrictChanged,
                  );
                },
              );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: regionDropdown),
                  const SizedBox(width: 8),
                  Expanded(child: districtSection),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlassDropdown<T> extends StatelessWidget {
  const _GlassDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  static String _labelFromMenuChild(Widget? child) {
    if (child is Text) {
      return child.data ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    const selectedStyle = TextStyle(
      color: _CourierUi.glassInputFg,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _CourierUi.glassDropdownLabel,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: _CourierUi.glassDropdownIcon,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 42,
          maxWidth: 42,
          minHeight: 40,
          maxHeight: 40,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.38)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.38)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _CourierUi.mint, width: 1.2),
        ),
        contentPadding: const EdgeInsetsDirectional.only(
          start: 4,
          end: 4,
          top: 2,
          bottom: 2,
        ),
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          dropdownColor: const Color(0xFFF0F9FF),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _CourierUi.glassDropdownIcon,
            size: 22,
          ),
          style: selectedStyle,
          selectedItemBuilder: (context) {
            return items.map((e) {
              final raw = _labelFromMenuChild(e.child);
              final label =
                  raw.isEmpty && e.value != null ? e.value.toString() : raw;
              return Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: selectedStyle,
                ),
              );
            }).toList();
          },
          hint: Text(
            '—',
            style: TextStyle(color: _CourierUi.glassInputMuted.withValues(alpha: 0.55)),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CourierListMapToggle extends StatelessWidget {
  const _CourierListMapToggle({
    required this.l10n,
    required this.view,
    required this.onChanged,
    this.listLabel,
  });

  final AppLocalizations l10n;
  final int view;
  final ValueChanged<int> onChanged;

  /// Bo'sh bo'lsa [AppLocalizations.tabList].
  final String? listLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PillSegment(
              label: listLabel ?? l10n.tabList,
              icon: Icons.view_list_rounded,
              selected: view == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _PillSegment(
              label: l10n.tabMap,
              icon: Icons.map_rounded,
              selected: view == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillSegment extends StatelessWidget {
  const _PillSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        splashColor: _CourierUi.mint.withValues(alpha: 0.2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected ? _CourierUi.mint : Colors.transparent,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _CourierUi.mint.withValues(alpha: 0.55),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: Offset.zero,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? _CourierUi.pillSelectedFg
                    : Colors.white.withValues(alpha: 0.82),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? _CourierUi.pillSelectedFg
                        : Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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

class _CourierOrderCard extends StatelessWidget {
  const _CourierOrderCard({
    required this.job,
    required this.locale,
    required this.l10n,
    required this.user,
    required this.onOpen,
  });

  final JobEntity job;
  final Locale locale;
  final AppLocalizations l10n;
  final AppUser user;
  final VoidCallback onOpen;

  String? _distanceKm() {
    final lat = user.courierLat;
    final lng = user.courierLng;
    if (lat == null || lng == null) return null;
    if (job.pickupLat == null || job.pickupLng == null) return null;
    final km = _kCourierDistance.as(
      LengthUnit.Kilometer,
      LatLng(lat, lng),
      LatLng(job.pickupLat!, job.pickupLng!),
    );
    return formatRouteDistanceKm(km);
  }

  ({Color bg, Color fg, String text}) _statusStyle() {
    switch (job.status) {
      case JobStatus.delivered:
      case JobStatus.completed:
        return (
          bg: const Color(0xFF065F46).withValues(alpha: 0.9),
          fg: _CourierUi.mint,
          text: l10n.courierDeliveredBadge,
        );
      case JobStatus.cancelled:
        return (
          bg: Colors.white24,
          fg: Colors.white70,
          text: l10n.statCancelled,
        );
      default:
        return (
          bg: const Color(0xFFB45309).withValues(alpha: 0.85),
          fg: const Color(0xFFFEF3C7),
          text: l10n.courierStatusWaiting,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle();
    final dist = _distanceKm();
    final listOfferCents = job.status == JobStatus.auctionLive &&
            job.currentPriceCents != null &&
            job.currentPriceCents! > 0
        ? math.max(job.currentPriceCents!, job.floorPriceCents)
        : job.startPriceCents;
    final listOfferLabel = job.status == JobStatus.auctionLive &&
            job.currentPriceCents != null &&
            job.currentPriceCents! > 0
        ? l10n.auctionCurrentOffer
        : l10n.auctionStartPriceLabel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        splashColor: _CourierUi.mint.withValues(alpha: 0.15),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _CourierUi.cardGradientTop,
                _CourierUi.cardGradientBottom,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _CourierUi.mint.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: JobImageThumbnail(
                    imageRef: job.imagePath,
                    size: 64,
                    borderRadius: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              job.title.resolveLang(locale.languageCode),
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status.bg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status.text,
                              style: TextStyle(
                                color: status.fg,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$listOfferLabel: ${_fmtCourierListPrice(listOfferCents, locale)}',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (job.transportType.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              JobTransportType.iconForStoredSummary(job.transportType),
                              size: 15,
                              color: const Color(0xFF1D4ED8),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${l10n.orderRequiredTransportTitle}: ${JobTransportType.displayLabelsJoined(l10n, job.transportType)}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.blueGrey.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        job.pickupAddress.resolveLang(locale.languageCode),
                        style: TextStyle(
                          color: Colors.blueGrey.shade700,
                          fontSize: 12,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dist != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _CourierUi.deepBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: _CourierUi.deepBlue.withValues(alpha: 0.12)),
                            ),
                            child: Text(
                              dist,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourierWalletTabBody extends StatelessWidget {
  const _CourierWalletTabBody({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: t.borderSoft),
              boxShadow: [
                BoxShadow(
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  color: t.shadow,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: t.brandPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 40,
                    color: t.brandPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Hisobim',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.senderWalletSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


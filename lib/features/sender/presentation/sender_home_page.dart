import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/debug/provider_error_screen.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/app_user.dart';
import '../../../models/job_entity.dart';
import '../../../models/job_status.dart';
import '../../../models/sender_in_app_notification.dart';
import '../../../models/user_role.dart';
import '../../../repositories/job_repository.dart';
import '../../../shared/flow/courier_role_switch_flow.dart';
import '../../../shared/widgets/role_switch_confirm_dialog.dart';
import '../../../shared/utils/display_name_formatter.dart';
import '../../../shared/utils/job_status_l10n.dart';
import '../../../shared/widgets/app_primary_scaffold.dart';
import '../application/sender_in_app_notifications_provider.dart';
import '../application/sender_jobs_provider.dart';
import '../data/sender_job_status_snapshot_storage.dart';
import 'widgets/sender_bottom_nav.dart';
import 'widgets/sender_create_job_hero_card.dart';
import 'widgets/sender_home_header.dart';
import 'widgets/sender_order_card.dart';
import 'widgets/sender_profile_tab_content.dart';
import 'widgets/sender_status_tabs.dart';

class SenderHomePage extends ConsumerStatefulWidget {
  const SenderHomePage({super.key});

  @override
  ConsumerState<SenderHomePage> createState() => _SenderHomePageState();
}

enum _SenderTab {
  active,
  inProgress,
  done,
}

class _SenderHomePageState extends ConsumerState<SenderHomePage> {
  final _search = TextEditingController();

  _SenderTab _selectedTab = _SenderTab.active;

  SenderBottomNavTab _bottomSelected = SenderBottomNavTab.orders;

  bool _roleSwitchBusy = false;

  Timer? _senderJobsPollTimer;
  String? _polledUserId;

  /// [ref.listen] faqat qiymat o‘zgaganda chaqiladi; kuryerdan qaytishda kesh
  /// bilan birinchi yuklanish o‘tkazib yuborilmasin — [listenManual] + fireImmediately.
  String? _senderJobsNotifListenUserId;

  @override
  void dispose() {
    _senderJobsPollTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  String _norm(String s) {
    return s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  List<JobEntity> _jobsForTab(List<JobEntity> jobs, _SenderTab tab) {
    switch (tab) {
      case _SenderTab.active:
        return jobs.where((j) => j.status == JobStatus.posted).toList();
      case _SenderTab.inProgress:
        return jobs.where((j) {
          return j.status == JobStatus.auctionLive ||
              j.status == JobStatus.assigned ||
              j.status == JobStatus.pickedUp ||
              j.status == JobStatus.delivered;
        }).toList();
      case _SenderTab.done:
        return jobs.where((j) {
          return j.status == JobStatus.completed || j.status == JobStatus.cancelled;
        }).toList();
    }
  }

  int get _statusTabIndex => switch (_selectedTab) {
        _SenderTab.active => 0,
        _SenderTab.inProgress => 1,
        _SenderTab.done => 2,
      };

  void _setStatusTabIndex(int i) {
    setState(() {
      _selectedTab = switch (i) {
        0 => _SenderTab.active,
        1 => _SenderTab.inProgress,
        _ => _SenderTab.done,
      };
    });
  }

  String _fmtSenderNotifMoney(int cents, Locale locale) {
    final v = (cents / 100).round();
    final fmt = NumberFormat('#,###', locale.toString());
    return '${fmt.format(v)} UZS';
  }

  /// Chiqib ketgan paytda snapshot yangilanmagan bo‘lsa ham eski spam bo‘lmasin.
  static const Duration _kSenderNotifBackfillMaxAge = Duration(days: 21);

  bool _senderJobEligibleForOfflineBackfill(JobEntity j) {
    return DateTime.now().difference(j.createdAt) <= _kSenderNotifBackfillMaxAge;
  }

  void _emitSenderJobTransitions(
    WidgetRef ref,
    String userId,
    BuildContext context,
    Map<String, JobStatus> priorSnapshot,
    List<JobEntity> latest,
  ) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final oldMap = priorSnapshot;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final notifNotifier =
        ref.read(senderInAppNotificationsProvider(userId).notifier);
    const uuid = Uuid();

    Future<void> pushNotif(
      SenderNotificationKind kind,
      String jobId, {
      String? displayMessage,
    }) {
      return notifNotifier.append(
        SenderInAppNotification(
          id: uuid.v4(),
          kind: kind,
          jobId: jobId,
          createdAt: DateTime.now(),
          read: false,
          displayMessage: displayMessage,
        ),
      );
    }

    void pushAuctionStarted(JobEntity j, {required bool showSnack}) {
      final product = j.title.resolveLang(locale.languageCode);
      final msg = l10n.senderNotifAuctionStartedBody(product);
      unawaited(pushNotif(
        SenderNotificationKind.auctionStarted,
        j.id,
        displayMessage: msg,
      ));
      setState(() => _selectedTab = _SenderTab.inProgress);
      if (showSnack) {
        messenger?.showSnackBar(SnackBar(content: Text(msg)));
      }
    }

    Future<void> pushAuctionEndedAssigned(JobEntity j, {required bool showSnack}) async {
      final product = j.title.resolveLang(locale.languageCode);
      var courier = l10n.senderNotifUnknownCourier;
      if (j.winnerCourierId != null) {
        try {
          final repo = await ref.read(userRepositoryProvider.future);
          final u = await repo.getUser(j.winnerCourierId!);
          if (u != null && u.displayName.trim().isNotEmpty) {
            courier = u.displayName.trim();
          }
        } catch (_) {}
      }
      final cents = j.finalPriceCents ?? j.floorPriceCents;
      final amount = _fmtSenderNotifMoney(cents, locale);
      final msg = l10n.senderNotifAuctionEndedAssignedBody(
        product,
        courier,
        amount,
      );
      await pushNotif(
        SenderNotificationKind.auctionEndedAssigned,
        j.id,
        displayMessage: msg,
      );
      if (showSnack && context.mounted) {
        messenger?.showSnackBar(SnackBar(content: Text(msg)));
      }
    }

    bool isAfterAuctionAssigned(JobStatus s) {
      return s == JobStatus.assigned ||
          s == JobStatus.pickedUp ||
          s == JobStatus.delivered ||
          s == JobStatus.completed;
    }

    for (final j in latest) {
      final before = oldMap[j.id];
      if (before == j.status) continue;

      // Snapshotda yo‘q: buyurtma yaratilgach sinxron bo‘lmagan (chiqish) — yaqin vaqtdagi auksionlarni tiklash.
      if (before == null) {
        if (!_senderJobEligibleForOfflineBackfill(j)) continue;
        if (j.status == JobStatus.auctionLive) {
          pushAuctionStarted(j, showSnack: false);
        } else if (isAfterAuctionAssigned(j.status)) {
          pushAuctionStarted(j, showSnack: false);
          unawaited(pushAuctionEndedAssigned(j, showSnack: false));
        }
        continue;
      }

      if (before == JobStatus.posted && j.status == JobStatus.auctionLive) {
        pushAuctionStarted(j, showSnack: true);
      } else if (before == JobStatus.auctionLive &&
          j.status == JobStatus.assigned) {
        unawaited(pushAuctionEndedAssigned(j, showSnack: true));
      } else if (before == JobStatus.posted && isAfterAuctionAssigned(j.status)) {
        // Chiqib ketgan: posted → … → g‘olib (auctionLive snapshotda bo‘lmasa ham).
        pushAuctionStarted(j, showSnack: false);
        unawaited(pushAuctionEndedAssigned(j, showSnack: false));
      } else if (before == JobStatus.auctionLive &&
          (j.status == JobStatus.pickedUp ||
              j.status == JobStatus.delivered ||
              j.status == JobStatus.completed)) {
        unawaited(pushAuctionEndedAssigned(j, showSnack: false));
      } else if (before == JobStatus.auctionLive && j.status == JobStatus.posted) {
        final product = j.title.resolveLang(locale.languageCode);
        final msg = l10n.senderNotifAuctionReopenedBody(product);
        unawaited(pushNotif(
          SenderNotificationKind.auctionEndedReopened,
          j.id,
          displayMessage: msg,
        ));
        messenger?.showSnackBar(SnackBar(content: Text(msg)));
      } else if (before == JobStatus.auctionLive &&
          j.status == JobStatus.cancelled) {
        final product = j.title.resolveLang(locale.languageCode);
        final msg = l10n.senderNotifAuctionCancelledBody(product);
        unawaited(pushNotif(
          SenderNotificationKind.auctionEndedCancelled,
          j.id,
          displayMessage: msg,
        ));
        messenger?.showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _syncSenderJobNotifications(
    WidgetRef ref,
    String userId,
    BuildContext context,
    List<JobEntity> latest,
  ) async {
    final prior = await SenderJobStatusSnapshotStorage.load(userId);
    if (!context.mounted) return;
    _emitSenderJobTransitions(ref, userId, context, prior, latest);
    if (!context.mounted) return;
    await SenderJobStatusSnapshotStorage.save(userId, latest);
  }

  void _ensureSenderJobsNotificationListener(WidgetRef ref, AppUser user) {
    if (_senderJobsNotifListenUserId == user.id) return;
    _senderJobsNotifListenUserId = user.id;
    ref.listenManual<AsyncValue<List<JobEntity>>>(
      senderJobsProvider(user.id),
      (prev, next) {
        if (!next.hasValue) return;
        if (!mounted) return;
        unawaited(
          _syncSenderJobNotifications(
            ref,
            user.id,
            context,
            next.requireValue,
          ),
        );
      },
      fireImmediately: true,
    );
  }

  Future<void> _onRoleSwitchPressed() async {
    if (_roleSwitchBusy) return;
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authSessionProvider).valueOrNull;
    if (user == null || !mounted) return;

    final currentRole = user.role ?? UserRole.sender;
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

  Widget _senderMainBody({
    required BuildContext context,
    required WidgetRef ref,
    required AppUser user,
    required Locale locale,
    required AppLocalizations l10n,
    required String displayName,
    required AsyncValue<List<JobEntity>> jobsAsync,
    required AsyncValue<JobRepository> repoAsync,
    required String query,
  }) {
    final tab = _bottomSelected == SenderBottomNavTab.roleSwitch
        ? SenderBottomNavTab.orders
        : _bottomSelected;

    if (tab == SenderBottomNavTab.wallet) {
      return SizedBox.expand(child: _SenderWalletTabBody(l10n: l10n));
    }
    if (tab == SenderBottomNavTab.profile) {
      return SizedBox.expand(child: SenderProfileTabContent(user: user));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SenderHomeHeader(
          displayNameFormatted: displayName,
          userId: user.id,
          onLogout: () async {
            final repo = await ref.read(authRepositoryProvider.future);
            await repo.logout();
            await ref.read(authSessionProvider.notifier).refresh();
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFFB8C0CC),
                width: 1.25,
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 16,
                  offset: Offset(0, 8),
                  color: Color(0x10000000),
                ),
              ],
            ),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              cursorColor: AppColors.primaryBlue,
              style: const TextStyle(
                fontSize: 16,
                height: 1.35,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: l10n.searchJobsHint,
                hintStyle: const TextStyle(
                  fontSize: 16,
                  height: 1.35,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF64748B),
                ),
                suffixIcon: _search.text.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: MaterialLocalizations.of(context).clearButtonTooltip,
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF64748B),
                        ),
                      ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SenderCreateJobHeroCard(
            onTap: () => context.push(AppRoutes.createJob),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: repoAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => ProviderErrorScreen(
              error: error,
              stackTrace: stack,
              onRetry: () {
                ref.invalidate(jobRepositoryProvider);
              },
            ),
            data: (repo) => jobsAsync.when(
              data: (jobs) {
                final activeJobsCount = _jobsForTab(jobs, _SenderTab.active).length;
                final inProgressJobsCount =
                    _jobsForTab(jobs, _SenderTab.inProgress).length;
                final doneJobsCount = _jobsForTab(jobs, _SenderTab.done).length;

                final tabJobs = _jobsForTab(jobs, _selectedTab);

                var filtered = repo.filterJobs(
                  tabJobs,
                  query,
                  locale.languageCode,
                );

                if (query.isNotEmpty) {
                  final byStatusLabel = tabJobs.where((j) {
                    final stLabel = _norm(jobStatusLabel(j.status, l10n));
                    return stLabel.contains(query);
                  }).toList();

                  final ids = <String>{for (final j in filtered) j.id};
                  for (final j in byStatusLabel) {
                    if (ids.add(j.id)) filtered.add(j);
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SenderStatusTabs(
                        selectedIndex: _statusTabIndex,
                        counts: [activeJobsCount, inProgressJobsCount, doneJobsCount],
                        onSelect: _setStatusTabIndex,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? _SenderEmptyState(
                              title: query.isEmpty
                                  ? 'Hozircha buyurtmalar yo\'q'
                                  : l10n.noJobsFound,
                              subtitle: query.isEmpty
                                  ? 'Yangi buyurtma yarating va bu yerda ko\'ring'
                                  : '"${_search.text.trim()}" — ${l10n.noJobsFound}',
                              onClear: _search.text.trim().isEmpty
                                  ? null
                                  : () {
                                      _search.clear();
                                      setState(() {});
                                    },
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemBuilder: (context, index) {
                                final job = filtered[index];
                                return SenderOrderCard(
                                  job: job,
                                  locale: locale,
                                  viewerId: user.id,
                                  onOpen: () => context.push(AppRoutes.jobDetail(job.id)),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ProviderErrorScreen(
                error: error,
                stackTrace: stack,
                onRetry: () {
                  ref.invalidate(senderJobsProvider(user.id));
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authSessionProvider).valueOrNull;
    final locale =
        ref.watch(localeControllerProvider).valueOrNull ?? const Locale('uz');

    ref.listen(authSessionProvider, (prev, next) {
      if (next.valueOrNull == null) {
        _senderJobsPollTimer?.cancel();
        _senderJobsPollTimer = null;
        _polledUserId = null;
      }
    });

    if (user == null) {
      return Scaffold(body: Center(child: Text(l10n.signInRequired)));
    }

    if (_polledUserId != user.id) {
      _polledUserId = user.id;
      _senderJobsNotifListenUserId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _senderJobsPollTimer?.cancel();
        _senderJobsPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
          if (!mounted) return;
          final uid = ref.read(authSessionProvider).valueOrNull?.id;
          if (uid != null) ref.invalidate(senderJobsProvider(uid));
        });
      });
    }

    if (_senderJobsNotifListenUserId != user.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ensureSenderJobsNotificationListener(ref, user);
      });
    }

    final jobsAsync = ref.watch(senderJobsProvider(user.id));
    final repoAsync = ref.watch(jobRepositoryProvider);
    final query = _norm(_search.text);
    final displayName = formatDisplayName(user.displayName);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: AppColors.lightBackground,
      ),
      child: AppPrimaryScaffold(
        showAppBar: false,
        showAppBarTitle: false,
        showLanguageSwitcher: false,
        title: '',
        actions: const [],
        bottomNavigationBar: SenderBottomNav(
          selected: _bottomSelected,
          onSelected: (t) => setState(() => _bottomSelected = t),
          onRoleSwitch: _onRoleSwitchPressed,
        ),
        body: _senderMainBody(
          context: context,
          ref: ref,
          user: user,
          locale: locale,
          l10n: l10n,
          displayName: displayName,
          jobsAsync: jobsAsync,
          repoAsync: repoAsync,
          query: query,
        ),
      ),
    );
  }
}

class _SenderWalletTabBody extends StatelessWidget {
  const _SenderWalletTabBody({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: AppColors.lightBackground,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE6EEFF)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 16,
                    offset: Offset(0, 8),
                    color: Color(0x10000000),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 40,
                      color: AppColors.primaryBlue.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.senderWalletTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0B2A4A),
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
      ),
    );
  }
}

class _SenderEmptyState extends StatelessWidget {
  const _SenderEmptyState({
    required this.title,
    required this.subtitle,
    this.onClear,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE6EEFF)),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 20,
                  offset: Offset(0, 10),
                  color: Color(0x12000000),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryBlue.withValues(alpha: 0.9),
                        const Color(0xFF0B5FFF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.inbox_outlined,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0B2A4A),
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
                if (onClear != null) ...[
                  const SizedBox(height: 18),
                  FilledButton.tonalIcon(
                    onPressed: onClear,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

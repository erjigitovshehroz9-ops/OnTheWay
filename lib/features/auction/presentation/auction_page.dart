import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/auction_math.dart';
import '../../../features/jobs/application/job_poll_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/app_user.dart';
import '../../../models/job_entity.dart';
import '../../../models/job_status.dart';
import '../../../models/job_transport_type.dart';
import '../../../models/user_role.dart';

const Color _auctionPageBg = Color(0xFFF8F9FB);
const Color _auctionNavy = Color(0xFF0A1629);
const Color _auctionGrey = Color(0xFF7D8592);
const Color _timerBlueDark = Color(0xFF061A33);
const Color _timerBlueMid = Color(0xFF1E40AF);
const Color _timerBlueLight = Color(0xFF38BDF8);
const Color _bidOrangeA = Color(0xFFFF8C42);
const Color _bidOrangeB = Color(0xFFFF5A1F);

class _AuctionExtras {
  const _AuctionExtras(this.sender, this.steps, this.couriers);

  final AppUser? sender;
  final List<Map<String, Object?>> steps;
  final List<AppUser> couriers;
}

Future<_AuctionExtras> _loadAuctionExtras(
  WidgetRef ref,
  String jobId,
  String senderId,
) async {
  final jobRepo = await ref.read(jobRepositoryProvider.future);
  final userRepo = await ref.read(userRepositoryProvider.future);
  final steps = await jobRepo.auctionHistory(jobId);
  final sender = await userRepo.getUser(senderId);
  final ids = <String>{};
  for (final m in steps) {
    final id = m['courier_id'] as String?;
    if (id != null) ids.add(id);
  }
  final couriers = <AppUser>[];
  for (final id in ids) {
    final u = await userRepo.getUser(id);
    if (u != null) couriers.add(u);
  }
  couriers.sort((a, b) => a.displayName.compareTo(b.displayName));
  return _AuctionExtras(sender, steps, couriers);
}

String _formatSum(int cents, Locale locale) {
  final v = (cents / 100).round();
  final fmt = NumberFormat('#,###', locale.toString());
  return '${fmt.format(v)} UZS';
}

String _auctionCrossDevicePlatform() {
  if (kIsWeb) return 'web';
  return defaultTargetPlatform.name;
}

/// Cross-device auction diagnostics (phone vs Windows): same fields on both platforms
/// to spot stale job rows, identity mismatch, or divergent isLeading/canPressNextStep.
void _debugLogAuctionPhoneVsWindows({
  required JobEntity job,
  required AppUser? user,
  required bool isCourier,
  required bool canLower,
  required bool actionBusy,
}) {
  if (!kDebugMode) return;
  if (job.status != JobStatus.auctionLive || !isCourier) return;
  final courierId = user?.id;
  final leadingId = job.leadingCourierId;
  final isLeading =
      courierId != null && leadingId != null && courierId == leadingId;
  final canPressNextStep = job.auctionTimerActive &&
      !isLeading &&
      canLower &&
      !actionBusy;
  final eff = job.effectiveAuctionLivePriceCentsOrDerived;
  debugPrint(
    '[auctionPhoneVsWindows] platform=${_auctionCrossDevicePlatform()} '
    'orderId=${job.id} userId=$courierId leadingCourierId=$leadingId '
    'isLeading=$isLeading canPressNextStep=$canPressNextStep '
    'auction_step=${job.auctionStep} currentPriceCents=${job.currentPriceCents} '
    'effectivePriceCents=$eff auctionTimerActive=${job.auctionTimerActive} '
    'canLower=$canLower actionBusy=$actionBusy',
  );
}

String _fmtMmSs(int totalSecs) {
  final s = totalSecs.clamp(0, 359999);
  final m = s ~/ 60;
  final r = s % 60;
  return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
}

int _distinctCourierCount(List<Map<String, Object?>> steps) {
  final ids = <String>{};
  for (final m in steps) {
    final id = m['courier_id'] as String?;
    if (id != null && id.isNotEmpty) ids.add(id);
  }
  return ids.length;
}

class AuctionPage extends ConsumerStatefulWidget {
  const AuctionPage({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<AuctionPage> createState() => _AuctionPageState();
}

class _AuctionPageState extends ConsumerState<AuctionPage> {
  bool _actionBusy = false;
  bool _auctionEndHandled = false;
  bool _wasEverLive = false;

  void _onJobSnapshot(JobEntity job) {
    if (_auctionEndHandled || !mounted) return;
    final s = job.status;
    if (s == JobStatus.auctionLive) {
      _wasEverLive = true;
      return;
    }
    if (s == JobStatus.posted && !_wasEverLive) {
      return;
    }
    if ((s == JobStatus.posted && _wasEverLive) ||
        (s != JobStatus.posted && s != JobStatus.auctionLive)) {
      _scheduleAuctionClosed(job);
    }
  }

  void _scheduleAuctionClosed(JobEntity job) {
    if (_auctionEndHandled || !mounted) return;
    _auctionEndHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _showAuctionClosedDialog(job);
      if (!mounted) return;
      ref.invalidate(courierJobsProvider);
      final session = ref.read(authSessionProvider).valueOrNull;
      if (session?.role == UserRole.courier) {
        if (mounted) context.go(AppRoutes.courier);
      } else if (context.canPop()) {
        context.pop();
      }
    });
  }

  Future<void> _showAuctionClosedDialog(JobEntity job) async {
    final l10n = AppLocalizations.of(context);
    final myId = ref.read(authSessionProvider).valueOrNull?.id;
    final String body;
    if (job.status == JobStatus.posted) {
      body = l10n.auctionEndedNoWinnerBody;
    } else if (job.winnerCourierId != null && job.winnerCourierId == myId) {
      body = l10n.auctionEndedYouWonBody;
    } else if (job.winnerCourierId != null) {
      body = l10n.auctionEndedOtherWinnerBody;
    } else {
      body = l10n.auctionEndedGenericBody;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.auctionStatusEnded),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authSessionProvider).valueOrNull;
    final jobAsync = ref.watch(jobPollProvider(widget.jobId));

    ref.listen<AsyncValue<JobEntity?>>(
      jobPollProvider(widget.jobId),
      (_, next) {
        next.whenData((job) {
          if (job != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _onJobSnapshot(job);
            });
          }
        });
      },
    );

    return Scaffold(
      backgroundColor: _auctionPageBg,
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: SelectableText('$e')),
        data: (job) {
          if (job == null) {
            return Center(child: Text(l10n.noJobsFound));
          }
          final authRepo = ref.read(authRepositoryProvider).valueOrNull;
          final sessionUser = user;
          if (sessionUser != null &&
              sessionUser.role == UserRole.courier &&
              authRepo != null &&
              !JobTransportType.courierSeesJob(
                courierNormalizedKeys:
                    authRepo.resolvedCourierTransportKeys(sessionUser),
                jobTransportStored: job.transportType,
              )) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.jobTransportMismatchMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => context.pop(),
                      child: Text(MaterialLocalizations.of(context).okButtonLabel),
                    ),
                  ],
                ),
              ),
            );
          }
          return FutureBuilder<_AuctionExtras>(
            future: _loadAuctionExtras(ref, job.id, job.senderId),
            builder: (context, snap) {
              final extras = snap.data;
              return _AuctionScaffoldBody(
                job: job,
                user: user,
                extras: extras,
                loadingExtras: snap.connectionState == ConnectionState.waiting,
                l10n: l10n,
                locale: Localizations.localeOf(context),
                actionBusy: _actionBusy,
                onJoin: () => _run(() async {
                  final repo = await ref.read(jobRepositoryProvider.future);
                  await repo.joinAuction(
                    jobId: job.id,
                    courierId: user!.id,
                  );
                }),
                onAcceptLower: () => _run(() async {
                  final repo = await ref.read(jobRepositoryProvider.future);
                  await repo.acceptLowerAuctionPrice(
                    jobId: job.id,
                    courierId: user!.id,
                  );
                }),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() => _actionBusy = true);
    try {
      await fn();
    } catch (e, st) {
      debugPrint('[auction_page] $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }
}

class _AuctionScaffoldBody extends StatelessWidget {
  const _AuctionScaffoldBody({
    required this.job,
    required this.user,
    required this.extras,
    required this.loadingExtras,
    required this.l10n,
    required this.locale,
    required this.actionBusy,
    required this.onJoin,
    required this.onAcceptLower,
  });

  final JobEntity job;
  final AppUser? user;
  final _AuctionExtras? extras;
  final bool loadingExtras;
  final AppLocalizations l10n;
  final Locale locale;
  final bool actionBusy;
  final Future<void> Function() onJoin;
  final Future<void> Function() onAcceptLower;

  @override
  Widget build(BuildContext context) {
    final canLower = job.status == JobStatus.auctionLive
        ? AuctionMath.canDecreaseFromCurrentPrice(
            job.effectiveAuctionLivePriceCentsOrDerived,
            job.floorPriceCents,
          )
        : AuctionMath.canDecreaseStep(
            job.startPriceCents,
            job.auctionStep,
            job.floorPriceCents,
          );
    final isCourier = user?.role == UserRole.courier;
    final participantCount =
        extras == null ? 0 : _distinctCourierCount(extras!.steps);

    _debugLogAuctionPhoneVsWindows(
      job: job,
      user: user,
      isCourier: isCourier,
      canLower: canLower,
      actionBusy: actionBusy,
    );

    return Column(
      children: [
        _AuctionMapHeader(
          job: job,
          locale: locale,
          l10n: l10n,
          onBack: () => context.pop(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: _AuctionTimerStrip(job: job, l10n: l10n),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WhiteShadowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BidGradientCard(
                        job: job,
                        viewer: user,
                        locale: locale,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 12),
                      if (loadingExtras)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        RepaintBoundary(
                          child: _ParticipantRow(
                            count: participantCount,
                            couriers: extras?.couriers ?? const [],
                            l10n: l10n,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _AuctionBottomBar(
          job: job,
          user: user,
          isCourier: isCourier,
          canLower: canLower,
          actionBusy: actionBusy,
          l10n: l10n,
          onJoin: onJoin,
          onAcceptLower: onAcceptLower,
          onWatch: () => context.pop(),
        ),
      ],
    );
  }
}

const Color _mapRouteBlue = Color(0xFF153E7A);
const Color _mapBgTop = Color(0xFFEEF2F7);
const Color _mapBgBottom = Color(0xFFE2EAF2);

class _AuctionMapHeader extends StatelessWidget {
  const _AuctionMapHeader({
    required this.job,
    required this.locale,
    required this.l10n,
    required this.onBack,
  });

  final JobEntity job;
  final Locale locale;
  final AppLocalizations l10n;
  final VoidCallback onBack;

  static const double _mapHeight = 176;
  static const double _headerBarHeight = 48;
  static const double _headerSideSlot = 48;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Material(
            color: _auctionPageBg,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final titleMaxW = (constraints.maxWidth -
                          2 * _headerSideSlot -
                          8)
                      .clamp(80.0, double.infinity);
                  return SizedBox(
                    height: _headerBarHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: titleMaxW),
                            child: Text(
                              l10n.auctionLiveScreenTitle,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _auctionNavy,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Material(
                              color: Colors.white,
                              elevation: 2,
                              shadowColor: Colors.black26,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: IconButton(
                                onPressed: onBack,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 18,
                                  color: _auctionNavy,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: SizedBox(
                              width: _headerSideSlot,
                              height: _headerSideSlot,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        SizedBox(
          height: _mapHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = _mapHeight;
              final pickupDot = Offset(w * 0.22, h * 0.36);
              final dropDot = Offset(w * 0.80, h * 0.76);
              final pickupCardMaxW = (w - 24) * 0.62;
              final dropCardMaxW = (w - 24) * 0.58;
              return Stack(
                clipBehavior: Clip.hardEdge,
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    size: Size(w, h),
                    painter: const _IllustratedMapPainter(),
                  ),
                  Center(
                    child: IgnorePointer(
                      child: Text(
                        'Toshkent',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _auctionGrey.withValues(alpha: 0.38),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: pickupDot.dx - 22,
                    top: pickupDot.dy - 22,
                    child: const _RouteRippleDot(),
                  ),
                  Positioned(
                    left: dropDot.dx - 22,
                    top: dropDot.dy - 22,
                    child: const _RouteRippleDot(),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: pickupCardMaxW.clamp(120, 280),
                      ),
                      child: _StylizedAddressCard(
                        label: l10n.auctionPickupMapLabel,
                        address: job.pickupAddress.resolveLang(locale.languageCode),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: dropCardMaxW.clamp(120, 280),
                      ),
                      child: _StylizedAddressCard(
                        label: l10n.auctionDropoffMapLabel,
                        address: job.dropoffAddress.resolveLang(locale.languageCode),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _IllustratedMapPainter extends CustomPainter {
  const _IllustratedMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_mapBgTop, _mapBgBottom],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final blockPaint = Paint()
      ..color = const Color(0xFFD8E0EA).withValues(alpha: 0.55);
    final blocks = <Rect>[
      Rect.fromLTWH(size.width * 0.05, size.height * 0.15, 38, 28),
      Rect.fromLTWH(size.width * 0.62, size.height * 0.08, 44, 36),
      Rect.fromLTWH(size.width * 0.12, size.height * 0.72, 52, 22),
      Rect.fromLTWH(size.width * 0.72, size.height * 0.22, 36, 40),
      Rect.fromLTWH(size.width * 0.42, size.height * 0.38, 48, 26),
    ];
    for (final r in blocks) {
      canvas.drawRRect(
        RRect.fromRectXY(r, 4, 4),
        blockPaint,
      );
    }

    final street = Paint()
      ..color = const Color(0xFFC5D0DC).withValues(alpha: 0.45)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 9; i++) {
      final y = size.height * (0.12 + i * 0.09);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), street);
    }
    for (var i = 0; i < 8; i++) {
      final x = size.width * (0.08 + i * 0.11);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), street);
    }
  }

  @override
  bool shouldRepaint(covariant _IllustratedMapPainter oldDelegate) => false;
}

class _RouteRippleDot extends StatelessWidget {
  const _RouteRippleDot();

  @override
  Widget build(BuildContext context) {
    const core = Color(0xFF153E7A);
    const ring = Color(0xFF3B82F6);
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ring.withValues(alpha: 0.12),
            ),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ring.withValues(alpha: 0.22),
            ),
          ),
          Container(
            width: 11,
            height: 11,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: core,
            ),
          ),
        ],
      ),
    );
  }
}

class _StylizedAddressCard extends StatelessWidget {
  const _StylizedAddressCard({
    required this.label,
    required this.address,
  });

  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 22,
              color: _mapRouteBlue,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _auctionGrey.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: _auctionNavy,
                      height: 1.25,
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

/// Har soniyada faqat status/timer qatorini yangilaydi; scroll ichidagi kontent rebuild bo‘lmaydi.
class _AuctionTimerStrip extends StatefulWidget {
  const _AuctionTimerStrip({
    required this.job,
    required this.l10n,
  });

  final JobEntity job;
  final AppLocalizations l10n;

  @override
  State<_AuctionTimerStrip> createState() => _AuctionTimerStripState();
}

class _AuctionTimerStripState extends State<_AuctionTimerStrip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rem = widget.job.auctionTimeRemaining();
    final secs = (rem?.inSeconds ?? 0).clamp(0, 99999);
    if (kDebugMode) {
      debugPrint(
        '[auction-ui] remaining=$secs state=${widget.job.status} '
        'step=${widget.job.auctionStep} bids=${widget.job.auctionBidCount}',
      );
    }
    return _TimerGradientCard(
      job: widget.job,
      secs: secs,
      l10n: widget.l10n,
    );
  }
}

class _TimerGradientCard extends StatelessWidget {
  const _TimerGradientCard({
    required this.job,
    required this.secs,
    required this.l10n,
  });

  final JobEntity job;
  final int secs;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final live = job.status == JobStatus.auctionLive && job.auctionTimerActive;
    final endedLive =
        job.status == JobStatus.auctionLive && !job.auctionTimerActive;
    final timeStr = _fmtMmSs(secs);
    final String main;
    final String sub;
    if (live) {
      main = l10n.auctionTimeLeftLine(timeStr);
      sub = l10n.auctionOngoingLabel;
    } else if (endedLive) {
      main = l10n.auctionTimeLeftLine('00:00');
      sub = l10n.auctionStatusEnded;
    } else {
      main = l10n.auctionWaitingStartLabel;
      sub = l10n.joinAuctionCta;
    }

    final gradientColors = live
        ? const [
            _timerBlueDark,
            _timerBlueMid,
            _timerBlueLight,
          ]
        : [
            _timerBlueDark.withValues(alpha: 0.82),
            _timerBlueMid.withValues(alpha: 0.78),
            _timerBlueLight.withValues(alpha: 0.55),
          ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _timerBlueLight.withValues(alpha: 0.45),
            blurRadius: 22,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _timerBlueMid.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: -40,
              top: -30,
              child: IgnorePointer(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -36,
              bottom: -24,
              child: IgnorePointer(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _timerBlueLight.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    main,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    sub,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

class _BidGradientCard extends StatefulWidget {
  const _BidGradientCard({
    required this.job,
    required this.viewer,
    required this.locale,
    required this.l10n,
  });

  final JobEntity job;
  final AppUser? viewer;
  final Locale locale;
  final AppLocalizations l10n;

  @override
  State<_BidGradientCard> createState() => _BidGradientCardState();
}

class _BidGradientCardState extends State<_BidGradientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _edgePulse;

  @override
  void initState() {
    super.initState();
    _edgePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _edgePulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final int committed = job.status == JobStatus.auctionLive
        ? math.max(
            job.effectiveAuctionLivePriceCentsOrDerived,
            job.floorPriceCents,
          )
        : AuctionMath.committedPriceCents(
            job.startPriceCents,
            job.auctionStep,
            job.floorPriceCents,
          );
    final canNext = job.status == JobStatus.auctionLive
        ? AuctionMath.canDecreaseFromCurrentPrice(
            job.effectiveAuctionLivePriceCentsOrDerived,
            job.floorPriceCents,
          )
        : AuctionMath.canDecreaseStep(
            job.startPriceCents,
            job.auctionStep,
            job.floorPriceCents,
          );
    final int nextCents = job.status == JobStatus.auctionLive
        ? AuctionMath.nextPriceAfterServerStepCents(
            job.effectiveAuctionLivePriceCentsOrDerived,
            job.floorPriceCents,
          )
        : AuctionMath.committedPriceCents(
            job.startPriceCents,
            job.auctionStep + 1,
            job.floorPriceCents,
          );

    final String label;
    final int displayCents;
    if (job.status == JobStatus.posted) {
      displayCents = AuctionMath.committedPriceCents(
        job.startPriceCents,
        0,
        job.floorPriceCents,
      );
      label = widget.l10n.auctionStartPriceLabel;
    } else if (job.status == JobStatus.auctionLive) {
      final viewer = widget.viewer;
      final viewerId = viewer?.id;
      final leadingId = job.leadingCourierId;
      final isCourier = viewer?.role == UserRole.courier;
      final isLeading =
          isCourier && viewerId != null && viewerId == leadingId;
      if (isLeading) {
        displayCents = committed;
        label = widget.l10n.auctionYourPriceLabel;
      } else if (isCourier && !isLeading && canNext) {
        displayCents = nextCents;
        label = widget.l10n.auctionNextOfferLabel;
      } else {
        displayCents = committed;
        label = widget.l10n.auctionHozirgiTaklif;
      }
    } else {
      displayCents = job.finalPriceCents ??
          AuctionMath.committedPriceCents(
            job.startPriceCents,
            job.auctionStep,
            job.floorPriceCents,
          );
      label = widget.l10n.auctionHozirgiTaklif;
    }

    if (kDebugMode && job.status == JobStatus.auctionLive) {
      final eff = job.effectiveAuctionLivePriceCentsOrDerived;
      final src = job.currentPriceCents != null && job.currentPriceCents! > 0
          ? 'current'
          : 'computed_step';
      debugPrint(
        '[auction-ui] order=${job.id} shownPrice=$displayCents source=$src '
        'step=${job.auctionStep} currentCents=${job.currentPriceCents} effective=$eff',
      );
    }

    return AnimatedBuilder(
      animation: _edgePulse,
      builder: (context, _) {
        final edgeOpacity = 0.28 + _edgePulse.value * 0.55;
        return Container(
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [_bidOrangeA, _bidOrangeB],
            ),
            boxShadow: [
              BoxShadow(
                color: _bidOrangeB.withValues(alpha: 0.42),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 10,
                  top: 11,
                  bottom: 11,
                  child: _BidVerticalGlowLine(opacity: edgeOpacity),
                ),
                Positioned(
                  right: 10,
                  top: 11,
                  bottom: 11,
                  child: _BidVerticalGlowLine(opacity: edgeOpacity),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _formatSum(displayCents, widget.locale),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.96),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.l10n.auctionFloor}: ${_formatSum(widget.job.floorPriceCents, widget.locale)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BidVerticalGlowLine extends StatelessWidget {
  const _BidVerticalGlowLine({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: opacity * 0.9),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: opacity),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.count,
    required this.couriers,
    required this.l10n,
  });

  final int count;
  final List<AppUser> couriers;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final show = couriers.take(5).toList();
    final stackW = show.isEmpty ? 0.0 : 22.0 + (show.length - 1) * 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (show.isEmpty)
          const SizedBox(height: 36)
        else
          SizedBox(
            height: 40,
            width: stackW,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < show.length; i++)
                  Positioned(
                    left: i * 16,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Color.lerp(
                          _timerBlueMid,
                          _bidOrangeB,
                          i / math.max(show.length, 2),
                        )!,
                        child: Text(
                          _avatarLetter(show[i].displayName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Text(
          l10n.auctionCouriersParticipatingCount(count),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _auctionGrey,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  String _avatarLetter(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return String.fromCharCode(t.runes.first).toUpperCase();
  }
}

class _WhiteShadowCard extends StatelessWidget {
  const _WhiteShadowCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _AuctionBottomBar extends StatelessWidget {
  const _AuctionBottomBar({
    required this.job,
    required this.user,
    required this.isCourier,
    required this.canLower,
    required this.actionBusy,
    required this.l10n,
    required this.onJoin,
    required this.onAcceptLower,
    required this.onWatch,
  });

  final JobEntity job;
  final AppUser? user;
  final bool isCourier;
  final bool canLower;
  final bool actionBusy;
  final AppLocalizations l10n;
  final Future<void> Function() onJoin;
  final Future<void> Function() onAcceptLower;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    final courierId = user?.id;
    final leadingId = job.leadingCourierId;
    final isLeading =
        courierId != null && leadingId != null && courierId == leadingId;

    if (kDebugMode && isCourier) {
      String? blockReason;
      if (job.status == JobStatus.auctionLive) {
        if (!job.auctionTimerActive) {
          blockReason = 'timer_ended';
        } else if (isLeading) {
          blockReason = 'already_leading_ui';
        } else if (!canLower) {
          blockReason = 'at_floor_or_cannot_lower';
        } else if (actionBusy) {
          blockReason = 'action_busy';
        }
      }
      final canPressNextStep = job.status == JobStatus.auctionLive &&
          job.auctionTimerActive &&
          !isLeading &&
          canLower &&
          !actionBusy;
      final eff = job.effectiveAuctionLivePriceCentsOrDerived;
      final nextPrice = job.status == JobStatus.auctionLive
          ? AuctionMath.nextPriceAfterServerStepCents(
              eff,
              job.floorPriceCents,
            )
          : AuctionMath.committedPriceCents(
              job.startPriceCents,
              job.auctionStep + 1,
              job.floorPriceCents,
            );
      debugPrint(
        '[auctionCrossDevice] bottomBar platform=${_auctionCrossDevicePlatform()} '
        'order=${job.id} localCourier=$courierId remoteLead=$leadingId '
        'step=${job.auctionStep} current=${job.currentPriceCents} effective=$eff nextPrice=$nextPrice '
        'alreadyLeading=$isLeading canPressNextStep=$canPressNextStep '
        'canLower=$canLower timerActive=${job.auctionTimerActive} busy=$actionBusy '
        'blockReason=${blockReason ?? "(n/a)"}',
      );
    }

    Widget? primary;

    if (isCourier && user != null) {
      if (job.status == JobStatus.posted) {
        primary = FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.auctionDeepBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: actionBusy
              ? null
              : () {
                  onJoin();
                },
          child: actionBusy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.joinAuctionCta),
        );
      } else if (job.status == JobStatus.auctionLive) {
        if (!job.auctionTimerActive) {
          primary = FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  AppColors.auctionDeepBlue.withValues(alpha: 0.35),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: null,
            child: Text(l10n.auctionStatusEnded),
          );
        } else if (isLeading || !canLower) {
          primary = FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  AppColors.auctionDeepBlue.withValues(alpha: 0.4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: null,
            child: Text(
              isLeading ? l10n.auctionYouAreLeading : l10n.auctionFloor,
            ),
          );
        } else {
          primary = FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.auctionDeepBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: (actionBusy || !job.auctionTimerActive)
                ? null
                : () {
                    onAcceptLower();
                  },
            child: actionBusy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.auctionAgreePriceCta),
          );
        }
      }
    }

    return Material(
      color: _auctionPageBg,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (primary != null) ...[primary],
              const SizedBox(height: 8),
              TextButton(
                onPressed: onWatch,
                child: Text(
                  l10n.auctionWatchCta,
                  style: const TextStyle(
                    color: _auctionNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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

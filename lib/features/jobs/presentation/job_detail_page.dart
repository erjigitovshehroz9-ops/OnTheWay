import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/auction_math.dart';
import '../../../data/regions_seed.dart';
import '../../../features/jobs/application/job_poll_provider.dart';
import '../../../features/jobs/presentation/job_pickup_dropoff_map_page.dart';
import '../../../features/jobs/presentation/widgets/job_courier_route_tracking_card.dart';
import '../../../features/sender/application/sender_jobs_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/app_user.dart';
import '../../../models/delivery_speed.dart';
import '../../../models/job_entity.dart';
import '../../../models/job_status.dart';
import '../../../models/job_transport_type.dart';
import '../../../models/payment_type.dart';
import '../../../models/user_role.dart';
import '../../../models/volume_category.dart';
import '../../../shared/utils/job_status_l10n.dart';
import '../../../shared/widgets/job_image.dart';
import 'widgets/order_feedback_widgets.dart';

String _fmtJobPriceUz(int cents, Locale locale) {
  final v = (cents / 100).round();
  final fmt = NumberFormat('#,###', locale.toString());
  return '${fmt.format(v)} UZS';
}

String _jobDetailDeliveryWindowText(JobEntity job) {
  final s = job.deliveryWindowStart?.trim();
  final e = job.deliveryWindowEnd?.trim();
  if (s != null && s.isNotEmpty && e != null && e.isNotEmpty) {
    return '$s — $e';
  }
  if (e != null && e.isNotEmpty) return e;
  if (s != null && s.isNotEmpty) return s;
  return '';
}

String _jobDetailDeliverySummary(JobEntity job, AppLocalizations l10n) {
  final window = _jobDetailDeliveryWindowText(job);
  String tail(String base) =>
      window.isNotEmpty ? '$base · $window' : base;

  switch (job.deliverySpeed) {
    case DeliverySpeed.fast:
      return tail(l10n.deliveryFast);
    case DeliverySpeed.relaxed:
      return tail(l10n.deliveryRelaxed);
    case DeliverySpeed.custom:
      return window.isNotEmpty ? '$window (${l10n.deliveryCustom})' : l10n.deliveryCustom;
  }
}

String _jobPaymentTypeLabel(JobEntity job, AppLocalizations l10n) {
  switch (job.paymentType) {
    case PaymentType.cash:
      return l10n.paymentCash;
    case PaymentType.card:
      return l10n.paymentCard;
    case PaymentType.prepaid:
      return l10n.paymentPrepaid;
  }
}

String? _jobVolumeCategoryLabel(JobEntity job, AppLocalizations l10n) {
  final vc = VolumeCategory.tryFromStorageKey(job.volumeCategoryKey);
  if (vc == null) return null;
  switch (vc) {
    case VolumeCategory.small:
      return l10n.volumeCatSmall;
    case VolumeCategory.medium:
      return l10n.volumeCatMedium;
    case VolumeCategory.large:
      return l10n.volumeCatLarge;
    case VolumeCategory.veryLarge:
      return l10n.volumeCatVeryLarge;
  }
}

String? _jobAdminRegionDistrictUz(JobEntity job) {
  final rc = job.regionCode.trim();
  final dc = job.districtCode.trim();
  if (rc.isEmpty && dc.isEmpty) return null;
  String rLabel = rc;
  String dLabel = dc;
  try {
    rLabel = RegionsSeed.regions.firstWhere((e) => e.code == rc).name.uz;
  } catch (_) {}
  if (dc.isNotEmpty) {
    try {
      dLabel = RegionsSeed.districts.firstWhere((e) => e.code == dc).name.uz;
    } catch (_) {}
  }
  if (dc.isEmpty) return rLabel;
  return '$rLabel / $dLabel';
}

String _jobDetailCreatedAtText(JobEntity job, Locale locale) {
  return DateFormat.yMMMd(locale.toString()).add_Hm().format(job.createdAt.toLocal());
}

enum _JobDetailChromeMode { courier, senderOwn }

abstract final class _CourierJobDetailPalette {
  static const Color pageBg = Color(0xFFF8F9FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0A1629);
  static const Color textSecondary = Color(0xFF7D8592);
  static const Color accentTeal = Color(0xFF13635B);
  /// Auksion CTA tugmasi — to‘q ko‘k ([AppColors.auctionDeepBlue]).
  static const Color auctionCtaBlue = AppColors.auctionDeepBlue;
  static const Color divider = Color(0xFFE8EAEF);
  static const Color shadow = Color(0x14000000);
  /// Ikki ustunli manzil/kontakt: minimal kenglik.
  static const double wideLayoutMinWidth = 420;
  /// Pastki auksion CTA uchun scroll ichki bo‘sh joy.
  static const double auctionCtaBarReserve = 88;
}

Widget _jobAuctionLiveDetailCard({
  required JobEntity job,
  required Locale locale,
  required AppLocalizations l10n,
}) {
  final committed = job.currentPriceCents != null && job.currentPriceCents! > 0
      ? math.max(job.currentPriceCents!, job.floorPriceCents)
      : AuctionMath.committedPriceCents(
          job.startPriceCents,
          job.auctionStep,
          job.floorPriceCents,
        );
  final rem = job.auctionTimeRemaining();
  final secs = (rem?.inSeconds ?? 0).clamp(0, 999999);
  final mm = secs ~/ 60;
  final ss = secs % 60;
  final timeStr =
      '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  if (kDebugMode) {
    debugPrint(
      '[auction-ui] detail job=${job.id} remaining=$secs bids=${job.auctionBidCount}',
    );
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          label: Text(l10n.auctionStatusLive),
          visualDensity: VisualDensity.compact,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '${l10n.auctionStartPriceLabel}: ${_fmtJobPriceUz(job.startPriceCents, locale)}',
        style: const TextStyle(
          fontSize: 13,
          height: 1.3,
          color: _CourierJobDetailPalette.textSecondary,
        ),
      ),
      Text(
        '${l10n.auctionCurrentOffer}: ${_fmtJobPriceUz(committed, locale)}',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: _CourierJobDetailPalette.textPrimary,
        ),
      ),
      if (job.startPriceCents > committed) ...[
        const SizedBox(height: 4),
        Text(
          '−${_fmtJobPriceUz(job.startPriceCents - committed, locale)}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _CourierJobDetailPalette.accentTeal,
          ),
        ),
      ],
      const SizedBox(height: 8),
      Text(
        l10n.auctionTimeLeftLine(timeStr),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _CourierJobDetailPalette.textPrimary,
        ),
      ),
      if (job.auctionBidCount > 0)
        Text(
          l10n.auctionCouriersParticipatingCount(job.auctionBidCount),
          style: const TextStyle(
            fontSize: 12,
            height: 1.35,
            color: _CourierJobDetailPalette.textSecondary,
          ),
        ),
    ],
  );
}

class _CourierDetailCard extends StatelessWidget {
  const _CourierDetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _CourierJobDetailPalette.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: _CourierJobDetailPalette.shadow,
            blurRadius: 18,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: child,
    );
  }
}

class JobDetailPage extends ConsumerStatefulWidget {
  const JobDetailPage({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends ConsumerState<JobDetailPage> {
  final _noteCtrl = TextEditingController();
  bool _orderDetailLoadedLogged = false;
  final Set<String> _orderCommentsDetailLogIds = {};
  bool _openedDeepFeedback = false;

  @override
  void dispose() {
    ref.read(courierLiveTrackingFocusJobIdProvider.notifier).state = null;
    _noteCtrl.dispose();
    super.dispose();
  }

  bool _usesJobDetailChromeWhileLoading(AppUser? user) {
    if (user == null) return false;
    return user.role == UserRole.courier || user.role == UserRole.sender;
  }

  bool _usesJobDetailChrome(AppUser user, JobEntity job) {
    if (user.role == UserRole.courier) return true;
    return user.id == job.senderId;
  }

  void _consumeOpenFeedbackDeepLink(
    JobEntity job,
    AppUser user,
    AppLocalizations l10n,
  ) {
    if (_openedDeepFeedback) return;
    final q = GoRouterState.of(context).uri.queryParameters['openFeedback'];
    if (q != '1') return;
    if (job.status != JobStatus.completed) return;
    if (user.id != job.senderId && user.id != job.winnerCourierId) return;
    final toId =
        user.id == job.senderId ? job.winnerCourierId ?? '' : job.senderId;
    if (toId.isEmpty) return;
    _openedDeepFeedback = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showOrderFeedbackBottomSheet(
        context: context,
        ref: ref,
        job: job,
        fromUserId: user.id,
        toUserId: toId,
        l10n: l10n,
        ratingCourier: user.id == job.senderId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authSessionProvider).valueOrNull;
    final jobAsync = ref.watch(jobPollProvider(widget.jobId));
    final chromeWhileLoading = _usesJobDetailChromeWhileLoading(user);

    PreferredSizeWidget appBarDefault() =>
        AppBar(title: Text(l10n.jobDetails));

    PreferredSizeWidget appBarForState() => chromeWhileLoading
        ? _courierJobDetailAppBar(context, l10n)
        : appBarDefault();

    return jobAsync.when(
      loading: () => Scaffold(
        backgroundColor:
            chromeWhileLoading ? _CourierJobDetailPalette.pageBg : null,
        appBar: appBarForState(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        backgroundColor:
            chromeWhileLoading ? _CourierJobDetailPalette.pageBg : null,
        appBar: appBarForState(),
        body: Center(child: SelectableText('$e')),
      ),
      data: (job) {
        if (job != null && kDebugMode && !_orderDetailLoadedLogged) {
          _orderDetailLoadedLogged = true;
          debugPrint('[order-detail] loaded id=${widget.jobId}');
        }
        if (job == null || user == null) {
          return Scaffold(
            backgroundColor:
                chromeWhileLoading ? _CourierJobDetailPalette.pageBg : null,
            appBar: appBarForState(),
            body: Center(child: Text(l10n.noJobsFound)),
          );
        }
        final authRepo = ref.read(authRepositoryProvider).valueOrNull;
        if (user.role == UserRole.courier &&
            authRepo != null &&
            !JobTransportType.courierSeesJob(
              courierNormalizedKeys:
                  authRepo.resolvedCourierTransportKeys(user),
              jobTransportStored: job.transportType,
            )) {
          return Scaffold(
            backgroundColor: _CourierJobDetailPalette.pageBg,
            appBar: appBarForState(),
            body: Center(
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
            ),
          );
        }
        final usesChrome = _usesJobDetailChrome(user, job);
        _consumeOpenFeedbackDeepLink(job, user, l10n);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final shouldFocus = user.role == UserRole.courier &&
              job.winnerCourierId == user.id &&
              (job.status == JobStatus.assigned ||
                  job.status == JobStatus.pickedUp ||
                  job.status == JobStatus.delivered);
          ref.read(courierLiveTrackingFocusJobIdProvider.notifier).state =
              shouldFocus ? job.id : null;
        });
        return Scaffold(
          backgroundColor:
              usesChrome ? _CourierJobDetailPalette.pageBg : null,
          appBar: usesChrome
              ? _courierJobDetailAppBar(context, l10n)
              : appBarDefault(),
          body: _content(
            context,
            job,
            user,
            Localizations.localeOf(context),
            l10n,
          ),
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    JobEntity job,
    AppUser viewer,
    Locale locale,
    AppLocalizations l10n,
  ) {
    final isSender = viewer.id == job.senderId;
    final isCourier = viewer.role == UserRole.courier;
    final contactsUnlocked = job.contactsBetweenSenderAndWinner(viewer.id);
    final recipientOpen = isSender || job.recipientVisibleToWinnerCourier(viewer.id);

    if (isCourier) {
      return _courierDetailContent(
        context,
        job,
        viewer,
        locale,
        l10n,
        contactsUnlocked,
        _JobDetailChromeMode.courier,
      );
    }

    if (isSender) {
      return _courierDetailContent(
        context,
        job,
        viewer,
        locale,
        l10n,
        contactsUnlocked,
        _JobDetailChromeMode.senderOwn,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        Text(
          job.title.resolveLang(locale.languageCode),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Chip(
          label: Text(jobStatusLabel(job.status, l10n)),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.productPhoto,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        JobImageDetailPreview(
          imageRef: job.imagePath,
          maxHeight: 220,
          borderRadius: 16,
        ),
        const SizedBox(height: 10),
        _sectionTitle(context, l10n.stepProduct),
        Text(job.productType.resolveLang(locale.languageCode)),
        Text(
          '${l10n.auctionStartPriceLabel}: ${_fmtJobPriceUz(job.startPriceCents, locale)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          '${job.productWeightKg} kg · ${job.productVolumeL} L',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (job.dimensionsMm.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '${l10n.jobDimensionsMm}: ${job.dimensionsMm.trim()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (job.transportType.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '${l10n.orderRequiredTransportTitle}: ${JobTransportType.displayLabelsJoined(l10n, job.transportType)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
        if (job.fragile) Text('· ${l10n.fragileItem}'),
        if (job.coldChain) Text('· ${l10n.needsColdChain}'),
        const SizedBox(height: 8),
        _sectionTitle(context, l10n.pickupLocation),
        Text(job.pickupAddress.resolveLang(locale.languageCode)),
        const SizedBox(height: 8),
        _sectionTitle(context, l10n.dropoffLocation),
        Text(job.dropoffAddress.resolveLang(locale.languageCode)),
        const SizedBox(height: 8),
        if (recipientOpen) ...[
          _sectionTitle(context, l10n.recipientNameLabel),
          Text(job.recipientName),
          Text(job.recipientPhone),
        ] else ...[
          _sectionTitle(context, l10n.recipientNameLabel),
          Text('••••••', style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 8),
        _sectionTitle(context, l10n.jobDescriptionLabel),
        Text(job.description.resolveLang(locale.languageCode)),
        const SizedBox(height: 12),
        if ((job.status == JobStatus.pickedUp ||
                job.status == JobStatus.delivered) &&
            job.courierLat != null &&
            job.courierLng != null &&
            job.liveTrackingVisibleTo(viewer.id)) ...[
          const SizedBox(height: 16),
          JobCourierRouteTrackingCard(
            job: job,
            locale: locale,
            l10n: l10n,
            leg: CourierRouteLeg.toDropoff,
            trackingViewerId: viewer.id,
          ),
        ],
        const SizedBox(height: 20),
        OrderFeedbackDetailSection(
          job: job,
          viewerId: viewer.id,
          l10n: l10n,
        ),
      ],
    );
  }

  PreferredSizeWidget _courierJobDetailAppBar(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return AppBar(
      backgroundColor: _CourierJobDetailPalette.pageBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 56,
      leading: Center(
        child: Material(
          color: _CourierJobDetailPalette.cardBg,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.pop(),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: _CourierJobDetailPalette.textPrimary,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        l10n.jobDetails,
        style: const TextStyle(
          color: _CourierJobDetailPalette.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 17,
        ),
      ),
      centerTitle: true,
    );
  }

  ButtonStyle _courierFilledStyle() {
    return FilledButton.styleFrom(
      backgroundColor: _CourierJobDetailPalette.accentTeal,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(vertical: 14),
    );
  }

  ButtonStyle _courierAuctionFilledStyle() {
    return FilledButton.styleFrom(
      backgroundColor: _CourierJobDetailPalette.auctionCtaBlue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(vertical: 14),
    );
  }

  Widget _courierMetricRow({
    required IconData icon,
    required String label,
    required String value,
    bool showDividerBelow = true,
    bool valueBold = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 20,
                color: _CourierJobDetailPalette.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 11,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    color: _CourierJobDetailPalette.textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 12,
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: valueBold
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: _CourierJobDetailPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDividerBelow)
          const Divider(
            height: 1,
            thickness: 1,
            color: _CourierJobDetailPalette.divider,
          ),
      ],
    );
  }

  String _fmtWeightKg(JobEntity job) {
    if (job.productWeightKg <= 0) return '— kg';
    return '${job.productWeightKg} kg';
  }

  String _fmtVolumeL(JobEntity job) {
    if (job.productVolumeL <= 0) return '— L';
    return '${job.productVolumeL} L';
  }

  String _fmtDims(JobEntity job) {
    final t = job.dimensionsMm.trim();
    if (t.isEmpty) return '—';
    return t;
  }

  JobMapCourierNavLeg? _courierWinnerNavLeg(JobEntity job, AppUser viewer) {
    if (job.winnerCourierId != viewer.id) return null;
    switch (job.status) {
      case JobStatus.assigned:
        return JobMapCourierNavLeg.toPickup;
      case JobStatus.pickedUp:
      case JobStatus.delivered:
        return JobMapCourierNavLeg.toDropoff;
      default:
        return null;
    }
  }

  LatLng? _jobCourierLatLng(JobEntity job) {
    final la = job.courierLat;
    final lo = job.courierLng;
    if (la == null || lo == null) return null;
    if (la < -90 || la > 90 || lo < -180 || lo > 180) return null;
    return LatLng(la, lo);
  }

  JobMapCourierNavLeg? _detailEmbedNavLeg(
    JobEntity job,
    AppUser viewer,
    _JobDetailChromeMode mode,
  ) {
    if (mode == _JobDetailChromeMode.courier) {
      return _courierWinnerNavLeg(job, viewer);
    }
    if (mode != _JobDetailChromeMode.senderOwn || viewer.id != job.senderId) {
      return null;
    }
    final w = job.winnerCourierId?.trim();
    if (w == null || w.isEmpty) return null;
    switch (job.status) {
      case JobStatus.assigned:
        return JobMapCourierNavLeg.toPickup;
      case JobStatus.pickedUp:
      case JobStatus.delivered:
        return JobMapCourierNavLeg.toDropoff;
      default:
        return null;
    }
  }

  bool _senderEmbedMapVisible(
    JobEntity job,
    JobMapCourierNavLeg leg,
    String viewerId,
  ) {
    if (viewerId != job.senderId) return false;
    if (leg == JobMapCourierNavLeg.toPickup) {
      return job.pickupLat != null && job.pickupLng != null;
    }
    if (!job.liveTrackingVisibleTo(viewerId)) return false;
    return job.pickupLat != null &&
        job.pickupLng != null &&
        job.dropoffLat != null &&
        job.dropoffLng != null;
  }

  bool _courierEmbedMapCoordsOk(JobEntity job, JobMapCourierNavLeg leg) {
    final hasPickup = job.pickupLat != null && job.pickupLng != null;
    final hasDropoff = job.dropoffLat != null && job.dropoffLng != null;
    if (leg == JobMapCourierNavLeg.toPickup) return hasPickup;
    return hasPickup && hasDropoff;
  }

  void _openCourierJobRouteMap(
    JobEntity job,
    AppLocalizations l10n, {
    JobMapCourierNavLeg? courierNavLeg,
    bool allowDeviceCourierGps = true,
    LatLng? serverCourierLatLng,
  }) {
    final pickup = job.pickupLat != null && job.pickupLng != null
        ? LatLng(job.pickupLat!, job.pickupLng!)
        : null;
    final dropoff = job.dropoffLat != null && job.dropoffLng != null
        ? LatLng(job.dropoffLat!, job.dropoffLng!)
        : null;

    if (courierNavLeg == JobMapCourierNavLeg.toPickup) {
      if (pickup == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.jobMapNoCoordinates)),
        );
        return;
      }
    } else if (courierNavLeg == JobMapCourierNavLeg.toDropoff) {
      if (pickup == null || dropoff == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.jobMapNoCoordinates)),
        );
        return;
      }
    } else if (pickup == null && dropoff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.jobMapNoCoordinates)),
      );
      return;
    }

    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (ctx) => JobPickupDropoffMapPage(
            pickup: pickup,
            dropoff: dropoff,
            courierNavLeg: courierNavLeg,
            allowDeviceCourierGps: allowDeviceCourierGps,
            serverCourierLatLng: serverCourierLatLng,
          ),
        ),
      ),
    );
  }

  Widget _courierPickupDropoffSection({
    required JobEntity job,
    required Locale locale,
    required AppLocalizations l10n,
    required String? pickupCoords,
    required VoidCallback onOpenMap,
    required bool revealAddresses,
    required VoidCallback onAddressesLocked,
  }) {
    if (!revealAddresses) {
      return _CourierDetailCard(
        child: InkWell(
          onTap: onAddressesLocked,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: _CourierJobDetailPalette.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.orderAddressesHiddenForNonWinner,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: _CourierJobDetailPalette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget mapTappable(Widget child) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenMap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: child,
          ),
        ),
      );
    }

    Widget pickupBlock() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pickupLocation,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _CourierJobDetailPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.location_on_outlined,
                  color: _CourierJobDetailPalette.accentTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.pickupAddress.resolveLang(locale.languageCode),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: _CourierJobDetailPalette.textPrimary,
                      ),
                    ),
                    if (pickupCoords != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        pickupCoords,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.15,
                          color: _CourierJobDetailPalette.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    Widget dropoffBlock() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dropoffLocation,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _CourierJobDetailPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.flag_outlined,
                  color: _CourierJobDetailPalette.accentTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  job.dropoffAddress.resolveLang(locale.languageCode),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: _CourierJobDetailPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return _CourierDetailCard(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: mapTappable(pickupBlock())),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: _CourierJobDetailPalette.divider,
              ),
            ),
            Expanded(child: mapTappable(dropoffBlock())),
          ],
        ),
      ),
    );
  }

  Widget _courierSenderRecipientInner({
    required AppUser sender,
    required JobEntity job,
    required AppLocalizations l10n,
    required bool wideLayout,
  }) {
    Widget senderBlock() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.roleSender,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _CourierJobDetailPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sender.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: _CourierJobDetailPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sender.phone,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.15,
              color: _CourierJobDetailPalette.textSecondary,
            ),
          ),
          if (sender.telegram.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              sender.telegram,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.15,
                color: _CourierJobDetailPalette.textSecondary,
              ),
            ),
          ],
        ],
      );
    }

    Widget recipientBlock() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recipientNameLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _CourierJobDetailPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            job.recipientName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: _CourierJobDetailPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            job.recipientPhone,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.15,
              color: _CourierJobDetailPalette.textSecondary,
            ),
          ),
        ],
      );
    }

    if (wideLayout) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: senderBlock()),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: _CourierJobDetailPalette.divider,
              ),
            ),
            Expanded(child: recipientBlock()),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        senderBlock(),
        const SizedBox(height: 6),
        const Divider(
          height: 1,
          thickness: 1,
          color: _CourierJobDetailPalette.divider,
        ),
        const SizedBox(height: 6),
        recipientBlock(),
      ],
    );
  }

  Widget _courierRecipientOnlyCard(JobEntity job, AppLocalizations l10n) {
    return _CourierDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.recipientNameLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _CourierJobDetailPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            job.recipientName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: _CourierJobDetailPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            job.recipientPhone,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.15,
              color: _CourierJobDetailPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _courierWinnerContactBody(
    AppUser courier,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.roleCourier,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _CourierJobDetailPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          courier.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: _CourierJobDetailPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          courier.phone,
          style: const TextStyle(
            fontSize: 12,
            height: 1.15,
            color: _CourierJobDetailPalette.textSecondary,
          ),
        ),
        if (courier.telegram.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            courier.telegram,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.15,
              color: _CourierJobDetailPalette.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          '${l10n.completedJobsLabel}: ${courier.completedJobs}',
          style: const TextStyle(
            fontSize: 12,
            color: _CourierJobDetailPalette.textSecondary,
          ),
        ),
        Text(
          l10n.courierRatingStarsLabel(courier.rating.toStringAsFixed(1)),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _CourierJobDetailPalette.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _orderWinnerOutcomeCard(
    JobEntity job,
    Locale locale,
    AppLocalizations l10n,
  ) {
    final fp = job.finalPriceCents;
    final fpStr =
        fp != null ? _fmtJobPriceUz(fp, locale) : '—';
    final when = job.winnerSelectedAt;
    final whenStr = when == null
        ? '—'
        : DateFormat.yMMMd(locale.toString()).add_Hm().format(when.toLocal());
    return _CourierDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.orderWinnerOutcomeTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _CourierJobDetailPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _courierMetricRow(
            icon: Icons.payments_outlined,
            label: l10n.orderFinalPriceLabel,
            value: fpStr,
            valueBold: true,
          ),
          _courierMetricRow(
            icon: Icons.event_outlined,
            label: l10n.orderWinnerSelectedAtLabel,
            value: whenStr,
            showDividerBelow: job.auctionBidCount <= 0,
          ),
          if (job.auctionBidCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${l10n.orderAuctionStepsCountLabel}: ${job.auctionBidCount}',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: _CourierJobDetailPalette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _courierDetailContent(
    BuildContext context,
    JobEntity job,
    AppUser viewer,
    Locale locale,
    AppLocalizations l10n,
    bool contactsUnlocked,
    _JobDetailChromeMode mode,
  ) {
    if (kDebugMode) {
      if (_orderCommentsDetailLogIds.add(job.id)) {
        final visible = job.orderComments != null &&
            job.orderComments!.trim().isNotEmpty;
        debugPrint('[order-comments] detail visible=$visible id=${job.id}');
      }
    }
    final titleText = job.title.resolveLang(locale.languageCode);
    final hasImage = job.imagePath.trim().isNotEmpty;
    final pickupCoords = job.pickupLat != null && job.pickupLng != null
        ? '(${job.pickupLat!.toStringAsFixed(6)}, ${job.pickupLng!.toStringAsFixed(6)})'
        : null;
    final wideLayout = MediaQuery.sizeOf(context).width >=
        _CourierJobDetailPalette.wideLayoutMinWidth;
    final showAuctionCta = mode == _JobDetailChromeMode.courier
        ? (job.status == JobStatus.posted ||
            job.status == JobStatus.auctionLive)
        : (job.status == JobStatus.auctionLive);
    final mq = MediaQuery.of(context);
    final scrollBottomPad = (showAuctionCta
            ? _CourierJobDetailPalette.auctionCtaBarReserve
            : 24.0) +
        mq.padding.bottom;

    final isCourierViewer = mode == _JobDetailChromeMode.courier;
    final revealLogistics =
        !isCourierViewer || job.courierSeesOrderAddresses(viewer.id);
    final postAuctionWinnerFlow = job.winnerCourierId != null &&
        job.winnerCourierId!.trim().isNotEmpty &&
        (job.status == JobStatus.assigned ||
            job.status == JobStatus.pickedUp ||
            job.status == JobStatus.delivered ||
            job.status == JobStatus.completed);
    final showLosingCourierAuctionEnd =
        isCourierViewer && !revealLogistics && postAuctionWinnerFlow;
    final showWinnerOutcomeCard = postAuctionWinnerFlow &&
        (mode == _JobDetailChromeMode.senderOwn ||
            (mode == _JobDetailChromeMode.courier &&
                job.winnerCourierId == viewer.id));
    if (kDebugMode) {
      final u = job.contactsBetweenSenderAndWinner(viewer.id);
      debugPrint(
        '[contact-visibility] order=${job.id} user=${viewer.id} role=${viewer.role} '
        'canSeeSender=${u && viewer.id == job.winnerCourierId} '
        'canSeeCourier=${u && viewer.id == job.senderId} revealLogistics=$revealLogistics',
      );
    }

    final JobMapCourierNavLeg? embedNavLeg =
        _detailEmbedNavLeg(job, viewer, mode);
    final showCourierEmbedMap = embedNavLeg != null &&
        _courierEmbedMapCoordsOk(job, embedNavLeg) &&
        (mode == _JobDetailChromeMode.courier ||
            _senderEmbedMapVisible(job, embedNavLeg, viewer.id));
    final embedAllowDeviceCourierGps =
        mode != _JobDetailChromeMode.senderOwn;
    final LatLng? embedServerCourier = mode == _JobDetailChromeMode.senderOwn
        ? _jobCourierLatLng(job)
        : null;

    final children = <Widget>[
      _CourierDetailCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.productPhoto,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _CourierJobDetailPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _CourierJobDetailPalette.accentTeal,
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  children: [
                    JobImageDetailPreview(
                      imageRef: job.imagePath,
                      maxHeight: 96,
                      borderRadius: 0,
                    ),
                    if (!hasImage)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                        child: Text(
                          l10n.jobDetailNoProductImage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _CourierJobDetailPalette.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 4),
      if (job.status == JobStatus.auctionLive) ...[
        _CourierDetailCard(
          child: _jobAuctionLiveDetailCard(
            job: job,
            locale: locale,
            l10n: l10n,
          ),
        ),
        const SizedBox(height: 4),
      ],
      if (showWinnerOutcomeCard) ...[
        _orderWinnerOutcomeCard(job, locale, l10n),
        const SizedBox(height: 4),
      ],
      if (showLosingCourierAuctionEnd) ...[
        _CourierDetailCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.auctionStatusEnded,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _CourierJobDetailPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.auctionEndedOtherWinnerBody,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: _CourierJobDetailPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
      _CourierDetailCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.jobDetailProductInfoTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _CourierJobDetailPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            _courierMetricRow(
              icon: Icons.edit_note_outlined,
              label: l10n.productNameLabel,
              value: titleText,
            ),
            _courierMetricRow(
              icon: Icons.payments_outlined,
              label: l10n.auctionStartPriceLabel,
              value: _fmtJobPriceUz(job.startPriceCents, locale),
              valueBold: true,
            ),
            _courierMetricRow(
              icon: Icons.inventory_2_outlined,
              label: l10n.stepProduct,
              value: job.productType.resolveLang(locale.languageCode),
            ),
            _courierMetricRow(
              icon: Icons.scale_outlined,
              label: l10n.weightKg,
              value: _fmtWeightKg(job),
            ),
            _courierMetricRow(
              icon: Icons.view_in_ar_outlined,
              label: l10n.jobDetailVolumeShort,
              value: _fmtVolumeL(job),
            ),
            _courierMetricRow(
              icon: Icons.straighten_outlined,
              label: l10n.jobDimensionsMm,
              value: _fmtDims(job),
            ),
            if (_jobVolumeCategoryLabel(job, l10n) != null)
              _courierMetricRow(
                icon: Icons.category_outlined,
                label: l10n.volumeCategoryLabel,
                value: _jobVolumeCategoryLabel(job, l10n)!,
              ),
            _courierMetricRow(
              icon: Icons.account_balance_wallet_outlined,
              label: l10n.paymentType,
              value: _jobPaymentTypeLabel(job, l10n),
              showDividerBelow: false,
            ),
            if (job.transportType.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '${l10n.orderRequiredTransportTitle}: ${JobTransportType.displayLabelsJoined(l10n, job.transportType)}',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: _CourierJobDetailPalette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_jobAdminRegionDistrictUz(job) != null) ...[
              const SizedBox(height: 6),
              Text(
                _jobAdminRegionDistrictUz(job)!,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: _CourierJobDetailPalette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (job.fragile || job.coldChain) ...[
              const SizedBox(height: 6),
              Text(
                [
                  if (job.fragile) l10n.fragileItem,
                  if (job.coldChain) l10n.needsColdChain,
                ].join(' · '),
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: _CourierJobDetailPalette.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            _courierMetricRow(
              icon: Icons.schedule_outlined,
              label: l10n.deliveryTimeTitle,
              value: _jobDetailDeliverySummary(job, l10n),
            ),
            _courierMetricRow(
              icon: Icons.flag_outlined,
              label: l10n.senderProfileStatusLabel,
              value: jobStatusLabel(job.status, l10n),
            ),
            _courierMetricRow(
              icon: Icons.event_outlined,
              label: l10n.courierCardCreated,
              value: _jobDetailCreatedAtText(job, locale),
              showDividerBelow: false,
            ),
          ],
        ),
      ),
      const SizedBox(height: 4),
      if (job.orderComments != null &&
          job.orderComments!.trim().isNotEmpty) ...[
        _CourierDetailCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.orderCommentsLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _CourierJobDetailPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                job.orderComments!.trim(),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: _CourierJobDetailPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
      _courierPickupDropoffSection(
        job: job,
        locale: locale,
        l10n: l10n,
        pickupCoords: pickupCoords,
        revealAddresses: revealLogistics,
        onAddressesLocked: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.orderAddressesHiddenForNonWinner)),
          );
        },
        onOpenMap: () => _openCourierJobRouteMap(
              job,
              l10n,
              courierNavLeg: embedNavLeg,
              allowDeviceCourierGps: embedAllowDeviceCourierGps,
              serverCourierLatLng: embedServerCourier,
            ),
      ),
      const SizedBox(height: 4),
    ];

    if (mode == _JobDetailChromeMode.senderOwn) {
      children.add(_courierRecipientOnlyCard(job, l10n));
      children.add(const SizedBox(height: 4));
      if (contactsUnlocked && job.winnerCourierId != null) {
        children.add(
          FutureBuilder<AppUser?>(
            future: ref
                .read(userRepositoryProvider.future)
                .then((r) => r.getUser(job.winnerCourierId!)),
            builder: (context, snap) {
              final c = snap.data;
              return _CourierDetailCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.orderContactSectionTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _CourierJobDetailPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (c == null)
                      Text(
                        l10n.loading,
                        style: const TextStyle(
                          color: _CourierJobDetailPalette.textSecondary,
                        ),
                      )
                    else
                      _courierWinnerContactBody(c, l10n),
                  ],
                ),
              );
            },
          ),
        );
        children.add(const SizedBox(height: 4));
      }
    }

    if (mode == _JobDetailChromeMode.courier &&
        contactsUnlocked &&
        job.winnerCourierId == viewer.id) {
      children.add(
        FutureBuilder<AppUser?>(
          future: ref
              .read(userRepositoryProvider.future)
              .then((r) => r.getUser(job.senderId)),
          builder: (context, snap) {
            final s = snap.data;
            return _CourierDetailCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.orderContactSectionTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _CourierJobDetailPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (s == null)
                    Text(
                      l10n.loading,
                      style: const TextStyle(
                        color: _CourierJobDetailPalette.textSecondary,
                      ),
                    )
                  else
                    _courierSenderRecipientInner(
                      sender: s,
                      job: job,
                      l10n: l10n,
                      wideLayout: wideLayout,
                    ),
                ],
              ),
            );
          },
        ),
      );
      children.add(const SizedBox(height: 4));
    }

    children.add(
      _CourierDetailCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.jobDescriptionLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _CourierJobDetailPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              job.description.resolveLang(locale.languageCode),
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: _CourierJobDetailPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
    children.add(const SizedBox(height: 8));

    if (showCourierEmbedMap) {
      children.add(
        _CourierDetailCard(
          child: InkWell(
            onTap: () => _openCourierJobRouteMap(
              job,
              l10n,
              courierNavLeg: embedNavLeg,
              allowDeviceCourierGps: embedAllowDeviceCourierGps,
              serverCourierLatLng: embedServerCourier,
            ),
            borderRadius: BorderRadius.circular(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 20,
                        color: _CourierJobDetailPalette.accentTeal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          embedNavLeg == JobMapCourierNavLeg.toPickup
                              ? l10n.courierJobMapToPickupTitle
                              : l10n.courierJobMapToDropoffTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _CourierJobDetailPalette.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                JobPickupDropoffMapPage(
                  key: ValueKey<String>(
                    'courier_embed_${job.id}_${job.status.name}_'
                    '${embedNavLeg.name}_${mode.name}_'
                    '${embedServerCourier?.latitude ?? 0}_'
                    '${embedServerCourier?.longitude ?? 0}',
                  ),
                  pickup: LatLng(job.pickupLat!, job.pickupLng!),
                  dropoff: job.dropoffLat != null && job.dropoffLng != null
                      ? LatLng(job.dropoffLat!, job.dropoffLng!)
                      : null,
                  courierNavLeg: embedNavLeg,
                  embedHeight: 220,
                  allowDeviceCourierGps: embedAllowDeviceCourierGps,
                  serverCourierLatLng: embedServerCourier,
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      );
      children.add(const SizedBox(height: 8));
    }

    void addSpacing() => children.add(const SizedBox(height: 8));

    // Kuryer va yuboruvchi: bitta marshrut xaritasi [JobPickupDropoffMapPage] embed.

    if (mode == _JobDetailChromeMode.courier &&
        job.winnerCourierId == viewer.id &&
        job.status == JobStatus.assigned) {
      children.add(
        FilledButton(
          style: _courierFilledStyle(),
          onPressed: () async {
            final repo = await ref.read(jobRepositoryProvider.future);
            try {
              await repo.markPickedUp(jobId: job.id, courierId: viewer.id);
              ref.invalidate(jobPollProvider(job.id));
              ref.invalidate(courierJobsProvider);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$e')),
                );
              }
            }
          },
          child: Text(l10n.markPickedUp),
        ),
      );
      addSpacing();
    }

    final gpsBlocked = ref.watch(courierTrackingGpsBlockedProvider);
    if (mode == _JobDetailChromeMode.courier &&
        job.winnerCourierId == viewer.id &&
        (job.status == JobStatus.assigned ||
            job.status == JobStatus.pickedUp ||
            job.status == JobStatus.delivered)) {
      children.add(
        _CourierDetailCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                gpsBlocked
                    ? Icons.location_off_rounded
                    : Icons.my_location_rounded,
                color: gpsBlocked
                    ? const Color(0xFFB45309)
                    : _CourierJobDetailPalette.accentTeal,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  gpsBlocked
                      ? l10n.courierTrackingLocationPermissionDenied
                      : l10n.courierTrackingSendingLabel,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: gpsBlocked
                        ? const Color(0xFFB45309)
                        : _CourierJobDetailPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      addSpacing();
    }

    if (mode == _JobDetailChromeMode.courier &&
        job.winnerCourierId == viewer.id &&
        job.status == JobStatus.pickedUp) {
      children.add(
        TextField(
          controller: _noteCtrl,
          decoration: InputDecoration(
            labelText: l10n.deliveryNoteOptional,
            filled: true,
            fillColor: _CourierJobDetailPalette.cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          maxLines: 2,
        ),
      );
      addSpacing();
      children.add(
        FilledButton(
          style: _courierFilledStyle(),
          onPressed: () async {
            final repo = await ref.read(jobRepositoryProvider.future);
            try {
              await repo.markDelivered(
                jobId: job.id,
                courierId: viewer.id,
                note: _noteCtrl.text.trim().isEmpty
                    ? null
                    : _noteCtrl.text.trim(),
              );
              ref.invalidate(jobPollProvider(job.id));
              ref.invalidate(courierJobsProvider);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$e')),
                );
              }
            }
          },
          child: Text(l10n.markDelivered),
        ),
      );
      addSpacing();
    }

    if (mode == _JobDetailChromeMode.senderOwn &&
        job.status == JobStatus.delivered) {
      children.add(
        FilledButton(
          style: _courierFilledStyle(),
          onPressed: () async {
            final repo = await ref.read(jobRepositoryProvider.future);
            try {
              await repo.markCompleted(jobId: job.id, senderId: viewer.id);
              ref.invalidate(senderJobsProvider(viewer.id));
              ref.invalidate(jobPollProvider(job.id));
              ref.invalidate(courierJobsProvider);
              ref.invalidate(
                myOrderFeedbackProvider((orderId: job.id, userId: viewer.id)),
              );
              ref.invalidate(
                userSubmittedFeedbackForJobProvider(
                  (jobId: job.id, userId: viewer.id),
                ),
              );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$e')),
                );
              }
            }
          },
          child: Text(l10n.statusCompleted),
        ),
      );
      addSpacing();
    }

    children.add(
      OrderFeedbackDetailSection(
        job: job,
        viewerId: viewer.id,
        l10n: l10n,
        courierChrome: true,
      ),
    );

    if (kDebugMode) {
      final tags = <String>[];
      if (mode == _JobDetailChromeMode.courier &&
          job.winnerCourierId == viewer.id &&
          job.status == JobStatus.assigned) {
        tags.add('markPickedUp');
      }
      if (mode == _JobDetailChromeMode.courier &&
          job.winnerCourierId == viewer.id &&
          job.status == JobStatus.pickedUp) {
        tags.add('markDelivered');
      }
      if (mode == _JobDetailChromeMode.senderOwn &&
          job.status == JobStatus.delivered) {
        tags.add('markCompleted');
      }
      if (tags.isNotEmpty) {
        debugPrint(
          '[detail-actions] order=${job.id} visibleActions=${tags.join(",")}',
        );
      }
    }

    return SafeArea(
      bottom: false,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 4, 16, scrollBottomPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
          if (showAuctionCta)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: _CourierJobDetailPalette.pageBg,
              elevation: 12,
              shadowColor: const Color(0x33000000),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: FilledButton.icon(
                    style: _courierAuctionFilledStyle(),
                    onPressed: () => context.push(AppRoutes.jobAuction(job.id)),
                    icon: const Icon(Icons.gavel_rounded),
                    label: Text(
                      job.status == JobStatus.posted &&
                              mode == _JobDetailChromeMode.courier
                          ? l10n.joinAuctionCta
                          : l10n.statusAuction,
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

  Widget _sectionTitle(BuildContext context, String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        t,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

}

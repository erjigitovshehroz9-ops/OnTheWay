import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/job_entity.dart';
import '../../../../models/job_status.dart';
import '../../../../models/job_transport_type.dart';
import '../../../../shared/utils/job_status_l10n.dart';
import '../../../../shared/widgets/job_image.dart';

/// Transport ikonkalari va min. stavka — neytral kulrang.
const Color _kSenderOrderSecondaryGrey = Color(0xFF6B7280);

/// Asosiy narx rangi.
const Color _kSenderOrderPriceColor = Color(0xFF1F305E);

/// Yuboruvchi buyurtma kartasi — thumbnail, sarlavha, marshrut, status va narx.
class SenderOrderCard extends StatelessWidget {
  const SenderOrderCard({
    super.key,
    required this.job,
    required this.locale,
    required this.viewerId,
    required this.onOpen,
  });

  final JobEntity job;
  final Locale locale;
  final String viewerId;
  final VoidCallback onOpen;

  static const _thumb = 68.0;
  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final title = job.title.resolveLang(locale.languageCode);
    final contactsOk = job.contactsBetweenSenderAndWinner(viewerId);
    final statusLabel = job.status == JobStatus.posted
        ? l10n.senderOrderStatusPosted
        : jobStatusLabel(job.status, l10n);
    final statusAccent = switch (job.status) {
      JobStatus.posted => AppColors.primaryBlue,
      JobStatus.auctionLive => const Color(0xFF4F46E5),
      JobStatus.assigned => const Color(0xFF1D4ED8),
      JobStatus.pickedUp => const Color(0xFFF59E0B),
      JobStatus.delivered => const Color(0xFF22C55E),
      JobStatus.completed => const Color(0xFF16A34A),
      JobStatus.cancelled => const Color(0xFFE11D48),
    };

    final nf = NumberFormat.decimalPattern(locale.languageCode);
    final currentCents = job.finalPriceCents ?? job.startPriceCents;
    final currentSom = (currentCents / 100).round();
    final currentText = '${_formatSomDigitsSpaceGrouped(currentSom)} so\'m';
    final floorText = '${nf.format((job.floorPriceCents / 100).round())} so\'m';

    final routeText = _senderFormattedRoute(job, locale);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
        onTap: onOpen,
        splashColor: statusAccent.withValues(alpha: 0.08),
        highlightColor: statusAccent.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: const Color(0xFFE8EEF5)),
            boxShadow: [
              const BoxShadow(
                color: Color(0x08000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: statusAccent.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumbnail(imageRef: job.imagePath),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _SoftBadge(
                            label: statusLabel,
                            foreground: statusAccent,
                            background: statusAccent.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        routeText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF1E293B),
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SenderTransportIconsRow(
                              stored: job.transportType,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currentText,
                                textAlign: TextAlign.end,
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 23,
                                  height: 1.05,
                                  letterSpacing: 0.2,
                                  color: _kSenderOrderPriceColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$floorText ${l10n.senderOrderMinStavkaSuffix}',
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _kSenderOrderSecondaryGrey,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10.5,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE8EEF5),
                      ),
                      const SizedBox(height: 10),
                      _ContactsHint(
                        contactsOk: contactsOk,
                        l10n: l10n,
                      ),
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

/// Masalan `4 073` — mingliklar orasida bo‘shliq (rasmdagi narx ko‘rinishi).
String _formatSomDigitsSpaceGrouped(int amount) {
  final neg = amount < 0;
  final s = (neg ? -amount : amount).toString();
  final buf = StringBuffer();
  if (neg) buf.write('-');
  final len = s.length;
  for (var i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// `Toshkent sh.` yoki `Samarqand vil, Bulungur tum.` — ikkala nuqta ham bir xil qoida.
String _senderFormattedRoute(JobEntity job, Locale locale) {
  final a = _formatSenderLocationPoint(job.pickupRegion, job.pickupDistrictOrCity);
  final b = _formatSenderLocationPoint(job.dropoffRegion, job.dropoffDistrictOrCity);
  if (a != null && b != null) return _stripShAfterTuman('$a — $b');
  if (a != null) return _stripShAfterTuman(a);
  if (b != null) return _stripShAfterTuman(b);
  final pickupText = job.pickupAddress.resolveLang(locale.languageCode);
  final dropoffText = job.dropoffAddress.resolveLang(locale.languageCode);
  return '$pickupText → $dropoffText';
}

String? _formatSenderLocationPoint(String? region, String? district) {
  final r = (region ?? '').trim();
  final d = (district ?? '').trim();
  if (r.isEmpty && d.isEmpty) return null;
  final blob = '$r $d';
  if (RegExp(r'viloyati|viloyat', caseSensitive: false).hasMatch(blob)) {
    var vil = r;
    var tum = d;
    vil = vil.replaceAll(RegExp(r'viloyati', caseSensitive: false), '');
    vil = vil.replaceAll(RegExp(r'viloyat', caseSensitive: false), '');
    vil = vil.trim();
    tum = tum.replaceAll(RegExp(r'tumani', caseSensitive: false), '');
    tum = tum.replaceAll(RegExp(r'tuman', caseSensitive: false), '');
    tum = tum.trim();
    if (vil.isNotEmpty && tum.isNotEmpty) return '$vil vil, $tum tum.';
    if (vil.isNotEmpty) return '$vil vil.';
    if (tum.isNotEmpty) return '$tum tum.';
  }
  var city = r.isNotEmpty ? r : d;
  if (RegExp(r'tumani|tuman', caseSensitive: false).hasMatch(city)) {
    var tum = city.replaceAll(RegExp(r'tumani', caseSensitive: false), '');
    tum = tum.replaceAll(RegExp(r'tuman', caseSensitive: false), '');
    tum = tum.trim();
    if (tum.isNotEmpty) return '$tum tum.';
  }
  city = city.replaceAll(RegExp(r'shahri', caseSensitive: false), '').trim();
  final comma = city.indexOf(',');
  if (comma > 0) city = city.substring(0, comma).trim();
  if (city.isEmpty) city = r.isNotEmpty ? r : d;
  return '$city sh.';
}

/// `… tum. sh.` yoki `… tumani sh.` kabi noto‘g‘ri qo‘shmalarni olib tashlaydi.
String _stripShAfterTuman(String s) {
  return s
      .replaceAll(RegExp(r'tum\.\s*sh\.', caseSensitive: false), 'tum.')
      .replaceAll(RegExp(r'tumani\s*sh\.', caseSensitive: false), 'tumani')
      .replaceAll(RegExp(r'tum\.\s*shahri', caseSensitive: false), 'tum.')
      .replaceAll(RegExp(r'tumani\s*shahri', caseSensitive: false), 'tumani');
}

class _SenderTransportIconsRow extends StatelessWidget {
  const _SenderTransportIconsRow({required this.stored});

  final String stored;

  @override
  Widget build(BuildContext context) {
    final keys = JobTransportType.normalizedJobTransportKeysFromStored(stored);
    if (keys.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final k in keys)
          Icon(
            JobTransportType.tryParse(k)?.icon ?? Icons.local_shipping_outlined,
            size: 22,
            color: _kSenderOrderSecondaryGrey,
          ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imageRef});

  final String imageRef;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: SenderOrderCard._thumb,
      height: SenderOrderCard._thumb,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        border: Border.all(color: const Color(0xFFE8EEF5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageRef.trim().isEmpty
          ? Icon(
              Icons.inventory_2_outlined,
              size: 28,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
            )
          : JobImageThumbnail(
              imageRef: imageRef,
              size: SenderOrderCard._thumb,
              borderRadius: 0,
            ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
          height: 1.1,
          color: foreground,
        ),
      ),
    );
  }
}

/// «Kutilmoqda» status nishanchasi bilan bir xil shrift va ko‘k rang.
class _ContactsHint extends StatelessWidget {
  const _ContactsHint({
    required this.contactsOk,
    required this.l10n,
  });

  final bool contactsOk;
  final AppLocalizations l10n;

  static final _kTextStyle = GoogleFonts.montserrat(
    fontWeight: FontWeight.w600,
    fontSize: 11.5,
    height: 1.1,
    color: AppColors.primaryBlue,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          contactsOk ? Icons.visibility_rounded : Icons.visibility_off_outlined,
          size: 15,
          color: AppColors.primaryBlue.withValues(alpha: 0.85),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            contactsOk ? l10n.contactsVisibleAfterWinner : l10n.senderOrderContactsHint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _kTextStyle,
          ),
        ),
      ],
    );
  }
}

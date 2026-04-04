import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import 'create_job_confirm_thumb_file_stub.dart'
    if (dart.library.io) 'create_job_confirm_thumb_file_io.dart' as confirm_thumb;

/// Buyurtma yaratish — oxirgi bosqich: rasmdagiga yaqin tasdiqlash kartochkasi.
class CreateJobConfirmPanel extends StatelessWidget {
  const CreateJobConfirmPanel({
    super.key,
    this.scrollController,
    required this.l10n,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.distanceKmFormatted,
    required this.pickupTimeLine,
    required this.deliveryTimeLine,
    this.productName,
    required this.packageType,
    required this.packageSize,
    required this.packageWeight,
    required this.packageDescription,
    this.packageOrderComments,
    required this.priceFormatted,
    this.imagePath,
    this.imagePreviewBytes,
  });

  final ScrollController? scrollController;
  final AppLocalizations l10n;
  final String pickupAddress;
  final String dropoffAddress;
  final String? distanceKmFormatted;
  final String pickupTimeLine;
  final String deliveryTimeLine;
  final String? productName;
  final String packageType;
  final String packageSize;
  final String packageWeight;
  final String packageDescription;
  final String? packageOrderComments;
  final String priceFormatted;
  final String? imagePath;
  final Uint8List? imagePreviewBytes;

  static const Color _navy = Color(0xFF1A2B5F);
  static const Color _labelGrey = Color(0xFF64748B);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _divider = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8EEF4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AddressChain(
                l10n: l10n,
                pickupAddress: pickupAddress,
                dropoffAddress: dropoffAddress,
                imagePath: imagePath,
                imagePreviewBytes: imagePreviewBytes,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, thickness: 1, color: _divider),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.mapDistanceLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: _labelGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.directions_car_outlined,
                              size: 20,
                              color: _navy.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                distanceKmFormatted ?? '—',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: _textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.createJobDeliveryTimeSection,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: _labelGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _TimeRow(icon: Icons.schedule_outlined, text: '${l10n.createJobPickupSlotLabel}: $pickupTimeLine'),
                        const SizedBox(height: 6),
                        _TimeRow(icon: Icons.schedule_outlined, text: '${l10n.createJobDeliverySlotLabel}: $deliveryTimeLine'),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, thickness: 1, color: _divider),
              ),
              Text(
                l10n.createJobAboutPackage,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  letterSpacing: -0.2,
                ),
              ),
              if (productName != null && productName!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  productName!.trim(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _InfoGrid(
                l10n: l10n,
                type: packageType,
                size: packageSize,
                weight: packageWeight,
                description: packageDescription,
              ),
              if (packageOrderComments != null &&
                  packageOrderComments!.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  l10n.orderCommentsLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _labelGrey,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  packageOrderComments!.trim(),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _textDark,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _navy.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.createJobEstimatedPrice,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      priceFormatted,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.createJobFinalPriceDisclaimer,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF475569)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  height: 1.3,
                ),
          ),
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({
    required this.l10n,
    required this.type,
    required this.size,
    required this.weight,
    required this.description,
  });

  final AppLocalizations l10n;
  final String type;
  final String size;
  final String weight;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: const Color(0xFF64748B),
      fontWeight: FontWeight.w600,
    );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: const Color(0xFF0F172A),
    );

    Widget cell(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 4),
            Text(value.isEmpty ? '—' : value, style: valueStyle),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cell(l10n.createJobPackageTypeShort, type)),
            Expanded(child: cell(l10n.createJobPackageSizeShort, size)),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cell(l10n.createJobPackageWeightShort, weight)),
            Expanded(child: cell(l10n.createJobPackageDescShort, description)),
          ],
        ),
      ],
    );
  }
}

class _AddressChain extends StatelessWidget {
  const _AddressChain({
    required this.l10n,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.imagePath,
    this.imagePreviewBytes,
  });

  final AppLocalizations l10n;
  final String pickupAddress;
  final String dropoffAddress;
  final String? imagePath;
  final Uint8List? imagePreviewBytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pickup = pickupAddress.trim().isEmpty ? '—' : pickupAddress.trim();
    final drop = dropoffAddress.trim().isEmpty ? '—' : dropoffAddress.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _BoxThumbnail(
              imagePath: imagePath,
              imagePreviewBytes: imagePreviewBytes,
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 22,
              height: 32,
              child: CustomPaint(
                painter: _VerticalDottedLinePainter(color: const Color(0xFF94A3B8)),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.35)),
              ),
              child: const Icon(Icons.map_outlined, color: Color(0xFF1D4ED8), size: 22),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.createJobSenderAddressLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pickup,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                l10n.createJobReceiverAddressLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                drop,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BoxThumbnail extends StatelessWidget {
  const _BoxThumbnail({this.imagePath, this.imagePreviewBytes});

  final String? imagePath;
  final Uint8List? imagePreviewBytes;

  @override
  Widget build(BuildContext context) {
    final bytes = imagePreviewBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
        ),
      );
    }
    final path = imagePath?.trim() ?? '';
    if (!kIsWeb && path.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: confirm_thumb.buildConfirmThumbFile(path),
      );
    }
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4DDE8)),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: Colors.brown.shade400,
        size: 28,
      ),
    );
  }
}

class _VerticalDottedLinePainter extends CustomPainter {
  _VerticalDottedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(cx, y), Offset(cx, y + 3), paint);
      y += 7;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDottedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

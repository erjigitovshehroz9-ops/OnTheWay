import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/job_transport_type.dart';
import 'transport_icon_chip.dart';

const Color _kOrderTransportErrorRed = Color(0xFFE11D48);

/// Buyurtma: bitta tur ([singleSelect]=true) yoki kuryer ro‘yxati uchun ko‘p tanlov.
class OrderTransportSelector extends StatelessWidget {
  const OrderTransportSelector({
    super.key,
    required this.l10n,
    required this.selectedStorageKeys,
    required this.onToggle,
    required this.showValidationError,
    this.singleSelect = false,
  });

  final AppLocalizations l10n;
  final Set<String> selectedStorageKeys;
  final ValueChanged<String> onToggle;
  final bool showValidationError;
  final bool singleSelect;

  bool get _missing => selectedStorageKeys.isEmpty;

  bool get _showError => showValidationError && _missing;

  @override
  Widget build(BuildContext context) {
    final options = JobTransportType.values;
    final title = singleSelect
        ? l10n.orderRequiredTransportTitle
        : l10n.orderSuitableTransportTitle;
    final errorText = singleSelect
        ? l10n.validationSelectOneTransport
        : l10n.validationSelectSuitableTransport;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: Theme.of(context).inputDecorationTheme.labelStyle ??
                TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            children: [
              TextSpan(
                text: title,
                style: denseLabelStyle(context),
              ),
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: _showError ? const Color(0xFFFFEEF2) : const Color(0xFFF9FBFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _showError ? _kOrderTransportErrorRed : const Color(0xFFDCE8FF),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useWrap = constraints.maxWidth < 340;
                final children = <Widget>[];
                for (final t in options) {
                  final selected = selectedStorageKeys.contains(t.storageKey);
                  final cell = Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onToggle(t.storageKey),
                        borderRadius: BorderRadius.circular(14),
                        splashColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
                        highlightColor: const Color(0xFF2563EB).withValues(alpha: 0.06),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TransportIconChip(
                                interactive: false,
                                icon: t.icon,
                                selected: selected,
                                dense: true,
                                onTap: () => onToggle(t.storageKey),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                t.label(l10n),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      height: 1.1,
                                      color: selected
                                          ? const Color(0xFF1D4ED8)
                                          : const Color(0xFF475569),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                  if (useWrap) {
                    children.add(
                      SizedBox(
                        width: (constraints.maxWidth - 4) / 2,
                        child: cell,
                      ),
                    );
                  } else {
                    children.add(Expanded(child: cell));
                  }
                }
                if (useWrap) {
                  return Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    runSpacing: 6,
                    children: children,
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                );
              },
            ),
          ),
        ),
        if (_showError) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(
              color: _kOrderTransportErrorRed,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  static TextStyle? denseLabelStyle(BuildContext context) {
    final base = Theme.of(context).inputDecorationTheme.labelStyle ??
        TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color);
    return base.copyWith(fontSize: (base.fontSize ?? 14) * 0.92);
  }
}

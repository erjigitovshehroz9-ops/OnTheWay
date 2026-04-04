import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/volume_category.dart';

// --- Theme -----------------------------------------------------------------

InputDecorationTheme wizardInputDecorationTheme(ColorScheme scheme) {
  const radius = 14.0;
  const defaultGrey = Color(0xFFCBD5E1);
  const disabledGrey = Color(0xFFD8DEE6);

  return InputDecorationTheme(
    filled: true,
    fillColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return const Color(0xFFF1F5F9);
      }
      return const Color(0xFFFFFFFF);
    }),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: WidgetStateTextStyle.resolveWith((states) {
      final base = scheme.onSurfaceVariant.withValues(alpha: 0.65);
      if (states.contains(WidgetState.disabled)) {
        return TextStyle(color: base.withValues(alpha: 0.45), fontSize: 14);
      }
      return TextStyle(color: base, fontSize: 14);
    }),
    labelStyle: WidgetStateTextStyle.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.38),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        );
      }
      return TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );
    }),
    floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.38),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        );
      }
      final c = states.contains(WidgetState.error)
          ? scheme.error
          : AppColors.primaryBlue;
      return TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 13);
    }),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: WidgetStateBorderSide.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const BorderSide(color: disabledGrey, width: 1);
        }
        if (states.contains(WidgetState.error)) {
          if (states.contains(WidgetState.focused)) {
            return BorderSide(color: scheme.error, width: 1.35);
          }
          return BorderSide(
            color: scheme.error.withValues(alpha: 0.78),
            width: 1.1,
          );
        }
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(color: AppColors.primaryBlue, width: 1.65);
        }
        return const BorderSide(color: defaultGrey, width: 1.05);
      }),
    ),
    errorStyle: TextStyle(
      color: scheme.error,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.3,
    ),
  );
}

// --- Stepper ---------------------------------------------------------------

class CreateJobWizardStepper extends StatelessWidget {
  const CreateJobWizardStepper({
    super.key,
    required this.currentStep,
    required this.labels,
  });

  final int currentStep;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final n = labels.length;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < n; i++)
              Expanded(
                child: _WizardStepColumn(
                  stepIndex: i,
                  totalSteps: n,
                  label: labels[i],
                  currentStep: currentStep,
                  compact: compact,
                  scheme: scheme,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WizardStepColumn extends StatelessWidget {
  const _WizardStepColumn({
    required this.stepIndex,
    required this.totalSteps,
    required this.label,
    required this.currentStep,
    required this.compact,
    required this.scheme,
  });

  final int stepIndex;
  final int totalSteps;
  final String label;
  final int currentStep;
  final bool compact;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final done = stepIndex < currentStep;
    final active = stepIndex == currentStep;
    final r = compact ? 11.0 : 12.5;
    final diameter = r * 2;
    // Ring/soya uchun barcha ustunlarda bir xil keng slot (1 va 4 ham tekis).
    final circleSlotW = diameter + 6;
    // Bir xil balandlik: barcha qadamlar vertikal tekis.
    final trackH = compact ? 34.0 : 38.0;

    final circleColor = done
        ? AppColors.accentGreen
        : active
            ? AppColors.primaryBlue
            : const Color(0xFFE2E8F0);
    final ringColor = active && !done ? AppColors.primaryBlue : Colors.transparent;
    final fg = done || active ? Colors.white : const Color(0xFF475569);

    /// Har bir ustunda bir xil: [Expanded | doira | Expanded] — 1 va 4 ham markazda,
    /// chiziqlar `Center` bilan doira markaziga tekislanadi.
    Widget horizontalLine({required bool isLeft, required bool filled}) {
      return Center(
        child: Container(
          height: 2,
          margin: EdgeInsets.only(
            right: isLeft ? 2 : 0,
            left: isLeft ? 0 : 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: filled
                ? AppColors.primaryBlue.withValues(alpha: 0.35)
                : const Color(0xFFE2E8F0),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: trackH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: stepIndex > 0
                    ? horizontalLine(
                        isLeft: true,
                        filled: stepIndex <= currentStep,
                      )
                    : const SizedBox.shrink(),
              ),
              SizedBox(
                width: circleSlotW,
                height: trackH,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: diameter,
                    height: diameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleColor,
                      border: Border.all(
                        color: ringColor,
                        width: active && !done ? 2.5 : 0,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(alpha: 0.18),
                                blurRadius: 5,
                                offset: Offset.zero,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: done
                          ? Icon(Icons.check_rounded, size: compact ? 14 : 16, color: Colors.white)
                          : Text(
                              '${stepIndex + 1}',
                              style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w800,
                                fontSize: compact ? 11.5 : 12.5,
                                height: 1,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: stepIndex < totalSteps - 1
                    ? horizontalLine(
                        isLeft: false,
                        filled: (stepIndex + 1) <= currentStep,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 6 : 7),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  fontSize: compact ? 9.75 : 10.25,
                  height: 1.15,
                  letterSpacing: compact ? -0.2 : -0.12,
                  color: active
                      ? const Color(0xFF0F172A)
                      : scheme.onSurfaceVariant.withValues(alpha: done ? 0.78 : 0.58),
                ),
          ),
        ),
      ],
    );
  }
}

// --- Volume chips ----------------------------------------------------------

class WizardVolumeSelector extends StatelessWidget {
  const WizardVolumeSelector({
    super.key,
    required this.l10n,
    required this.selected,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final VolumeCategory selected;
  final ValueChanged<VolumeCategory> onChanged;

  String _label(VolumeCategory c) {
    return switch (c) {
      VolumeCategory.small => l10n.volumeCatSmall,
      VolumeCategory.medium => l10n.volumeCatMedium,
      VolumeCategory.large => l10n.volumeCatLarge,
      VolumeCategory.veryLarge => l10n.volumeCatVeryLarge,
    };
  }

  @override
  Widget build(BuildContext context) {
    const gap = 6.0;
    final cats = VolumeCategory.values;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < cats.length; i++) ...[
          if (i > 0) const SizedBox(width: gap),
          Expanded(
            child: _VolumeChip(
              label: _label(cats[i]),
              selected: selected == cats[i],
              onTap: () => onChanged(cats[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _VolumeChip extends StatelessWidget {
  const _VolumeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _chipH = 48;
  static const double _hPad = 8;

  @override
  Widget build(BuildContext context) {
    const defaultBorder = Color(0xFFCBD5E1);

    return LayoutBuilder(
      builder: (context, c) {
        const iconSize = 18.0;
        const afterIconGap = 4.0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: _chipH,
                maxHeight: _chipH,
                maxWidth: c.maxWidth,
              ),
              padding: const EdgeInsets.symmetric(horizontal: _hPad),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryBlue.withValues(alpha: 0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? AppColors.primaryBlue.withValues(alpha: 0.55)
                      : defaultBorder,
                  width: selected ? 1.35 : 1.05,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? AppColors.primaryBlue.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: selected ? 8 : 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    const Icon(
                      Icons.check_circle_rounded,
                      size: iconSize,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: afterIconGap),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                            color: selected ? const Color(0xFF1E40AF) : const Color(0xFF475569),
                            letterSpacing: -0.25,
                            height: 1.2,
                            fontSize: c.maxWidth < 64 ? 11.5 : null,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Location card ---------------------------------------------------------

class WizardLocationCard extends StatelessWidget {
  const WizardLocationCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.hintWhenEmpty,
    this.errorText,
    this.leadingIcon = Icons.trip_origin_rounded,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String hintWhenEmpty;
  final String? errorText;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasError = errorText != null && errorText!.trim().isNotEmpty;
    final empty = subtitle.trim().isEmpty || subtitle == '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                border: Border.all(
                  color: hasError
                      ? scheme.error.withValues(alpha: 0.85)
                      : const Color(0xFFE2E8F0),
                  width: hasError ? 1.4 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: hasError
                        ? scheme.error.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      ),
                      child: Icon(leadingIcon, color: AppColors.primaryBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                  letterSpacing: 0.1,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            empty ? hintWhenEmpty : subtitle,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: empty
                                      ? scheme.onSurfaceVariant.withValues(alpha: 0.55)
                                      : const Color(0xFF0F172A),
                                  height: 1.25,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.map_rounded, color: Color(0xFF475569), size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 16, color: scheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    errorText!,
                    style: TextStyle(
                      color: scheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// --- Bottom actions --------------------------------------------------------

class WizardBottomBar extends StatelessWidget {
  const WizardBottomBar({
    super.key,
    required this.showBack,
    required this.onBack,
    required this.backLabel,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryLoading = false,
    this.isFinalStep = false,
    this.footerHint,
    this.primaryBackground,
  });

  final bool showBack;
  final VoidCallback onBack;
  final String backLabel;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryLoading;
  final bool isFinalStep;
  /// Tasdiqlash bosqichi ostidagi izoh matni.
  final String? footerHint;
  final Color? primaryBackground;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE8EEF4))),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (footerHint != null && footerHint!.trim().isNotEmpty) ...[
                Text(
                  footerHint!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
            children: [
              if (showBack)
                OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(backLabel),
                ),
              if (showBack) const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: primaryLoading ? null : onPrimary,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryBackground ??
                        (isFinalStep ? AppColors.accentGreen : AppColors.primaryBlue),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: primaryLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          primaryLabel,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Review ----------------------------------------------------------------

class WizardReviewSectionCard extends StatelessWidget {
  const WizardReviewSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class WizardReviewRow extends StatelessWidget {
  const WizardReviewRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final v = value.trim().isEmpty ? '—' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Switches row ----------------------------------------------------------

class WizardSwitchTile extends StatelessWidget {
  const WizardSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onChanged(!value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EEF4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.primaryBlue,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nozik / sovuq switchlarni bitta qatorda, overflowsiz.
class WizardFragileColdSwitchRow extends StatelessWidget {
  const WizardFragileColdSwitchRow({
    super.key,
    required this.fragileLabel,
    required this.coldLabel,
    required this.fragile,
    required this.cold,
    required this.onFragileChanged,
    required this.onColdChanged,
  });

  final String fragileLabel;
  final String coldLabel;
  final bool fragile;
  final bool cold;
  final ValueChanged<bool> onFragileChanged;
  final ValueChanged<bool> onColdChanged;

  static Widget _compactSwitch(bool value, ValueChanged<bool> onChanged) {
    return Transform.scale(
      scale: 0.78,
      alignment: Alignment.center,
      child: Switch(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.primaryBlue,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFFCBD5E1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF334155),
          height: 1.3,
          fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) + 1,
        );

    Widget cell({
      required String title,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onChanged(!value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EEF4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ),
                const SizedBox(width: 6),
                _compactSwitch(value, onChanged),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: cell(
              title: fragileLabel,
              value: fragile,
              onChanged: onFragileChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: cell(
              title: coldLabel,
              value: cold,
              onChanged: onColdChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Section label ---------------------------------------------------------

class WizardSectionTitle extends StatelessWidget {
  const WizardSectionTitle(this.text, {super.key, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
          letterSpacing: -0.2,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: required
          ? Text.rich(
              TextSpan(
                style: style,
                children: [
                  TextSpan(text: text),
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
          : Text(
              text,
              style: style,
            ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/job_transport_type.dart';
import 'transport_icon_chip.dart';

/// Courier profil ro‘yxatidan olingan transport tanlash qatori (icon chip’lar).
/// Boshqa joylarda aynan shu UI ni qayta ishlatish uchun ajratilgan.
class CourierRegistrationTransportRow extends StatelessWidget {
  const CourierRegistrationTransportRow({
    super.key,
    required this.selected,
    required this.onToggle,
    this.showValidationError = false,
  });

  final Set<String> selected;
  final void Function(String value) onToggle;
  final bool showValidationError;

  static const Color errorRed = Color(0xFFE11D48);

  static final List<CourierTransportRegistrationOption> options =
      JobTransportType.values
          .map(
            (t) => CourierTransportRegistrationOption(
              value: t.storageKey,
              icon: t.icon,
            ),
          )
          .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final missing = showValidationError && selected.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: missing ? const Color(0xFFFFEEF2) : const Color(0xFFF9FBFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: missing ? errorRed : const Color(0xFFDCE8FF),
              width: 1.2,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: math.max(0.0, constraints.maxWidth - 4),
                    child: Row(
                      children: options.map((option) {
                        final isSelected = selected.contains(option.value);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: TransportIconChip(
                              icon: option.icon,
                              selected: isSelected,
                              dense: true,
                              onTap: () => onToggle(option.value),
                            ),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (missing) ...[
          const SizedBox(height: 6),
          const Text(
            'Kamida bitta transport turini tanlang',
            style: TextStyle(
              color: errorRed,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class CourierTransportRegistrationOption {
  const CourierTransportRegistrationOption({
    required this.value,
    required this.icon,
  });

  final String value;
  final IconData icon;
}

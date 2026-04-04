import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../l10n/generated/app_localizations.dart';

/// Kunduzgi / tungi / tizim rejimi — barcha ekranlardan ochish mumkin.
void showAppThemeBottomSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Consumer(
            builder: (context, ref, _) {
              final modeAsync = ref.watch(themeModeProvider);
              final mode = modeAsync.valueOrNull ?? ThemeMode.system;
              final scheme = Theme.of(context).colorScheme;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      l10n.createJobThemeTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  _ThemeOptionTile(
                    icon: Icons.light_mode_outlined,
                    label: l10n.createJobThemeLight,
                    selected: mode == ThemeMode.light,
                    accent: scheme.primary,
                    onTap: () async {
                      await ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                  _ThemeOptionTile(
                    icon: Icons.dark_mode_outlined,
                    label: l10n.createJobThemeDark,
                    selected: mode == ThemeMode.dark,
                    accent: scheme.primary,
                    onTap: () async {
                      await ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                  _ThemeOptionTile(
                    icon: Icons.settings_suggest_outlined,
                    label: l10n.createJobThemeSystem,
                    selected: mode == ThemeMode.system,
                    accent: scheme.primary,
                    onTap: () async {
                      await ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: selected ? accent : null),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? accent : null,
                    ),
                  ),
                ),
                if (selected) Icon(Icons.check_circle_rounded, color: accent, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

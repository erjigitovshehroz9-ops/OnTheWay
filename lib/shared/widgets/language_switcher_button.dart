import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../l10n/generated/app_localizations.dart';

class LanguageSwitcherButton extends ConsumerWidget {
  const LanguageSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeControllerProvider);
    final current = localeAsync.valueOrNull ?? const Locale('uz');
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(localeControllerProvider.notifier);
    final alternates = notifier.alternateLocales(current);

    String labelFor(Locale locale) {
      switch (locale.languageCode) {
        case 'uz':
          return l10n.languageUzbek;
        case 'ru':
          return l10n.languageRussian;
        case 'en':
          return l10n.languageEnglish;
        default:
          return locale.languageCode;
      }
    }

    return PopupMenuButton<Locale>(
      tooltip: l10n.language,
      icon: const Icon(Icons.language_rounded),
      position: PopupMenuPosition.under,
      onSelected: (locale) async {
        await notifier.setLocale(locale);
      },
      itemBuilder: (context) {
        return alternates
            .map(
              (locale) => PopupMenuItem<Locale>(
                value: locale,
                child: Text(labelFor(locale)),
              ),
            )
            .toList();
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/courier/courier_live_location_host.dart';
import 'core/providers/core_providers.dart';
import 'core/push/push_lifecycle_host.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/auction_heartbeat.dart';
import 'l10n/generated/app_localizations.dart';

class CourierApp extends ConsumerWidget {
  const CourierApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final localeAsync = ref.watch(localeControllerProvider);
    final locale = localeAsync.valueOrNull ?? const Locale('uz');
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? ThemeMode.system;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: (deviceLocale, supported) {
        if (deviceLocale == null) {
          return locale;
        }
        for (final s in supported) {
          if (s.languageCode == deviceLocale.languageCode) {
            return s;
          }
        }
        return locale;
      },
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => PushLifecycleHost(
        child: CourierLiveLocationHost(
          child: AuctionHeartbeat(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}

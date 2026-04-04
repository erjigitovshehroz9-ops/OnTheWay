import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../web/job_local_persistence.dart';
import '../web/sqlite_job_persistence.dart';
import '../web/sqlite_user_backing_store.dart';
import '../web/user_backing_store.dart';
import '../web/web_job_memory_persistence.dart';
import '../web/web_prefs_user_backing_store.dart';
import '../../data/regions_seed.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/job_entity.dart';
import '../../models/order_feedback_entity.dart';
import '../../models/region_record.dart';
import '../../models/support_request_entity.dart';
import '../../models/user_role.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/feedback_repository.dart';
import '../../repositories/job_repository.dart';
import '../../repositories/support_request_repository.dart';
import '../../repositories/user_repository.dart';
import '../../services/geocoding/nominatim_service.dart';
import '../../services/locale/locale_preferences.dart';
import '../../services/routing/osrm_route_service.dart';
import '../../services/supabase_service.dart';
import '../../services/theme/theme_preferences.dart';
import '../../services/translation/mock_translation_service.dart';
import '../../services/translation/translation_service.dart';
import '../courier/courier_feed_selection.dart';
import '../geo/work_area_keys.dart';
import '../network/startup_reachability.dart';
import '../utils/local_file_exists.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

/// Profil menyusidagi rasm: `SharedPreferences` + fayl mavjudligi.
final profileImagePathProvider =
    FutureProvider.family<String?, String>((ref, userId) async {
  final sp = await ref.watch(sharedPreferencesProvider.future);
  final raw = sp.getString('profile_image_path_$userId')?.trim();
  if (raw == null || raw.isEmpty) return null;
  if (kIsWeb) {
    return null;
  }
  if (!localFileExistsSync(raw)) return null;
  return raw;
});

final splashHoldProvider = FutureProvider<void>(
  (ref) => Future<void>.delayed(const Duration(milliseconds: 3300)),
);

/// Birinchi ochilish: internet (+ ixtiyoriy server health) tekshiruvi.
final startupReachabilityProvider = FutureProvider<void>(
  (ref) async {
    await verifyStartupReachability();
  },
);

/// SQLite is disabled on Flutter web; returns null there.
final appDatabaseProvider = FutureProvider<AppDatabase?>((ref) async {
  if (kIsWeb) return null;
  return AppDatabase.open();
});

WebJobMemoryPersistence? _webJobMemorySingleton;

/// User rows: SQLite (native) or SharedPreferences JSON (web).
final userBackingStoreProvider = FutureProvider<UserBackingStore>((ref) async {
  if (kIsWeb) {
    final sp = await ref.watch(sharedPreferencesProvider.future);
    return WebPrefsUserBackingStore(sp);
  }
  final db = await ref.watch(appDatabaseProvider.future);
  return SqliteUserBackingStore(db!);
});

/// Job/bid cache: SQLite (native) or in-memory (web; hydrated from Supabase).
final jobLocalPersistenceProvider = FutureProvider<JobLocalPersistence>(
  (ref) async {
    if (kIsWeb) {
      return _webJobMemorySingleton ??= WebJobMemoryPersistence();
    }
    final db = await ref.watch(appDatabaseProvider.future);
    return SqliteJobPersistence(db!);
  },
);

final supabaseOrderServiceProvider = Provider<SupabaseOrderService>(
  (ref) => SupabaseOrderService(),
);

final translationServiceProvider = Provider<TranslationService>(
  (ref) => MockTranslationService(),
);

final localePreferencesProvider = FutureProvider<LocalePreferences>(
  (ref) async {
    final sp = await ref.watch(sharedPreferencesProvider.future);
    return LocalePreferences(sp);
  },
);

final localeControllerProvider =
    AsyncNotifierProvider<LocaleController, Locale>(LocaleController.new);

class LocaleController extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    final prefs = await ref.watch(localePreferencesProvider.future);
    final code = await prefs.loadLocaleCode();
    if (code == null || code.isEmpty) {
      return const Locale('uz');
    }
    return Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await ref.read(localePreferencesProvider.future);
    await prefs.saveLocaleCode(locale.languageCode);
    state = AsyncData(locale);
  }

  List<Locale> alternateLocales(Locale current) {
    const all = AppLocalizations.supportedLocales;
    return all.where((l) => l.languageCode != current.languageCode).toList();
  }
}

final themeModeProvider =
    AsyncNotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final sp = await ref.watch(sharedPreferencesProvider.future);
    return ThemePreferences(sp).loadThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final sp = await ref.read(sharedPreferencesProvider.future);
    await ThemePreferences(sp).saveThemeMode(mode);
    state = AsyncData(mode);
  }
}

final authRepositoryProvider = FutureProvider<AuthRepository>(
  (ref) async {
    final store = await ref.watch(userBackingStoreProvider.future);
    final sp = await ref.watch(sharedPreferencesProvider.future);
    return AuthRepository(userStore: store, preferences: sp);
  },
);

final jobRepositoryProvider = FutureProvider<JobRepository>(
  (ref) async {
    final local = await ref.watch(jobLocalPersistenceProvider.future);
    final translation = ref.watch(translationServiceProvider);
    final users = await ref.watch(userRepositoryProvider.future);
    final auth = await ref.watch(authRepositoryProvider.future);
    final supabaseOrders = ref.watch(supabaseOrderServiceProvider);
    return JobRepository(
      localPersistence: local,
      translationService: translation,
      userRepository: users,
      authRepository: auth,
      supabaseOrderService: supabaseOrders,
    );
  },
);

final userRepositoryProvider = FutureProvider<UserRepository>(
  (ref) async {
    final store = await ref.watch(userBackingStoreProvider.future);
    return UserRepository(store);
  },
);

final feedbackRepositoryProvider = FutureProvider<FeedbackRepository>(
  (ref) async {
    final db = await ref.watch(appDatabaseProvider.future);
    final users = await ref.watch(userRepositoryProvider.future);
    final supa = ref.watch(supabaseOrderServiceProvider);
    return FeedbackRepository(
      database: db,
      userRepository: users,
      supabaseOrderService: supa,
    );
  },
);

/// Joriy foydalanuvchi ushbu buyurtmada fikr qoldirganmi (eski `feedback` yoki `order_feedback`).
final userSubmittedFeedbackForJobProvider =
    FutureProvider.family<bool, ({String jobId, String userId})>(
  (ref, key) async {
    final repo = await ref.watch(feedbackRepositoryProvider.future);
    return repo.hasSubmittedForJob(fromUserId: key.userId, jobId: key.jobId);
  },
);

/// Yakuniy `order_feedback` qatori (remote bilan sinxron).
final myOrderFeedbackProvider =
    FutureProvider.autoDispose.family<OrderFeedbackEntity?, ({String orderId, String userId})>(
  (ref, key) async {
    final repo = await ref.watch(feedbackRepositoryProvider.future);
    return repo.loadMyOrderFeedback(
      orderId: key.orderId,
      fromUserId: key.userId,
    );
  },
);

final supportRequestRepositoryProvider = FutureProvider<SupportRequestRepository>(
  (ref) async {
    final db = await ref.watch(appDatabaseProvider.future);
    return SupportRequestRepository(database: db);
  },
);

final adminSupportRequestsProvider =
    FutureProvider<List<SupportRequestEntity>>((ref) async {
  final repo = await ref.watch(supportRequestRepositoryProvider.future);
  return repo.listAll();
});

final nominatimServiceProvider = Provider<NominatimService>(
  (ref) => NominatimService(),
);

final osrmRouteServiceProvider = Provider<OsrmRouteService>(
  (ref) => OsrmRouteService(),
);

final courierRegionCodeProvider = StateProvider<String?>((ref) => null);
final courierDistrictCodeProvider = StateProvider<String?>((ref) => null);

/// Kuryer buyurtma tafsilotida ochilganda — GPS shu buyurtma uchun ustuvor.
final courierLiveTrackingFocusJobIdProvider = StateProvider<String?>((ref) => null);

/// Jonli lokatsiya: GPS/ruxsat yo‘q (kuryer UI).
final courierTrackingGpsBlockedProvider = StateProvider<bool>((ref) => false);

String _seedRegionUz(String? code) {
  if (code == null || code.isEmpty) return '(empty)';
  try {
    return RegionsSeed.regions.firstWhere((e) => e.code == code).name.uz;
  } catch (_) {
    return code;
  }
}

String _seedDistrictUz(String? code) {
  if (code == null || code.isEmpty) return '(empty)';
  try {
    return RegionsSeed.districts.firstWhere((e) => e.code == code).name.uz;
  } catch (_) {
    return code;
  }
}

final courierJobsProvider = FutureProvider<List<JobEntity>>((ref) async {
  final selR = ref.watch(courierRegionCodeProvider);
  final selD = ref.watch(courierDistrictCodeProvider);
  final user = ref.watch(authSessionProvider).valueOrNull;
  final repo = await ref.watch(jobRepositoryProvider.future);
  final auth = await ref.watch(authRepositoryProvider.future);
  List<String>? courierTransportFilter;
  if (user?.role == UserRole.courier) {
    courierTransportFilter = auth.resolvedCourierTransportKeys(user!);
  }
  final feedSel = resolveCourierFeedSelection(
    user: user,
    selRegionCode: selR,
    selDistrictCode: selD,
  );
  final effectiveR = feedSel.regionCode;
  final effectiveD = feedSel.districtCode;
  final wholeRegion = feedSel.wholeRegion;
  final courierRKey = user?.workingRegionKey ?? '';
  final courierDKey = user?.workingDistrictKey ?? '';
  // Courier feed: only Supabase-backed cache rows (exclude local-only posted jobs).
  final requireRemoteBacked =
      user?.role == UserRole.courier;
  final all = await repo.courierFeed(
    regionCode: effectiveR,
    districtCode: effectiveD,
    courierWorkingRegionKey: courierRKey,
    courierWorkingDistrictKey: courierDKey,
    courierWholeRegionDistrict: wholeRegion,
    courierTransportKeys: courierTransportFilter,
    winnerCourierId:
        user?.role == UserRole.courier ? user?.id : null,
    requireRemoteBackedJobs: requireRemoteBacked,
  );

  if (kDebugMode && user?.role == UserRole.courier) {
    final u = user!;
    final eff = WorkAreaKeys.effectiveCourierKeys(
      workingRegionKey: u.workingRegionKey,
      workingDistrictKey: u.workingDistrictKey,
      regionCode: effectiveR,
      districtCode: effectiveD,
    );
    debugPrint('[courierFeed] provider selR=$selR selD=$selD');
    debugPrint('[courierFeed] effective region_code=$effectiveR district_code=$effectiveD');
    debugPrint(
      '[courierFeed] selected region (label): ${_seedRegionUz(effectiveR)}',
    );
    debugPrint(
      '[courierFeed] selected district (label): ${_seedDistrictUz(effectiveD)}',
    );
    debugPrint(
      '[courierFeed] effective selected region key=${eff.regionKey} '
      'district key=${eff.districtKey}',
    );
    debugPrint('[courierFeed] wholeRegion=$wholeRegion');
    debugPrint(
      '[courierFeed] profile workingRKey=${u.workingRegionKey} workingDKey=${u.workingDistrictKey}',
    );
    debugPrint(
      '[courierFeed] profile regionCode=${u.regionCode} districtCode=${u.districtCode}',
    );
    for (final j in all) {
      final o = WorkAreaKeys.effectiveOrderKeys(j);
      final match = WorkAreaKeys.courierJobMatchesWorkArea(
        job: j,
        courierWorkingRegionKey: courierRKey,
        courierWorkingDistrictKey: courierDKey,
        courierRegionCode: effectiveR,
        courierDistrictCode: effectiveD,
        wholeRegionDistrict: wholeRegion,
      );
      debugPrint('[courierFeed] --- job ${j.id} dartMatch=$match');
      debugPrint('[courierFeed] Order pickupR=${j.pickupRegion} pickupD=${j.pickupDistrictOrCity}');
      debugPrint('[courierFeed] Order keys R=${o.regionKey} D=${o.districtKey}');
      debugPrint('[courierFeed] Order admin ${j.regionCode}/${j.districtCode}');
    }
  }

  // Courier ko'rinishida foydalanuvchi o'zi yaratgan buyurtmalarni yashiramiz.
  // Sender rolda bu provider ishlatilmaydi, shuning uchun "o'chib ketish" bo'lmasligi kerak.
  if (user?.role == UserRole.courier) {
    // `user` nullable bo‘lgani uchun bu filterda crash bo‘lmasligi kerak.
    // Null holatda "exclude" qo'llanmaydi.
    final userId = user?.id;
    if (userId == null) return all;
    final out = all.where((j) => j.senderId != userId).toList();
    if (kDebugMode) {
      debugPrint('[order-list] courier count=${out.length}');
      debugPrint(
        '[courierJobsProvider] providerReturn ids=${out.map((e) => e.id).join(",")} count=${out.length}',
      );
    }
    return out;
  }

  return all;
});

/// Viloyat/tuman ro‘yxati — doim [RegionsSeed] (kod bilan birga yangilanadi).
/// SQLite `districts` jadvali bilan sinxron bo‘lmasligi mumkin; tanlov UI uchun seed ishlatiladi.
final regionsListProvider = FutureProvider<List<RegionRecord>>((ref) async {
  return RegionsSeed.regions;
});

final districtsForRegionProvider =
    FutureProvider.family<List<DistrictRecord>, String>((ref, code) async {
  final list =
      RegionsSeed.districts.where((d) => d.regionCode == code).toList()
        ..sort((a, b) => a.code.compareTo(b.code));
  return list;
});

final authSessionProvider =
    AsyncNotifierProvider<AuthSessionNotifier, AppUser?>(
  AuthSessionNotifier.new,
);

class AuthSessionNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    debugPrint('[session] build started');
    final repo = await ref.watch(authRepositoryProvider.future).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('authRepositoryProvider timeout'),
        );
    final user = await repo.currentUser().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('currentUser timeout'),
        );
    debugPrint('[session] build completed: user=${user?.id}');
    return user;
  }

  Future<void> refresh() async {
    debugPrint('[session] refresh started');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(authRepositoryProvider.future).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('authRepositoryProvider timeout'),
          );
      final user = await repo.currentUser().timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('currentUser timeout'),
          );
      debugPrint('[session] refresh completed: user=${user?.id}');
      return user;
    });
    if (state.hasError) {
      debugPrint('[session] refresh error: ${state.error}');
    }
  }
}

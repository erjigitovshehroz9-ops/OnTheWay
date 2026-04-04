import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_contact_requests_page.dart';
import '../../features/admin/presentation/admin_home_page.dart';
import '../../features/admin/presentation/admin_map_page.dart';
import '../../features/admin/presentation/admin_statistics_page.dart';
import '../../features/admin/presentation/admin_users_page.dart';
import '../../features/auction/presentation/auction_page.dart';
import '../../features/auth/presentation/offer_agreement_page.dart';
import '../../features/auth/presentation/phone_login_page.dart';
import '../../features/auth/presentation/sms_verification_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/courier/presentation/courier_home_page.dart';
import '../../features/jobs/presentation/job_detail_page.dart';
import '../../features/map/presentation/map_location_page.dart';
import '../../features/sender/presentation/create_job_wizard_page.dart';
import '../../features/sender/presentation/sender_home_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../models/app_user.dart';
import '../../models/user_role.dart';
import '../admin/admin_access.dart';
import '../providers/core_providers.dart';
import 'app_routes.dart';

/// Modal/sheet uchun root [Navigator] konteksti (async dan keyin `BuildContext` uzatmaslik).
final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AsyncValue<AppUser?>>(authSessionProvider, (_, __) {
    refresh.value++;
  });
  ref.listen<AsyncValue<void>>(splashHoldProvider, (_, __) {
    refresh.value++;
  });
  ref.listen<AsyncValue<void>>(startupReachabilityProvider, (_, __) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authSessionProvider);
      final splashHold = ref.read(splashHoldProvider);
      final loc = state.matchedLocation;
      final forcePhoneEdit = state.uri.queryParameters['editPhone'] == '1';
      debugPrint(
        '[router] loc=$loc isLoading=${auth.isLoading} '
        'hasError=${auth.hasError} user=${auth.valueOrNull?.id} '
        'forcePhoneEdit=$forcePhoneEdit',
      );

      if (!splashHold.hasValue) {
        if (loc == AppRoutes.splash) return null;
        return AppRoutes.splash;
      }

      final reach = ref.read(startupReachabilityProvider);
      if (reach.isLoading || reach.hasError) {
        if (loc == AppRoutes.splash) return null;
        return AppRoutes.splash;
      }

      if (auth.isLoading) {
        if (loc == AppRoutes.splash) return null;
        return AppRoutes.splash;
      }

      if (auth.hasError) {
        if (loc == AppRoutes.splash) {
          return null;
        }
        return AppRoutes.splash;
      }

      final user = auth.valueOrNull;

      if (user == null) {
        if (loc == AppRoutes.splash) {
          return AppRoutes.phone;
        }
        if (loc == AppRoutes.phone) {
          return null;
        }
        if (loc == AppRoutes.sms) {
          return AppRoutes.phone;
        }
        return AppRoutes.phone;
      }

      if (!user.phoneVerified) {
        if (loc == AppRoutes.phone && forcePhoneEdit) {
          return null;
        }
        if (loc == AppRoutes.splash) return AppRoutes.sms;
        if (loc != AppRoutes.sms) return AppRoutes.sms;
        return null;
      }

      if (!user.offerAccepted) {
        if (loc == AppRoutes.splash) return AppRoutes.offer;
        if (loc != AppRoutes.offer) return AppRoutes.offer;
        return null;
      }

      if (user.role == null) {
        if (loc == AppRoutes.splash) return AppRoutes.role;
        if (loc != AppRoutes.role) return AppRoutes.role;
        return null;
      }

      final home = switch (user.role!) {
        UserRole.sender => AppRoutes.sender,
        UserRole.courier => AppRoutes.courier,
        UserRole.admin => user.canAccessAdminPanel
            ? AppRoutes.admin
            : AppRoutes.sender,
      };

      final authFlow = {
        AppRoutes.phone,
        AppRoutes.sms,
        AppRoutes.offer,
        AppRoutes.role,
      };

      final adminPaths = {
        AppRoutes.admin,
        AppRoutes.adminStats,
        AppRoutes.adminUsers,
        AppRoutes.adminMap,
        AppRoutes.adminContactRequests,
      };

      if (adminPaths.contains(loc) && !AdminAccess.allowAdminPanel(user)) {
        return home;
      }

      if (authFlow.contains(loc)) {
        return home;
      }

      if (loc == AppRoutes.splash) {
        return home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.phone,
        builder: (context, state) => const PhoneLoginPage(),
      ),
      GoRoute(
        path: AppRoutes.sms,
        builder: (context, state) {
          final phoneFromQuery = state.uri.queryParameters['phone'];
          final phone = (phoneFromQuery != null && phoneFromQuery.trim().isNotEmpty)
              ? phoneFromQuery
              : (ref.read(authSessionProvider).valueOrNull?.phone ?? '');
          return SmsVerificationPage(
            key: ValueKey('sms_${phone ?? 'none'}'),
            phoneNumber: phone,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.offer,
        builder: (context, state) {
          final phoneFromQuery = state.uri.queryParameters['phone'];
          final phone = (phoneFromQuery != null && phoneFromQuery.trim().isNotEmpty)
              ? phoneFromQuery
              : (ref.read(authSessionProvider).valueOrNull?.phone ?? '');
          return OfferAgreementPage(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: AppRoutes.role,
        builder: (context, state) {
          final phoneFromQuery = state.uri.queryParameters['phone'];
          final phone = (phoneFromQuery != null && phoneFromQuery.trim().isNotEmpty)
              ? phoneFromQuery
              : (ref.read(authSessionProvider).valueOrNull?.phone ?? '');
          return ProfileSetupPage(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: AppRoutes.sender,
        builder: (context, state) => const SenderHomePage(),
      ),
      GoRoute(
        path: AppRoutes.courier,
        builder: (context, state) => const CourierHomePage(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => AdminHomePage(
          initialTabQuery: state.uri.queryParameters['tab'],
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.createJob,
        builder: (context, state) => const CreateJobWizardPage(),
      ),
      GoRoute(
        path: AppRoutes.mapPicker,
        builder: (context, state) => const MapLocationPage(),
      ),
      GoRoute(
        path: AppRoutes.adminStats,
        builder: (context, state) => const AdminStatisticsPage(),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        builder: (context, state) => const AdminUsersPage(),
      ),
      GoRoute(
        path: AppRoutes.adminMap,
        builder: (context, state) => const AdminMapPage(),
      ),
      GoRoute(
        path: AppRoutes.adminContactRequests,
        builder: (context, state) => const AdminContactRequestsPage(),
      ),
      GoRoute(
        path: '/job/:jobId',
        builder: (context, state) {
          final id = state.pathParameters['jobId']!;
          return JobDetailPage(jobId: id);
        },
        routes: [
          GoRoute(
            path: 'auction',
            builder: (context, state) {
              final id = state.pathParameters['jobId']!;
              return AuctionPage(jobId: id);
            },
          ),
        ],
      ),
    ],
  );
});

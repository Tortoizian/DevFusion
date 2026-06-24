import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../auth/profile_provider.dart';
import 'auth_redirect.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/profile_setup_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/groups/create_group_screen.dart';
import '../../features/groups/join_group_screen.dart';
import '../../features/groups/group_detail_screen.dart';
import '../../features/groups/qr_scan_screen.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final _routerRefreshNotifierProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier();

  void refresh() => notifier.refresh();

  ref.listen(authStateProvider, (_, __) => refresh(), fireImmediately: true);
  ref.listen(sessionProvider, (_, __) => refresh(), fireImmediately: true);
  ref.listen(currentProfileProvider, (_, __) => refresh(), fireImmediately: true);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(_routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      return resolveAuthRedirect(
        location: state.matchedLocation,
        authReady: ref.read(authReadyProvider),
        hasSession: ref.read(sessionProvider) != null,
        profileAsync: ref.read(currentProfileProvider),
      );
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/groups/create',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/groups/join',
        builder: (context, state) => const JoinGroupScreen(),
      ),
      GoRoute(
        path: '/groups/join/scan',
        builder: (context, state) => const QrScanScreen(),
      ),
      GoRoute(
        path: '/groups/:groupId',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return GroupDetailScreen(groupId: groupId);
        },
      ),
    ],
  );
});

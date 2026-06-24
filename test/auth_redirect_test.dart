import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitsmart/core/models/user_model.dart';
import 'package:splitsmart/core/router/auth_redirect.dart';

void main() {
  final profile = UserModel(
    id: 'user-1',
    name: 'Ananya',
    upiId: 'ananya@ybl',
    createdAt: DateTime(2026, 6, 24),
  );

  group('resolveAuthRedirect', () {
    test('waits on splash while auth is unresolved', () {
      expect(
        resolveAuthRedirect(
          location: '/',
          authReady: false,
          hasSession: false,
          profileAsync: const AsyncLoading(),
        ),
        isNull,
      );

      expect(
        resolveAuthRedirect(
          location: '/dashboard',
          authReady: false,
          hasSession: false,
          profileAsync: const AsyncLoading(),
        ),
        '/',
      );
    });

    test('sends signed-out users to login', () {
      expect(
        resolveAuthRedirect(
          location: '/',
          authReady: true,
          hasSession: false,
          profileAsync: const AsyncData(null),
        ),
        '/login',
      );

      expect(
        resolveAuthRedirect(
          location: '/login',
          authReady: true,
          hasSession: false,
          profileAsync: const AsyncData(null),
        ),
        isNull,
      );
    });

    test('sends signed-in users without profile to setup', () {
      expect(
        resolveAuthRedirect(
          location: '/login',
          authReady: true,
          hasSession: true,
          profileAsync: const AsyncData(null),
        ),
        '/profile-setup',
      );
    });

    test('sends signed-in users with profile to dashboard on cold start splash', () {
      expect(
        resolveAuthRedirect(
          location: '/',
          authReady: true,
          hasSession: true,
          profileAsync: AsyncData(profile),
        ),
        '/dashboard',
      );
    });

    test('keeps signed-in users on dashboard', () {
      expect(
        resolveAuthRedirect(
          location: '/dashboard',
          authReady: true,
          hasSession: true,
          profileAsync: AsyncData(profile),
        ),
        isNull,
      );
    });

    test('waits on splash while profile is loading', () {
      expect(
        resolveAuthRedirect(
          location: '/',
          authReady: true,
          hasSession: true,
          profileAsync: const AsyncLoading(),
        ),
        isNull,
      );
    });
  });
}

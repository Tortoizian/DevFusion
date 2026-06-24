import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

/// Pure redirect logic for GoRouter — testable without Supabase.
String? resolveAuthRedirect({
  required String location,
  required bool authReady,
  required bool hasSession,
  required AsyncValue<UserModel?> profileAsync,
}) {
  final onSplash = location == '/';
  final onLogin = location == '/login';
  final onSetup = location == '/profile-setup';

  if (!authReady) {
    return onSplash ? null : '/';
  }

  if (!hasSession) {
    return onLogin ? null : '/login';
  }

  if (profileAsync.isLoading) {
    return onSplash ? null : '/';
  }

  final profile = profileAsync.valueOrNull;
  if (profile == null || profile.upiId.isEmpty) {
    return onSetup ? null : '/profile-setup';
  }

  if (onLogin || onSetup || onSplash) return '/dashboard';
  return null;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Streams Supabase auth state changes (sign-in, sign-out, token refresh).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Current session, or null if signed out.
final sessionProvider = Provider<Session?>((ref) {
  return ref.watch(authStateProvider).value?.session;
});

/// Current authenticated user id, or null.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(sessionProvider)?.user;
});

/// Convenience: signed-in user id string.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.id;
});

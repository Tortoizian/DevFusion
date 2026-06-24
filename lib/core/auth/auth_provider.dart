import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Emits the persisted session immediately, then live auth changes.
Stream<AuthState> authStateStream(GoTrueClient auth) async* {
  yield AuthState(AuthChangeEvent.initialSession, auth.currentSession);
  yield* auth.onAuthStateChange;
}

/// Streams Supabase auth state changes (sign-in, sign-out, token refresh).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return authStateStream(Supabase.instance.client.auth);
});

/// Current session, or null if signed out.
///
/// Uses [GoTrueClient.currentSession] so cold starts with a stored session
/// are resolved before the auth stream's first event.
final sessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentSession;
});

/// True once we know whether a session exists (not waiting on first stream event).
final authReadyProvider = Provider<bool>((ref) {
  final authAsync = ref.watch(authStateProvider);
  if (!authAsync.isLoading) return true;
  return ref.watch(sessionProvider) != null;
});

/// Current authenticated user id, or null.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(sessionProvider)?.user;
});

/// Convenience: signed-in user id string.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.id;
});

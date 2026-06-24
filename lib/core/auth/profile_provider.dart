import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';
import 'profile_service.dart';

/// Fetches the signed-in user's profile row, or null if missing / signed out.
final currentProfileProvider = FutureProvider<UserModel?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ProfileService.fetchProfile(userId);
});

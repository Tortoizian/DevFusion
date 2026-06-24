import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

abstract final class ProfileService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<UserModel?> fetchProfile(String userId) async {
    final data = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  static Future<void> upsertProfile({
    required String userId,
    required String name,
    required String upiId,
  }) async {
    final user = UserModel(
      id: userId,
      name: name.trim(),
      upiId: upiId.trim(),
      createdAt: DateTime.now(),
    );

    await _client.from('profiles').upsert({
      'id': userId,
      'name': user.name,
      'upi_id': user.upiId,
      'avatar_url': user.avatarUrl,
    });
  }
}

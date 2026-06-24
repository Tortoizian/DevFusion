import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Deep link registered in AndroidManifest and Supabase Auth redirect URLs.
const kAuthRedirectUrl = 'io.supabase.splitsmart://login-callback/';

abstract final class AuthService {
  static GoTrueClient get _auth => Supabase.instance.client.auth;

  static Future<void> signInWithGoogle() async {
    await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : kAuthRedirectUrl,
    );
  }
}

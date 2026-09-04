import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginException implements Exception {
  const LoginException(this.message);
  final String message;
}

class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (error) {
      debugPrint('SUPABASE AUTH ERROR: ${error.message}');
      debugPrint('SUPABASE AUTH STATUS: ${error.statusCode}');
      throw LoginException(error.message);
    } catch (error, stackTrace) {
      debugPrint('LOGIN UNKNOWN ERROR: $error');
      debugPrint('$stackTrace');
      throw LoginException('Login error: $error');
    }
  }

  Future<bool> hasValidActiveSession() async =>
      _client.auth.currentSession != null;

  Future<void> signOut() => _client.auth.signOut();
}

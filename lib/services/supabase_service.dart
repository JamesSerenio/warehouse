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
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null || response.session == null) {
        throw const LoginException('Incorrect email or password.');
      }
    } on LoginException {
      rethrow;
    } on AuthException catch (error) {
      debugPrint('SUPABASE AUTH ERROR: ${error.message}');
      debugPrint('SUPABASE AUTH STATUS: ${error.statusCode}');
      throw const LoginException('Incorrect email or password.');
    } catch (error, stackTrace) {
      debugPrint('LOGIN ERROR: $error');
      debugPrint('$stackTrace');
      throw const LoginException('Unable to connect to the login service.');
    }
  }

  Future<bool> hasValidActiveSession() async =>
      _client.auth.currentSession != null;

  Future<void> signOut() => _client.auth.signOut();
}

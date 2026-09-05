import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';

class LoginException implements Exception {
  const LoginException(this.message);
  final String message;
}

abstract final class LoginFunction {
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
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

  static bool hasActiveSession() =>
      SupabaseService.client.auth.currentSession != null;

  static String? getCurrentUserEmail() =>
      SupabaseService.client.auth.currentUser?.email;
}

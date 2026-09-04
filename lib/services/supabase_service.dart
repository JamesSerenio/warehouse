import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

enum LoginFailure { invalidCredentials, inactiveAccount, network, server }

class LoginException implements Exception {
  const LoginException(this.failure);
  final LoginFailure failure;
}

class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  String _normalizeUsername(String username) => username.trim().toLowerCase();

  String _internalEmail(String username) =>
      '${_normalizeUsername(username)}@${SupabaseConfig.internalEmailDomain}';

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: _internalEmail(username),
        password: password,
      );
      if (response.session == null || !await _currentUserHasActiveProfile()) {
        await _client.auth.signOut();
        throw const LoginException(LoginFailure.inactiveAccount);
      }
    } on LoginException {
      rethrow;
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login credentials') ||
          message.contains('email not confirmed')) {
        throw const LoginException(LoginFailure.invalidCredentials);
      }
      throw const LoginException(LoginFailure.server);
    } on PostgrestException {
      await _safeSignOut();
      throw const LoginException(LoginFailure.server);
    } catch (_) {
      await _safeSignOut();
      throw const LoginException(LoginFailure.network);
    }
  }

  Future<bool> hasValidActiveSession() async {
    if (_client.auth.currentSession == null) return false;
    try {
      final isActive = await _currentUserHasActiveProfile();
      if (!isActive) await _safeSignOut();
      return isActive;
    } catch (_) {
      await _safeSignOut();
      return false;
    }
  }

  Future<bool> _currentUserHasActiveProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    final profile = await _client
        .from('staff_profiles')
        .select('id')
        .eq('auth_user_id', user.id)
        .eq('is_active', true)
        .maybeSingle();
    return profile != null;
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> _safeSignOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Preserve the original error.
    }
  }
}

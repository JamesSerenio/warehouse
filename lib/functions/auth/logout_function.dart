import '../../services/supabase_service.dart';

abstract final class LogoutFunction {
  static Future<void> logout() => SupabaseService.client.auth.signOut();
}

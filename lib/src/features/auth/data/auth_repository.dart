import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/providers/supabase_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(client: ref.watch(supabaseClientProvider));
});

class AuthRepository {
  final SupabaseClient client;
  AuthRepository({required this.client});

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await client.auth.signInWithPassword(email: email, password: password);
    } catch (error, stackTrace) {
      throw AppError.from(error, stackTrace);
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await client.auth.signUp(email: email, password: password);
    } catch (error, stackTrace) {
      throw AppError.from(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (error, stackTrace) {
      throw AppError.from(error, stackTrace);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await client.auth.signInWithOAuth(OAuthProvider.google);
    } catch (error, stackTrace) {
      throw AppError.from(error, stackTrace);
    }
  }
}

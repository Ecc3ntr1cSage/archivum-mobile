import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';
import '../domain/account.dart';
import '../domain/account_repository.dart';

const _credentialsTable = 'credentials';

class SupabaseAccountRepository implements AccountRepository {
  final SupabaseClient client;

  SupabaseAccountRepository(this.client);

  String _requireUserId() {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw AppError.auth('You must be signed in to manage credentials.');
    }
    return userId;
  }

  String _scopedUserId(String? requestedUserId) {
    final userId = _requireUserId();
    if (requestedUserId != null && requestedUserId != userId) {
      throw AppError.permission(
        'You cannot access another user’s credentials.',
      );
    }
    return userId;
  }

  @override
  Future<Account> createAccount(Account account) async {
    final userId = _requireUserId();
    final payload = account.toJson();
    payload['user_id'] = userId;

    final response = await client
        .from(_credentialsTable)
        .insert(payload)
        .select()
        .single();
    final result = Account.fromJson(response);
    await client.from('activity_logs').insert({
      'activity_type': 'credential_created',
    });
    return result;
  }

  @override
  Future<List<Account>> listAccounts({String? userId}) async {
    final scopedUserId = _scopedUserId(userId);
    var query = client
        .from(_credentialsTable)
        .select()
        .eq('user_id', scopedUserId);
    final response = await query.order('created_at', ascending: false);
    return (response as List).map((row) => Account.fromJson(row)).toList();
  }

  @override
  Future<Account> updateAccount(Account account) async {
    if (account.id == null) {
      throw AppError.validation('Credential ID is required for update.');
    }
    final userId = _requireUserId();
    final payload = {
      'title': account.title,
      'method': account.method,
      'email': account.email,
      'username': account.username,
      'password': account.password,
      'provider': account.provider,
      'tags': account.tags,
    };
    final response = await client
        .from(_credentialsTable)
        .update(payload)
        .eq('id', account.id!)
        .eq('user_id', userId)
        .select()
        .single();
    final result = Account.fromJson(response);
    await client.from('activity_logs').insert({
      'activity_type': 'credential_updated',
    });
    return result;
  }

  @override
  Future<void> deleteAccount(String id) async {
    final userId = _requireUserId();
    await client
        .from(_credentialsTable)
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
    await client.from('activity_logs').insert({
      'activity_type': 'credential_deleted',
    });
  }

  @override
  Future<void> addTag(String text, String feature) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw AppError.auth('You must be signed in to manage credentials.');
    }

    await client.from('tags').insert({
      'text': text,
      'feature': feature,
      'user_id': userId,
    });
  }

  @override
  Future<List<String>> getTags(String feature) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await client
        .from('tags')
        .select('text')
        .eq(
          'feature',
          feature,
        ) // Make sure to use the parameter instead of hardcoded
        .eq('user_id', userId);

    return (response as List).map((row) => row['text'] as String).toList();
  }
}

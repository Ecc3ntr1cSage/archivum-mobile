import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/account.dart';
import '../domain/account_repository.dart';

class SupabaseAccountRepository implements AccountRepository {
  final SupabaseClient client;

  SupabaseAccountRepository(this.client);

  @override
  Future<Account> createAccount(Account account) async {
    final payload = account.toJson();
    if (payload['user_id'] == null) {
      payload['user_id'] = client.auth.currentUser?.id;
    }
    
    final response = await client
        .from('accounts')
        .insert(payload)
        .select()
        .single();
    final result = Account.fromJson(response);
    await client.from('activity_logs').insert({'activity_type': 'credential_created'});
    return result;
  }

  @override
  Future<List<Account>> listAccounts({String? userId}) async {
    var query = client.from('accounts').select();
    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List).map((row) => Account.fromJson(row)).toList();
  }

  @override
  Future<Account> updateAccount(Account account) async {
    final payload = account.toJson()
      ..remove('id')
      ..remove('user_id');
    final response = await client
        .from('accounts')
        .update(payload)
        .eq('id', account.id!)
        .select()
        .single();
    final result = Account.fromJson(response);
    await client.from('activity_logs').insert({'activity_type': 'credential_updated'});
    return result;
  }

  @override
  Future<void> deleteAccount(String id) async {
    await client.from('accounts').delete().eq('id', id);
    await client.from('activity_logs').insert({'activity_type': 'credential_deleted'});
  }

  @override
  Future<void> addTag(String text, String feature) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

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
        .eq('feature', feature) // Make sure to use the parameter instead of hardcoded
        .eq('user_id', userId);

    return (response as List).map((row) => row['text'] as String).toList();
  }
}

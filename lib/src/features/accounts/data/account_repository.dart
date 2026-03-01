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
    return Account.fromJson(response);
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
}

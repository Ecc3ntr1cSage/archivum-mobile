import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/transaction.dart';

class TransactionRepository {
  final SupabaseClient client;
  TransactionRepository(this.client);

  Future<void> createTransaction(TransactionModel t) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not logged in');
    }

    await client.from('transactions').insert({
      'user_id': userId,
      'status': t.type.index,
      'amount': (t.amount * 100).toInt(),
      'details': t.details,
      'tag': t.tag,
      'created_at': t.createdAt.toIso8601String(),
    });
  }
}

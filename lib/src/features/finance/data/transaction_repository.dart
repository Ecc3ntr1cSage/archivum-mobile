import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/transaction.dart';

class TransactionRepository {
  final SupabaseClient client;
  TransactionRepository(this.client);

  Future<void> createTransaction(TransactionModel t) async {
    await client.from('transactions').insert({
      'id': t.id,
      'type': t.type.toString().split('.').last,
      'amount': t.amount,
      'details': t.details,
      'tag': t.tag,
      'created_at': t.createdAt.toIso8601String(),
    });
  }
}

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

  Future<void> addTag(String text, String feature) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await client.from('tags').insert({
      'text': text,
      'feature': feature,
      'user_id': userId,
    });
  }

  Future<List<String>> getTags(String feature) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await client
        .from('tags')
        .select('text')
        .eq('feature', feature)
        .eq('user_id', userId);

    return (response as List).map((row) => row['text'] as String).toList();
  }

  Future<List<TransactionModel>> getTransactions() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((row) {
      return TransactionModel(
        id: row['id']?.toString() ?? '',
        type: TransactionType.values[row['status'] as int],
        amount: (row['amount'] as int) / 100,
        details: row['details'] as String,
        tag: row['tag'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }
}

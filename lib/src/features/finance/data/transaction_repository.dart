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
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/transaction.dart';

class TransactionRepository {
  final SupabaseClient client;
  TransactionRepository(this.client);

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

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
      'date': _formatDate(t.date),
      'created_at': t.createdAt.toIso8601String(),
    });
    final activityType = t.type == TransactionType.income
        ? 'income_created'
        : 'expense_created';
    await client.from('activity_logs').insert({'activity_type': activityType});
  }

  Future<void> updateTransaction(TransactionModel t) async {
    await client
        .from('transactions')
        .update({
          'status': t.type.index,
          'amount': (t.amount * 100).toInt(),
          'details': t.details,
          'tag': t.tag,
          'date': _formatDate(t.date),
        })
        .eq('id', t.id);
    final activityType = t.type == TransactionType.income
        ? 'income_updated'
        : 'expense_updated';
    await client.from('activity_logs').insert({'activity_type': activityType});
  }

  Future<void> deleteTransaction(String id, TransactionType type) async {
    await client.from('transactions').delete().eq('id', id);
    final activityType = type == TransactionType.income
        ? 'income_deleted'
        : 'expense_deleted';
    await client.from('activity_logs').insert({'activity_type': activityType});
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

    final transactions = (response as List).map((row) {
      final date = row['date'] as String?;
      return TransactionModel(
        id: row['id']?.toString() ?? '',
        type: TransactionType.values[row['status'] as int],
        amount: (row['amount'] as int) / 100,
        details: row['details'] as String,
        tag: row['tag'] as String,
        date: date == null ? null : DateTime.parse(date),
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();

    transactions.sort((a, b) {
      final byDisplayDate = b.displayDate.compareTo(a.displayDate);
      if (byDisplayDate != 0) return byDisplayDate;
      return b.createdAt.compareTo(a.createdAt);
    });

    return transactions;
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/quote.dart';
import '../domain/quote_repository.dart';

class SupabaseQuoteRepository implements QuoteRepository {
  final SupabaseClient client;
  SupabaseQuoteRepository(this.client);

  @override
  Future<Quote> createQuote(Quote quote) async {
    final payload = {
      'content': quote.content,
      if (quote.author != null) 'author': quote.author,
      if (quote.tag != null) 'tag': quote.tag,
      if (quote.userId != null) 'user_id': quote.userId,
    };

    final response = await client
        .from('quotes')
        .insert(payload)
        .select()
        .single();
    return _mapToQuote(response);
  }

  @override
  Future<Quote> updateQuote(Quote quote) async {
    if (quote.id == null) throw Exception('Quote ID is required for update');

    final payload = {
      'content': quote.content,
      if (quote.author != null) 'author': quote.author,
      if (quote.tag != null) 'tag': quote.tag,
    };

    final response = await client
        .from('quotes')
        .update(payload)
        .eq('id', quote.id as Object)
        .select()
        .single();
    return _mapToQuote(response);
  }

  @override
  Future<void> deleteQuote(String id) async {
    await client.from('quotes').delete().eq('id', id);
  }

  @override
  Future<Quote?> getQuote(String id) async {
    final response = await client
        .from('quotes')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return _mapToQuote(response);
  }

  @override
  Future<List<Quote>> listQuotes({String? userId}) async {
    var query = client.from('quotes').select();
    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List).map((row) => _mapToQuote(row)).toList();
  }

  Quote _mapToQuote(Map<String, dynamic> row) {
    return Quote(
      id: row['id']?.toString(),
      userId: row['user_id']?.toString(),
      content: row['content'] ?? '',
      author: row['author'],
      tag: row['tag'],
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'])
          : null,
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/quote.dart';

class QuoteRepository {
  final SupabaseClient client;
  QuoteRepository(this.client);

  Future<void> createQuote(Quote q) async {
    await client.from('quotes').insert({'id': q.id, 'content': q.content});
  }
}

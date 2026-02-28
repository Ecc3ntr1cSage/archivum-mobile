import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/quotes/domain/quote_repository.dart';
import '../../features/quotes/data/quote_repository.dart';
import 'supabase_provider.dart';

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseQuoteRepository(client);
});

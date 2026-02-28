import 'quote.dart';

abstract class QuoteRepository {
  Future<Quote> createQuote(Quote quote);
  Future<Quote> updateQuote(Quote quote);
  Future<void> deleteQuote(int id);
  Future<Quote?> getQuote(int id);
  Future<List<Quote>> listQuotes({int? userId});
}

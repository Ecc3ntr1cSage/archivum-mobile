import 'quote.dart';

abstract class QuoteRepository {
  Future<Quote> createQuote(Quote quote);
  Future<Quote> updateQuote(Quote quote);
  Future<void> deleteQuote(String id);
  Future<Quote?> getQuote(String id);
  Future<List<Quote>> listQuotes({String? userId});
  Future<void> addTag(String text, String feature);
  Future<List<String>> getTags(String feature);
}

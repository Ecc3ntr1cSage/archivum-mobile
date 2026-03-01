import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notes/domain/note.dart';
import '../../features/notes/domain/note_repository.dart';
import '../../features/quotes/domain/quote.dart';
import '../../features/quotes/domain/quote_repository.dart';
import '../../features/indexes/domain/index_item.dart';
import '../../features/indexes/domain/index_repository.dart';
import 'note_repository_provider.dart';
import 'quote_repository_provider.dart';
import 'index_repository_provider.dart';

final notesListProvider = FutureProvider<List<Note>>((ref) async {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.listNotes();
});

final quotesListProvider = FutureProvider<List<Quote>>((ref) async {
  final repository = ref.watch(quoteRepositoryProvider);
  return repository.listQuotes();
});

final indexesListProvider = FutureProvider<List<IndexEntry>>((ref) async {
  final repository = ref.watch(indexRepositoryProvider);
  return repository.listIndexes();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notes/domain/note_repository.dart';
import '../../features/notes/data/note_repository.dart';
import 'supabase_provider.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseNoteRepository(client);
});

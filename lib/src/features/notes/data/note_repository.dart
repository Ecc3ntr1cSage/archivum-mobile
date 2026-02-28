import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/note.dart';

class NoteRepository {
  final SupabaseClient client;
  NoteRepository(this.client);

  Future<void> createNote(Note n) async {
    await client.from('notes').insert({'id': n.id, 'title': n.title, 'content': n.content});
  }
}

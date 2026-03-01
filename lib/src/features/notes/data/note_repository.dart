import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/note.dart';
import '../domain/note_repository.dart';

class SupabaseNoteRepository implements NoteRepository {
  final SupabaseClient client;
  SupabaseNoteRepository(this.client);

  @override
  Future<Note> createNote(Note note) async {
    final payload = {
      'title': note.title,
      'content': note.content,
      if (note.tag != null) 'tag': note.tag,
      if (note.userId != null) 'user_id': note.userId,
    };

    final response = await client
        .from('notes')
        .insert(payload)
        .select()
        .single();
    return _mapToNote(response);
  }

  @override
  Future<Note> updateNote(Note note) async {
    if (note.id == null) throw Exception('Note ID is required for update');

    final payload = {
      'title': note.title,
      'content': note.content,
      if (note.tag != null) 'tag': note.tag,
    };

    final response = await client
        .from('notes')
        .update(payload)
        .eq('id', note.id as Object)
        .select()
        .single();
    return _mapToNote(response);
  }

  @override
  Future<void> deleteNote(String id) async {
    await client.from('notes').delete().eq('id', id);
  }

  @override
  Future<Note?> getNote(String id) async {
    final response = await client
        .from('notes')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return _mapToNote(response);
  }

  @override
  Future<List<Note>> listNotes({String? userId}) async {
    var query = client.from('notes').select();
    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List).map((row) => _mapToNote(row)).toList();
  }

  Note _mapToNote(Map<String, dynamic> row) {
    return Note(
      id: row['id']?.toString(),
      userId: row['user_id']?.toString(),
      title: row['title'] ?? '',
      content: row['content'] ?? '',
      tag: row['tag'],
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'])
          : null,
    );
  }
}

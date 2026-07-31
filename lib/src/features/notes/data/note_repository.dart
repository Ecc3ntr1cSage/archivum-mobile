import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';
import '../domain/note.dart';
import '../domain/note_repository.dart';

class SupabaseNoteRepository implements NoteRepository {
  final SupabaseClient client;
  SupabaseNoteRepository(this.client);

  String _requireUserId() {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw AppError.auth('You must be signed in to manage notes.');
    }
    return userId;
  }

  String _scopedUserId(String? requestedUserId) {
    final userId = _requireUserId();
    if (requestedUserId != null && requestedUserId != userId) {
      throw AppError.permission('You cannot access another user’s notes.');
    }
    return userId;
  }

  @override
  Future<Note> createNote(Note note) async {
    final userId = _requireUserId();
    final payload = {
      'title': note.title,
      'content': note.content,
      if (note.tag != null) 'tag': note.tag,
      'user_id': userId,
    };

    final response = await client
        .from('notes')
        .insert(payload)
        .select()
        .single();
    final result = _mapToNote(response);
    await client.from('activity_logs').insert({
      'activity_type': 'note_created',
    });
    return result;
  }

  @override
  Future<Note> updateNote(Note note) async {
    if (note.id == null) {
      throw AppError.validation('Note ID is required for update.');
    }
    final userId = _requireUserId();

    final payload = {
      'title': note.title,
      'content': note.content,
      'tag': note.tag,
      'color': note.color,
    };

    final response = await client
        .from('notes')
        .update(payload)
        .eq('id', note.id as Object)
        .eq('user_id', userId)
        .select()
        .single();
    final result = _mapToNote(response);
    await client.from('activity_logs').insert({
      'activity_type': 'note_updated',
    });
    return result;
  }

  @override
  Future<void> deleteNote(String id) async {
    final userId = _requireUserId();
    await client.from('notes').delete().eq('id', id).eq('user_id', userId);
    await client.from('activity_logs').insert({
      'activity_type': 'note_deleted',
    });
  }

  @override
  Future<Note?> getNote(String id) async {
    final userId = _requireUserId();
    final response = await client
        .from('notes')
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();
    if (response == null) return null;
    return _mapToNote(response);
  }

  @override
  Future<List<Note>> listNotes({String? userId}) async {
    final scopedUserId = _scopedUserId(userId);
    var query = client.from('notes').select().eq('user_id', scopedUserId);
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
      color: row['color'],
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'])
          : null,
    );
  }

  @override
  Future<void> addTag(String text, String feature) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw AppError.auth('You must be signed in to manage notes.');
    }

    await client.from('tags').insert({
      'text': text,
      'feature': feature,
      'user_id': userId,
    });
  }

  @override
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
}

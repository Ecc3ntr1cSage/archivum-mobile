import 'note.dart';

abstract class NoteRepository {
  Future<Note> createNote(Note note);
  Future<Note> updateNote(Note note);
  Future<void> deleteNote(String id);
  Future<Note?> getNote(String id);
  Future<List<Note>> listNotes({String? userId});
}

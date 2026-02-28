import 'note.dart';

abstract class NoteRepository {
  Future<Note> createNote(Note note);
  Future<Note> updateNote(Note note);
  Future<void> deleteNote(int id);
  Future<Note?> getNote(int id);
  Future<List<Note>> listNotes({int? userId});
}

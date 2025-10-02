import 'package:hive/hive.dart';
import 'package:note_taker/src/core/notes/data/models/note_model.dart';

class NotesRepository {
  static Box<NoteModel> get box => Hive.box<NoteModel>('notes');

  static List<NoteModel> getAll() => box.values.toList();

  static Future<void> addOrUpdate(NoteModel note) async {
    await box.put(note.id, note);
  }

  static Future<void> delete(String id) async {
    await box.delete(id);
  }
}
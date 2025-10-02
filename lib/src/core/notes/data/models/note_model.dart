import 'package:flutter_quill/quill_delta.dart' as quill;
import 'package:hive/hive.dart';
import 'package:note_taker/src/core/notes/domains/entities/category.dart';

class NoteModel {
  String id;
  String title;
  List<dynamic> bodyJson; // Quill Delta as JSON
  DateTime createdAt;
  DateTime updatedAt;
  Category category;
  int colorValue;
  List<String> tags;
  bool? isPinned;

  NoteModel({
    required this.id,
    required this.title,
    required this.bodyJson,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    required this.colorValue,
    required this.tags,
    this.isPinned = false,
  });

  quill.Delta get bodyDelta => quill.Delta.fromJson(bodyJson);
  set bodyDelta(quill.Delta d) => bodyJson = d.toJson();
}

class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 1;

  @override
  NoteModel read(BinaryReader reader) {
    final id = reader.readString();
    final title = reader.readString();
    final bodyJson = reader.read() as List<dynamic>;
    final createdAt = DateTime.parse(reader.readString());
    final updatedAt = DateTime.parse(reader.readString());
    final catIdx = reader.readInt();
    final colorValue = reader.readInt();
    final tags = (reader.read() as List).cast<String>();
    final hasMore = reader.availableBytes > 0;
    final isPinned = hasMore ? reader.readBool() : false;
    return NoteModel(
      id: id,
      title: title,
      bodyJson: bodyJson,
      createdAt: createdAt,
      updatedAt: updatedAt,
      category: Category.values[catIdx],
      colorValue: colorValue,
      tags: tags,
      isPinned: isPinned,
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.write(obj.bodyJson);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
    writer.writeInt(obj.category.index);
    writer.writeInt(obj.colorValue);
    writer.write(obj.tags);
    writer.writeBool(obj.isPinned ?? false);
  }
}

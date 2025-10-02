import 'category.dart';

class Note {
  final String id;
  final String title;
  final List<dynamic> bodyJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Category category;
  final int colorValue;
  final List<String> tags;
  bool? isPinned;

  Note({
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
}

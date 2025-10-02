import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

enum Category {
  important,
  lectureNotes,
  todoLists,
  shopping,
  diary,
  other,
  shoppingList,
}

extension CategoryExt on Category {
  String get name {
    switch (this) {
      case Category.important:
        return 'Important';
      case Category.lectureNotes:
        return 'Lecture notes';
      case Category.todoLists:
        return 'To-do lists';
      case Category.shopping:
        return 'Shopping list';
      case Category.diary:
        return 'Diary';
      default:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case Category.important:
        return Icons.label_important;
      case Category.lectureNotes:
        return Icons.menu_book;
      case Category.todoLists:
        return Icons.checklist;
      case Category.shopping:
        return Icons.shopping_cart;
      case Category.diary:
        return Icons.calendar_today;
      default:
        return Icons.note;
    }
  }
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 0;

  @override
  Category read(BinaryReader reader) {
    final idx = reader.readInt();
    return Category.values[idx];
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer.writeInt(obj.index);
  }
}

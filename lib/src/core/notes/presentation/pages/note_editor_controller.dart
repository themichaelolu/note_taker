import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart' as quill;
import 'package:note_taker/src/core/notes/data/models/note_model.dart';
import 'package:note_taker/src/core/notes/domains/entities/category.dart';
import 'package:note_taker/src/core/notes/domains/repositories/note_repository.dart';
import 'package:share_plus/share_plus.dart';

class NoteEditorController extends ChangeNotifier {
  final String noteId;
  final bool isNew;

  late NoteModel note;
  late quill.QuillController quillController;
  late TextEditingController titleController;
  bool loading = true;

  NoteEditorController({required this.noteId, this.isNew = false}) {
    _loadNote();
  }

  void _loadNote() {
    final stored = NotesRepository.box.get(noteId);
    if (stored == null) {
      final now = DateTime.now();
      note = NoteModel(
        id: noteId,
        title: 'Untitled',
        bodyJson: (quill.Delta()..insert('\n')).toJson(),
        createdAt: now,
        updatedAt: now,
        category: Category.lectureNotes,
        colorValue: Colors.white.value.toInt(),
        tags: [],
      );
    } else {
      note = stored;
    }

    quillController = quill.QuillController(
      document: quill.Document.fromDelta(note.bodyDelta),
      selection: const TextSelection.collapsed(offset: 0),
    );
    titleController = TextEditingController(text: note.title);
    loading = false;
    notifyListeners();
  }

  Future<void> save(BuildContext context) async {
    final now = DateTime.now();
    note.title = titleController.text.trim().isEmpty
        ? 'Untitled'
        : titleController.text.trim();
    note.bodyJson = quillController.document.toDelta().toJson();
    if (isNew) {
      note.createdAt = note.createdAt;
    }
    note.updatedAt = now;
    await NotesRepository.addOrUpdate(note);
    if (context.mounted) Navigator.of(context).pop(note);
  }

  Future<void> delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await NotesRepository.delete(note.id);
      if (context.mounted) Navigator.of(context).pop(null);
    }
  }

  Future<void> share() async {
    final title = note.title;
    final plain = plainTextFromDelta(note.bodyDelta);
    await Share.share('$title\n\n$plain');
  }

  String plainTextFromDelta(quill.Delta d) {
    final buffer = StringBuffer();
    for (final op in d.toList()) {
      if (op.value is String) buffer.write(op.value as String);
    }
    return buffer.toString();
  }

  Future<int?> pickColor(BuildContext context) async {
    final palette = [
      const Color(0xFFFFF3B0),
      const Color(0xFFD3FDE6),
      const Color(0xFFFAE1F5),
      const Color(0xFFD6E6FF),
      const Color(0xFFFFE0D6),
      const Color(0xFFE8F6FF),
      Colors.white,
    ];
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Color',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: palette.map((c) {
                  final isSelected = c.value == note.colorValue;
                  return GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(c.value),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.black12,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      note.colorValue = picked;
      notifyListeners();
      return picked;
    }
    return null;
  }

  Future<Set<String>?> editTags(BuildContext context) async {
    final controller = TextEditingController();
    final chosen = Set<String>.from(note.tags);
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setSt) {
              return Container(
                padding: const EdgeInsets.all(20),
                height: 450,
                child: Column(
                  children: [
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: 'Add tag',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          color: Colors.blue,
                          iconSize: 32,
                          onPressed: () {
                            final t = controller.text.trim();
                            if (t.isEmpty) return;
                            setSt(() {
                              chosen.add(t);
                              controller.clear();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: chosen.map((t) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(t),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () => setSt(() => chosen.remove(t)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(null),
                            child: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(chosen),
                            child: const Text('Save'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (result != null) {
      note.tags = result.toList();
      notifyListeners();
      return result;
    }
    return null;
  }

  bool isAttributeActive(quill.Attribute attribute) {
    final style = quillController.getSelectionStyle().attributes;
    return style.containsKey(attribute.key);
  }

  void toggleAttribute(quill.Attribute attribute) {
    final active = isAttributeActive(attribute);
    if (active) {
      quillController.formatSelection(quill.Attribute.clone(attribute, null));
    } else {
      quillController.formatSelection(attribute);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    titleController.dispose();
    quillController.dispose();
    super.dispose();
  }
}

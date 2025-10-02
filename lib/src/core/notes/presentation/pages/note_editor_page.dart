import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart' as quill;
import 'package:note_taker/src/core/notes/data/models/note_model.dart';
import 'package:note_taker/src/core/notes/domains/entities/category.dart';
import 'package:note_taker/src/core/notes/domains/repositories/note_repository.dart';
import 'package:share_plus/share_plus.dart';

class NoteEditorPage extends StatefulWidget {
  final String noteId;
  final bool isNew;
  const NoteEditorPage({Key? key, required this.noteId, this.isNew = false})
    : super(key: key);

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late NoteModel note;
  late quill.QuillController _quillController;
  late TextEditingController _titleController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  void _loadNote() {
    final stored = NotesRepository.box.get(widget.noteId);
    if (stored == null) {
      final now = DateTime.now();
      note = NoteModel(
        id: widget.noteId,
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
    _quillController = quill.QuillController(
      document: quill.Document.fromDelta(note.bodyDelta),
      selection: TextSelection.collapsed(offset: 0),
    );
    _titleController = TextEditingController(text: note.title);
    _loading = false;
    setState(() {});
  }

  Future<void> _save() async {
    final now = DateTime.now();
    note.title = _titleController.text.trim().isEmpty
        ? 'Untitled'
        : _titleController.text.trim();
    note.bodyJson = _quillController.document.toDelta().toJson();
    if (widget.isNew) {
      note.createdAt = note.createdAt;
    }
    note.updatedAt = now;
    await NotesRepository.addOrUpdate(note);
    if (mounted) {
      Navigator.of(context).pop(note);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await NotesRepository.delete(note.id);
      Navigator.of(context).pop(null);
    }
  }

  Future<void> _shareNote() async {
    final title = note.title;
    final plain = _plainTextFromDelta(note.bodyDelta);
    await Share.share('$title\n\n$plain');
  }

  String _plainTextFromDelta(quill.Delta d) {
    final buffer = StringBuffer();
    for (final op in d.toList()) {
      if (op.value is String) buffer.write(op.value as String);
    }
    return buffer.toString();
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
      onTap: onTap,
    );
  }

  Future<void> _pickColor() async {
    final palette = [
      Color(0xFFFFF3B0),
      Color(0xFFD3FDE6),
      Color(0xFFFAE1F5),
      Color(0xFFD6E6FF),
      Color(0xFFFFE0D6),
      Color(0xFFE8F6FF),
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
              Text(
                'Choose Color',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20),
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
                          ? Icon(Icons.check, color: Colors.blue)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => note.colorValue = picked);
    }
  }

  Future<void> _editTags() async {
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
                padding: EdgeInsets.all(20),
                height: 450,
                child: Column(
                  children: [
                    Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
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
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.add_circle),
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
                    SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: chosen.map((t) {
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(t),
                              trailing: IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                onPressed: () => setSt(() => chosen.remove(t)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(null),
                            child: Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(chosen),
                            child: Text('Save'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
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
      setState(() => note.tags = result.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            _save();
          },
        ),
        actions: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                CupertinoIcons.pin_fill,
                color: Colors.black87,
                size: 20,
              ),
              onPressed: () {},
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.create_new_folder_sharp,
                color: Colors.black87,
                size: 24,
              ),
              onPressed: () async {
                final chosen = await showModalBottomSheet<Category>(
                  backgroundColor: Colors.white,
                  context: context,
                  isScrollControlled: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (ctx2) {
                    Category? tempSelection = note.category;

                    return StatefulBuilder(
                      builder: (context, setSt) {
                        return SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: 40,
                                    ), // Spacer to align center title
                                    Text(
                                      "Category",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.of(ctx2).pop(),
                                      child: Container(
                                        height: 32,
                                        width: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey.shade300,
                                        ),
                                        child: Icon(Icons.close, size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),

                                // Categories List
                                Expanded(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: Category.values.length,
                                    itemBuilder: (context, index) {
                                      final c = Category.values[index];
                                      final isSelected = c == tempSelection;

                                      return ListTile(
                                        onTap: () =>
                                            setSt(() => tempSelection = c),
                                        title: Text(c.name),
                                        trailing: isSelected
                                            ? Icon(
                                                Icons.check_circle,
                                                color: Colors.black,
                                              )
                                            : Icon(
                                                Icons.circle_outlined,
                                                color: Colors.grey.shade400,
                                              ),
                                      );
                                    },
                                  ),
                                ),

                                // Save Button
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      onPressed: () =>
                                          Navigator.of(ctx2).pop(tempSelection),
                                      child: Text(
                                        "Save",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );

                if (chosen != null) {
                  setState(() => note.category = chosen);
                }
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 8, left: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.save, color: Colors.black87, size: 24),
              onPressed: _save,
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 8, left: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.share_outlined, color: Colors.black87, size: 24),
              onPressed: _shareNote,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Title',
                        hintStyle: TextStyle(
                          color: Colors.black38,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      constraints: BoxConstraints(minHeight: 400),
                      child: QuillEditor.basic(
                        scrollController: ScrollController(),
                        controller: _quillController,
                        focusNode: FocusNode(),
                        config: QuillEditorConfig(
                          autoFocus: false,
                          scrollable: false,
                          expands: false,
                          padding: EdgeInsets.zero,
                          placeholder: 'Start writing...',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: SafeArea(
                  top: false,
                  child: ListenableBuilder(
                    listenable: _quillController,
                    builder: (context, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildToolbarButton(
                            Icons.format_bold,
                            quill.Attribute.bold,
                          ),
                          _buildToolbarButton(
                            Icons.format_italic,
                            quill.Attribute.italic,
                          ),
                          _buildToolbarButton(
                            Icons.format_underlined,
                            quill.Attribute.underline,
                          ),
                          _buildToolbarButton(
                            Icons.format_strikethrough,
                            quill.Attribute.strikeThrough,
                          ),
                          _buildToolbarButton(
                            Icons.format_align_left,
                            quill.Attribute.leftAlignment,
                          ),
                          _buildToolbarButton(
                            Icons.format_align_center,
                            quill.Attribute.centerAlignment,
                          ),
                          _buildToolbarButton(
                            Icons.format_align_right,
                            quill.Attribute.rightAlignment,
                          ),
                          _buildToolbarButton(
                            Icons.format_list_bulleted,
                            quill.Attribute.ul,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, quill.Attribute attribute) {
    final style = _quillController.getSelectionStyle();
    final isActive = style.containsKey(attribute.key);

    return IconButton(
      icon: Icon(
        icon,
        color: isActive ? Color(note.colorValue) : Colors.white,
        size: 20,
      ),
      onPressed: () {
        if (isActive) {
          // Remove attribute if active
          _quillController.formatSelection(
            quill.Attribute.clone(attribute, null),
          );
        } else {
          // Apply attribute if not active
          _quillController.formatSelection(attribute);
        }
      },
      padding: EdgeInsets.all(8),
      constraints: BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }
}

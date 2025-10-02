import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:note_taker/src/core/notes/presentation/pages/note_editor_controller.dart';
import 'package:note_taker/src/core/notes/data/models/note_model.dart';
import 'package:note_taker/src/core/notes/domains/entities/category.dart';
import 'package:note_taker/src/core/notes/domains/repositories/note_repository.dart';
import 'package:note_taker/src/features/app_colors.dart';
import 'package:share_plus/share_plus.dart';

class NoteEditorPage extends StatefulWidget {
  final String noteId;
  final bool isNew;
  const NoteEditorPage({super.key, required this.noteId, this.isNew = false});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final NoteEditorController controller;

  @override
  void initState() {
    super.initState();
    controller = NoteEditorController(
      noteId: widget.noteId,
      isNew: widget.isNew,
    );
    controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    controller.removeListener(() {});
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final note = controller.note;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => controller.save(context),
        ),
        actions: [
          _appBarAction(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) {
                // Scale + rotation animation
                return RotationTransition(
                  turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
                  child: ScaleTransition(scale: anim, child: child),
                );
              },
              child: Icon(
                note.isPinned == true
                    ? CupertinoIcons.pin_fill
                    : CupertinoIcons.pin_slash, // 🔹 clear feedback
                key: ValueKey(note.isPinned), // needed for AnimatedSwitcher
                size: 22,
              ),
            ),
            onTap: () async {
              setState(() {
                note.isPinned = !(note.isPinned ?? false);
              });
              await NotesRepository.addOrUpdate(note); // persist pin state
            },
          ),

          _appBarAction(
            icon: const Icon(Icons.create_new_folder_sharp, size: 24),
            onTap: () async {
              final chosen = await showModalBottomSheet<Category>(
                backgroundColor:
                    theme.bottomSheetTheme.backgroundColor ??
                    theme.scaffoldBackgroundColor,
                context: context,
                isScrollControlled: false,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const SizedBox(width: 40),
                                  Text(
                                    "Category",
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.of(ctx2).pop(),
                                    child: Container(
                                      height: 32,
                                      width: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colorScheme.surfaceVariant,
                                      ),
                                      child: const Icon(Icons.close, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
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
                                      title: Text(
                                        c.name,
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                      trailing: isSelected
                                          ? Icon(
                                              Icons.check_circle,
                                              color: colorScheme.primary,
                                            )
                                          : Icon(
                                              Icons.circle_outlined,
                                              color: colorScheme.outline,
                                            ),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: Theme.of(
                                      context,
                                    ).elevatedButtonTheme.style,

                                    onPressed: () =>
                                        Navigator.of(ctx2).pop(tempSelection),
                                    child: const Text("Save"),
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
              if (chosen != null) controller.note.category = chosen;
            },
          ),
          _appBarAction(
            icon: const Icon(Icons.save, size: 24),
            onTap: () => controller.save(context),
          ),
          _appBarAction(
            icon: const Icon(CupertinoIcons.share, size: 24),
            onTap: controller.share,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller.titleController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Title',
                        hintStyle: theme.textTheme.headlineSmall?.copyWith(
                          color: invertColor(theme.hintColor),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(minHeight: 400),
                      child: quill.QuillEditor.basic(
                        controller: controller.quillController,
                        
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
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SafeArea(
                  top: false,
                  child: ListenableBuilder(
                    listenable: controller.quillController,
                    builder: (context, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildToolbarButton(
                            Icons.format_bold,
                            quill.Attribute.bold,
                            theme,
                          ),
                          _buildToolbarButton(
                            Icons.format_italic,
                            quill.Attribute.italic,
                            theme,
                          ),
                          _buildToolbarButton(
                            Icons.format_underlined,
                            quill.Attribute.underline,
                            theme,
                          ),
                          _buildToolbarButton(
                            Icons.format_strikethrough,
                            quill.Attribute.strikeThrough,
                            theme,
                          ),
                          _buildToolbarButton(
                            Icons.format_align_left,
                            quill.Attribute.leftAlignment,
                            theme,
                          ),
                          _buildToolbarButton(
                            Icons.format_align_center,
                            quill.Attribute.centerAlignment,
                            theme,
                          ),
                          _buildToolbarButton(
                            Icons.format_align_right,
                            quill.Attribute.rightAlignment,
                            theme,
                          ),
                          _buildToolbarButton(
                            Icons.format_list_bulleted,
                            quill.Attribute.ul,
                            theme,
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

  Widget _buildToolbarButton(
    IconData icon,
    quill.Attribute attribute,
    ThemeData theme,
  ) {
    final isActive = controller.isAttributeActive(attribute);

    return IconButton(
      icon: Icon(
        icon,
        color: isActive
            ? Color(controller.note.colorValue)
            : invertColor(theme.primaryColor),
        size: 20,
      ),
      onPressed: () => controller.toggleAttribute(attribute),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }

  Widget _appBarAction({required Widget icon, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: IconButton(icon: icon, onPressed: onTap),
    );
  }
}

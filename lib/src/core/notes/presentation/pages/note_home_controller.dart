import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart' as quill;
import 'package:hive/hive.dart';
import 'package:note_taker/src/core/notes/data/models/note_model.dart';
import 'package:note_taker/src/core/notes/domains/entities/category.dart';
import 'package:note_taker/src/core/notes/domains/repositories/note_repository.dart';
import 'package:note_taker/src/core/notes/presentation/pages/note_editor_page.dart';
import 'package:note_taker/src/features/app_colors.dart';
import 'package:uuid/uuid.dart';

enum SortMode { updatedDesc, createdDesc, titleAsc }

class NotesHomeController extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  final _uuid = Uuid();

  String search = '';
  SortMode sortMode = SortMode.updatedDesc;
  Set<String> filterTags = {};
  Category? selectedCategory;
  int selectedDayIndex = 0;

  NotesHomeController() {
    searchController.addListener(() {
      final s = searchController.text.trim();
      if (s != search) {
        search = s;
        notifyListeners();
      }
    });
    // default select today
    final weekDays = getWeekDays();
    final today = DateTime.now();
    selectedDayIndex = weekDays.indexWhere(
      (d) =>
          d.year == today.year && d.month == today.month && d.day == today.day,
    );
    if (selectedDayIndex == -1) selectedDayIndex = 0;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<DateTime> getWeekDays() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  String plainTextFromDelta(quill.Delta d) {
    final buffer = StringBuffer();
    for (final op in d.toList()) {
      if (op.value is String) buffer.write(op.value as String);
    }
    return buffer.toString();
  }

  List<NoteModel> getFilteredSortedNotes() {
    final all = NotesRepository.getAll();
    List<NoteModel> filtered = all.where((n) {
      final plain = plainTextFromDelta(n.bodyDelta);

      final matchesSearch =
          search.isEmpty ||
          n.title.toLowerCase().contains(search.toLowerCase()) ||
          plain.toLowerCase().contains(search.toLowerCase());

      final matchesTags =
          filterTags.isEmpty ||
          filterTags.intersection(n.tags.toSet()).isNotEmpty;

      final matchesCategory =
          selectedCategory == null || n.category == selectedCategory;

      return matchesSearch && matchesTags && matchesCategory;
    }).toList();

    switch (sortMode) {
      case SortMode.updatedDesc:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case SortMode.createdDesc:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortMode.titleAsc:
        filtered.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
    }
    return filtered;
  }

  Future<void> createNewNote(BuildContext context) async {
    final now = DateTime.now();
    final newNote = NoteModel(
      id: _uuid.v4(),
      title: 'Untitled',
      bodyJson: (quill.Delta()..insert('\n')).toJson(),
      createdAt: now,
      updatedAt: now,
      category: Category.lectureNotes,
      colorValue: AppColors.randomNoteColor().value,
      tags: [],
    );
    await NotesRepository.addOrUpdate(newNote);

    final updated = await Navigator.of(context).push<NoteModel>(
      MaterialPageRoute(
        builder: (_) =>
            NoteEditorPage(noteId: newNote.id), // stub marker; UI will replace
      ),
    );

    if (updated != null) {
      await NotesRepository.addOrUpdate(updated);
    } else {
      final stored = NotesRepository.box.get(newNote.id);
      if (stored != null &&
          (stored.title == 'Untitled' &&
              plainTextFromDelta(stored.bodyDelta).trim().isEmpty)) {
        await NotesRepository.delete(newNote.id);
      }
    }
    notifyListeners();
  }

  Future<void> openNoteEditor(BuildContext context, NoteModel n) async {
    final updated = await Navigator.of(context).push<NoteModel>(
      MaterialPageRoute(builder: (_) => NoteEditorPage(noteId: n.id)),
    );
    if (updated != null) {
      await NotesRepository.addOrUpdate(updated);
      notifyListeners();
    }
  }

  void toggleTheme() {
    final box = Hive.box('settings');
    final current = box.get('darkMode', defaultValue: false) as bool;
    box.put('darkMode', !current);
    // no notify needed; UI reading Hive will update
  }

  Future<void> deleteNoteWithConfirm(BuildContext context, NoteModel n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete note?'),
        content: Text('This will permanently delete the note.'),
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
      await NotesRepository.delete(n.id);
      notifyListeners();
    }
  }

  Future<void> openSortMenu(BuildContext context) async {
    final chosen = await showModalBottomSheet<SortMode>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.update),
                title: Text('Sort by last modified'),
                selected: sortMode == SortMode.updatedDesc,
                onTap: () => Navigator.of(ctx).pop(SortMode.updatedDesc),
              ),
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Sort by creation date'),
                selected: sortMode == SortMode.createdDesc,
                onTap: () => Navigator.of(ctx).pop(SortMode.createdDesc),
              ),
              ListTile(
                leading: Icon(Icons.sort_by_alpha),
                title: Text('Sort alphabetically'),
                selected: sortMode == SortMode.titleAsc,
                onTap: () => Navigator.of(ctx).pop(SortMode.titleAsc),
              ),
            ],
          ),
        );
      },
    );
    if (chosen != null) {
      sortMode = chosen;
      notifyListeners();
    }
  }

  Future<void> openTagFilter(BuildContext context) async {
    final allNotes = NotesRepository.getAll();
    final tagSet = <String>{};
    for (final n in allNotes) tagSet.addAll(n.tags);
    final tags = tagSet.toList()..sort();

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      builder: (ctx) {
        final chosen = Set<String>.from(filterTags);
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      'Filter by Tags',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    if (tags.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            'No tags yet. Add tags from note editor.',
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView(
                          children: tags.map((t) {
                            final sel = chosen.contains(t);
                            return CheckboxListTile(
                              title: Text(t),
                              value: sel,
                              onChanged: (v) => setStateSB(
                                () => v == true
                                    ? chosen.add(t)
                                    : chosen.remove(t),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(<String>{}),
                          child: Text('Clear'),
                        ),
                        Spacer(),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(chosen),
                          child: Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      filterTags = result;
      notifyListeners();
    }
  }
}

// NOTE:
// The controller references NoteEditorPage; to avoid circular imports in this new file
// provide a small stub type here that the UI file will replace with the real NoteEditorPage.
// The controller uses Navigator to push a route built with this stub. The UI page that uses
// the controller should ensure the route builder returns the actual editor widget.
class NoteEditorPageStub extends StatelessWidget {
  final String noteId;
  const NoteEditorPageStub({required this.noteId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Replace NoteEditorPageStub in controller import usage.'),
      ),
    );
  }
}

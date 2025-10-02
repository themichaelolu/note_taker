import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:note_taker/src/core/notes/domains/entities/category.dart';
import 'package:note_taker/src/core/notes/domains/repositories/note_repository.dart';
import 'package:note_taker/src/core/notes/presentation/pages/note_home_controller.dart';
import 'package:note_taker/src/core/notes/presentation/widgets/category_chip.dart';

enum SortMode { updatedDesc, createdDesc, titleAsc }

enum _MenuAction { filter, sort, theme }

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({super.key});

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage>
    with SingleTickerProviderStateMixin {
  late final NotesHomeController controller;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    controller = NotesHomeController();
    controller.addListener(() => setState(() {}));

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = controller.getFilteredSortedNotes();
    final weekDays = controller.getWeekDays();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat.yMMMM().format(DateTime.now()),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<_MenuAction>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) {
              switch (action) {
                case _MenuAction.filter:
                  controller.openTagFilter(context);
                  break;
                case _MenuAction.sort:
                  controller.openSortMenu(context);
                  break;
                case _MenuAction.theme:
                  controller.toggleTheme();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _MenuAction.filter,
                child: ListTile(
                  leading: Icon(Icons.filter_list),
                  title: Text("Filter"),
                ),
              ),
              const PopupMenuItem(
                value: _MenuAction.sort,
                child: ListTile(leading: Icon(Icons.sort), title: Text("Sort")),
              ),
              const PopupMenuItem(
                value: _MenuAction.theme,
                child: ListTile(
                  leading: Icon(Icons.brightness_6),
                  title: Text("Toggle Theme"),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Search bar
            TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hint: Text(
                  'Search for notes',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
                prefixIcon: Icon(CupertinoIcons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📅 Weekday selector
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: weekDays.length,
                itemBuilder: (context, index) {
                  final date = weekDays[index];
                  final isSelected = controller.selectedDayIndex == index;
                  return GestureDetector(
                    onTap: () => controller.selectedDayIndex = index,
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat.E().format(date),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.d().format(date),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // 🏷️ Tag filter preview (categories)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  CategoryChip(
                    category: null,
                    label: "All",
                    selected: controller.selectedCategory == null,
                    onSelected: () =>
                        setState(() => controller.selectedCategory = null),
                  ),
                  CategoryChip(
                    category: Category.important,
                    label: "Important",
                    selected: controller.selectedCategory == Category.important,
                    onSelected: () => setState(
                      () => controller.selectedCategory = Category.important,
                    ),
                  ),
                  CategoryChip(
                    category: Category.lectureNotes,
                    label: "Lecture notes",
                    selected:
                        controller.selectedCategory == Category.lectureNotes,
                    onSelected: () => setState(
                      () => controller.selectedCategory = Category.lectureNotes,
                    ),
                  ),
                  CategoryChip(
                    category: Category.todoLists,
                    label: "To-do lists",
                    selected: controller.selectedCategory == Category.todoLists,
                    onSelected: () => setState(
                      () => controller.selectedCategory = Category.todoLists,
                    ),
                  ),
                  CategoryChip(
                    category: Category.shoppingList,
                    label: "Shopping list",
                    selected:
                        controller.selectedCategory == Category.shoppingList,
                    onSelected: () => setState(
                      () => controller.selectedCategory = Category.shoppingList,
                    ),
                  ),
                  CategoryChip(
                    category: Category.diary,
                    label: "Diary",
                    selected: controller.selectedCategory == Category.diary,
                    onSelected: () => setState(
                      () => controller.selectedCategory = Category.diary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 📝 Notes grid
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: NotesRepository.box.listenable(),
                builder: (context, box, _) {
                  final display = notes;
                  if (display.isEmpty) {
                    return Center(child: Text('No notes. Tap + to start.'));
                  }
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                    itemCount: display.length,
                    itemBuilder: (context, index) {
                      final n = display[index];
                      return GestureDetector(
                        onTap: () => controller.openNoteEditor(context, n),
                        onLongPress: () =>
                            controller.deleteNoteWithConfirm(context, n),
                        child: Container(
                          padding: const EdgeInsets.all(12),

                          decoration: BoxDecoration(
                            color: Color(n.colorValue),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  if (n.isPinned == true)
                                    Icon(
                                      CupertinoIcons.pin_fill,
                                      size: 24,
                                      color: Colors.grey.shade500,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  controller.plainTextFromDelta(n.bodyDelta),
                                  maxLines: 6,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
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
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(
          context,
        ).floatingActionButtonTheme.backgroundColor,
        shape: CircleBorder(),
        onPressed: () => controller.createNewNote(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:note_taker/src/core/notes/data/models/note_model.dart';
import 'package:note_taker/src/core/notes/domains/entities/category.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:note_taker/src/core/notes/presentation/pages/note_home_page.dart';
import 'package:note_taker/src/features/app_theme.dart';

enum ThemeSetting { system, light, dark }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(NoteModelAdapter());

  // open boxes
  await Hive.openBox('settings'); // for theme and other simple settings
  await Hive.openBox<NoteModel>('notes');

  runApp(NotesApp());
}

/// ---------- Models & Hive Adapters (manual, no codegen) ----------

/// ---------- App ----------

class NotesApp extends StatefulWidget {
  const NotesApp({super.key});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  final Box settingsBox = Hive.box('settings');
  bool get isDark => settingsBox.get('darkMode', defaultValue: false) as bool;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(keys: ['theme']),
      builder: (context, Box box, _) {
        final int modeIndex = box.get('theme', defaultValue: 0) as int;
        final themeSetting = ThemeSetting.values[modeIndex];
        return MaterialApp(
          title: 'Notes (Hive + Quill)',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeSetting == ThemeSetting.system
              ? ThemeMode.system
              : themeSetting == ThemeSetting.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const NotesHomePage(),
          localizationsDelegates: const [
            FlutterQuillLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

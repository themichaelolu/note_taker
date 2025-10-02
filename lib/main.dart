// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:note_taker/src/core/notes/data/models/note_model.dart';
import 'package:note_taker/src/core/notes/domains/entities/category.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:note_taker/src/core/notes/presentation/pages/note_home_page.dart';

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
      valueListenable: settingsBox.listenable(keys: ['darkMode']),
      builder: (context, Box box, _) {
        final dark = box.get('darkMode', defaultValue: false) as bool;
        return MaterialApp(
          title: 'Notes (Hive + Quill)',
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            fontFamily: 'EauSans',
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: true,
            appBarTheme: AppBarTheme(backgroundColor: Colors.white),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueGrey,
              brightness: Brightness.dark,
            ),
            brightness: Brightness.dark,
          ),
          home: NotesHomePage(),

          localizationsDelegates: const [
            FlutterQuillLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // add more if you want
          ],
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

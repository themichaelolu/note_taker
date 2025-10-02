import 'package:flutter/material.dart';
import 'dart:math';

class AppColors {
  static const Color pastelBlue = Color(0xFFC2DCFD);
  static const Color pastelPink = Color(0xFFFFD8F4);
  static const Color pastelYellow = Color(0xFFFBF6AA);
  static const primaryTextColor = Color(0xff212121);
  static const darkTextPrimaryColor = Color(0xffE0E0E0);
  static const Color pastelGreen = Color(0xFFB0E9CA);
  static const Color pastelCream = Color(0xFFFCFAD9);
  static const Color pastelLavender = Color(0xFFF1DBF5);
  static const Color pastelLightBlue = Color(0xFFD9E8FC);
  static const Color pastelPeach = Color(0xFFFFDBE3);

  static const List<Color> noteColors = [
    pastelBlue,
    pastelPink,
    pastelYellow,
    pastelGreen,
    pastelCream,
    pastelLavender,
    pastelLightBlue,
    pastelPeach,
  ];

  /// Get a random color for new notes
  static Color randomNoteColor() {
    final rand = Random();
    return noteColors[rand.nextInt(noteColors.length)];
  }
}

Color invertColor(Color color) {
  return Color.fromARGB(
    color.alpha,
    255 - color.red,
    255 - color.green,
    255 - color.blue,
  );
}

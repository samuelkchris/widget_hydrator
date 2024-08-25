import 'package:flutter/material.dart';

final appTheme = ThemeData.dark().copyWith(
  colorScheme: ColorScheme.dark(
    primary: Colors.deepPurple.shade300,
    secondary: Colors.tealAccent,
    surface: const Color(0xFF1E1E1E),
    background: const Color(0xFF121212),
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
  ),
);
import 'package:flutter/material.dart';

class AppTheme {
  static const teal    = Color(0xFF00C9A7);
  static const navy    = Color(0xFF0A0F1A);
  static const surface = Color(0xFF111827);
  static const card    = Color(0xFF1A2436);
  static const border  = Color(0xFF1F2F45);
  static const muted   = Color(0xFF64748B);
  static const amber   = Color(0xFFF59E0B);
  static const red     = Color(0xFFEF4444);

  static ThemeData dark() => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: navy,
    colorScheme: const ColorScheme.dark(
      primary: teal, secondary: amber,
      surface: navy,

    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface, elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: card, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: border)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: teal, width: 1.5)),
      labelStyle: const TextStyle(color: muted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: teal, foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    dividerColor: border,
    useMaterial3: true,
  );
}
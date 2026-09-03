import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  // 1. Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      surface: Colors.white,
      onSurface: Color(0xFF1E293B),
      outline: Color(0xFFE2E8F0),
    ),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFF1F5F9),
  );

  // 2. Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep dark background
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6C63FF),
      surface: Color(0xFF1E293B), // Dark card surface
      onSurface: Color(0xFFF8FAFC), // White/light text
      outline: Color(0xFF334155),
    ),
    cardColor: const Color(0xFF1E293B),
    dividerColor: const Color(0xFF334155),
  );
}

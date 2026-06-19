// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color forest    = Color(0xFF1B4332);
  static const Color forestMid = Color(0xFF2D6A4F);
  static const Color sage      = Color(0xFF52B788);
  static const Color mint      = Color(0xFFB7E4C7);
  static const Color cream     = Color(0xFFF8F4EF);
  static const Color sand      = Color(0xFFE9C46A);
  static const Color terra     = Color(0xFFE76F51);
  static const Color sky       = Color(0xFF90E0EF);
  static const Color white     = Color(0xFFFFFFFF);
  static const Color ink       = Color(0xFF344E41);
  static const Color grey      = Color(0xFF8D9E94);
  static const Color bgLight   = Color(0xFFF0F7F4);
  static const Color divider   = Color(0xFFDAEDE4);

  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.light(
          primary: sage, secondary: forestMid, surface: cream, error: terra,
        ),
        scaffoldBackgroundColor: bgLight,
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: sage, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          hintStyle: GoogleFonts.nunito(fontSize: 14, color: Color(0xFFABC4BB)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: forest, foregroundColor: cream, elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: cream),
          iconTheme: const IconThemeData(color: Color(0xFFF8F4EF)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: white, selectedItemColor: sage,
          unselectedItemColor: Color(0xFFADB5BD),
          type: BottomNavigationBarType.fixed, elevation: 16,
        ),
      );

  static Color? get bgLightGrey => null;

  static Color needColor(int s)  => s >= 70 ? forestMid : s >= 40 ? sand : terra;
  static Color fomoColor(int s)  => s <= 30 ? forestMid : s <= 60 ? sand : terra;
  static Color susColor(double s)=> s >= 70 ? forestMid : s >= 40 ? sand : terra;
}

// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ── Color Palette ──────────────────────────────────────────────────
  static const Color obsidianBlack    = Color(0xFF0A0A0F);
  static const Color obsidianSurface  = Color(0xFF12121A);
  static const Color obsidianCard     = Color(0xFF1A1A26);
  static const Color royalGold        = Color(0xFFFFD700);
  static const Color deepGold         = Color(0xFFB8860B);
  static const Color softGold         = Color(0xFFFFEC8B);
  static const Color glowGold         = Color(0xFFFFD70066);
  static const Color successGreen     = Color(0xFF00E676);
  static const Color dangerRed        = Color(0xFFFF1744);
  static const Color textPrimary      = Color(0xFFF5F5F5);
  static const Color textSecondary    = Color(0xFFB0BEC5);

  // ── Gold Gradient ──────────────────────────────────────────────────
  static const LinearGradient goldGradient = LinearGradient(
    colors: [royalGold, deepGold, royalGold],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1F1F2E), Color(0xFF252535)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldCardGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFB8860B), Color(0xFFFFD700)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Gold Glow Box Shadow ───────────────────────────────────────────
  static List<BoxShadow> goldGlow = [
    BoxShadow(color: royalGold.withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
    BoxShadow(color: royalGold.withOpacity(0.2), blurRadius: 40, spreadRadius: 4),
  ];

  static List<BoxShadow> subtleGlow = [
    BoxShadow(color: royalGold.withOpacity(0.15), blurRadius: 12, spreadRadius: 1),
  ];

  // ── ThemeData ──────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: obsidianBlack,
    colorScheme: const ColorScheme.dark(
      primary: royalGold,
      secondary: deepGold,
      surface: obsidianSurface,
      background: obsidianBlack,
      onPrimary: obsidianBlack,
      onSurface: textPrimary,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, letterSpacing: -1),
      titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textSecondary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: obsidianBlack,
      elevation: 0,
      titleTextStyle: TextStyle(color: royalGold, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 1),
      iconTheme: IconThemeData(color: royalGold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: royalGold,
        foregroundColor: obsidianBlack,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: obsidianCard,
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: Color(0xFF555566)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A3A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: royalGold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dangerRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dangerRed, width: 1.5),
      ),
    ),
  );
}

class AppConstants {
  static const String appName        = 'MarketMind Elite';
  static const String telegramHandle = '@YourSupportHandle';    // ← Update
  static const String masterPassword = 'Azoz200569@'; // ← Change before release

  static const Duration shimmerDuration = Duration(milliseconds: 1500);
  static const Duration tickerSpeed     = Duration(milliseconds: 30);
}

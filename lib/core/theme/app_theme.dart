import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF4F46E5);
  static const primaryOnDark = Color(0xFF818CF8);
  static const accent = Color(0xFF14B8A6);
  static const accentOnDark = Color(0xFF2DD4BF);

  static const backgroundLight = Color(0xFFF8FAFC);
  static const backgroundDark = Color(0xFF0B132B); // совпадает с тёмной картой
}

class AppRadius {
  AppRadius._();

  static const double field = 12;
  static const double chip = 12;
  static const double card = 16;
  static const double button = 16;
  static const double sheet = 24;
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
}

class AppTheme {
  AppTheme._();

  static const _font = 'Inter';

  static ColorScheme get _lightScheme => ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: AppColors.backgroundLight,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: Colors.white, // карточки
        surfaceContainerHigh: const Color(0xFFEEF1F6), // заливка полей
        surfaceContainerHighest: const Color(0xFFE5E9F0),
      );

  static ColorScheme get _darkScheme => ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.primaryOnDark,
        onPrimary: const Color(0xFF0B132B),
        secondary: AppColors.accentOnDark,
        onSecondary: const Color(0xFF0B132B),
        error: const Color(0xFFF87171),
        surface: AppColors.backgroundDark,
        onSurface: const Color(0xFFF1F5F9),
        onSurfaceVariant: const Color(0xFF9AA5C0),
        outlineVariant: const Color(0xFF2A3558),
        surfaceContainerLowest: const Color(0xFF0B132B),
        surfaceContainerLow: const Color(0xFF111A3A), // карточки
        surfaceContainerHigh: const Color(0xFF1B2547), // заливка полей
        surfaceContainerHighest: const Color(0xFF243056),
      );

  static ThemeData get light => _build(_lightScheme);
  static ThemeData get dark => _build(_darkScheme);

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _font,
    );

    final applied = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final text = applied.copyWith(
      titleLarge: applied.titleLarge
          ?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: applied.titleMedium
          ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      labelMedium:
          applied.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    );

    OutlineInputBorder fieldBorder() => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide.none, // рамки нет, только радиус
        );

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _font,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: fieldBorder(),
        enabledBorder: fieldBorder(),
        focusedBorder: fieldBorder(),
        disabledBorder: fieldBorder(),
        errorBorder: fieldBorder(),
        focusedErrorBorder: fieldBorder(),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(
            fontFamily: _font,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

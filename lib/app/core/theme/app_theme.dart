import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Builds the app's light and dark [ThemeData].
///
/// WHAT: two static getters, `light` and `dark`, each a fully-configured
/// Material 3 `ThemeData` derived from [AppColors].
///
/// WHY a class of static getters over two loose top-level variables:
/// keeps `AppTheme.light` / `AppTheme.dark` readable at the call site
/// (`main.dart`) and gives this file room to grow into computed theme
/// logic (e.g. high-contrast variant for accessibility) without changing
/// how callers use it.
///
/// WHERE: `core/theme` — imported once, by `app/app.dart`.
///
/// WHEN: evaluated once at `MaterialApp` construction; Flutter handles
/// switching between them based on `themeMode`/system brightness.
///
/// HOW: `ColorScheme.fromSeed` generates a full Material 3 palette from
/// the single brand seed color, so every default component (buttons,
/// switches, app bars) looks coherent without manually specifying dozens
/// of color roles.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
    );
  }
}

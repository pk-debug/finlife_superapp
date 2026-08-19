import 'package:flutter/material.dart';

/// Centralized color tokens for the app.
///
/// WHAT: named `Color` constants instead of hardcoded hex values sprinkled
/// through widgets.
/// WHY: this is the single edit point for a rebrand or a new domain-color
/// scheme — the tips doc that inspired this project's conventions calls
/// this out explicitly ("Use ThemeExtension for Design Tokens"); this file
/// is step one of that, with a `ThemeExtension` promoted to `app_theme.dart`
/// once more than color is being tokenized (spacing, radii).
/// WHERE: `core/theme` — importable by any widget in any feature.
/// WHEN: read at build time by any widget; never mutated at runtime (dark
/// mode is handled by `AppTheme`'s two `ThemeData` variants, not by
/// mutating these constants).
class AppColors {
  const AppColors._(); // no instances — static-only holder

  static const brandPrimary = Color(0xFF0B6E4F);
  static const brandSecondary = Color(0xFF1B998B);

  // Per-domain accent colors, used consistently so a user learns to
  // recognize "green = banking" etc. across the whole app over time.
  static const bankingAccent = Color(0xFF0B6E4F);
  static const insuranceAccent = Color(0xFF3D5A80);
  static const stockAccent = Color(0xFFB08900);
  static const consumerAccent = Color(0xFFB5446E);
  static const lifestyleAccent = Color(0xFF6A4C93);
}

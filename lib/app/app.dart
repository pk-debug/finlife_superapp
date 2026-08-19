import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'app_router.dart';

/// Root application widget.
///
/// WHAT: the single `MaterialApp.router` instance for the whole app —
/// theme + routing composition, nothing else.
///
/// WHY this file is intentionally almost empty: it's the composition
/// root. Every concern it touches (theme, routing) is fully defined
/// elsewhere (`core/theme`, `app/app_router.dart`); this file's only job
/// is wiring them together, which makes it a stable file that rarely
/// needs to change as features are added underneath it.
///
/// WHERE: `app/` — imported exactly once, from `main.dart`.
///
/// WHEN: built once; `MaterialApp.router` internally reacts to
/// `appRouter`'s navigation state, so this widget itself never rebuilds
/// due to navigation.
///
/// HOW: `ThemeMode.system` — follows the OS light/dark setting rather
/// than hardcoding one, per Material 3 defaults; a manual override
/// toggle (stored via a `ValueNotifier`, per the state-management table
/// in the README) is a natural feature-2-or-later addition, not needed
/// for the Home dashboard itself.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FinLife Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}

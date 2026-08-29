import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
/// WHY now a `ConsumerWidget` (it was `StatelessWidget` in feature 1):
/// `routerConfig` must come from `ref.watch(appRouterProvider)` now that
/// the router itself needs live access to auth state (see
/// `app_router.dart`) — this is the one line that changed here to enable
/// the entire auth-redirect flow; everything else in this file is
/// unchanged from feature 1.
///
/// WHERE: `app/` — imported exactly once, from `main.dart`.
///
/// WHEN: rebuilds only if `appRouterProvider` itself were ever replaced
/// (it isn't, in the current design — the `GoRouter` instance is stable
/// for the process lifetime; only its internal redirect state reacts to
/// auth changes, via `GoRouterRefreshStream`, not via provider rebuilds).
///
/// HOW: `ThemeMode.system` — follows the OS light/dark setting rather
/// than hardcoding one, per Material 3 defaults; a manual override
/// toggle (stored via a `ValueNotifier`, per the state-management table
/// in the README) remains a future addition, not needed for Auth or Home.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'FinLife Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
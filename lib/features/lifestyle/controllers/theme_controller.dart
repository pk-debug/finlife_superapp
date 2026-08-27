import 'package:get/get.dart';

/// Controls light/dark mode for the whole `/lifestyle` module — the
/// deliberate "Simple State Manager" (`GetBuilder`) example, sitting
/// right next to [HabitListController]'s "Reactive State Manager" (`Obx`)
/// example so the two GetX approaches can be compared directly.
///
/// WHAT: a plain field (`isDark`), no `.obs`. State changes only become
/// visible to the UI when [toggle] explicitly calls `update()`.
///
/// WHY use `GetBuilder` here specifically instead of making this reactive
/// too: this is the textbook case the GetX docs themselves point to —
/// "not everything needs Bloc, Riverpod, or Redux" applies equally to
/// "not everything needs `.obs`". A boolean that changes on a single
/// button tap, with exactly one consumer (the theme-switch in the
/// AppBar) and one thing rebuilding as a result (the whole nested
/// `GetMaterialApp`, since `themeMode` lives at that level) does not
/// benefit from `Obx`'s automatic dependency-tracking — `GetBuilder`'s
/// explicit `update()` call is simpler to read here: the exact moment
/// a rebuild happens is spelled out at the call site, not inferred from
/// which `Rx` a build method happened to read.
///
/// WHERE: registered once at module level (alongside [HabitService]) in
/// `lifestyle_module.dart`, NOT inside a per-page `Bindings` — the theme
/// choice must survive navigating between the module's pages, same
/// "module-lifetime state belongs at module root" rule [HabitService]
/// follows.
///
/// WHEN [toggle] is called: from the AppBar's theme-switch `IconButton`
/// on `HabitListView` — the only place in this module that exposes it.
class ThemeController extends GetxController {
  bool isDark = false;

  /// HOW: mutate the plain field, then call `update()` — `GetBuilder`
  /// widgets registered against this controller (there is exactly one,
  /// wrapping the nested `GetMaterialApp` in `lifestyle_module.dart`)
  /// rebuild in response. Contrast with [HabitService.toggleCompletedToday],
  /// where reactivity is automatic via `.obs`/`RxList` — no `update()`
  /// call exists there at all, because that's the other GetX approach.
  void toggle() {
    isDark = !isDark;
    update();
  }
}
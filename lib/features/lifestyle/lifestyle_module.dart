import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import 'controllers/habit_service.dart';
import 'controllers/theme_controller.dart';
import 'routes/lifestyle_pages.dart';
import 'routes/lifestyle_routes.dart';
import 'translations/lifestyle_translations.dart';

/// Entry point for a self-contained GetX learning module — a Habit
/// Tracker demonstrating every major GetX pillar, deliberately kept
/// independent of the rest of this app's Riverpod + go_router stack.
///
/// WHAT: a widget that, when built, registers this module's two
/// module-lifetime dependencies ([HabitService], [ThemeController]) and
/// returns a *nested* `GetMaterialApp` with its own `getPages` table —
/// i.e. an "app within the app". Everything under this widget (list,
/// add, detail pages) is pure GetX: no `ConsumerWidget`, no
/// `StateNotifier`, no `ref` anywhere in `features/lifestyle/`.
///
/// WHY nested `GetMaterialApp` instead of converting the whole app to
/// GetX, or trying to make GetX and go_router share one Navigator: this
/// was a deliberate, requested learning exercise — the goal is to
/// exercise GetX's full feature set, not to migrate the app's real
/// architecture off Riverpod/go_router (which the rest of this project
/// is intentionally standardized on — see the README's state-management
/// table). Nesting is the only approach that lets GetX's own root widget
/// exist (`GetMaterialApp` is what registers `Get.key`, the overlay
/// context `Get.snackbar`/`Get.dialog`/`Get.bottomSheet` all rely on)
/// without touching the outer `MaterialApp.router` at all.
///
/// HONEST CAVEAT — read before reusing this pattern anywhere real: GetX
/// treats its navigation/overlay state as effectively a singleton (one
/// active `Get.key` at a time). Nesting a second `GetMaterialApp` works
/// for a single, exclusively-GetX subtree like this one, but this
/// project does NOT recommend nesting *multiple* independent GetX
/// modules inside one app, or mixing GetX and go_router navigation calls
/// within the same screen — the one unavoidable seam this module has
/// with the outer app is documented at its single occurrence, in
/// `HabitListView._exitModule`. Production apps should pick one
/// navigation framework app-wide; this module exists specifically
/// because "pick one and learn it in isolation" was the stated goal.
///
/// WHERE: mounted at the go_router route `/lifestyle` in
/// `app/app_router.dart` — from the outer app's point of view, this
/// entire module is just one more `GoRoute` builder, no different in
/// shape from `HomeScreen` or `LoginScreen`.
///
/// WHEN [HabitService]/[ThemeController] are registered: guarded with
/// `Get.isRegistered<T>()` checks (see [build]) specifically because
/// this `build` method can legitimately run more than once (e.g. if
/// go_router rebuilds the route for unrelated reasons) — without the
/// guard, a second `Get.put(HabitService())` would silently replace the
/// first instance and wipe out any habits added or completions toggled
/// since the module was first entered. This is the single most important
/// correctness detail in this whole module and the easiest one to get
/// wrong by copying GetX tutorial code that assumes `Get.put` is only
/// ever called once, from a true `main()`.
class LifestyleModule extends StatelessWidget {
  const LifestyleModule({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<HabitService>()) {
      Get.put(HabitService(), permanent: true);
    }
    if (!Get.isRegistered<ThemeController>()) {
      Get.put(ThemeController(), permanent: true);
    }

    return GetBuilder<ThemeController>(
      builder: (theme) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Habits',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.lifestyleAccent),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.lifestyleAccent,
            brightness: Brightness.dark,
          ),
        ),
        themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
        translations: LifestyleTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        initialRoute: LifestyleRoutes.habitList,
        getPages: LifestylePages.pages,
      ),
    );
  }
}
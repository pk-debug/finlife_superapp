import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../controllers/habit_list_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/habit_tile.dart';

/// The module's home screen — habit list, search, theme toggle, language
/// toggle, and the module's single exit point back to the rest of the app.
///
/// WHAT: extends `GetView<HabitListController>` — GetX's convenience base
/// class that exposes a `controller` getter doing `Get.find<T>()` for
/// you, so this class never writes `Get.find` itself. Compare to this
/// app's Riverpod `HomeScreen`, which reads its ViewModel via
/// `ref.watch(homeViewModelProvider)` — `GetView` is the direct
/// structural analogue, just without needing a `WidgetRef` parameter
/// threaded through `build`.
///
/// WHY this view mixes `Obx` AND `GetBuilder` in the same widget tree:
/// intentionally, to make the contrast physically visible in one screen
/// — the AppBar's theme switch is wrapped in `GetBuilder<ThemeController>`
/// (simple state), the body's habit list is wrapped in
/// `Obx` reading `controller.filteredHabits` (reactive state). Neither is
/// "more correct" in general — see [ThemeController]'s docstring for why
/// each was chosen where it was.
///
/// WHERE this view sits in navigation: it is `LifestyleRoutes.habitList`,
/// this module's `initialRoute` — meaning it's also the *only* screen in
/// this module that needs a way back to the rest of the app (Home).
/// [_exitModule] is that seam, documented in detail below.
class HabitListView extends GetView<HabitListController> {
  const HabitListView({super.key});

  /// The one deliberate point of contact between this module's nested
  /// GetX `Navigator` and the app's outer go_router `Navigator`.
  ///
  /// WHY this can't just be `Get.back()`: this screen is the *root* of
  /// the nested `GetMaterialApp`'s own navigation stack — there is
  /// nothing beneath it for `Get.back()` to pop to within that stack.
  /// Calling it here would either no-op or (depending on GetX/Flutter
  /// Navigator version behavior) attempt to pop the nested Navigator
  /// itself out from under the still-mounted `GetMaterialApp`, which is
  /// exactly the kind of two-navigation-systems conflict this module's
  /// docstring (`lifestyle_module.dart`) warns about.
  ///
  /// HOW this works instead: `context.pop()` is go_router's extension on
  /// `BuildContext`, reaching up to the *outer* Navigator that owns the
  /// `/lifestyle` route itself — popping that route removes this entire
  /// nested GetX module from the tree and returns to whatever go_router
  /// route was active before (Home, via its own back button/gesture).
  ///
  /// WHY this one function is the only place `go_router` is imported
  /// anywhere in this GetX module: keeping that import contained to
  /// exactly one call site, with this much explanation attached, means
  /// anyone auditing "is this module really independent of the rest of
  /// the app's navigation" can find the one honest exception immediately
  /// instead of discovering it scattered across multiple files.
  void _exitModule(BuildContext context) => context.pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _exitModule(context),
        ),
        title: Text('habits_title'.tr),
        actions: [
          IconButton(
            tooltip: 'Toggle language',
            icon: const Icon(Icons.translate_rounded),
            onPressed: () {
              final next = Get.locale?.languageCode == 'hi'
                  ? const Locale('en', 'US')
                  : const Locale('hi', 'IN');
              Get.updateLocale(next);
            },
          ),
          // GetBuilder — the "Simple State Manager" pillar. Rebuilds only
          // this icon button when ThemeController.toggle() runs.
          GetBuilder<ThemeController>(
            builder: (theme) => IconButton(
              tooltip: 'Toggle theme',
              icon: Icon(theme.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
              onPressed: theme.toggle,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'search_hint'.tr,
                border: const OutlineInputBorder(),
              ),
              onChanged: controller.setSearchQuery,
            ),
            const SizedBox(height: 16),
            // Obx — the "Reactive State Manager" pillar. Rebuilds only
            // this list whenever filteredHabits changes, regardless of
            // whether that change came from typing, an ever() worker
            // reacting to a completion toggle elsewhere, or an add/delete.
            Expanded(
              child: Obx(() {
                final habits = controller.filteredHabits;
                if (habits.isEmpty) {
                  return Center(child: Text('no_results'.tr));
                }
                return ListView.builder(
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
                    final habit = habits[index];
                    return HabitTile(
                      habit: habit,
                      onTap: () => Get.toNamed(LifestyleRoutes.habitDetail, arguments: habit.id),
                      onToggleComplete: () => controller.toggleComplete(habit.id),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Get.toNamed — contextless named-route navigation, the "Route
        // Management" pillar. No BuildContext is passed or needed.
        onPressed: () => Get.toNamed(LifestyleRoutes.addHabit),
        icon: const Icon(Icons.add_rounded),
        label: Text('add_habit'.tr),
      ),
    );
  }
}
import 'package:get/get.dart';

import '../controllers/habit_list_controller.dart';

/// Wires up everything `HabitListView` needs, before it builds.
///
/// WHAT/WHY the `fenix: true` choice specifically: `Get.lazyPut` without
/// `fenix` fully deletes [HabitListController] the moment `HabitListView`
/// is popped (e.g. after pushing into a detail page and coming back —
/// wait, no: popping *back to* this page doesn't delete it; it's
/// navigating *away* from it, such as via the module's back button, that
/// would). `fenix: true` means "if something asks to `Get.find` this
/// controller again after it was deleted, silently recreate it" — the
/// right choice for a list screen a user might plausibly return to
/// within the same session, without this module needing to manually
/// track "has the list controller been created before".
///
/// WHERE: passed to the `GetPage` for [LifestyleRoutes.habitList] in
/// `lifestyle_pages.dart`.
///
/// WHEN: `dependencies()` runs once per navigation *to* this route —
/// GetX calls it before building the page widget, which is what makes
/// `Get.find<HabitListController>()` safe inside `HabitListView` with no
/// null-check needed.
class HabitListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HabitListController>(() => HabitListController(), fenix: true);
  }
}
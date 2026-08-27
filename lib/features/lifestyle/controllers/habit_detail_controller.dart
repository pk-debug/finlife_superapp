import 'package:get/get.dart';

import '../models/habit.dart';
import 'habit_service.dart';

/// Drives the habit detail page — the [Get.arguments] and
/// [Get.defaultDialog] demonstration in this module.
///
/// WHAT: reads which habit to show from [Get.arguments] rather than a
/// constructor parameter. WHY that's the correct GetX idiom here (not
/// just an arbitrary choice): `HabitDetailBinding` constructs this
/// controller with a no-argument `HabitDetailController()` — GetX's own
/// `Get.toNamed(route, arguments: habitId)` pattern is specifically
/// designed so the *page being navigated to* pulls its own arguments via
/// `Get.arguments`, decoupling the binding from needing to know what
/// argument was passed. The equivalent in this app's Riverpod features
/// is a route parameter read by the View and handed to a provider family
/// — same idea, different mechanism.
///
/// WHERE: page-scoped via [HabitDetailBinding], `fenix: false` (default)
/// — same reasoning as [AddHabitController]: a detail page for a
/// *specific* habit ID should not be kept alive after being popped, since
/// a future visit will pass a (possibly different) ID via fresh arguments
/// anyway.
class HabitDetailController extends GetxController {
  final HabitService _service = Get.find<HabitService>();

  /// HOW MUCH defensiveness: `Get.arguments as String` throws a
  /// `TypeError` immediately (during construction) if something calls
  /// this route without a `String` argument — a loud, early failure at
  /// the exact call site that got it wrong, rather than a confusing null
  /// somewhere deep in the view.
  late final String habitId = Get.arguments as String;

  /// A getter, not a stored field — reads through to the live [Habit] in
  /// [HabitService.habits] every time it's called, so `Obx` blocks in
  /// the view that read `controller.habit` stay correctly reactive to
  /// edits made from *other* screens too (e.g. toggling completion from
  /// the list view while this detail page is still on the stack).
  ///
  /// HOW: a manual loop, not `Iterable.firstWhereOrNull` — that
  /// extension lives in `package:collection`, which this module doesn't
  /// otherwise need; pulling in a whole package for one null-safe lookup
  /// isn't worth it when four lines does the same job with zero new
  /// dependencies.
  Habit? get habit {
    for (final h in _service.habits) {
      if (h.id == habitId) return h;
    }
    return null;
  }

  void toggleComplete() => _service.toggleCompletedToday(habitId);

  /// Shows a contextless confirmation dialog, then deletes on confirm.
  ///
  /// WHY [Get.defaultDialog] over a hand-rolled `showDialog` +
  /// `AlertDialog`: it needs no `BuildContext` at all — the whole point
  /// of this method living on the controller (not duplicated as
  /// UI-layer code in the view) is that it *can*, since GetX resolves
  /// its own overlay context internally. Compare to this app's Auth
  /// feature, where an equivalent confirmation would need a `BuildContext`
  /// threaded in from the widget calling it — that contrast is exactly
  /// what this whole module exists to make concrete.
  void confirmDelete() {
    Get.defaultDialog(
      title: 'Delete habit?',
      middleText: 'This can\'t be undone.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Get.theme.colorScheme.onError,
      buttonColor: Get.theme.colorScheme.error,
      onConfirm: () {
        _service.removeHabit(habitId);
        Get.back(); // close the dialog
        Get.back(); // pop the detail page itself
        Get.snackbar('Deleted', 'Habit removed.', snackPosition: SnackPosition.BOTTOM);
      },
    );
  }
}
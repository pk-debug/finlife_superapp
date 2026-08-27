import 'package:get/get.dart';

import '../controllers/habit_detail_controller.dart';

/// Wires up [HabitDetailController] for `HabitDetailView`.
///
/// WHY this binding takes no parameters even though the controller needs
/// to know *which* habit to show: see [HabitDetailController]'s own
/// docstring — the habit ID travels via [Get.arguments], read by the
/// controller itself once constructed, not threaded through this
/// binding. This keeps the binding identical in shape regardless of
/// which habit is being viewed, which is exactly why `Get.arguments` is
/// the idiom GetX provides for this case.
class HabitDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HabitDetailController>(() => HabitDetailController());
  }
}
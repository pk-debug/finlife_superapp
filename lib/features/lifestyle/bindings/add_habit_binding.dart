import 'package:get/get.dart';

import '../controllers/add_habit_controller.dart';

/// Wires up [AddHabitController] for `AddHabitView`.
///
/// WHY plain `Get.lazyPut` (no `fenix`) here, in direct contrast to
/// [HabitListBinding]: see [AddHabitController]'s own docstring — a form
/// controller should be fully discarded, including disposing its
/// `TextEditingController`, the instant this page is popped. `fenix`
/// would work against that by keeping the option open to silently
/// resurrect stale, half-filled form state.
class AddHabitBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddHabitController>(() => AddHabitController());
  }
}
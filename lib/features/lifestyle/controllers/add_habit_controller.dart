import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/habit.dart';
import 'habit_service.dart';

/// Drives the "Add Habit" form — a second, independent `GetBuilder`
/// example (see [ThemeController] for the first) chosen for a different
/// reason: this one shows `GetBuilder` doing real work (gating a submit
/// button on form validity), not just toggling a boolean.
///
/// WHERE: page-scoped via [AddHabitBinding] — plain `Get.lazyPut` (no
/// `fenix: true`), unlike [HabitListController]. WHY the difference:
/// there is no scenario where returning to this form should resume a
/// half-typed title from a previous visit — a fresh form every time is
/// the correct UX, so this controller should be fully discarded
/// (`GetxController.onClose` disposes [titleController]) the moment the
/// page is popped, not kept alive for a hypothetical revisit the way
/// `fenix: true` would allow.
///
/// WHEN destroyed: automatically, by GetX, the instant `AddHabitView` is
/// popped off the nested Navigator — no manual `Get.delete` call needed
/// anywhere in this module for page-scoped controllers.
class AddHabitController extends GetxController {
  final titleController = TextEditingController();

  static const _availableEmojis = ['💧', '📖', '🧘', '🚶', '🌙', '🏋️', '🥗', '🎯'];
  List<String> get availableEmojis => _availableEmojis;

  String selectedEmoji = _availableEmojis.first;

  bool get isValid => titleController.text.trim().isNotEmpty;

  /// HOW: wired to `TextField.onChanged` in `AddHabitView` — every
  /// keystroke calls `update()` so the submit button's enabled state
  /// (derived from [isValid]) stays in sync. This is the same "field
  /// state lives close to where it's typed" idea `PhoneEntryView` used
  /// in the Auth feature, just expressed with GetX's primitive instead
  /// of a `TextEditingController` listener + `setState`.
  void onTitleChanged(String _) => update();

  void selectEmoji(String emoji) {
    selectedEmoji = emoji;
    update();
  }

  /// Creates the habit, hands it to [HabitService], and closes this page
  /// — returning the newly-created [Habit] as the route's result.
  ///
  /// WHY return a result via `Get.back(result: ...)` rather than relying
  /// on the caller re-reading `HabitService.habits` after the pop: it's
  /// the direct GetX equivalent of `Navigator.pop(context, result)`, and
  /// demonstrating it here — even though `HabitListView` in this demo
  /// doesn't currently need the returned value, since it's already
  /// watching the same reactive `habits` list — is deliberate: a caller
  /// that pushes this same route from somewhere else in a larger app
  /// (with no reactive link back to `HabitService`) would need exactly
  /// this pattern, and it costs nothing to model correctly now.
  void submit() {
    if (!isValid) return;
    final habit = Habit(
      id: 'h_${DateTime.now().microsecondsSinceEpoch}',
      title: titleController.text.trim(),
      emoji: selectedEmoji,
    );
    Get.find<HabitService>().addHabit(habit);
    Get.back(result: habit);
  }

  @override
  void onClose() {
    titleController.dispose();
    super.onClose();
  }
}
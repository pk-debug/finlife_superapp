import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/add_habit_controller.dart';

/// The "Add Habit" form — pushed via `Get.toNamed`, popped via
/// `Get.back()` (this time correctly, since it's not the module root —
/// contrast with `HabitListView._exitModule`'s docstring on why *that*
/// screen can't use `Get.back()`).
///
/// WHAT's demonstrated here that isn't elsewhere in this module:
/// [Get.bottomSheet] — the third of GetX's three contextless overlay
/// primitives, alongside `Get.snackbar` (used in `HabitListController`'s
/// workers) and `Get.defaultDialog` (used in `HabitDetailController`).
/// All three are called from outside a widget's `build` method, with no
/// `BuildContext` parameter anywhere in the call.
class AddHabitView extends GetView<AddHabitController> {
  const AddHabitView({super.key});

  /// Opens the emoji picker as a bottom sheet.
  ///
  /// WHY a bottom sheet for this specifically, versus e.g. a `DropdownButton`
  /// inline in the form: it's a natural fit for picking one of several
  /// equally-weighted visual options — but more importantly for this
  /// module's purpose, it's the one overlay primitive the other two
  /// controllers didn't already cover, so putting it here (rather than,
  /// say, also using a dialog for this) means the module demonstrates
  /// snackbar, dialog, AND bottom sheet each exactly once, each in the
  /// place it fits best.
  void _openEmojiPicker() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: GetBuilder<AddHabitController>(
          builder: (c) => Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: c.availableEmojis.map((emoji) {
              final selected = emoji == c.selectedEmoji;
              return InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  c.selectEmoji(emoji);
                  Get.back(); // close the bottom sheet
                },
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      selected ? Get.theme.colorScheme.primaryContainer : Get.theme.colorScheme.surfaceContainerHighest,
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New habit')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GetBuilder<AddHabitController>(
                builder: (c) => InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: _openEmojiPicker,
                  child: CircleAvatar(
                    radius: 40,
                    child: Text(c.selectedEmoji, style: const TextStyle(fontSize: 32)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('Tap to choose an icon', style: TextStyle(fontSize: 12))),
            const SizedBox(height: 24),
            TextField(
              controller: controller.titleController,
              autofocus: true,
              onChanged: controller.onTitleChanged,
              decoration: const InputDecoration(
                labelText: 'Habit name',
                border: OutlineInputBorder(),
                hintText: 'e.g. Meditate',
              ),
            ),
            const SizedBox(height: 24),
            // GetBuilder gating the submit button on form validity —
            // rebuilds only this button on every keystroke, not the
            // whole screen (contrast: an Obx-based equivalent would need
            // controller.titleController.text wrapped in an RxString the
            // TextField writes to on every change — GetBuilder's explicit
            // update() call is simpler for this specific shape of state).
            GetBuilder<AddHabitController>(
              builder: (c) => FilledButton(
                onPressed: c.isValid ? c.submit : null,
                child: const Text('Add habit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
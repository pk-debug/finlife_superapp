import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/habit_detail_controller.dart';

/// Detail page for a single habit, reached from `HabitListView` via
/// `Get.toNamed(LifestyleRoutes.habitDetail, arguments: habit.id)`.
///
/// WHAT's notable here: the `Obx` in [build] wraps a read of
/// `controller.habit` — a *getter*, not a stored `Rx` field (see
/// [HabitDetailController.habit]'s docstring). GetX's dependency
/// tracking works by recording which `Rx` values were read during the
/// `Obx` callback's execution, regardless of how many function calls
/// deep that read happens — this view doesn't need to know or care that
/// `habit` is secretly reading `HabitService.habits` several calls away;
/// it only needs to read `controller.habit` inside `Obx` and reactivity
/// works correctly.
///
/// WHERE this page can be reached from: currently only `HabitListView`'s
/// tile taps — but because it resolves its subject entirely from
/// `Get.arguments` (not a constructor parameter), any future entry point
/// within this module (e.g. a "recently completed" widget) could push
/// this exact same route/binding pair with a different habit ID and it
/// would just work.
class HabitDetailView extends GetView<HabitDetailController> {
  const HabitDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: controller.confirmDelete, // Get.defaultDialog, see controller
          ),
        ],
      ),
      body: Obx(() {
        final habit = controller.habit;
        // WHY this null-check matters even though the habit "should"
        // always exist when this page is reached from the list: it's
        // the correct defensive read for a value sourced from a live,
        // mutable list by ID — e.g. deleting a habit from elsewhere
        // while this exact detail page happens to still be mounted
        // (not reachable via this module's current UI, but a real
        // possibility the reactive getter makes safe to handle anyway).
        if (habit == null) {
          return const Center(child: Text('This habit no longer exists.'));
        }
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(habit.emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(habit.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                habit.streak > 0 ? ' ${habit.streak} ${'day_streak'.tr}' : 'No streak yet',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: controller.toggleComplete,
                icon: Icon(habit.isCompletedToday ? Icons.undo_rounded : Icons.check_rounded),
                label: Text(habit.isCompletedToday ? 'Mark not done' : 'Mark done today'),
              ),
            ],
          ),
        );
      }),
    );
  }
}
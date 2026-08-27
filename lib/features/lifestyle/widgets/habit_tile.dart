import 'package:flutter/material.dart';

import '../models/habit.dart';

/// A single row in the habit list — purely presentational, exactly like
/// `DomainSummaryCard` elsewhere in this app (see that widget's
/// docstring for the general reasoning, not repeated here).
///
/// WHAT's GetX-specific about this file: nothing, deliberately. This
/// widget takes plain data in and emits plain callbacks out — it doesn't
/// know `HabitListController` or `HabitService` exist. That's the point:
/// even inside a GetX-flavored module, not every widget needs to reach
/// for `Get.find`/`GetView` — a "dumb" presentational widget is exactly
/// as appropriate here as it is in the Riverpod side of this app.
class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.onTap,
    required this.onToggleComplete,
  });

  final Habit habit;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Text(habit.emoji, style: const TextStyle(fontSize: 28)),
        title: Text(habit.title),
        subtitle: habit.streak > 0
            ? Text('🔥 ${habit.streak}-day streak', style: theme.textTheme.bodySmall)
            : null,
        trailing: IconButton(
          icon: Icon(
            habit.isCompletedToday ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: habit.isCompletedToday ? theme.colorScheme.primary : theme.disabledColor,
          ),
          onPressed: onToggleComplete,
        ),
      ),
    );
  }
}
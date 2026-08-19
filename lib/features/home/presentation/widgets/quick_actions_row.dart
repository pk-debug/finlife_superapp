import 'package:flutter/material.dart';

/// A single tappable quick-action chip, e.g. "Pay", "Scan QR".
///
/// WHAT/WHY/WHERE: see [QuickActionsRow] docstring — this class exists
/// only to give each action item a stable, testable widget rather than
/// building `Column`s ad hoc inside a `ListView.builder` callback.
class QuickAction {
  const QuickAction({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

/// Horizontal, scrollable row of top-level quick actions on Home.
///
/// WHAT: renders a fixed list of [QuickAction]s ("Pay", "Scan QR",
/// "Add Money", "Track Order", "Support") as tappable icon+label chips.
///
/// WHY a dedicated widget instead of inlining a `Row`/`ListView` in
/// `HomeScreen`: same rebuild-isolation reasoning as [GreetingHeader] —
/// the actions list is static content, independent of `HomeState`, so it
/// should not be rebuilt on every dashboard refresh. It also gives this
/// exact widget a name that can carry a golden test later ("quick actions
/// row golden test") without dragging the whole Home screen into that test.
///
/// WHERE: `features/home/presentation/widgets` — private to Home today;
/// candidate for promotion to `core/widgets` the moment a second screen
/// (e.g. Banking's own dashboard) wants the same chip-row pattern.
///
/// WHEN: built once per Home build; the row itself has no internal state.
///
/// HOW: `ListView.builder` with `scrollDirection: Axis.horizontal` — kept
/// builder-based (not `Row` + `SingleChildScrollView`) on purpose, even
/// though today's list is short, so this doesn't silently become a
/// performance trap if the action list grows.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key, required this.actions});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final action = actions[index];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: action.onTap,
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(action.icon, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    action.label,
                    style: theme.textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

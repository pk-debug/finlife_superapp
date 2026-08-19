import 'package:flutter/material.dart';

/// Time-aware greeting shown at the top of Home ("Good morning, ...").
///
/// WHAT: a tiny stateless widget computing "Good morning/afternoon/evening"
/// from the current wall-clock time and displaying it beside a name.
///
/// WHY it's a separate widget rather than inline text in `HomeScreen.build`:
/// per the project's "split widgets to reduce rebuilds" convention — this
/// piece never depends on `HomeState` at all (it only reads `DateTime.now()`
/// and a static name), so keeping it separate means it is *not* rebuilt
/// every time the dashboard's async data changes, only when its own
/// parent forces a rebuild.
///
/// WHERE: `features/home/presentation/widgets` — private to Home; not
/// promoted to `core/widgets` because nothing else needs a greeting.
///
/// WHEN: the greeting bucket (morning/afternoon/evening) is computed once
/// per build — acceptable because Home is rebuilt on navigation, not on a
/// timer, so staleness across a midnight boundary is not a real concern.
///
/// HOW: plain `DateTime.now().hour` bucketing — no `intl` needed for
/// something this coarse; `intl` is reserved for actual date/currency
/// formatting in the data layer (see `DomainSummaryModel`).
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key, required this.userName});

  final String userName;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$_greeting,', style: theme.textTheme.bodyLarge),
        Text(
          userName,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../features/home/domain/entities/domain_summary.dart';
import '../theme/app_colors.dart';

/// A single dashboard tile rendering one [DomainSummary].
///
/// WHAT: purely presentational — takes data in via constructor params,
/// emits a tap event via [onTap]. Holds zero state and no business logic.
///
/// WHY it lives in `core/widgets` rather than `features/home/presentation/
/// widgets`: this card is expected to be reused by *other* features later
/// (e.g. a "Banking" tab could show the same card style for sub-accounts).
/// The rule of thumb this project follows: a widget stays inside a
/// feature's own `presentation/widgets` folder until a second feature
/// needs it — then it moves to `core/widgets`. This one is promoted
/// pre-emptively because the Home dashboard's whole purpose is to be a
/// visual entry point *into* every other domain, so reuse is a near-term
/// certainty, not speculation.
///
/// WHERE: `core/widgets` — may be imported by any feature; must never
/// import anything from a specific feature's `domain` or `data` layer
/// (it already imports `DomainSummary` from Home's domain layer, which is
/// the one acceptable exception since that entity is the shared
/// display-projection type by design — see that class's own docstring).
///
/// WHEN: rebuilt whenever the [DomainSummary] passed to it changes
/// (standard `StatelessWidget` rebuild — no internal animation state to
/// manage here, which is why `const` constructors upstream matter: a
/// `DomainSummaryCard` whose summary hasn't changed should not rebuild
/// at all when a sibling card's data updates).
///
/// HOW: a `Card` + `InkWell` for the tap ripple, laid out with a
/// `Column` — deliberately simple, no `CustomPainter`, no animation,
/// because a dashboard tile is read constantly and any per-frame cost
/// here is paid on every scroll.
class DomainSummaryCard extends StatelessWidget {
  const DomainSummaryCard({
    super.key,
    required this.summary,
    required this.icon,
    this.onTap,
  });

  final DomainSummary summary;

  /// Icon representing the domain, chosen by the caller (Home screen maps
  /// [AppDomain] → icon) rather than hardcoded here, so this widget stays
  /// domain-agnostic and reusable.
  final IconData icon;

  /// Called when the card is tapped. `null` disables the tap ripple.
  ///
  /// WHEN: Home wires this to `context.push('/route-for-domain')` via
  /// go_router once each domain's screen exists; today (feature 1) it's
  /// wired to a placeholder snackbar since those routes don't exist yet.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: AppColors.brandPrimary, size: 22),
                  if (summary.isStale)
                    Tooltip(
                      message: 'Showing cached data',
                      child: Icon(
                        Icons.sync_problem_rounded,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(summary.title, style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(
                summary.headlineValue,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                summary.statusLine,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

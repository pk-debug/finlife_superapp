import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/domain_summary_card.dart';
import '../../domain/entities/domain_summary.dart';
import '../providers/home_providers.dart';
import '../state/home_state.dart';
import '../widgets/greeting_header.dart';
import '../widgets/quick_actions_row.dart';

/// Home Dashboard screen — the "V" in MVVM, and the app's landing screen.
///
/// WHAT: renders a greeting, a row of quick actions, and a grid of
/// [DomainSummaryCard]s (one per business domain), sourced entirely from
/// [homeViewModelProvider]'s [HomeState].
///
/// WHY a `ConsumerWidget` (not `ConsumerStatefulWidget`): this screen owns
/// no local mutable state of its own — everything it needs to react to
/// lives in `HomeState` via Riverpod. Reaching for `StatefulWidget` "just
/// in case" is exactly the kind of unnecessary complexity this
/// architecture is meant to avoid; add local state only when a genuine
/// need appears (e.g. a scroll controller for a collapsing app bar).
///
/// WHERE: `presentation/views` — the only file in the Home feature that
/// is allowed to import `core/widgets` UI components and wire them to
/// this feature's own ViewModel. It imports nothing from `data/`.
///
/// WHEN: built whenever `homeViewModelProvider`'s state changes (loading
/// → data, or loading → error, or data → data on refresh) — Riverpod's
/// `ref.watch` handles the rebuild scoping automatically.
///
/// WHO: registered as the app's initial route in `app/app_router.dart`.
///
/// HOW: three states are rendered explicitly — loading (spinner),
/// error+no-data (full-screen retry), and data (the actual dashboard,
/// wrapped in `RefreshIndicator` for pull-to-refresh) — so there is never
/// an ambiguous "in-between" UI.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('FinLife Hub')),
      body: SafeArea(
        child: switch (state) {
          _ when state.isLoading => const Center(child: CircularProgressIndicator()),
          _ when state.hasError && !state.hasData => _ErrorRetry(
              message: state.errorMessage!,
              onRetry: () => ref.read(homeViewModelProvider.notifier).load(),
            ),
          _ => _DashboardBody(state: state, ref: ref),
        },
      ),
    );
  }
}

/// Full-screen error state with a retry button.
///
/// WHEN shown: only when there is an error AND no cached/previous data to
/// fall back to (see [HomeState.hasError] / [HomeState.hasData] usage in
/// [HomeScreen.build]) — a refresh failure with existing data on screen
/// is deliberately handled differently once `HomeViewModel.refresh`'s
/// TODO (see that file) is implemented.
class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text('Couldn\'t load your dashboard', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// The actual dashboard content — greeting, quick actions, domain grid.
///
/// WHY split out of [HomeScreen.build] rather than inlined in the
/// `switch` expression's data branch: keeps `HomeScreen.build` readable
/// as "pick which of three states to show" and puts the real layout in
/// its own widget, consistent with the "split widgets" convention used
/// throughout this feature.
class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.state, required this.ref});

  final HomeState state;
  final WidgetRef ref;

  IconData _iconFor(AppDomain domain) => switch (domain) {
        AppDomain.banking => Icons.account_balance_rounded,
        AppDomain.insurance => Icons.shield_outlined,
        AppDomain.stock => Icons.show_chart_rounded,
        AppDomain.consumer => Icons.shopping_bag_outlined,
        AppDomain.lifestyle => Icons.favorite_border_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => ref.read(homeViewModelProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GreetingHeader(userName: 'Alex'),
          const SizedBox(height: 20),
          QuickActionsRow(
            actions: [
              QuickAction(
                label: 'Pay',
                icon: Icons.send_rounded,
                onTap: () => _placeholderSnackbar(context, 'Pay'),
              ),
              QuickAction(
                label: 'Scan QR',
                icon: Icons.qr_code_scanner_rounded,
                onTap: () => _placeholderSnackbar(context, 'Scan QR'),
              ),
              QuickAction(
                label: 'Add Money',
                icon: Icons.add_card_rounded,
                onTap: () => _placeholderSnackbar(context, 'Add Money'),
              ),
              QuickAction(
                label: 'Track Order',
                icon: Icons.local_shipping_outlined,
                onTap: () => _placeholderSnackbar(context, 'Track Order'),
              ),
              QuickAction(
                label: 'Support',
                icon: Icons.headset_mic_outlined,
                onTap: () => _placeholderSnackbar(context, 'Support'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Overview', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.summaries.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              final summary = state.summaries[index];
              return DomainSummaryCard(
                summary: summary,
                icon: _iconFor(summary.domain),
                // WHY Lifestyle is special-cased here instead of staying
                // a placeholder like every other domain card: it's the
                // first domain with a real screen behind it — the GetX
                // Habit Tracker module at `/lifestyle`. Every other card
                // stays a placeholder until its own feature drop lands,
                // same as before.
                onTap: summary.domain == AppDomain.lifestyle
                    ? () => context.push('/lifestyle')
                    : () => _placeholderSnackbar(context, summary.title),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Stand-in for real navigation until each domain's own screen exists.
  ///
  /// WHY a snackbar and not a silently-ignored tap: makes every card
  /// visibly interactive during manual QA even before routes exist,
  /// instead of looking broken.
  void _placeholderSnackbar(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — coming in a later feature drop'),
        backgroundColor: AppColors.brandPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
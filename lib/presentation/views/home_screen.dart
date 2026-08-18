// packages/features/home/lib/presentation/views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife_superapp/domain/entities/home_summary.dart';
import 'package:finlife_superapp/domain/entities/recent_transaction.dart';
import 'package:finlife_superapp/presentation/viewmodels/home_state.dart';
import 'package:finlife_superapp/presentation/viewmodels/home_viewmodel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    // Load data on first build (could also be done in a initState via stateful)
    if (state.status == HomeStatus.initial) {
      // Schedule after frame to avoid calling during build.
      Future.microtask(() => viewModel.loadHomeData());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinLife Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: _buildBody(context, state),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.errorMessage}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read(homeViewModelProvider.notifier).loadHomeData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Success state
    final summary = state.summary;
    final transactions = state.recentTransactions;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGreetingCard(summary?.userName ?? 'User'),
        const SizedBox(height: 16),
        _buildQuickActions(context),
        const SizedBox(height: 16),
        _buildSummaryCards(summary),
        const SizedBox(height: 16),
        _buildRecentTransactions(transactions),
      ],
    );
  }

  Widget _buildGreetingCard(String userName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning, $userName',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome back to your financial hub.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.account_balance,
        label: 'Banking',
        onTap: () => context.go('/banking'),
      ),
      _QuickAction(
        icon: Icons.health_and_safety,
        label: 'Insurance',
        onTap: () => context.go('/insurance'),
      ),
      _QuickAction(
        icon: Icons.show_chart,
        label: 'Stocks',
        onTap: () => context.go('/stocks'),
      ),
      _QuickAction(
        icon: Icons.shopping_cart,
        label: 'Shop',
        onTap: () => context.go('/consumer'),
      ),
      _QuickAction(
        icon: Icons.fitness_center,
        label: 'Lifestyle',
        onTap: () => context.go('/lifestyle'),
      ),
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => actions[index],
      ),
    );
  }

  Widget _buildSummaryCards(HomeSummary? summary) {
    if (summary == null) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Account Balance',
            value: '₹${summary.accountBalance.toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Portfolio',
            value: '₹${summary.portfolioValue.toStringAsFixed(2)}',
            icon: Icons.trending_up,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(List<RecentTransaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          const Text('No recent transactions')
        else
          ...transactions.map((tx) => _TransactionTile(transaction: tx)),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0, // Home is selected
      onTap: (index) {
        // Use go_router to navigate to respective top-level routes
        switch (index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/banking');
            break;
          case 2:
            context.go('/stocks');
            break;
          case 3:
            context.go('/consumer');
            break;
          case 4:
            context.go('/lifestyle');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_balance), label: 'Banking'),
        BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Stocks'),
        BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart), label: 'Shop'),
        BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center), label: 'Life'),
      ],
    );
  }
}

// Custom widgets (could be in separate files)
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            child: Icon(icon, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final RecentTransaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.amount > 0;
    return ListTile(
      leading: Icon(
        isCredit ? Icons.arrow_downward : Icons.arrow_upward,
        color: isCredit ? Colors.green : Colors.red,
      ),
      title: Text(transaction.title),
      subtitle: Text(
        '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
      ),
      trailing: Text(
        '₹${transaction.amount.abs().toStringAsFixed(2)}',
        style: TextStyle(
          color: isCredit ? Colors.green : Colors.red,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
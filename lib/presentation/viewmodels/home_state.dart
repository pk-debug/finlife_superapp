// packages/features/home/lib/presentation/viewmodels/home_state.dart
import 'package:finlife_superapp/domain/entities/home_summary.dart';
import 'package:finlife_superapp/domain/entities/recent_transaction.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState {
  final HomeStatus status;
  final HomeSummary? summary;
  final List<RecentTransaction> recentTransactions;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.summary,
    this.recentTransactions = const [],
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    HomeSummary? summary,
    List<RecentTransaction>? recentTransactions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get isLoading => status == HomeStatus.loading;
  bool get hasError => status == HomeStatus.failure;
}
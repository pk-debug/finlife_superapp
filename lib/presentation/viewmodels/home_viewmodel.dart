// packages/features/home/lib/presentation/viewmodels/home_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlife_superapp/domain/use_cases/get_home_data.dart';
import 'package:finlife_superapp/presentation/viewmodels/home_state.dart';

// Provider for the use case (will be provided by DI in a real app)
final getHomeDataProvider = Provider<GetHomeData>((ref) {
  // In a real app, this would be created using the repository.
  throw UnimplementedError('GetHomeData should be provided');
});

// StateNotifierProvider for HomeViewModel
final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  final getHomeData = ref.watch(getHomeDataProvider);
  return HomeViewModel(getHomeData);
});

class HomeViewModel extends StateNotifier<HomeState> {
  final GetHomeData _getHomeData;

  HomeViewModel(this._getHomeData) : super(const HomeState());

  Future<void> loadHomeData() async {
    state = state.copyWith(status: HomeStatus.loading);
    try {
      final data = await _getHomeData.execute();
      state = state.copyWith(
        status: HomeStatus.success,
        summary: data.summary,
        recentTransactions: data.recentTransactions,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: HomeStatus.failure,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() => loadHomeData();
}
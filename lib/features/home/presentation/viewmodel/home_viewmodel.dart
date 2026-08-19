import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/get_home_dashboard.dart';
import '../state/home_state.dart';

/// ViewModel for the Home screen — the "VM" in MVVM.
///
/// WHAT: owns [HomeState], exposes it as a Riverpod-observable stream of
/// values, and exposes intent methods (`load`, `refresh`) that the View
/// calls in response to user actions/lifecycle events.
///
/// WHY `StateNotifier<HomeState>` specifically (over `AsyncNotifier` or a
/// raw `ChangeNotifier`): `StateNotifier` gives immutable-state-in,
/// immutable-state-out semantics, which pairs naturally with the
/// `HomeState` value class above and is trivial to unit test — construct
/// the notifier with a fake use case, call a method, assert on `.state`,
/// no widget tree required. A raw `ChangeNotifier` would allow accidental
/// in-place mutation; `AsyncNotifier` was considered but this project's
/// convention (see README) is to keep the View decoupled from Riverpod's
/// `AsyncValue` type specifically, in favor of the feature's own
/// `HomeState`.
///
/// WHERE: `presentation/viewmodel` — depends only on
/// `domain/usecases/get_home_dashboard.dart`. It does NOT import anything
/// from `data/` — that's the whole payoff of the use-case indirection.
///
/// WHEN: constructed once per Home screen lifetime via
/// `homeViewModelProvider` (see `home_providers.dart`); `load()` is
/// triggered on construction; `refresh()` is triggered by user
/// pull-to-refresh.
///
/// WHO: consumed only by `HomeScreen` (the View) via
/// `ref.watch(homeViewModelProvider)`. Widgets never call the use case or
/// repository directly — always through this ViewModel.
///
/// HOW: every state transition goes through `state = HomeState.xxx(...)`
/// — Riverpod diffs and notifies listeners automatically because
/// [HomeState] implements value equality via [Equatable].
class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel(this._getHomeDashboard) : super(const HomeState.loading()) {
    load();
  }

  final GetHomeDashboard _getHomeDashboard;

  /// Initial load, called automatically from the constructor.
  ///
  /// WHEN: once, at ViewModel construction — i.e. the first time
  /// `homeViewModelProvider` is read (Riverpod providers are lazy).
  Future<void> load() async {
    state = const HomeState.loading();
    await _fetchAndSetState();
  }

  /// Pull-to-refresh entry point.
  ///
  /// HOW it currently differs from [load]: functionally identical today.
  /// TODO(feature-2): once [HomeState] is shown to real users, change
  /// this to keep `state.summaries` visible (pass them through as the
  /// fallback in `HomeState.error`) instead of clearing to a full loading
  /// state, so a refresh failure doesn't blank a screen that already had
  /// good data on it.
  Future<void> refresh() => _fetchAndSetState();

  Future<void> _fetchAndSetState() async {
    try {
      final summaries = await _getHomeDashboard();
      state = HomeState.data(summaries);
    } catch (e) {
      // HOW MUCH: no retry/backoff here — Home is a low-stakes read, a
      // manual pull-to-refresh is an acceptable retry mechanism. Compare
      // to Stock's WebSocket reconnect, which does need exponential
      // backoff because it's a persistent connection, not a one-shot GET.
      state = HomeState.error(e.toString());
    }
  }
}

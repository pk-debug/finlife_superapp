import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/home_remote_data_source.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/usecases/get_home_dashboard.dart';
import '../state/home_state.dart';
import '../viewmodel/home_viewmodel.dart';

/// Single file owning the entire Home feature's dependency graph.
///
/// WHAT: one `Provider` per layer (datasource → repository → use case →
/// ViewModel), each depending only on the provider directly below it.
///
/// WHY centralize wiring here instead of constructing dependencies inline
/// inside the ViewModel or View: this is the *only* file in the Home
/// feature that is allowed to know about every layer at once. Everywhere
/// else (View, ViewModel, UseCase, Repository) only ever sees the layer
/// directly beneath it. When the fake datasource is swapped for a real
/// Dio-backed one, exactly one line changes — [_remoteDataSourceProvider]
/// — and nothing else in the app needs to know.
///
/// WHERE: `presentation/providers` by convention (Riverpod providers are
/// technically framework-agnostic wiring, but they're grouped with
/// presentation since that's their only consumer here).
///
/// WHEN: providers are lazy — none of this runs until `HomeScreen` first
/// calls `ref.watch(homeViewModelProvider)`.
///
/// HOW: plain `Provider`s for the stateless layers (datasource,
/// repository, use case) and a `StateNotifierProvider` for the one
/// stateful layer (the ViewModel).
final _remoteDataSourceProvider = Provider<HomeRemoteDataSource>(
  (ref) => FakeHomeRemoteDataSource(),
);

final _repositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(ref.watch(_remoteDataSourceProvider)),
);

final _getHomeDashboardProvider = Provider<GetHomeDashboard>(
  (ref) => GetHomeDashboard(ref.watch(_repositoryProvider)),
);

/// The provider [HomeScreen] actually watches.
///
/// HOW MUCH: exactly one instance lives for as long as any widget is
/// watching it (default Riverpod `Provider` semantics, no `.autoDispose`
/// — the dashboard is cheap enough to keep warm across navigation for
/// snappier back-navigation; revisit with `.autoDispose` if memory
/// profiling ever flags it).
final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>(
  (ref) => HomeViewModel(ref.watch(_getHomeDashboardProvider)),
);

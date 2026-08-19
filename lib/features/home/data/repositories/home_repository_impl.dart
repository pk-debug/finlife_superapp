import '../../domain/entities/domain_summary.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

/// Concrete implementation of [HomeRepository] backed by a remote
/// datasource.
///
/// WHAT: the class that actually fulfills the domain layer's contract —
/// fetches [DomainSummaryModel]s and maps each one to a [DomainSummary]
/// before returning it.
///
/// WHY this thin: for Home specifically there's no local cache or
/// conflict resolution to do — it's read-only aggregation. Compare this
/// to the *documented* design for Banking's offline-first sync (local DB
/// as source of truth, write-ahead queue, server-authoritative conflict
/// resolution): that complexity belongs in `BankingRepositoryImpl`, not
/// here. Repositories are exactly as complex as their domain requires —
/// resist the urge to add caching "for consistency" where nothing needs it.
///
/// WHERE: `data/repositories` — the only place in the app allowed to
/// import both a `data/datasources` class and a `domain/entities` class
/// in the same file; that's precisely its job, translating between them.
///
/// WHEN: constructed once via Riverpod provider; each call to
/// [getDashboardSummaries] triggers one datasource fetch (no internal
/// caching — see WHY above).
///
/// HOW: delegate to [HomeRemoteDataSource], then `.map(toEntity)` over
/// the result. If the datasource throws, this method lets the exception
/// propagate — the ViewModel is the layer responsible for turning a
/// thrown exception into `AsyncValue.error` for the UI.
class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._remoteDataSource);

  final HomeRemoteDataSource _remoteDataSource;

  @override
  Future<List<DomainSummary>> getDashboardSummaries() async {
    final models = await _remoteDataSource.fetchDashboardSummaries();
    return models.map((model) => model.toEntity()).toList();
  }
}

import '../entities/domain_summary.dart';

/// Contract for fetching the aggregated dashboard data shown on Home.
///
/// WHAT: an interface (abstract class) — not an implementation. The domain
/// layer only says *what* it needs, never *how* it's fetched.
///
/// WHY an interface at all: this is the seam that lets `data/` be swapped
/// (fake in-memory today → Dio + Drift cache tomorrow) without touching
/// [HomeViewModel] or any test written against this contract. It's also
/// what makes the ViewModel trivially unit-testable with a fake/mock.
///
/// WHERE: implemented by `HomeRepositoryImpl` in the `data` layer; consumed
/// by `usecases/get_home_dashboard.dart` in this same `domain` layer.
///
/// WHO: any future domain-specific repository (BankingRepository,
/// StockRepository, ...) should follow this exact shape — interface in
/// `domain`, implementation in `data`.
abstract class HomeRepository {
  /// Fetches the current summary tile for every business domain.
  ///
  /// WHEN: called once on Home screen load, and again on pull-to-refresh.
  /// HOW: implementations decide the strategy (parallel fetch + cache
  /// fallback per domain is the intended real-world approach — see
  /// `HomeRepositoryImpl` docs).
  /// HOW MUCH: expected to return one [DomainSummary] per [AppDomain]
  /// value; callers should not assume a fixed list length beyond that.
  ///
  /// Throws whatever the underlying data source throws on total failure
  /// (e.g. no network AND no cache) — the ViewModel is responsible for
  /// turning that into user-facing error state, not this layer.
  Future<List<DomainSummary>> getDashboardSummaries();
}

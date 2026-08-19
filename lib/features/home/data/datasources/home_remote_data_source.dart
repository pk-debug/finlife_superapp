import '../models/domain_summary_model.dart';

/// Contract + fake implementation for fetching dashboard data "remotely".
///
/// WHAT: today this is an in-memory stand-in that returns hardcoded data
/// after a simulated network delay. It exists so the rest of the stack
/// (repository → use case → ViewModel → view) can be built and tested
/// against a *stable, real interface* before a backend exists.
///
/// WHY build a fake datasource instead of stubbing the repository
/// directly: the fake lives exactly where the real Dio-backed datasource
/// will live later. Swapping this class for `HomeRemoteDataSourceDio`
/// (implementing the same abstract contract) requires touching exactly
/// one line — the provider wiring in `home_providers.dart` — nothing in
/// `domain/` or `presentation/` changes. That's the whole point of the
/// datasource being behind an interface even on day one.
///
/// WHERE: `data/datasources` — the outermost ring of Clean Architecture.
/// This is the only file in the Home feature allowed to "know" about
/// network/IO concepts (delays, timeouts, JSON).
///
/// WHEN: invoked by `HomeRepositoryImpl.getDashboardSummaries()`.
///
/// WHO: owned by whoever is implementing the Home API contract on the
/// backend side — this class documents the exact JSON shape they need to
/// return (see [_fakeJsonPayload]).
///
/// HOW: `Future.delayed` simulates network latency so the ViewModel's
/// loading state is exercised realistically even before a real backend
/// exists (otherwise the loading spinner would never actually render
/// during local development).
abstract class HomeRemoteDataSource {
  Future<List<DomainSummaryModel>> fetchDashboardSummaries();
}

class FakeHomeRemoteDataSource implements HomeRemoteDataSource {
  /// HOW MUCH: fixed 600ms artificial latency — long enough to see a
  /// loading state during manual testing, short enough not to be annoying.
  /// Swap for real network timing once wired to an actual backend.
  static const _simulatedLatency = Duration(milliseconds: 600);

  @override
  Future<List<DomainSummaryModel>> fetchDashboardSummaries() async {
    await Future.delayed(_simulatedLatency);
    return _fakeJsonPayload.map(DomainSummaryModel.fromJson).toList();
  }

  /// The exact JSON shape a real `/dashboard/summary` endpoint should
  /// return — one object per domain. Documented here so a backend
  /// engineer can implement the real endpoint from this file alone.
  static final List<Map<String, dynamic>> _fakeJsonPayload = [
    {
      'domain': 'banking',
      'title': 'Banking',
      'headline_value': '₹42,500.00',
      'status_line': 'Synced 2 min ago',
      'is_stale': false,
    },
    {
      'domain': 'insurance',
      'title': 'Insurance',
      'headline_value': '3 policies',
      'status_line': '1 claim in review',
      'is_stale': false,
    },
    {
      'domain': 'stock',
      'title': 'Stock Market',
      'headline_value': '+2.4% today',
      'status_line': 'Portfolio ₹1,18,340',
      'is_stale': false,
    },
    {
      'domain': 'consumer',
      'title': 'Shopping',
      'headline_value': '2 orders in transit',
      'status_line': 'Next arrival: tomorrow',
      'is_stale': false,
    },
    {
      'domain': 'lifestyle',
      'title': 'Lifestyle',
      'headline_value': '5-day habit streak',
      'status_line': '7,340 steps today',
      'is_stale': false,
    },
  ];
}

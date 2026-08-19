import 'package:finlife_superapp/features/home/domain/entities/domain_summary.dart';
import 'package:finlife_superapp/features/home/domain/repositories/home_repository.dart';
import 'package:finlife_superapp/features/home/domain/usecases/get_home_dashboard.dart';
import 'package:flutter_test/flutter_test.dart';

/// WHAT: a hand-written fake implementing [HomeRepository] — no mocking
/// framework needed for an interface this small.
/// WHY hand-written over `mocktail`/`mockito`: this is the textbook case
/// for a fake vs. a mock — we want *real* (if canned) behavior, not
/// verification of call counts, so a fake is simpler and more readable.
/// Larger repositories (Banking's, with many methods) are where a mocking
/// framework starts paying for itself.
class _FakeHomeRepository implements HomeRepository {
  _FakeHomeRepository({this.summariesToReturn, this.errorToThrow});

  final List<DomainSummary>? summariesToReturn;
  final Object? errorToThrow;

  @override
  Future<List<DomainSummary>> getDashboardSummaries() async {
    if (errorToThrow != null) throw errorToThrow!;
    return summariesToReturn ?? const [];
  }
}

void main() {
  group('GetHomeDashboard', () {
    // WHAT this group tests: the use case is a pure pass-through to the
    // repository. WHY that's worth a test at all (it looks trivial): it
    // locks in the contract so that if someone "helpfully" adds filtering
    // or sorting logic into the use case later without updating this
    // test, the test starts failing and forces a deliberate decision
    // rather than a silent behavior change.

    test('returns the summaries provided by the repository, unmodified', () async {
      const summary = DomainSummary(
        domain: AppDomain.banking,
        title: 'Banking',
        headlineValue: '₹1,000.00',
        statusLine: 'Synced',
      );
      final useCase = GetHomeDashboard(
        _FakeHomeRepository(summariesToReturn: const [summary]),
      );

      final result = await useCase();

      expect(result, equals(const [summary]));
    });

    test('propagates a repository failure instead of swallowing it', () async {
      final useCase = GetHomeDashboard(
        _FakeHomeRepository(errorToThrow: Exception('network down')),
      );

      // WHY this matters architecturally: the use case must NOT catch and
      // hide errors — that responsibility belongs to HomeViewModel, which
      // turns a thrown exception into HomeState.error for the UI. If the
      // use case swallowed errors here, the ViewModel's error state would
      // never trigger.
      expect(useCase(), throwsA(isA<Exception>()));
    });

    test('returns an empty list rather than throwing when there is genuinely no data', () async {
      final useCase = GetHomeDashboard(_FakeHomeRepository(summariesToReturn: const []));

      final result = await useCase();

      expect(result, isEmpty);
    });
  });
}

import '../entities/domain_summary.dart';
import '../repositories/home_repository.dart';

/// Use case: "get everything needed to render the Home dashboard".
///
/// WHAT: a single-purpose, callable class wrapping exactly one business
/// action. It does nothing a ViewModel couldn't do by calling the
/// repository directly — its value is discipline and testability, not
/// mechanism.
///
/// WHY a use-case class instead of calling [HomeRepository] straight from
/// the ViewModel: (1) it gives this one action a name that shows up in
/// stack traces and test descriptions, (2) it's the natural place to add
/// cross-cutting logic later (e.g. "also log an analytics event on every
/// dashboard load") without bloating the ViewModel, (3) it keeps the
/// pattern consistent with larger features (Banking's `TransferMoney`,
/// Stock's `PlaceOrder`) where a use case genuinely does orchestrate
/// multiple repositories.
///
/// WHERE: `domain/usecases` — depends only on [HomeRepository] (an
/// interface), never on a concrete data-layer class.
///
/// WHEN: instantiated once via Riverpod provider (see
/// `presentation/providers/home_providers.dart`) and invoked by
/// [HomeViewModel] on init and on refresh.
///
/// WHO: called only by presentation-layer ViewModels — never by widgets
/// directly, and never by other use cases in this small feature (multi-use-case
/// orchestration is reserved for features where it earns its complexity).
///
/// HOW: thin delegation to [HomeRepository.getDashboardSummaries]; exposed
/// via `call()` so the class itself can be invoked like a function:
/// `await getHomeDashboard()`.
class GetHomeDashboard {
  const GetHomeDashboard(this._repository);

  final HomeRepository _repository;

  /// Executes the use case.
  ///
  /// HOW MUCH: no pagination, no filtering — Home always wants the full
  /// set of domain summaries. If that ever changes (e.g. "let the user
  /// hide a domain tile"), that's a parameter added here, not a new
  /// method — one use case, one action.
  Future<List<DomainSummary>> call() {
    return _repository.getDashboardSummaries();
  }
}

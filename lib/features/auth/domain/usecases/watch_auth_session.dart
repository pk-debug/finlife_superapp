import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Use case: "keep me informed of who's signed in, as it changes".
///
/// WHAT: thin wrapper around [AuthRepository.sessionChanges] — the
/// stream-based counterpart to this feature's other one-shot use cases
/// ([RequestOtp], [VerifyOtp]).
///
/// WHY this earns a use case even though it's a single property read: the
/// project's convention is "ViewModels depend on `domain/usecases`, never
/// directly on a repository" (see `GetHomeDashboard`'s docstring) — that
/// rule doesn't get an exception just because the underlying capability
/// happens to be a stream instead of a `Future`. It also gives this
/// specific capability a name (`WatchAuthSession`) that shows up clearly
/// wherever it's injected, e.g. into both [AuthViewModel] and the
/// router's redirect logic in `app_router.dart` — both consumers share
/// this exact use case instance via Riverpod, so they observe the same
/// session changes in lockstep.
///
/// WHERE: `domain/usecases`.
///
/// WHEN: `call()` is invoked once, at provider construction, and the
/// returned stream is subscribed to for the provider's lifetime.
class WatchAuthSession {
  const WatchAuthSession(this._repository);

  final AuthRepository _repository;

  Stream<AuthSession?> call() => _repository.sessionChanges;
}

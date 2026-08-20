import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Use case: "verify this code against this challenge and sign me in".
///
/// WHAT: thin delegation to [AuthRepository.verifyOtp], plus a guard
/// against submitting an obviously-incomplete code.
///
/// WHY the length check belongs here and not only in the widget: the
/// widget's "disable the submit button until 6 digits are entered" is a
/// UX affordance a user can't normally bypass — but the use case is the
/// layer whose contract actually promises correctness, so it re-asserts
/// the same rule independent of whatever the current UI happens to do.
/// This is the same "don't trust the UI layer as your only validation"
/// principle applied at use-case granularity instead of at a network
/// boundary.
///
/// WHERE: `domain/usecases`, called only by [AuthViewModel].
///
/// WHEN: invoked once per OTP submission attempt (including retries after
/// a wrong-code error — each retry is a fresh call with the same
/// `challengeId` until the repository's own attempt limit is hit).
class VerifyOtp {
  const VerifyOtp(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call({required String challengeId, required String code}) {
    if (code.length != 6) {
      throw ArgumentError('Enter the 6-digit code.');
    }
    return _repository.verifyOtp(challengeId: challengeId, code: code);
  }
}

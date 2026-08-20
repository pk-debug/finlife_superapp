import '../entities/otp_challenge.dart';
import '../repositories/auth_repository.dart';

/// Use case: "send me an OTP at this phone number".
///
/// WHAT/WHY/HOW: same thin-delegation pattern as `GetHomeDashboard` — see
/// that class's docstring for the full reasoning on why this project uses
/// one-class-per-action use cases even where they look trivial.
///
/// WHY this one specifically earns a tiny bit of extra logic (basic
/// format validation before touching the repository): failing fast on an
/// obviously malformed number avoids burning one of the backend's
/// rate-limited OTP-send slots on client-side typos — a real cost with
/// SMS providers, unlike Home's read-only fetch which has no such budget
/// to protect.
///
/// WHERE: `domain/usecases` — the *only* file in this feature allowed to
/// contain phone-format validation logic; the presentation-layer
/// `PhoneNumberField` widget has its own lighter-weight, immediate
/// keystroke-level validation (see that widget's docstring) which is a
/// UX nicety, not the source of truth — this use case is.
class RequestOtp {
  const RequestOtp(this._repository);

  final AuthRepository _repository;

  /// HOW MUCH: accepts any digit string of at least 10 digits — real
  /// validation (country-code-aware, carrier checks) belongs server-side;
  /// this is a cheap client-side sanity check only.
  Future<OtpChallenge> call(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 10) {
      throw ArgumentError('Enter a valid phone number.');
    }
    return _repository.requestOtp(digitsOnly);
  }
}

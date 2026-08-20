import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Use case: "unlock the existing session using device biometrics".
///
/// WHAT: checks biometric availability first, then delegates to
/// [AuthRepository.authenticateWithBiometrics] — the two-step shape
/// mirrors how this must actually be called safely (never invoke a
/// biometric prompt on hardware that doesn't support it or has nothing
/// enrolled; the OS-level API will error, but asking first is both
/// cheaper and produces a far better error message for the user).
///
/// WHY this orchestration lives in the use case and not inside
/// [AuthViewModel]: this exact "check availability, then act" sequence
/// is the kind of thing later features will want to reuse verbatim (e.g.
/// Banking re-prompting biometrics before revealing a full account
/// number) — a use case is reusable from any ViewModel; logic embedded
/// directly in `AuthViewModel` is not.
///
/// WHERE: `domain/usecases`. Depends only on [AuthRepository].
///
/// WHEN: called (a) right after a fresh OTP sign-in, if the user opts in
/// to "Enable biometric unlock", and (b) on subsequent app opens, before
/// [AuthViewModel] otherwise requires a full OTP flow again.
class AuthenticateWithBiometrics {
  const AuthenticateWithBiometrics(this._repository);

  final AuthRepository _repository;

  /// Throws a [StateError] with a clear message if biometrics aren't
  /// available on this device, instead of forwarding whatever low-level
  /// platform exception the OS would produce.
  Future<AuthSession> call() async {
    final available = await _repository.isBiometricAvailable();
    if (!available) {
      throw StateError(
        'Biometric unlock is not available on this device — no enrolled '
        'fingerprint/face, or the hardware does not support it.',
      );
    }
    return _repository.authenticateWithBiometrics();
  }
}

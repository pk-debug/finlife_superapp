/// Contract + fake implementation wrapping device biometric auth
/// (fingerprint/Face ID).
///
/// WHAT: today, [FakeBiometricLocalDataSource] simulates "always
/// available, always succeeds after a short delay" — there is no real
/// `local_auth` plugin call yet, because this sandbox has no device/
/// simulator to exercise it against.
///
/// WHY this is still worth building behind an interface today rather
/// than deferring the whole biometric feature: the *rest* of the auth
/// flow (the "enable biometric unlock?" prompt, the opt-in toggle stored
/// on [AuthSession], the re-auth-on-resume flow) can all be built,
/// wired, and tested right now against this fake — only the single
/// method [authenticate] needs a real implementation swapped in later.
///
/// WHERE: `data/datasources` — this is a genuine platform/IO boundary
/// (talks to OS-level secure hardware), same ring as
/// `AuthRemoteDataSource`.
///
/// WHEN: [isAvailable] is checked before ever showing a biometric prompt
/// in the UI; [authenticate] is invoked exactly when the user taps
/// "Use Face ID / Fingerprint".
///
/// HOW real biometric auth will be wired later (documented here as the
/// concrete next step, not left vague):
/// 1. Add `local_auth: ^2.1.8` to `pubspec.yaml` — NOT yet added; this
///    drop intentionally ships zero new plugin dependencies so the whole
///    Auth feature stays buildable and testable in any environment,
///    including one with no device/simulator and no platform toolchain
///    configured. Add it only when actually wiring the real datasource.
/// 2. Add Android `USE_BIOMETRIC` permission / iOS `NSFaceIDUsageDescription`
///    per the `local_auth` package's platform setup docs.
/// 3. Implement `DeviceBiometricLocalDataSource` calling
///    `LocalAuthentication().canCheckBiometrics` for [isAvailable] and
///    `LocalAuthentication().authenticate(localizedReason: ...)` for
///    [authenticate].
/// 4. Swap the provider in `auth_providers.dart` — nothing else changes,
///    by the same seam-based design used throughout this project.
abstract class BiometricLocalDataSource {
  Future<bool> isAvailable();
  Future<bool> authenticate({required String reason});
}

class FakeBiometricLocalDataSource implements BiometricLocalDataSource {
  @override
  Future<bool> isAvailable() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    // HOW MUCH: simulated liveness-check delay, long enough to be
    // visible in the UI's "authenticating..." state during manual testing.
    await Future.delayed(const Duration(milliseconds: 900));
    return true;
  }
}

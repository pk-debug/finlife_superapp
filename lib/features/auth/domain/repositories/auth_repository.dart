import '../entities/auth_session.dart';
import '../entities/otp_challenge.dart';

/// Contract for everything auth-related: OTP sign-in, biometric unlock,
/// session lifecycle.
///
/// WHAT: a single interface covering three related but distinct flows —
/// OTP request/verify, biometric re-auth, and session sign-out — kept in
/// one contract (rather than three) because a real implementation shares
/// one thing across all of them: the persisted [AuthSession]. Splitting
/// it into `OtpRepository` + `BiometricRepository` would force two
/// implementations to coordinate over the same token storage, which is
/// more awkward than the interface being slightly less granular.
///
/// WHY biometric auth is modeled as *re-authenticating an existing
/// session* rather than a first-class sign-in method: biometric unlock
/// only ever works after at least one successful OTP sign-in has
/// happened on that device (there is no "biometric-only" account
/// creation) — [authenticateWithBiometrics] is documented to throw if no
/// prior session/biometric-enrollment exists, matching that real-world
/// constraint.
///
/// WHERE: implemented by `AuthRepositoryImpl` in `data/`; consumed by
/// this feature's use cases.
///
/// WHO: any feature that needs to know "is the user signed in" reads
/// [sessionChanges] via the shared `authNotifierProvider` (see
/// `presentation/providers/auth_providers.dart`) — never this repository
/// directly, to keep the dependency-direction rule intact.
abstract class AuthRepository {
  /// Sends an OTP to [phoneNumber] and returns a challenge receipt.
  ///
  /// WHEN: called once per "Send code" tap, and again (fresh challenge)
  /// on every "Resend code" tap once [OtpChallenge.canResend] is true.
  Future<OtpChallenge> requestOtp(String phoneNumber);

  /// Verifies [code] against the challenge identified by [challengeId].
  ///
  /// HOW MUCH: implementations should allow a small, fixed number of
  /// incorrect attempts before forcing a fresh [requestOtp] call — the
  /// fake datasource documents its own limit; a real backend enforces
  /// this server-side regardless of what the client does.
  ///
  /// On success, persists the resulting [AuthSession] (so it survives
  /// app restarts) before returning it.
  Future<AuthSession> verifyOtp({required String challengeId, required String code});

  /// Whether this device is capable of biometric auth right now (has
  /// enrolled biometrics AND the OS reports the hardware as available).
  ///
  /// WHEN: checked once, when rendering the "Enable biometric unlock?"
  /// prompt after a successful OTP sign-in — a device with no enrolled
  /// fingerprint/face should never see that prompt in the first place.
  Future<bool> isBiometricAvailable();

  /// Re-authenticates using device biometrics, returning the session that
  /// was active when biometric unlock was enabled.
  ///
  /// WHEN: called on app resume/relaunch when a biometric-enabled session
  /// exists locally but its access token needs a fresh liveness check
  /// before being trusted again (e.g. before showing a Banking balance).
  Future<AuthSession> authenticateWithBiometrics();

  /// Emits the current session whenever it changes — `null` means signed
  /// out. The very first value emitted reflects whatever was restored
  /// from local storage at app start (may be `null` on a fresh install).
  ///
  /// WHY a stream rather than a one-shot `getCurrentSession()`: this is
  /// exactly what drives [app_router]'s auth redirect — the router needs
  /// to react to sign-in/sign-out happening anywhere in the app, not poll
  /// for it.
  Stream<AuthSession?> get sessionChanges;

  /// Clears the persisted session and emits `null` on [sessionChanges].
  Future<void> signOut();
}

import 'package:equatable/equatable.dart';

/// The result of a successful sign-in — everything the rest of the app
/// needs to know about "who is logged in and how".
///
/// WHAT: an immutable value object holding the signed-in user's phone
/// number, a token pair, and whether biometric unlock is enabled for
/// this device.
///
/// WHY tokens live on the entity (not hidden entirely in the data layer):
/// the domain layer legitimately needs to know *that* a session exists
/// and *whether it's still valid* (see [isAccessTokenExpired]) — that's
/// business logic, not storage detail. What the domain layer never sees
/// is *where* the token is persisted (Keychain/Keystore via
/// `flutter_secure_storage`) — that stays entirely inside
/// `data/datasources` / `core/storage`.
///
/// WHERE: `domain/entities` — depended on by every other feature that
/// needs to know "is someone logged in" (Banking, Stock, etc. will all
/// read `AuthSession` via a shared provider once those features exist).
///
/// WHEN: created by [AuthRepository.verifyOtp] or
/// [AuthRepository.authenticateWithBiometrics] on success; destroyed
/// (replaced by `null`) on sign-out or token-refresh failure.
///
/// HOW: plain class + [Equatable], consistent with [DomainSummary] in the
/// Home feature — no `freezed` needed for a shape this size.
class AuthSession extends Equatable {
  const AuthSession({
    required this.userId,
    required this.phoneNumber,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.biometricEnabled,
  });

  final String userId;
  final String phoneNumber;
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;

  /// Whether the user has opted in to biometric unlock on this device.
  ///
  /// WHY per-session (not a device-wide setting stored separately): this
  /// keeps the "is biometric usable right now" question answerable from
  /// one object — a request-OTP-again flow correctly starts a fresh
  /// session with this defaulted to `false` until the user opts in again
  /// on this device.
  final bool biometricEnabled;

  /// WHY a computed getter instead of a stored bool: expiry is a function
  /// of wall-clock time, not app state — storing a separate
  /// `isExpired` flag would let it silently go stale between checks.
  bool get isAccessTokenExpired => DateTime.now().isAfter(accessTokenExpiresAt);

  AuthSession copyWith({bool? biometricEnabled}) {
    return AuthSession(
      userId: userId,
      phoneNumber: phoneNumber,
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: accessTokenExpiresAt,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        phoneNumber,
        accessToken,
        refreshToken,
        accessTokenExpiresAt,
        biometricEnabled,
      ];
}

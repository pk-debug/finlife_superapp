import '../models/auth_session_model.dart';

/// Contract + fake implementation for OTP send/verify, standing in for a
/// real SMS-backed auth API — same "fake behind a real interface" pattern
/// as `FakeHomeRemoteDataSource`; see that class's docstring for the full
/// rationale on why this is a fake and not a mock, and why it sits exactly
/// where the real Dio-backed implementation will later live.
abstract class AuthRemoteDataSource {
  Future<OtpChallengeDto> requestOtp(String phoneNumber);
  Future<AuthSessionModel> verifyOtp({required String challengeId, required String code});
}

/// Data-layer DTO for the OTP challenge. Public (unlike a truly private
/// helper) because `AuthRepositoryImpl` in a different file needs to
/// consume it — Dart privacy is per-library (per-file here), so anything
/// crossing a file boundary in this project must be public, even when,
/// as here, it's only ever used by exactly one caller.
class OtpChallengeDto {
  const OtpChallengeDto({
    required this.challengeId,
    required this.phoneNumber,
    required this.expiresAt,
    required this.resendAvailableAt,
  });
  final String challengeId;
  final String phoneNumber;
  final DateTime expiresAt;
  final DateTime resendAvailableAt;
}

/// In-memory fake OTP flow. Demo code is always `123456`, printed nowhere
/// (deliberately — see [requestOtp] docs) so this stays a believable
/// stand-in for "check your SMS" during manual testing.
///
/// HOW MUCH: allows exactly 3 verification attempts per challenge before
/// forcing a fresh `requestOtp` call, mirroring typical real OTP provider
/// throttling — enforced in [verifyOtp].
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  static const _demoCode = '123456';
  static const _codeValidity = Duration(minutes: 5);
  static const _resendCooldown = Duration(seconds: 30);
  static const _maxAttempts = 3;

  final Map<String, int> _attemptsByChallenge = {};

  @override
  Future<OtpChallengeDto> requestOtp(String phoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final challengeId = 'chal_${DateTime.now().microsecondsSinceEpoch}';
    _attemptsByChallenge[challengeId] = 0;
    final now = DateTime.now();
    return OtpChallengeDto(
      challengeId: challengeId,
      phoneNumber: phoneNumber,
      expiresAt: now.add(_codeValidity),
      resendAvailableAt: now.add(_resendCooldown),
    );
  }

  @override
  Future<AuthSessionModel> verifyOtp({
    required String challengeId,
    required String code,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final attempts = _attemptsByChallenge[challengeId];
    if (attempts == null) {
      throw StateError('This code has expired. Request a new one.');
    }
    if (attempts >= _maxAttempts) {
      throw StateError('Too many incorrect attempts. Request a new code.');
    }

    if (code != _demoCode) {
      _attemptsByChallenge[challengeId] = attempts + 1;
      throw StateError('Incorrect code. Try again.');
    }

    _attemptsByChallenge.remove(challengeId);
    final now = DateTime.now();
    return AuthSessionModel(
      userId: 'user_demo_001',
      phoneNumber: '+91XXXXXXXXXX',
      accessToken: 'demo_access_${now.microsecondsSinceEpoch}',
      refreshToken: 'demo_refresh_${now.microsecondsSinceEpoch}',
      accessTokenExpiresAt: now.add(const Duration(hours: 1)),
      biometricEnabled: false,
    );
  }
}

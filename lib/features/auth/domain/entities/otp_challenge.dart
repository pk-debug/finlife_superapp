import 'package:equatable/equatable.dart';

/// Represents an in-flight "we sent you a code" OTP challenge.
///
/// WHAT: the receipt returned by [AuthRepository.requestOtp] — identifies
/// which challenge a subsequent [AuthRepository.verifyOtp] call is
/// answering, plus enough metadata to drive the OTP screen's UI (resend
/// cooldown, expiry countdown) without that screen guessing at timing.
///
/// WHY a separate entity rather than just returning the phone number:
/// a real OTP backend issues a `challenge_id` precisely so it can rate-limit
/// and expire challenges independently of the phone number itself (a user
/// can have multiple challenges in flight if they retry) — modeling that
/// now avoids an entity redesign the moment a real backend is wired in.
///
/// WHERE: `domain/entities`, consumed by [AuthState] and
/// `OtpVerificationScreen`.
///
/// WHEN: created fresh on every [AuthRepository.requestOtp] call
/// (including resends — a resend is a new challenge, not a mutation of
/// the old one, matching how most OTP providers actually behave).
class OtpChallenge extends Equatable {
  const OtpChallenge({
    required this.challengeId,
    required this.phoneNumber,
    required this.expiresAt,
    required this.resendAvailableAt,
  });

  final String challengeId;
  final String phoneNumber;

  /// After this instant, [AuthRepository.verifyOtp] should be expected to
  /// fail with an "expired" error — enforced server-side in a real
  /// backend; the fake datasource enforces it too, so the UI's countdown
  /// timer isn't purely decorative even in this drop.
  final DateTime expiresAt;

  /// Before this instant, the "Resend code" action on the OTP screen
  /// should stay disabled — standard anti-abuse throttling.
  final DateTime resendAvailableAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get canResend => DateTime.now().isAfter(resendAvailableAt);

  @override
  List<Object?> get props => [challengeId, phoneNumber, expiresAt, resendAvailableAt];
}

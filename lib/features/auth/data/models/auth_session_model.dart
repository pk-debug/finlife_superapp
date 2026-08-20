import '../../domain/entities/auth_session.dart';

/// Transport/storage shape for [AuthSession] — see `DomainSummaryModel`
/// in the Home feature for the full Model-vs-Entity reasoning; the same
/// rationale applies here and isn't repeated in full.
///
/// WHAT's different about this model specifically: it carries
/// `access_token_expires_at` as an ISO-8601 string (JSON has no
/// `DateTime`), which is exactly the kind of transport-detail leak this
/// separation exists to contain — [AuthSession] only ever sees a real
/// `DateTime`.
class AuthSessionModel {
  const AuthSessionModel({
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
  final bool biometricEnabled;

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      userId: json['user_id'] as String,
      phoneNumber: json['phone_number'] as String,
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessTokenExpiresAt: DateTime.parse(json['access_token_expires_at'] as String),
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
    );
  }

  AuthSession toEntity() {
    return AuthSession(
      userId: userId,
      phoneNumber: phoneNumber,
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: accessTokenExpiresAt,
      biometricEnabled: biometricEnabled,
    );
  }
}

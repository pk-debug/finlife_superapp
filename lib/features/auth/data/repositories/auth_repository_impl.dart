import 'dart:async';

import '../../../../core/storage/token_store.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/biometric_local_data_source.dart';
import '../models/auth_session_model.dart';

/// Concrete [AuthRepository], coordinating three collaborators: the OTP
/// remote datasource, the biometric local datasource, and the token
/// store — this is the one class in the Auth feature allowed to know
/// about all three at once, same "only the repository sees every layer
/// beneath it" rule as `HomeRepositoryImpl`.
///
/// WHY this repository is meaningfully less thin than `HomeRepositoryImpl`:
/// unlike Home's read-only aggregation, Auth has real state to own — the
/// current session and who's listening for changes to it — so this class
/// is the natural, correct place for that state to live rather than being
/// pushed up into the ViewModel (which would make the session invisible
/// to any other feature that isn't watching this particular ViewModel).
///
/// WHERE: `data/repositories`.
///
/// WHEN [sessionChanges] emits: on construction (after attempting to
/// restore a session from [TokenStore]), on successful [verifyOtp], on
/// successful [authenticateWithBiometrics], and on [signOut].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required BiometricLocalDataSource biometricDataSource,
    required TokenStore tokenStore,
  })  : _remote = remoteDataSource,
        _biometric = biometricDataSource,
        _tokenStore = tokenStore {
    _restoreSession();
  }

  final AuthRemoteDataSource _remote;
  final BiometricLocalDataSource _biometric;
  final TokenStore _tokenStore;

  final _sessionController = StreamController<AuthSession?>.broadcast();

  /// The last known session, kept in memory so [authenticateWithBiometrics]
  /// has something to "re-authenticate" without a network round trip —
  /// biometric unlock is a local liveness check on an already-issued
  /// session, not a new sign-in.
  AuthSession? _currentSession;

  @override
  Stream<AuthSession?> get sessionChanges => _sessionController.stream;

  Future<void> _restoreSession() async {
    // WHAT: on cold start, check whether a token pair survived from a
    // previous run. WHY it currently always finds nothing: today's
    // TokenStore is InMemoryTokenStore (process-lifetime only) — see
    // that class's own TODO for the real-persistence swap. This method
    // is written against the *interface*, so it will start correctly
    // restoring sessions the moment that swap happens, with zero changes
    // needed here.
    final stored = await _tokenStore.read();
    if (stored == null) {
      _emit(null);
      return;
    }
    // A real implementation would also fetch the user profile associated
    // with these tokens; the fake reconstructs a plausible session shape.
    _emit(AuthSession(
      userId: 'user_demo_001',
      phoneNumber: '+91XXXXXXXXXX',
      accessToken: stored.accessToken,
      refreshToken: stored.refreshToken,
      accessTokenExpiresAt: stored.accessTokenExpiresAt,
      biometricEnabled: true,
    ));
  }

  @override
  Future<OtpChallenge> requestOtp(String phoneNumber) async {
    final dto = await _remote.requestOtp(phoneNumber);
    return OtpChallenge(
      challengeId: dto.challengeId,
      phoneNumber: dto.phoneNumber,
      expiresAt: dto.expiresAt,
      resendAvailableAt: dto.resendAvailableAt,
    );
  }

  @override
  Future<AuthSession> verifyOtp({required String challengeId, required String code}) async {
    final AuthSessionModel model =
        await _remote.verifyOtp(challengeId: challengeId, code: code);
    final session = model.toEntity();
    await _tokenStore.write(StoredTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      accessTokenExpiresAt: session.accessTokenExpiresAt,
    ));
    _emit(session);
    return session;
  }

  @override
  Future<bool> isBiometricAvailable() => _biometric.isAvailable();

  @override
  Future<AuthSession> authenticateWithBiometrics() async {
    final existing = _currentSession;
    if (existing == null) {
      // WHY this can legitimately happen: e.g. app was force-quit before
      // any OTP sign-in ever completed on this device. The use case layer
      // (AuthenticateWithBiometrics) already checked hardware
      // availability; this is a *different* failure — no enrolled
      // session — so it gets its own distinct error.
      throw StateError('No signed-in session to unlock. Sign in with OTP first.');
    }
    final ok = await _biometric.authenticate(
      reason: 'Confirm it\'s you to continue to FinLife Hub',
    );
    if (!ok) {
      throw StateError('Biometric authentication failed.');
    }
    final refreshed = existing.copyWith(biometricEnabled: true);
    _emit(refreshed);
    return refreshed;
  }

  @override
  Future<void> signOut() async {
    await _tokenStore.delete();
    _emit(null);
  }

  void _emit(AuthSession? session) {
    _currentSession = session;
    _sessionController.add(session);
  }
}

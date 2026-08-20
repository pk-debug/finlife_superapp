import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/token_store.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/biometric_local_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/authenticate_with_biometrics.dart';
import '../../domain/usecases/request_otp.dart';
import '../../domain/usecases/verify_otp.dart';
import '../../domain/usecases/watch_auth_session.dart';
import '../state/auth_state.dart';
import '../viewmodel/auth_viewmodel.dart';

/// Dependency graph for the Auth feature — same one-provider-per-layer
/// pattern as `home_providers.dart`; see that file's docstring for the
/// full rationale (not repeated here).
///
/// WHAT's different from Home's wiring: three datasource-ish
/// dependencies feed the repository instead of one ([AuthRemoteDataSource],
/// [BiometricLocalDataSource], [TokenStore]), and this feature exposes a
/// [WatchAuthSession] use case that two *different* consumers share —
/// [AuthViewModel] and, separately, `app_router.dart`'s redirect logic —
/// both reading the exact same underlying stream via Riverpod's provider
/// caching (one [AuthRepositoryImpl] instance, one broadcast stream).
///
/// WHEN this graph is (re)built: [AuthRepositoryImpl] is constructed once
/// on first read, and its constructor kicks off session restoration
/// immediately — see that class's docstring. It stays alive for the
/// process lifetime (no `.autoDispose`) because the router needs the same
/// live session stream for as long as the app runs, not just while a
/// login screen happens to be mounted.
final _authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => FakeAuthRemoteDataSource(),
);

final _biometricDataSourceProvider = Provider<BiometricLocalDataSource>(
  (ref) => FakeBiometricLocalDataSource(),
);

/// HOW MUCH this matters for manual testing: because this is
/// [InMemoryTokenStore], every hot restart / app relaunch starts fully
/// signed out — there is no real persistence yet (see that class's own
/// TODO for the `flutter_secure_storage`-backed swap, which is the
/// concrete next step for a later feature drop, not this one).
final _tokenStoreProvider = Provider<TokenStore>((ref) => InMemoryTokenStore());

final _authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(_authRemoteDataSourceProvider),
    biometricDataSource: ref.watch(_biometricDataSourceProvider),
    tokenStore: ref.watch(_tokenStoreProvider),
  );
});

final _requestOtpProvider = Provider<RequestOtp>(
  (ref) => RequestOtp(ref.watch(_authRepositoryProvider)),
);

final _verifyOtpProvider = Provider<VerifyOtp>(
  (ref) => VerifyOtp(ref.watch(_authRepositoryProvider)),
);

final _authenticateWithBiometricsProvider = Provider<AuthenticateWithBiometrics>(
  (ref) => AuthenticateWithBiometrics(ref.watch(_authRepositoryProvider)),
);

/// Exposed (not prefixed with `_`) because `app_router.dart` needs it too,
/// to build its own [GoRouterRefreshStream] from the same session stream
/// the ViewModel listens to — see that file's docstring for why sharing
/// this exact provider (not a second, separate subscription) matters.
final watchAuthSessionProvider = Provider<WatchAuthSession>(
  (ref) => WatchAuthSession(ref.watch(_authRepositoryProvider)),
);

/// The provider `LoginScreen` watches.
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(
    requestOtp: ref.watch(_requestOtpProvider),
    verifyOtp: ref.watch(_verifyOtpProvider),
    authenticateWithBiometrics: ref.watch(_authenticateWithBiometricsProvider),
    watchAuthSession: ref.watch(watchAuthSessionProvider),
  );
});

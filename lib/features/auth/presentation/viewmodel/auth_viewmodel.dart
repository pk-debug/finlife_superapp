import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/authenticate_with_biometrics.dart';
import '../../domain/usecases/request_otp.dart';
import '../../domain/usecases/verify_otp.dart';
import '../../domain/usecases/watch_auth_session.dart';
import '../state/auth_state.dart';

/// ViewModel driving the whole sign-in flow — phone entry, OTP entry,
/// biometric shortcut, and reacting to session restoration on cold start.
///
/// WHAT: owns [AuthState] and exposes one intent method per user action
/// (`submitPhoneNumber`, `submitOtp`, `resendOtp`, `useBiometrics`), plus
/// a background subscription to [WatchAuthSession] that can push the
/// state straight to [AuthStage.authenticated] without any explicit user
/// action — e.g. after a successful [VerifyOtp] call, or (once real
/// persistence lands) on a cold start with a still-valid stored session.
///
/// WHY the session subscription lives here and not duplicated logic in
/// each method: [VerifyOtp] and [AuthenticateWithBiometrics] both cause
/// `AuthRepositoryImpl` to emit on `sessionChanges` as their *side
/// effect* of succeeding — rather than have `submitOtp` and
/// `useBiometrics` each separately set `state = AuthState.authenticated(...)`
/// from their own return value, both paths funnel through the one
/// [_onSessionChanged] listener. This means a *third* way of becoming
/// authenticated later (e.g. a passkey flow) automatically works
/// correctly too, the moment it also emits on the same stream — zero
/// changes needed in this ViewModel.
///
/// WHERE: `presentation/viewmodel`, depends only on this feature's
/// `domain/usecases` — never on `AuthRepository` or anything in `data/`.
///
/// WHEN constructed: once, via `authViewModelProvider`, which happens the
/// moment `app_router.dart`'s router provider is first built (since the
/// router itself reads auth state for its redirect logic) — i.e.
/// effectively at app start, not lazily deferred until a login screen
/// mounts.
class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel({
    required RequestOtp requestOtp,
    required VerifyOtp verifyOtp,
    required AuthenticateWithBiometrics authenticateWithBiometrics,
    required WatchAuthSession watchAuthSession,
  })  : _requestOtp = requestOtp,
        _verifyOtp = verifyOtp,
        _authenticateWithBiometrics = authenticateWithBiometrics,
        super(const AuthState.checkingSession()) {
    _sessionSubscription = watchAuthSession().listen(_onSessionChanged);
  }

  final RequestOtp _requestOtp;
  final VerifyOtp _verifyOtp;
  final AuthenticateWithBiometrics _authenticateWithBiometrics;
  late final StreamSubscription<AuthSession?> _sessionSubscription;

  /// Reacts to every emission from [WatchAuthSession].
  ///
  /// HOW MUCH restraint this applies: a non-null [session] always wins
  /// (moves straight to authenticated, from any stage). A `null`
  /// emission, however, is only honored while still on
  /// [AuthStage.checkingSession] — once past that, `null` most likely
  /// means an explicit [signOut] happening elsewhere (not modeled in
  /// this drop's UI yet), and should NOT silently yank the user out of a
  /// half-typed OTP entry back to phone entry.
  void _onSessionChanged(AuthSession? session) {
    if (session != null) {
      state = AuthState.authenticated(session);
      return;
    }
    if (state.stage == AuthStage.checkingSession) {
      state = const AuthState.phoneEntry();
    }
  }

  /// Intent: user tapped "Send code".
  Future<void> submitPhoneNumber(String phoneNumber) async {
    state = AuthState.sendingOtp(phoneNumber);
    try {
      final challenge = await _requestOtp(phoneNumber);
      state = AuthState.otpEntry(challenge);
    } catch (e) {
      state = AuthState.phoneEntry(errorMessage: _readableMessage(e));
    }
  }

  /// Intent: user submitted a 6-digit code.
  ///
  /// WHY this method does not itself set `AuthState.authenticated(...)`
  /// on success: see the class-level docstring — that transition is
  /// driven by [_onSessionChanged] once the repository confirms the
  /// session was persisted, not by this method's return value directly.
  /// This guards against a subtle bug class where the UI would show
  /// "authenticated" a moment before the token was actually saved.
  Future<void> submitOtp(String code) async {
    final challenge = state.challenge;
    if (challenge == null) return; // UI should never allow this; defensive.
    state = AuthState.otpEntry(challenge, isSubmitting: true);
    try {
      await _verifyOtp(challengeId: challenge.challengeId, code: code);
    } catch (e) {
      state = AuthState.otpEntry(challenge, errorMessage: _readableMessage(e));
    }
  }

  /// Intent: user tapped "Resend code" (only enabled once
  /// [OtpChallenge.canResend] is true — enforced by the widget, not here,
  /// matching this project's "UI affordance + use-case-level guard, not
  /// either alone" pattern documented on [VerifyOtp]).
  Future<void> resendOtp() async {
    final phone = state.challenge?.phoneNumber ?? state.phoneNumber;
    if (phone == null) return;
    await submitPhoneNumber(phone);
  }

  /// Intent: user tapped "Use Face ID / Fingerprint instead".
  Future<void> useBiometrics() async {
    try {
      await _authenticateWithBiometrics();
      // On success, _onSessionChanged fires from the repository's emit —
      // no direct state assignment needed here either.
    } catch (e) {
      state = AuthState.phoneEntry(errorMessage: _readableMessage(e));
    }
  }

  /// Intent: user tapped "Use a different number" from the OTP screen.
  void backToPhoneEntry() => state = const AuthState.phoneEntry();

  /// Strips Dart's default `Exception: ` / `StateError: ` prefixes so the
  /// UI shows a clean sentence instead of a stringified exception type.
  ///
  /// HOW MUCH: this is a presentation-layer nicety only — it does not
  /// change *which* errors are shown, only their formatting; the actual
  /// error messages themselves are authored in the domain/data layers
  /// (see `FakeAuthRemoteDataSource`, `RequestOtp`, `VerifyOtp`).
  String _readableMessage(Object error) {
    return error.toString().replaceFirst(RegExp(r'^(StateError|ArgumentError|Exception): '), '');
  }

  @override
  void dispose() {
    _sessionSubscription.cancel();
    super.dispose();
  }
}

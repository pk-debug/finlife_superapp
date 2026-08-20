import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/otp_challenge.dart';

/// Which step of the sign-in flow is currently showing.
///
/// WHY an explicit enum instead of inferring the stage from which fields
/// are non-null: [AuthState] carries [challenge] and [session] fields
/// that could theoretically both be non-null at an awkward transition
/// moment (e.g. right as biometric re-auth resolves while an OTP
/// challenge object is still cached) — an explicit [stage] removes any
/// ambiguity about what the View should render, matching the same
/// "never an ambiguous in-between UI" principle [HomeState] follows.
enum AuthStage { checkingSession, phoneEntry, otpEntry, authenticated }

/// Immutable snapshot of the entire sign-in flow — one state class
/// covering all four [AuthStage]s, following the same pattern as
/// [HomeState] (see that class's docstring for the full Model-half-of-MVVM
/// reasoning, not repeated here).
///
/// WHY one combined class for a multi-step flow rather than one state
/// class per screen: the stages share data across transitions (the phone
/// number typed on step 1 is needed for the "resend code" action on step
/// 2; the challenge from step 2 is needed to retry after a wrong-code
/// error without re-fetching it) — modeling them as entirely separate
/// state classes would mean passing that shared data through screen
/// constructors/route arguments instead of through one coherent state
/// object the single [AuthViewModel] owns.
///
/// WHERE: `presentation/state`, produced by [AuthViewModel], consumed by
/// `LoginScreen` and read by `app_router.dart`'s redirect logic to decide
/// whether the user may reach `/` (Home).
///
/// HOW: private base constructor + named factories per stage, exactly
/// like [HomeState] — callers read intent ("AuthState.otpEntry(...)")
/// rather than assembling positional fields by hand.
class AuthState extends Equatable {
  const AuthState._({
    required this.stage,
    required this.isSubmitting,
    this.phoneNumber,
    this.challenge,
    this.session,
    this.errorMessage,
  });

  /// Transient first state: waiting on [WatchAuthSession]'s first
  /// emission to know whether a session survived from a previous run.
  ///
  /// WHEN this resolves: as soon as `AuthRepositoryImpl`'s constructor
  /// finishes `_restoreSession()` — today that's always fast (in-memory,
  /// always empty) but the state exists so the UI is correct once real
  /// persistence lands (a Keystore read is not instant).
  const AuthState.checkingSession()
      : this._(stage: AuthStage.checkingSession, isSubmitting: true);

  /// Ready for the user to type a phone number and request a code.
  ///
  /// [errorMessage] is set when this stage is re-entered *after* a
  /// failure (bad phone format, OTP-send failure, biometric failure) —
  /// the phone entry screen shows it inline rather than as a transient
  /// snackbar, so it survives if the user pauses before retrying.
  const AuthState.phoneEntry({String? errorMessage})
      : this._(stage: AuthStage.phoneEntry, isSubmitting: false, errorMessage: errorMessage);

  /// "Send code" was tapped; waiting on the network call to resolve.
  ///
  /// WHY keep [stage] as `phoneEntry` here (not a fifth enum value): the
  /// View to render is still the phone entry screen — only [isSubmitting]
  /// changes, which is enough for it to show a spinner on the submit
  /// button and disable the field.
  const AuthState.sendingOtp(String phoneNumber)
      : this._(
          stage: AuthStage.phoneEntry,
          isSubmitting: true,
          phoneNumber: phoneNumber,
        );

  /// A code has been sent; waiting for the user to enter it.
  ///
  /// [isSubmitting] true means "verifying the just-entered code right
  /// now"; [errorMessage] set means "the previous attempt at this same
  /// challenge failed" — both can be read together to render "showing an
  /// error, but a fresh submit is already in flight" correctly if the
  /// user retries quickly.
  const AuthState.otpEntry(
    OtpChallenge challenge, {
    bool isSubmitting = false,
    String? errorMessage,
  }) : this._(
          stage: AuthStage.otpEntry,
          isSubmitting: isSubmitting,
          challenge: challenge,
          errorMessage: errorMessage,
        );

  /// Signed in. [session] is guaranteed non-null whenever [stage] is
  /// [AuthStage.authenticated] — every other stage guarantees it `null`.
  const AuthState.authenticated(AuthSession session)
      : this._(stage: AuthStage.authenticated, isSubmitting: false, session: session);

  final AuthStage stage;
  final bool isSubmitting;
  final String? phoneNumber;
  final OtpChallenge? challenge;
  final AuthSession? session;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  @override
  List<Object?> get props => [
        stage,
        isSubmitting,
        phoneNumber,
        challenge,
        session,
        errorMessage,
      ];
}

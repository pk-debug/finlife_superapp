import 'package:finlife_superapp/features/home/presentation/views/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../state/auth_state.dart';
import 'otp_entry_view.dart';
import 'phone_entry_view.dart';

/// Top-level Auth screen — a single route (`/login`) that internally
/// switches between the checking-session splash, [PhoneEntryView], and
/// [OtpEntryView] based on [AuthState.stage].
///
/// WHAT/WHY one route for a multi-step flow instead of two `go_router`
/// routes (`/login` and `/login/otp`): the two steps share one
/// [AuthViewModel] and transition based on business state, not URL
/// navigation — there's no real-world case where a user should be able
/// to deep-link straight to "enter OTP" without a challenge already in
/// [AuthState], so a second route would only add complexity (its own
/// redirect guard: "don't allow /login/otp without a live challenge")
/// without adding capability. Compare to Home's future `/banking`,
/// `/stock` etc. routes, which *do* need to be independently
/// deep-linkable (e.g. from a push notification) — that's the dividing
/// line this project uses for "one route with internal state" vs.
/// "separate routes."
///
/// WHERE: `presentation/views` — registered in `app/app_router.dart`.
///
/// WHEN: mounted whenever the router's redirect sends an unauthenticated
/// user to `/login` (see that file). Never mounted while
/// `AuthStage.authenticated` — the router redirects away from `/login`
/// the instant that stage is reached (also see that file).
///
/// HOW: `AnimatedSwitcher` gives a small cross-fade between steps instead
/// of an abrupt jump cut — cheap polish, no animation controller needed.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authViewModelProvider);

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (state.stage) {
            AuthStage.checkingSession => const _CheckingSessionView(key: ValueKey('checking')),
            AuthStage.phoneEntry => PhoneEntryView(key: const ValueKey('phone'), state: state),
            AuthStage.otpEntry => OtpEntryView(key: const ValueKey('otp'), state: state),
            // WHY authenticated is handled here too, even though the
            // router should already have redirected away by the time
            // this could render: `redirect` runs on the *next* route
            // evaluation, not synchronously the instant state changes —
            // there's a one-frame window where this screen could still
            // be the mounted widget with an already-authenticated state.
            // Showing a spinner (rather than, say, a blank Scaffold) for
            // that one frame is a strictly better fallback than crashing
            // on a null-unwrap in PhoneEntryView/OtpEntryView.
            AuthStage.authenticated => const HomeScreen(key: ValueKey('home')),
          },
        ),
      ),
    );
  }
}

class _CheckingSessionView extends StatelessWidget {
  const _CheckingSessionView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

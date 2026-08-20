import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../state/auth_state.dart';
import '../widgets/otp_code_field.dart';

/// Step 2 of the sign-in flow: enter the 6-digit code sent to the number
/// from step 1.
///
/// WHAT: renders [OtpCodeField], a "Verify" button that auto-enables at 6
/// digits, a live resend-cooldown countdown driven by
/// [OtpChallenge.resendAvailableAt], and a "Use a different number" link
/// back to step 1.
///
/// WHY the countdown is computed with a local `Timer.periodic` rather
/// than pushed through [AuthState]: the countdown is once-a-second,
/// purely cosmetic UI churn (see [OtpChallenge.canResend] docstring — the
/// *actual* enforcement is the timestamp comparison, done fresh on every
/// tick here and independently re-checked by the fake datasource
/// server-side-equivalent). Routing a once-a-second tick through Riverpod
/// state would rebuild every other widget watching [authViewModelProvider]
/// (including, notably, `app_router.dart`'s redirect listener) once a
/// second for no reason — keeping it as widget-local `setState` scopes
/// the churn to exactly the one `Text` that needs it.
///
/// WHERE: `presentation/views`.
///
/// WHEN: shown whenever `AuthState.stage == AuthStage.otpEntry`.
class OtpEntryView extends ConsumerStatefulWidget {
  const OtpEntryView({super.key, required this.state});

  final AuthState state;

  @override
  ConsumerState<OtpEntryView> createState() => _OtpEntryViewState();
}

class _OtpEntryViewState extends ConsumerState<OtpEntryView> {
  final _controller = TextEditingController();
  late Timer _ticker;
  String _code = '';

  @override
  void initState() {
    super.initState();
    // HOW MUCH: ticks once a second, purely to refresh the countdown
    // label's text — see class docstring for why this stays local state.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_code.length != 6) return;
    ref.read(authViewModelProvider.notifier).submitOtp(_code);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final challenge = state.challenge!; // guaranteed by AuthStage.otpEntry
    final canSubmit = !state.isSubmitting && _code.length == 6;
    final secondsUntilResend = challenge.resendAvailableAt.difference(DateTime.now()).inSeconds;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.sms_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Enter the code',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Sent to +91 ${challenge.phoneNumber}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          OtpCodeField(
            controller: _controller,
            enabled: !state.isSubmitting,
            onChanged: (value) => setState(() => _code = value),
            onSubmitted: (_) => _submit(),
          ),
          if (state.hasError) ...[
            const SizedBox(height: 8),
            Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: canSubmit ? _submit : null,
            child: state.isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Verify'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: (!state.isSubmitting && secondsUntilResend <= 0)
                ? () => ref.read(authViewModelProvider.notifier).resendOtp()
                : null,
            child: Text(
              secondsUntilResend > 0 ? 'Resend code in ${secondsUntilResend}s' : 'Resend code',
            ),
          ),
          TextButton(
            onPressed: state.isSubmitting
                ? null
                : () => ref.read(authViewModelProvider.notifier).backToPhoneEntry(),
            child: const Text('Use a different number'),
          ),
        ],
      ),
    );
  }
}

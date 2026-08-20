import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';
import '../state/auth_state.dart';
import '../widgets/phone_number_field.dart';

/// Step 1 of the sign-in flow: enter a phone number, request a code.
///
/// WHAT: renders [PhoneNumberField], a submit button, an optional inline
/// error (from [AuthState.errorMessage]), and — when the device supports
/// it — a "Use biometrics instead" shortcut.
///
/// WHY biometrics is offered from the *phone entry* screen rather than a
/// separate route: biometric re-auth (per [AuthRepository]'s docstring)
/// only ever succeeds if a prior session already exists on this device —
/// offering it here means a returning user who still has a live session
/// can skip typing their number entirely, which is the whole point of
/// the feature; a user with no prior session simply won't see it succeed
/// (and today's fake always reports biometrics available — see TODO on
/// [BiometricLocalDataSource] for the real device check).
///
/// WHERE: `presentation/views` — the only file allowed to combine
/// `core/widgets`-level styling with this feature's own state and
/// widgets.
///
/// WHEN: shown whenever `AuthState.stage == AuthStage.phoneEntry`
/// (including the loading variant driven by `isSubmitting`).
class PhoneEntryView extends ConsumerStatefulWidget {
  const PhoneEntryView({super.key, required this.state});

  final AuthState state;

  @override
  ConsumerState<PhoneEntryView> createState() => _PhoneEntryViewState();
}

class _PhoneEntryViewState extends ConsumerState<PhoneEntryView> {
  late final _controller = TextEditingController(text: widget.state.phoneNumber)
    ..addListener(_onTextChanged);

  // WHY a listener that only calls setState (no other logic): the submit
  // button's enabled state depends on live keystroke length, which lives
  // in this StatefulWidget, not in AuthState — see the docstring on the
  // FilledButton below for why that split is deliberate. Without this
  // listener the button would only re-evaluate `canSubmit` on the next
  // unrelated rebuild (e.g. a Riverpod state change), which would make it
  // feel unresponsive while typing.
  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _submit() {
    final phone = _controller.text.trim();
    if (phone.isEmpty) return;
    ref.read(authViewModelProvider.notifier).submitPhoneNumber(phone);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final canSubmit = !state.isSubmitting && _controller.text.trim().length == 10;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.account_balance_wallet_rounded, size: 48, color: AppColors.brandPrimary),
          const SizedBox(height: 16),
          Text(
            'Welcome to FinLife Hub',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your phone number to continue',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          PhoneNumberField(
            controller: _controller,
            enabled: !state.isSubmitting,
            onSubmitted: (_) => _submit(),
          ),
          if (state.hasError) ...[
            const SizedBox(height: 8),
            Text(
              state.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            // WHY re-derive canSubmit from _controller here via
            // setState-on-change rather than passing it in: this is a
            // StatefulWidget precisely because "is the field long enough
            // to submit" is transient, keystroke-level UI state that has
            // no business living in AuthState (see AuthState's own
            // docstring on why it deliberately does NOT track partial,
            // per-keystroke input).
            onPressed: canSubmit ? _submit : null,
            child: state.isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Send code'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: state.isSubmitting
                ? null
                : () => ref.read(authViewModelProvider.notifier).useBiometrics(),
            icon: const Icon(Icons.fingerprint_rounded),
            label: const Text('Use biometrics instead'),
          ),
        ],
      ),
    );
  }
}

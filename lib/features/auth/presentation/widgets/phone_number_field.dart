import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A digits-only phone number `TextField`, pre-styled for the login flow.
///
/// WHAT: wraps `TextField` with a digit-only input formatter and a fixed
/// "+91" prefix (India-first, per this project's fintech focus — see
/// project notes on India-specific UPI/AA work).
///
/// WHY keystroke-level filtering here, in addition to [RequestOtp]'s
/// own validation: this is the "immediate UX nicety" layer mentioned in
/// that use case's docstring — stopping a letter from ever appearing in
/// the field is a better experience than letting it in and rejecting the
/// whole string on submit. It is explicitly NOT the source of truth for
/// validity; [RequestOtp] re-checks length independently, and this
/// widget must never be trusted as the only guard.
///
/// WHERE: `features/auth/presentation/widgets` — private to this feature;
/// promote to `core/widgets` only if a second feature needs a phone input
/// (Banking's own KYC step is the likely first candidate).
///
/// WHEN: rebuilt on every keystroke (standard `TextField` behavior); the
/// [enabled] flag is toggled by `PhoneEntryView` while a request is
/// in flight, so the user can't double-submit.
class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.controller,
    required this.enabled,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumber],
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      onSubmitted: onSubmitted,
      decoration: const InputDecoration(
        labelText: 'Phone number',
        prefixText: '+91  ',
        border: OutlineInputBorder(),
        hintText: '9876543210',
      ),
    );
  }
}

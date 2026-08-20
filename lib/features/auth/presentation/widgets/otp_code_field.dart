import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single `TextField` for the 6-digit OTP, letter-spaced for legibility.
///
/// WHAT: deliberately a single field, not six separate boxes. WHY: a
/// six-box "OTP tile" UI is a common pattern but adds real complexity
/// (focus management between boxes, paste-across-boxes handling) for a
/// benefit that's mostly cosmetic — this project defers that polish
/// until there's a design-system reason to invest in it; the single-field
/// version is fully functional and is what most production banking apps
/// still ship for the *keyboard-driven* case (autofill from SMS still
/// works correctly with `AutofillHints.oneTimeCode` on a single field).
///
/// WHERE: `features/auth/presentation/widgets`.
///
/// WHEN: [onChanged] fires on every digit; `OtpEntryView` uses that to
/// know when exactly 6 digits are present (to enable "Verify") without
/// requiring an explicit submit tap, matching how most OTP UIs behave.
class OtpCodeField extends StatelessWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.enabled,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.w600),
      decoration: const InputDecoration(
        counterText: '',
        border: OutlineInputBorder(),
        hintText: '••••••',
      ),
    );
  }
}

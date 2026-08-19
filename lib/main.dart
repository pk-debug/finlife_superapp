import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

/// Process entry point.
///
/// WHAT: standard Flutter `main()`, wrapping [App] in a [ProviderScope].
///
/// WHY [ProviderScope] specifically: it's Riverpod's mandatory root
/// widget — every provider declared anywhere in the app (see
/// `home_providers.dart`) resolves against this single scope. Only one
/// [ProviderScope] should ever exist in the widget tree; test files
/// create their own scoped instance per test instead of reusing this one
/// (see `test/features/home/domain/usecases/get_home_dashboard_test.dart`
/// for why the use-case test doesn't need Riverpod at all — it tests
/// below the provider layer, which is the point of the layering).
///
/// WHEN: runs exactly once, at process start.
void main() {
  runApp(const ProviderScope(child: App()));
}

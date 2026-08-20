import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapts any [Stream] into a [Listenable] that `GoRouter`'s
/// `refreshListenable` can consume.
///
/// WHAT: `go_router` re-evaluates its `redirect` callback whenever the
/// `Listenable` passed to `refreshListenable` fires — but our source of
/// truth for "is the user signed in" is [WatchAuthSession]'s `Stream`,
/// not a `ChangeNotifier`. This class is the standard, minimal adapter
/// between the two.
///
/// WHY this lives in `core/routing` (not inside the Auth feature): it's
/// a generic stream→listenable bridge with zero auth-specific logic —
/// nothing here mentions [AuthSession] or [AuthState]. Any future
/// feature that needs the router to react to a stream (e.g. a real-time
/// "your session was revoked remotely" push) can reuse this exact class.
///
/// WHERE: constructed once inside `appRouterProvider` in `app_router.dart`.
///
/// WHEN: fires `notifyListeners()` immediately on construction (so
/// `go_router` runs `redirect` once right away, before the first stream
/// event even arrives) and again on every subsequent stream event.
///
/// HOW: wraps the given stream in `.asBroadcastStream()` defensively —
/// if the caller ever passes a single-subscription stream that's already
/// been listened to elsewhere, this would otherwise throw at runtime
/// instead of silently misbehaving.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

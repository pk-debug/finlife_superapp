import 'package:go_router/go_router.dart';

import '../features/home/presentation/views/home_screen.dart';

/// App-wide route table.
///
/// WHAT: a single [GoRouter] instance mapping URL-like paths to screens.
///
/// WHY `go_router` from day one (even with only one real route): every
/// future feature (Banking, Stock, Insurance, Consumer, Lifestyle) will
/// need deep-linkable, guard-able routes (e.g. an auth redirect before
/// `/banking`, a push-notification deep link straight to
/// `/stock/orders/:id`). Wiring routing in as an afterthought once five
/// features exist is far more expensive than starting with it — this is
/// the same reasoning as picking one state-management approach early
/// (see README) applied to navigation.
///
/// WHERE: `app/` — the composition-root layer, sitting above all
/// features. Every feature route is registered here; features never
/// register themselves globally.
///
/// WHEN: constructed once at app startup and handed to
/// `MaterialApp.router` in `app.dart`.
///
/// HOW: flat `GoRoute` list for now. As domain screens land, nested
/// routes (e.g. `/banking`, `/banking/transfer`, `/banking/statements`)
/// will use `GoRoute`'s `routes:` parameter for sub-navigation, and an
/// auth `redirect:` callback will be added once the Auth feature exists.
///
/// HOW MANY: one route today (`/`). Placeholder comments below show
/// exactly where each future feature's top-level route will be added,
/// so this file's growth path is unambiguous.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    // Future feature routes — added as each feature lands:
    // GoRoute(path: '/banking', name: 'banking', builder: ...),
    // GoRoute(path: '/insurance', name: 'insurance', builder: ...),
    // GoRoute(path: '/stock', name: 'stock', builder: ...),
    // GoRoute(path: '/shop', name: 'consumer', builder: ...),
    // GoRoute(path: '/lifestyle', name: 'lifestyle', builder: ...),
  ],
);

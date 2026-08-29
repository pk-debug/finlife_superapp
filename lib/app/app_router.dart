import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/go_router_refresh_stream.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/state/auth_state.dart';
import '../features/auth/presentation/views/login_screen.dart';
import '../features/home/presentation/views/home_screen.dart';
import '../features/lifestyle/lifestyle_module.dart';

/// App-wide route table, exposed as a Riverpod provider so its
/// `redirect` logic can read live auth state.
///
/// WHAT: a [GoRouter] with three routes today (`/login`, `/`,
/// `/lifestyle`) and an auth guard in `redirect` that keeps
/// unauthenticated users on `/login` and bounces authenticated users
/// away from it.
///
/// WHY this became a `Provider<GoRouter>` instead of the plain top-level
/// `final appRouter` from feature 1: a static `GoRouter` has no way to
/// react to "the user just signed in" — `redirect` only re-runs when
/// something tells it to via `refreshListenable`, and the thing that
/// changes here (auth session) lives inside Riverpod. Building the
/// router *as* a provider means it can `ref.watch` the same
/// [watchAuthSessionProvider] the [AuthViewModel] uses, wrap that stream
/// in [GoRouterRefreshStream], and pass it straight to
/// `refreshListenable` — one shared source of truth, two consumers
/// (ViewModel and router) that can never disagree about sign-in state.
///
/// WHERE: `app/` — the composition root. Depends on the Auth feature's
/// public provider (`authViewModelProvider`, `watchAuthSessionProvider`)
/// and Home's `HomeScreen` — this is one of very few files in the app
/// allowed to import across features, because routing is inherently a
/// cross-feature concern.
///
/// WHEN `redirect` runs: on every navigation attempt, and once
/// immediately at startup (see [GoRouterRefreshStream]'s docstring), and
/// again every time the auth session stream emits.
///
/// HOW MUCH: three routes today. Every future feature route
/// (`/banking`, `/stock`, ...) will sit inside the same `if (!isAuthed)`
/// guard for free, by virtue of not being `/login` — no per-route auth
/// wiring will be needed as those land.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshStream = GoRouterRefreshStream(ref.watch(watchAuthSessionProvider)());
  ref.onDispose(refreshStream.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshStream,
    redirect: (context, routerState) {
      final authState = ref.read(authViewModelProvider);

      // Still restoring a possible previous session — don't redirect yet,
      // avoids a flash of the login screen for a user who turns out to
      // already be signed in once real persistence lands.
      if (authState.stage == AuthStage.checkingSession) return null;

      final isAuthenticated = authState.stage == AuthStage.authenticated;
      final isOnLoginRoute = routerState.matchedLocation == '/login';

      if (!isAuthenticated && !isOnLoginRoute) return '/login';
      if (isAuthenticated && isOnLoginRoute) return '/';
      return null; // no redirect needed
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/lifestyle',
        name: 'lifestyle',
        // WHY no `builder` doing anything module-aware here: from
        // go_router's point of view, LifestyleModule is exactly as
        // opaque as HomeScreen or LoginScreen — it neither knows nor
        // needs to know that everything under this one route is a
        // nested GetX app. That opacity is the whole architectural
        // point; see lifestyle_module.dart for the full explanation.
        builder: (context, state) => const LifestyleModule(),
      ),
      // Future feature routes — added as each feature lands:
      // GoRoute(path: '/banking', name: 'banking', builder: ...),
      // GoRoute(path: '/insurance', name: 'insurance', builder: ...),
      // GoRoute(path: '/stock', name: 'stock', builder: ...),
      // GoRoute(path: '/shop', name: 'consumer', builder: ...),
    ],
  );
});
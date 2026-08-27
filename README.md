# FinLife Hub

A portfolio-grade, multi-domain Flutter super-app — **Banking · Insurance ·
Stock Market · Consumer/E-commerce · Lifestyle** — for Android, iOS and Web.

This repo is being built incrementally, feature by feature. **Feature 1:
Home Dashboard** is complete and is the reference pattern every later
feature (Banking, Stock, Insurance, Consumer, Lifestyle) will copy.

## Architecture

**Clean Architecture, three layers per feature, MVVM in the presentation layer.**

```
lib/features/<feature>/
  domain/            <- pure Dart, zero Flutter imports, zero package imports
    entities/         business objects (e.g. DomainSummary)
    repositories/      abstract contracts (interfaces)
    usecases/          one class = one business action, callable via call()
  data/               <- implements domain contracts
    models/             DTOs, know how to (de)serialize
    datasources/        remote/local IO (today: fake/in-memory; later: Dio/Drift)
    repositories/        implements domain repository using datasources
  presentation/       <- MVVM
    state/               immutable UI state (View's "Model" in MVVM terms)
    viewmodel/            StateNotifier: holds state, exposes intents, calls usecases
    providers/            Riverpod wiring (dependency graph, one place to read)
    views/                Flutter screens (Views) - render state, forward intents
    widgets/              small presentational widgets used only by this feature
```

Dependency direction is always **inward**: `presentation → domain ← data`.
Domain never imports `data` or `presentation`. This is what lets you swap
Riverpod for Bloc, or REST for GraphQL, without touching business logic.

## State management per feature (not one-size-fits-all, by design)

| Feature | Tool | Why |
|---|---|---|
| Home (this drop) | **Riverpod** `StateNotifier` | app-wide DI is needed anyway; async load + retry maps cleanly to `AsyncValue` |
| Stock ticker (later) | **Bloc** (event-sourced) | high-frequency WebSocket events benefit from Bloc's explicit event→state transform log, useful for interview walkthroughs |
| Banking transfer form (later) | **Riverpod** `AsyncNotifier` + `ValueNotifier` for field-level validation | mixed granular/local + app-level state |
| Simple toggles (theme, filters) | **ValueNotifier** | overkill to involve a full store for one boolean |
| Lifestyle Habit Tracker | **GetX** (`.obs`/`Obx` + `GetBuilder`) | deliberate, isolated learning module — see "Feature 3" below. Not the app's standard; contained entirely to one feature folder. |

Mixing tools isn't indecision — it demonstrates picking the right tool per
problem shape, which is the actual point tip #2 in most "Flutter tips"
lists (⁠"pick one pattern") gets slightly wrong: pick one pattern *per
problem*, document why, and don't mix within the same feature.

## Docstring convention: 5W2H

Every non-trivial class/method carries a doc comment answering as many of
these as are relevant, so a reader (or interviewer) gets full context
without reading the implementation:

- **What** — what this thing is / does, in one line
- **Why** — why it exists, why this approach over an obvious alternative
- **Where** — where it sits in the architecture / who calls it
- **When** — when it runs / is invoked / becomes invalid
- **Who** — which layer/actor owns it, who's expected to extend it
- **How** — the mechanism, briefly
- **How much/many** — complexity, cost, limits (e.g. cache TTL, retry count)

See any file under `lib/features/home/` for the pattern in practice.

## Running

```bash
flutter pub get
flutter run
flutter test
```

No code generation step is required for this feature (plain `Equatable`
classes instead of `freezed`) so `flutter pub get` is enough to get moving.
Later features that need `freezed`/`json_serializable` will document their
own `build_runner` step when they land.

## Roadmap (next drops)

1. ✅ Home Dashboard (Riverpod, read-only aggregation across domains)
2. ✅ Auth — phone + OTP sign-in, biometric re-auth seam, session-aware
   `go_router` redirect. See "Feature 2" below for what's real vs. stubbed.
3. ✅ Lifestyle Habit Tracker — a self-contained **GetX** learning module
   (see "GetX module" below). Everything else in this app is Riverpod;
   this one screen is a deliberate, isolated exception.
4. Banking (offline-first ledger, idempotent transfer, Drift)
5. Stock (multiplexed WebSocket ticker, Bloc)
6. Insurance, Consumer
7. Native platform channel (one written by hand, not a plugin)
8. CI (GitHub Actions: analyze + test on every push)

## Feature 2: Auth — what's real, what's stubbed

**Real today:** the full phone → OTP → session flow, client + server-side-
equivalent validation (see `RequestOtp`, `VerifyOtp`, and
`FakeAuthRemoteDataSource`'s attempt-limit/expiry logic), a `go_router`
redirect guard that keeps unauthenticated users out of `/` and bounces
signed-in users away from `/login`, and a resend-cooldown countdown.

**Stubbed behind real interfaces, documented swap path:**
- `TokenStore` → `InMemoryTokenStore` today (tokens don't survive an app
  restart, on purpose — see that class's docstring). Swap to a
  `flutter_secure_storage`-backed `SecureTokenStore` later.
- `BiometricLocalDataSource` → `FakeBiometricLocalDataSource` today
  (always reports available, always succeeds). Swap to a `local_auth`-
  backed implementation later — see that file's docstring for the exact
  4-step plan.

Both swaps are single-provider changes in `auth_providers.dart` — nothing
in `domain/` or `presentation/` needs to change, which is the whole point
of the interfaces existing on day one.

**Demo credentials:** any 10-digit number, OTP code `123456`.

## Feature 3: Lifestyle Habit Tracker — the GetX module

`lib/features/lifestyle/` is a **self-contained GetX app-within-the-app**,
reached from the Lifestyle card on Home (`/lifestyle`). It exists as a
focused, isolated place to learn GetX properly — everything else in this
project is Riverpod + go_router, on purpose (see the state-management
table above); this module doesn't touch either.

**GetX pillars it exercises, and where:**

| Pillar | Where |
|---|---|
| Reactive state (`.obs`, `Obx`) | `HabitService.habits`, `HabitListController.filteredHabits` |
| Simple state (`GetBuilder`, `update()`) | `ThemeController` (theme toggle), `AddHabitController` (form validity) |
| Dependency injection | `Get.put` (module-lifetime: `HabitService`, `ThemeController`), `Get.lazyPut`/`fenix` (page-lifetime, via `Bindings`), `Get.find` |
| Route management | `Get.toNamed`, `Get.back(result:)`, `Get.arguments`, `GetPage`, `GetMiddleware` |
| Contextless overlays | `Get.snackbar` (workers), `Get.defaultDialog` (delete confirm), `Get.bottomSheet` (emoji picker) |
| Workers | `debounce` (search), `ever` (data sync + streak milestones), `once` (first-load tip) |
| `GetxService` | `HabitService` — survives page navigation within the module |
| Translations | `LifestyleTranslations`, toggled live via `Get.updateLocale` |
| `GetView<T>` | every view in the module |

**The one seam with the rest of the app:** `HabitListView._exitModule`
calls go_router's `context.pop()` — the single point where this module
has to reach outside itself to return to Home. That method's docstring
explains exactly why `Get.back()` can't do this job. Everywhere else in
`features/lifestyle/`, there is zero Riverpod and zero go_router.

**Demo credentials:** none needed — reachable directly from Home once
signed in (see the Auth demo credentials above to get there).
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// A minimal [GetMiddleware] — logs every navigation within this module.
///
/// WHAT: overrides [onPageCalled], one of the five middleware hook points
/// GetX exposes (`redirect`, `onPageCalled`, `onBindingsStart`,
/// `onPageBuildStart`, `onPageBuilt`/`onPageDispose` in newer versions) —
/// this demo uses the two simplest ones to keep the example legible.
///
/// WHY this exists at all in a module with no auth/permission logic to
/// guard: middleware isn't only for auth redirects — the GetX docs'
/// own example is a `redirect` that checks an `AuthService`, but
/// `onPageCalled`/`onPageBuildStart` are equally valid middleware
/// use cases for cross-cutting concerns like analytics or logging that
/// should fire on every navigation without every single `GetPage`
/// duplicating the same `debugPrint` call. [redirect] here always
/// returns `null` (never blocks navigation) — this middleware observes,
/// it doesn't gate.
///
/// WHERE: attached to every `GetPage` in `lifestyle_pages.dart` via that
/// page's `middlewares: [...]` list.
///
/// WHEN each hook fires: [redirect] first, then (if it returned `null`,
/// i.e. allowed navigation) [onPageCalled], both on every attempt to
/// navigate to a page this middleware is attached to — including the
/// very first entry to this module's `initialRoute`.
///
/// HOW MUCH: `priority` matters only when multiple middlewares are
/// attached to the same page (lower runs first) — with exactly one
/// middleware in this whole module, `0` is fine as-is; documented anyway
/// since it's part of the contract a reader would otherwise have to
/// guess at.
class LifestyleAnalyticsMiddleware extends GetMiddleware {
  @override
  int? get priority => 0;

  @override
  RouteSettings? redirect(String? route) => null;

  @override
  GetPage? onPageCalled(GetPage? page) {
    debugPrint('[lifestyle] navigating → ${page?.name}');
    return page;
  }
}
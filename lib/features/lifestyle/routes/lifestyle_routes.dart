/// Named-route constants for the `/lifestyle` module's own internal
/// navigation (`Get.toNamed`, `GetPage.name`).
///
/// WHY string constants in one place instead of inline literals at every
/// `Get.toNamed('/add-habit')` call site: a typo in an inline string
/// route name fails silently at runtime (GetX just won't find a matching
/// page) — referencing `LifestyleRoutes.addHabit` instead makes the same
/// mistake a compile-time error.
///
/// WHERE: consumed by `lifestyle_pages.dart` (defines the routes) and by
/// every view that calls `Get.toNamed`/`Get.offNamed` (uses the routes).
///
/// HOW MUCH: three routes — this module's entire internal route table.
abstract class LifestyleRoutes {
  const LifestyleRoutes._();

  static const habitList = '/habit-list';
  static const addHabit = '/add-habit';
  static const habitDetail = '/habit-detail';
}
import 'package:get/get.dart';

import '../bindings/add_habit_binding.dart';
import '../bindings/habit_detail_binding.dart';
import '../bindings/habit_list_binding.dart';
import '../views/add_habit_view.dart';
import '../views/habit_detail_view.dart';
import '../views/habit_list_view.dart';
import 'lifestyle_analytics_middleware.dart';
import 'lifestyle_routes.dart';

/// The module's internal route table — GetX's `GetPage` list, handed to
/// the nested `GetMaterialApp.getPages` in `lifestyle_module.dart`.
///
/// WHAT: each `GetPage` bundles four things GetX treats as one unit —
/// the route name, the widget to build, the `Bindings` that must run
/// first, and any `middlewares` — which is the concrete payoff of the
/// "bindings decouple DI from the view" pillar: nothing in
/// `HabitListView` itself mentions `HabitListBinding` at all; this file
/// is the only place that association is made.
///
/// WHY [LifestyleRoutes.addHabit] gets a custom `transition` and the
/// other two don't: it's presented as a "sheet-like" full page (slides
/// up), which reads correctly as "an add/create action", versus the list
/// → detail navigation using GetX's default transition since that's a
/// lateral "drill in" motion, not a creation action — a small, deliberate
/// UX distinction demonstrated via `GetPage.transition`, one more knob
/// this project hasn't needed to reach for elsewhere (go_router's
/// `CustomTransitionPage` is the equivalent there, unused so far since
/// no route has needed a non-default transition yet).
class LifestylePages {
  const LifestylePages._();

  static final pages = <GetPage>[
    GetPage(
      name: LifestyleRoutes.habitList,
      page: () => const HabitListView(),
      binding: HabitListBinding(),
      middlewares: [LifestyleAnalyticsMiddleware()],
    ),
    GetPage(
      name: LifestyleRoutes.addHabit,
      page: () => const AddHabitView(),
      binding: AddHabitBinding(),
      middlewares: [LifestyleAnalyticsMiddleware()],
      transition: Transition.downToUp,
    ),
    GetPage(
      name: LifestyleRoutes.habitDetail,
      page: () => const HabitDetailView(),
      binding: HabitDetailBinding(),
      middlewares: [LifestyleAnalyticsMiddleware()],
    ),
  ];
}
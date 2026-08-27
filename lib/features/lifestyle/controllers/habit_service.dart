import 'package:get/get.dart';

import '../models/habit.dart';

/// The permanent, module-wide source of truth for habit data.
///
/// WHAT: a [GetxService] — GetX's variant of [GetxController] that
/// explicitly promises "I will not be auto-deleted from memory when no
/// widget is watching me". Everything else in this module (controllers,
/// views) treats this as the single place habit data actually lives.
///
/// WHY [GetxService] and not just another [GetxController] with
/// `permanent: true` passed to `Get.put`: they end up equivalent at
/// runtime, but `GetxService` documents *intent* at the type level — a
/// reader instantly knows "this class is meant to outlive every screen",
/// versus having to go find wherever it happens to be `Get.put` to check
/// whether `permanent: true` was passed. This is the exact distinction
/// the GetX docs draw between "Services" (ApiService, StorageService,
/// CacheService) and ordinary page controllers.
///
/// WHERE: registered once, in `lifestyle_module.dart`, before the nested
/// `GetMaterialApp` is built — never inside a per-page `Bindings` class,
/// because a page binding's lifecycle is tied to that page's route, and
/// this data must outlive any single page.
///
/// WHEN it's created/destroyed: created on first entry to the `/lifestyle`
/// module; destroyed only by `Get.reset()` (a full GetX teardown, not
/// used in this demo) — navigating between the module's internal pages
/// (list → detail → back) never touches it.
///
/// HOW reactivity works here: [habits] is an `RxList`, so any widget
/// reading it inside `Obx`/`GetX` rebuilds automatically on `.add`,
/// `.removeWhere`, or index-assignment (`habits[i] = x`) — see the docs
/// pasted into this project's context on why `list[i] = x` is the
/// correct way to "update" an item in an observable list (mutating the
/// object in place would NOT notify listeners, since Dart doesn't deep-
/// observe object fields).
class HabitService extends GetxService {
  /// HOW MUCH: five seed habits, enough to make search/filtering and the
  /// streak-milestone worker demonstrable without real backend data.
  final RxList<Habit> habits = <Habit>[].obs;

  /// GetxService lifecycle hook — same `onInit`/`onReady`/`onClose`
  /// contract as [GetxController]. WHEN: called once, synchronously,
  /// right after `Get.put(HabitService())` registers this instance —
  /// this is why `lifestyle_module.dart` does not need to `await`
  /// anything before building the UI; seeding is synchronous on purpose
  /// to keep this demo free of a loading-state dance that would dilute
  /// the GetX-specific teaching points.
  @override
  void onInit() {
    super.onInit();
    habits.addAll([
      const Habit(id: 'h1', title: 'Drink water', emoji: '💧', streak: 2),
      const Habit(id: 'h2', title: 'Read 10 pages', emoji: '📖', streak: 5),
      const Habit(id: 'h3', title: 'Stretch', emoji: '🧘', streak: 0),
      const Habit(id: 'h4', title: 'Walk 5k steps', emoji: '🚶', streak: 1),
      const Habit(id: 'h5', title: 'Sleep by 11pm', emoji: '🌙', streak: 0),
    ]);
  }

  /// Fired (as a milestone value) whenever any habit's streak becomes a
  /// multiple of 3 — [HabitListController] has an `ever` worker watching
  /// this specifically to trigger a celebratory snackbar, kept separate
  /// from [habits] itself so that worker doesn't have to re-derive
  /// "did a milestone just happen" from a full list diff on every change.
  ///
  /// WHY a dedicated Rx for this rather than computing it inline where
  /// the snackbar is shown: decouples "detecting the event" (this
  /// service's job — it knows the domain rule for what counts as a
  /// milestone) from "reacting to the event" (the controller's job —
  /// UI-adjacent side effects). A real app might add a second `ever`
  /// listener here later (e.g. write an analytics event) without ever
  /// touching the controller.
  final RxInt milestoneStreak = 0.obs;

  void addHabit(Habit habit) => habits.add(habit);

  void removeHabit(String id) => habits.removeWhere((h) => h.id == id);

  /// Toggles today's completion for the habit with [id], updating streak.
  ///
  /// HOW: reads the current [Habit], builds a new one via [Habit.copyWith],
  /// and writes it back with `habits[index] = updated` — the reactive
  /// write pattern documented on [Habit] itself. Un-completing (tapping
  /// an already-completed habit again) decrements the streak back down,
  /// so this method is a true toggle, not a one-way "mark done".
  void toggleCompletedToday(String id) {
    final index = habits.indexWhere((h) => h.id == id);
    if (index == -1) return;
    final current = habits[index];

    final Habit updated;
    if (current.isCompletedToday) {
      updated = current.copyWith(streak: current.streak - 1, lastCompletedOn: null);
    } else {
      updated = current.copyWith(streak: current.streak + 1, lastCompletedOn: DateTime.now());
      if (updated.streak > 0 && updated.streak % 3 == 0) {
        milestoneStreak.value = updated.streak;
      }
    }
    habits[index] = updated;
  }
}
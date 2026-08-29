import 'package:get/get.dart';

import '../models/habit.dart';
import 'habit_service.dart';

/// Drives `HabitListView` — search/filter state plus three of GetX's
/// four documented Worker types, each chosen for a genuinely different
/// reason (not just "included for completeness").
///
/// WHAT: reactive counterpart to [ThemeController] — every field here is
/// `.obs`, and the view rebuilds via `Obx`/`GetX`, never `GetBuilder`.
///
/// WHERE: page-scoped, unlike [HabitService]/[ThemeController] — this
/// controller is registered via [HabitListBinding] with `fenix: true`
/// (see that binding's docstring for what `fenix` buys here), because
/// list/search UI state has no reason to survive once the user leaves
/// this screen, the way habit data or theme choice does.
///
/// WHEN constructed: the instant `HabitListBinding.dependencies()` runs,
/// which GetX guarantees happens before `HabitListView.build()` — so
/// `Get.find<HabitListController>()` inside the view (via `GetView`) is
/// always safe, never a race.
class HabitListController extends GetxController {
  final HabitService _service = Get.find<HabitService>();

  /// What the user has typed into the search field. Deliberately NOT
  /// what the list is filtered by directly — see [_searchDebounce].
  final RxString searchQuery = ''.obs;

  /// What the view actually renders. Recomputed by [_applyFilter],
  /// itself triggered by two different Workers below — not by anything
  /// in the view, which only ever reads this list.
  final RxList<Habit> filteredHabits = <Habit>[].obs;

  late final Worker _searchDebounce;
  late final Worker _milestoneWorker;
  late final Worker _firstLoadTip;

  @override
  void onInit() {
    super.onInit();

    // WORKER 1 — debounce: re-filter 300ms after the user stops typing,
    // not on every keystroke. WHY this matters even against an in-memory
    // list of 5 items: it's the correct pattern regardless of dataset
    // size — the moment `_applyFilter` is backed by a real API call
    // instead of a local `.where()`, an un-debounced version would fire
    // a network request per keystroke. Demonstrating the *pattern* here
    // means swapping in real search-as-you-type networking later costs
    // zero changes to this Worker.
    _searchDebounce = debounce(
      searchQuery,
      (_) => _applyFilter(),
      time: const Duration(milliseconds: 300),
    );

    // WORKER 2 — ever: re-filter every time the underlying data changes
    // (habit added/removed/toggled), unconditionally, with no debounce —
    // data changes are already discrete user actions (one tap = one
    // change), so there's nothing to throttle, unlike free-form typing.
    ever(_service.habits, (_) => _applyFilter());

    // WORKER 2b — a second `ever`, on a different Rx, proving Workers are
    // attached per-observable, not per-controller: this one celebrates a
    // streak milestone the moment HabitService reports one, completely
    // independently of the search/filter machinery above.
    _milestoneWorker = ever<int>(_service.milestoneStreak, (streak) {
      if (streak > 0) {
        Get.snackbar(
          '🔥 $streak-day streak!',
          'Keep it up — consistency is the whole game.',
          snackPosition: SnackPosition.TOP,
        );
      }
    });

    // WORKER 3 — once: show a one-time usage tip the first time habit
    // data actually changes after this controller starts watching it.
    // WHY `once` and not just showing this in `onReady()`: `once` reacts
    // to the *first change event* on the observable, which is the
    // correct primitive for "the first time X happens" in general (e.g.
    // "the first time real data arrives from a slow API") — using it
    // here on a synchronously-seeded list is a slightly contrived fit
    // for this demo's synchronous data, but the Worker itself is written
    // exactly as it would be against real async data, which is the point.
    _firstLoadTip = once(_service.habits, (_) {
      Get.snackbar(
        'Tip',
        'Tap a habit to mark today complete. Long-press for quick actions.',
        snackPosition: SnackPosition.BOTTOM,
      );
    });

    _applyFilter(); // populate filteredHabits immediately, don't wait for
    // the first debounce/ever tick — see docstring on _applyFilter.
  }

  /// WHY called both from `onInit` directly AND from two Workers instead
  /// of relying solely on the Workers: a Worker only fires on a
  /// *subsequent* change to the observable it watches, never for the
  /// value already present at subscribe-time — without this direct call,
  /// [filteredHabits] would stay empty until the very first edit, which
  /// is the wrong first-frame experience for a screen that should show
  /// all habits by default.
  void _applyFilter() {
    final query = searchQuery.value.trim().toLowerCase();
    filteredHabits.value = query.isEmpty
        ? _service.habits.toList()
        : _service.habits.where((h) => h.title.toLowerCase().contains(query)).toList();
  }

  void setSearchQuery(String value) => searchQuery.value = value;

  void toggleComplete(String habitId) => _service.toggleCompletedToday(habitId);

  /// HOW MUCH cleanup discipline matters: every `Worker` created in
  /// `onInit` must be disposed in `onClose`, or it keeps listening to its
  /// source `Rx` forever — a real memory/behavior leak, not a cosmetic
  /// one, since `_service.habits` outlives this controller (it's a
  /// [GetxService]). `debounce`/`ever`/`once` all return a [Worker] with
  /// `.dispose()` specifically so this cleanup is possible.
  @override
  void onClose() {
    _searchDebounce.dispose();
    _milestoneWorker.dispose();
    _firstLoadTip.dispose();
    super.onClose();
  }
}
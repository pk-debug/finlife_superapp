/// A single trackable habit — the one piece of data this whole GetX
/// module exists to manage.
///
/// WHAT: a plain, immutable-by-convention model (fields are `final`, but
/// unlike the Riverpod features elsewhere in this app, this one is NOT
/// [Equatable] and has no `freezed` — that's deliberate, see WHY.
///
/// WHY plain instead of matching the rest of the app's Equatable pattern:
/// this whole feature is a GetX learning sandbox (see `lifestyle_module.dart`
/// for the full framing) — GetX's own idioms (`.obs`, `RxList`,
/// `list[i] = updated`) don't need value-equality on the model the way
/// Riverpod's `select`/diffing does, so adding Equatable here would be
/// copying a Riverpod habit into GetX code for no benefit, which defeats
/// the point of an honest side-by-side comparison.
///
/// WHERE: `features/lifestyle/models` — used by every layer of this
/// module (service, controllers, views).
///
/// HOW updates happen: never mutate a [Habit] in place. Always build a
/// new one via [copyWith] and replace it in the owning `RxList` by index
/// (`habits[i] = updated`) — see [HabitService.toggleCompletedToday] for
/// why that specific write pattern is what makes GetX's reactivity fire.
class Habit {
  const Habit({
    required this.id,
    required this.title,
    required this.emoji,
    this.streak = 0,
    this.lastCompletedOn,
  });

  final String id;
  final String title;
  final String emoji;

  /// Consecutive days completed. HOW MUCH: no cap — a real app would
  /// probably reset this after a missed day; this demo module only ever
  /// increments it (see [HabitService.toggleCompletedToday]), which is
  /// enough to demonstrate GetX workers reacting to a changing value
  /// without adding date-arithmetic edge cases that would distract from
  /// the GetX-focused point of this feature.
  final int streak;

  final DateTime? lastCompletedOn;

  /// WHEN true: [lastCompletedOn] falls on today's calendar date.
  bool get isCompletedToday {
    final last = lastCompletedOn;
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year && last.month == now.month && last.day == now.day;
  }

  Habit copyWith({int? streak, DateTime? lastCompletedOn}) {
    return Habit(
      id: id,
      title: title,
      emoji: emoji,
      streak: streak ?? this.streak,
      lastCompletedOn: lastCompletedOn ?? this.lastCompletedOn,
    );
  }
}
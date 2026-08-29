import 'package:get/get.dart';

/// This ₹ `Translations` class, used
/// with `.tr` on string keys and `Get.updateLocale` to switch languages
/// at runtime with no widget rebuild plumbing of your own.
///
/// WHAT: two locales, `en_US` and `hi_IN`, covering just the strings this
/// small module actually displays — not a stand-in for a real i18n setup
/// (which would use `.arb` files + `flutter_localizations` for the rest
/// of the app, as most production Flutter apps do), but a faithful,
/// working example of GetX's *own* built-in mechanism specifically,
/// since that's one of the three pillars this feature exists to cover.
///
/// WHY scoped to this module only, not applied app-wide: the rest of
/// this app (Home, Auth) doesn't use GetX at all, so it has no
/// `Translations` concept to share with — this is one more expression of
/// this feature's "self-contained sandbox" boundary.
///
/// WHERE: passed to `translations:` on the nested `GetMaterialApp` in
/// `lifestyle_module.dart`.
///
/// WHEN the active locale changes: only when the user taps the language
/// toggle in `HabitListView`'s AppBar, which calls
/// `Get.updateLocale(...)` directly — every widget using `.tr` on a key
/// defined here rebuilds automatically; no controller or Rx variable is
/// involved in that mechanism at all, it's fully internal to GetX.
class LifestyleTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'habits_title': 'My Habits',
          'add_habit': 'Add habit',
          'search_hint': 'Search habits',
          'no_results': 'No habits match your search',
          'day_streak': 'day streak',
        },
        'hi_IN': {
          'habits_title': 'मेरी आदतें',
          'add_habit': 'आदत जोड़ें',
          'search_hint': 'आदतें खोजें',
          'no_results': 'कोई आदत नहीं मिली',
          'day_streak': 'दिन की लकीर',
        },
      };
}
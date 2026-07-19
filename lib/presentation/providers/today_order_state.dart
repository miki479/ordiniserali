import '../../domain/entities/accompaniment.dart';
import '../../domain/entities/food_order.dart';
import '../../domain/usecases/calculate_frequent_dish_usecase.dart';

/// A one-tap "order again" suggestion offered when there's no order yet
/// today: either the exact last order placed, or the dish ordered often
/// enough to count as a habit. The two alternate by day when both exist.
sealed class RepeatSuggestion {
  const RepeatSuggestion();
}

class RepeatLastOrder extends RepeatSuggestion {
  const RepeatLastOrder({required this.ordine, required this.accompagnamento});
  final String ordine;
  final Accompaniment accompagnamento;
}

class RepeatFrequentDish extends RepeatSuggestion {
  const RepeatFrequentDish(this.suggestion);
  final FrequentDishSuggestion suggestion;
}

/// Everything the home screen's order card needs for "today".
class TodayOrderData {
  const TodayOrderData({
    required this.order,
    required this.dayLocked,
    required this.suggestion,
  });

  /// The order already saved today under my identity (possibly adopted from
  /// a colleague-placed guest order) — `null` if I haven't ordered yet.
  final FoodOrder? order;

  /// The whole evening's service is closed (capolinea already generated the
  /// PDF) — distinct from *my* order being individually locked.
  final bool dayLocked;

  final RepeatSuggestion? suggestion;
}

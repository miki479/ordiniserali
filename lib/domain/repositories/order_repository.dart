import '../entities/food_order.dart';

class DayStatus {
  const DayStatus({required this.giorno, required this.locked});
  final String giorno;
  final bool locked;
}

abstract class OrderRepository {
  Future<FoodOrder?> getOrder(String docId);

  /// Looks up an order placed for a not-yet-registered "guest" identity
  /// (`{giorno}_ospite_{cognomeSlug}_{nomeSlug}`).
  Future<FoodOrder?> getGuestOrder({
    required String giorno,
    required String cognomeSlug,
    required String nomeSlug,
  });

  Future<void> attachUidToOrder({required String docId, required String uid});

  Future<DayStatus?> getDayStatus(String giorno);

  /// Creates or updates the order at [docId], enforcing optimistic
  /// concurrency via [expectedVersion] and refusing writes once the order or
  /// the whole day is locked. Throws [OrderException] on failure.
  Future<void> submitOrder({
    required String docId,
    required String giorno,
    required String? uid,
    required String nome,
    required String cognome,
    required String ordine,
    required String? accompagnamento,
    required int expectedVersion,
  });

  /// Places or updates an order on someone else's behalf ("ordina per un
  /// collega"). Unlike [submitOrder] this never rejects on a version
  /// mismatch — the person placing it may not know the current version.
  Future<void> submitOrderForColleague({
    required String docId,
    required String giorno,
    required String? uid,
    required String nome,
    required String cognome,
    required String ordine,
    required String? accompagnamento,
  });

  Future<List<FoodOrder>> getOrdersForDay(String giorno);

  Future<List<FoodOrder>> getOrdersForUid(String uid);

  Future<void> updateOrderContent({
    required String docId,
    required String ordine,
    required String? accompagnamento,
    required int expectedVersion,
  });

  Future<void> deleteOrder(String docId);

  Future<void> deleteOrdersForDay(String giorno);

  Future<void> lockOrders(List<String> docIds);

  Future<void> lockDay(String giorno);

  Future<void> unlockDay(String giorno);

  Future<void> logDeletion({required String account, required String uid});

  Future<void> deleteOrdersOlderThan(String cutoffDayKey);

  Future<void> deleteStaleDayLocks(String cutoffDayKey);
}

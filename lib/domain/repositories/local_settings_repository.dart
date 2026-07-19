/// On-device, non-authoritative state: the cached display profile, the
/// "still you?" re-confirmation timestamp, the once-a-day cleanup guard and
/// the last order placed (used for the "repeat order" suggestion).
abstract class LocalSettingsRepository {
  Future<void> saveProfile({required String nome, required String cognome});

  ({String nome, String cognome})? readProfile();

  Future<void> clearProfile();

  Future<void> markIdentityConfirmedNow();

  bool isIdentityConfirmationRecent(Duration within);

  String? readLastCleanupDay();

  Future<void> saveLastCleanupDay(String dayKey);

  Future<void> saveLastOrder({
    required String uid,
    required String ordine,
    required String? accompagnamento,
  });

  ({String ordine, String? accompagnamento})? readLastOrder(String uid);
}

import '../../core/utils/date_utils.dart';
import '../repositories/local_settings_repository.dart';
import '../repositories/order_repository.dart';

const int _retentionDays = 90;

/// Deletes orders (and their stale day-lock documents) older than 90 days,
/// run at most once per day per device by whoever with delete rights
/// (capolinea) opens the app.
class CleanupOldOrdersUseCase {
  const CleanupOldOrdersUseCase(this._orders, this._localSettings);

  final OrderRepository _orders;
  final LocalSettingsRepository _localSettings;

  Future<void> call() async {
    final today = todayKey();
    if (_localSettings.readLastCleanupDay() == today) return;
    await _localSettings.saveLastCleanupDay(today);

    try {
      final cutoff = dayKey(
        DateTime.now().subtract(const Duration(days: _retentionDays)),
      );
      await _orders.deleteOrdersOlderThan(cutoff);
      await _orders.deleteStaleDayLocks(cutoff);
    } catch (_) {
      // Best-effort background maintenance: a failure here must never block
      // the person from using the app.
    }
  }
}

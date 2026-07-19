/// Local-calendar-day key ("2026-07-19") used as the Firestore day/order
/// grouping key. Intentionally based on device-local time, matching what a
/// person expects "today" to mean, not UTC.
String todayKey([DateTime? now]) => dayKey(now ?? DateTime.now());

String dayKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

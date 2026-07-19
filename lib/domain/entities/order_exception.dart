/// Mirrors the specific failure modes the original app distinguished when
/// writing an order, so the UI can show a precise message for each.
enum OrderFailureReason { locked, conflict, dayClosed, timeout, unknown }

class OrderException implements Exception {
  const OrderException(this.reason, [this.message]);

  final OrderFailureReason reason;
  final String? message;

  @override
  String toString() => 'OrderException($reason, $message)';
}

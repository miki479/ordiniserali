import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../core/utils/text_utils.dart';
import '../../domain/entities/food_order.dart';
import 'repository_providers.dart';
import 'today_order_controller.dart';

/// Backs the "Ordini di oggi" tab of the capolinea panel: every order placed
/// today, editable and deletable in place.
class PanelOrdersController extends AsyncNotifier<List<FoodOrder>> {
  @override
  Future<List<FoodOrder>> build() {
    return ref.read(orderRepositoryProvider).getOrdersForDay(todayKey());
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(orderRepositoryProvider).getOrdersForDay(todayKey()),
    );
  }

  Future<void> saveOrder(
    FoodOrder order, {
    required String ordine,
    required String? accompagnamento,
  }) async {
    final cleaned = sanitizeOrderText(ordine);
    await ref
        .read(orderRepositoryProvider)
        .updateOrderContent(
          docId: order.id,
          ordine: cleaned,
          accompagnamento: accompagnamento,
          expectedVersion: order.version,
        );
    await refresh();
    // My own order card may show the value that was just corrected.
    ref.invalidate(todayOrderControllerProvider);
  }

  Future<void> deleteOrder(FoodOrder order) async {
    await ref.read(orderRepositoryProvider).deleteOrder(order.id);
    await refresh();
    ref.invalidate(todayOrderControllerProvider);
  }
}

final panelOrdersControllerProvider =
    AsyncNotifierProvider<PanelOrdersController, List<FoodOrder>>(
      PanelOrdersController.new,
    );

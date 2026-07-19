import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/panel_orders_controller.dart';
import 'panel_order_row.dart';

class PanelOrdersTab extends ConsumerWidget {
  const PanelOrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ordersAsync = ref.watch(panelOrdersControllerProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          l10n.panelOrdersLoadError,
          style: TextStyle(color: context.colors.inkSoft),
        ),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Text(
              l10n.panelOrdersEmpty,
              style: TextStyle(
                color: context.colors.inkSoft,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 8),
          itemCount: orders.length,
          itemBuilder: (context, index) => PanelOrderRow(order: orders[index]),
        );
      },
    );
  }
}

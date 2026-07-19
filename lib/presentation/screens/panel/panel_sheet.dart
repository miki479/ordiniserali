import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/panel_orders_tab.dart';
import 'widgets/panel_users_tab.dart';

/// The capolinea (team lead) admin panel: today's orders and the member
/// roster, each editable in place. Presented as a tall bottom sheet rather
/// than a full route, matching the rest of the app's overlay-driven flows.
Future<void> showPanelSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _PanelSheet(),
  );
}

class _PanelSheet extends StatefulWidget {
  const _PanelSheet();

  @override
  State<_PanelSheet> createState() => _PanelSheetState();
}

class _PanelSheetState extends State<_PanelSheet>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Container(
        decoration: BoxDecoration(
          color: colors.paper,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.panelTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: colors.inkSoft,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: TabBar(
                controller: _tabController,
                labelColor: colors.paper,
                unselectedLabelColor: colors.inkSoft,
                indicator: BoxDecoration(
                  color: colors.wine,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
                tabs: [
                  Tab(text: l10n.panelTabOrders),
                  Tab(text: l10n.panelTabUsers),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: TabBarView(
                  controller: _tabController,
                  children: const [PanelOrdersTab(), PanelUsersTab()],
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }
}

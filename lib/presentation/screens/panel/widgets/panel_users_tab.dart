import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/panel_users_controller.dart';
import '../../../providers/session_controller.dart';
import '../../../providers/session_state.dart';
import 'panel_user_row.dart';

class PanelUsersTab extends ConsumerWidget {
  const PanelUsersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final usersAsync = ref.watch(panelUsersControllerProvider);
    final session = ref.watch(sessionControllerProvider);
    final isSuperuser = session is SessionActive && session.isSuperuser;

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          l10n.panelUsersLoadError,
          style: TextStyle(color: context.colors.inkSoft),
        ),
      ),
      data: (data) {
        if (data.users.isEmpty) {
          return Center(
            child: Text(
              l10n.panelUsersEmpty,
              style: TextStyle(
                color: context.colors.inkSoft,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 8),
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.colors.paperDeep,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l10n.panelUsersNote,
                style: TextStyle(
                  color: context.colors.inkSoft,
                  fontSize: 11.5,
                  height: 1.5,
                ),
              ),
            ),
            for (final user in data.users)
              PanelUserRow(
                profile: user,
                isCapolinea: data.capolineaIds?.contains(user.uid),
                capolineaEditable: isSuperuser && data.capolineaIds != null,
              ),
          ],
        );
      },
    );
  }
}

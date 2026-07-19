import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_sheet.dart';
import '../../l10n/app_localizations.dart';

enum OmonimoAction { switchToLogin, addInitial }

/// Shown when registration hits an existing "nome cognome" — lets the person
/// either sign in (if it's really them) or add a distinguishing initial.
Future<OmonimoAction?> showOmonimoDialog(
  BuildContext context, {
  required String nome,
  required String cognome,
}) {
  final l10n = AppLocalizations.of(context);
  return showAppSheet<OmonimoAction>(
    context,
    builder: (ctx) => AppSheetContainer(
      title: l10n.omonimoTitle,
      children: [
        Text(
          l10n.omonimoBody(nome, cognome),
          style: TextStyle(
            color: ctx.colors.inkSoft,
            fontSize: 12.5,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.omonimoInfo,
          style: TextStyle(
            color: ctx.colors.inkSoft,
            fontSize: 12.5,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(OmonimoAction.switchToLogin),
          style: FilledButton.styleFrom(backgroundColor: ctx.colors.tomato),
          child: Text(l10n.omonimoBtnLogin),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(OmonimoAction.addInitial),
          style: FilledButton.styleFrom(
            backgroundColor: ctx.colors.ink,
            foregroundColor: ctx.colors.paper,
          ),
          child: Text(l10n.omonimoBtnAddInitial),
        ),
      ],
    ),
  );
}

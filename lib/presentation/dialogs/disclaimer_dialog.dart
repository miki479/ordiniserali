import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_sheet.dart';
import '../../l10n/app_localizations.dart';

/// The "how your data is used" info sheet, reachable from the small "i"
/// button that floats above every screen.
Future<void> showDisclaimerDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final paragraphs = [
    l10n.disclaimerP1,
    l10n.disclaimerP2,
    l10n.disclaimerP3,
    l10n.disclaimerP4,
    l10n.disclaimerP5,
  ];

  return showAppSheet<void>(
    context,
    builder: (ctx) => AppSheetContainer(
      title: l10n.disclaimerTitle,
      children: [
        for (final p in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              p,
              style: TextStyle(
                color: ctx.colors.inkSoft,
                fontSize: 12.5,
                height: 1.55,
              ),
            ),
          ),
        const SizedBox(height: 6),
        OutlinedButton(
          onPressed: () => Navigator.of(ctx).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: ctx.colors.inkSoft,
            side: BorderSide(color: ctx.colors.line),
          ),
          child: Text(l10n.close),
        ),
      ],
    ),
  );
}

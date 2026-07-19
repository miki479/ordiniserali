import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_sheet.dart';

/// Generic yes/no confirmation, replacing `#confirm-overlay`. Used for
/// destructive or hard-to-undo actions (logout, delete order, delete the
/// whole evening's orders).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Conferma',
  String cancelLabel = 'Annulla',
}) async {
  final result = await showAppSheet<bool>(
    context,
    builder: (ctx) => AppSheetContainer(
      title: title,
      children: [
        Text(
          message,
          style: TextStyle(
            color: ctx.colors.inkSoft,
            fontSize: 13,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: ctx.colors.tomato),
          child: Text(confirmLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

class ChipSuggestion {
  const ChipSuggestion(this.label, this.fillText);
  final String label;
  final String fillText;
}

/// Quick-fill chips above the order field: tapping one drops its text into
/// the textarea so a common order takes one tap instead of typing.
class ChipSuggestions extends StatelessWidget {
  const ChipSuggestions({super.key, required this.onPick, this.enabled = true});

  final ValueChanged<String> onPick;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final chips = [
      ChipSuggestion(l10n.chipPanino, l10n.chipPaninoFill),
      ChipSuggestion(l10n.chipGrigliata, l10n.chipGrigliataFill),
      ChipSuggestion(l10n.chipPasta, l10n.chipPastaFill),
      ChipSuggestion(l10n.chipHamburger, l10n.chipHamburgerFill),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final chip in chips)
          ActionChip(
            label: Text(chip.label),
            onPressed: enabled ? () => onPick(chip.fillText) : null,
            backgroundColor: colors.paperDeep,
            labelStyle: TextStyle(
              color: colors.inkSoft,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              side: BorderSide.none,
            ),
          ),
      ],
    );
  }
}

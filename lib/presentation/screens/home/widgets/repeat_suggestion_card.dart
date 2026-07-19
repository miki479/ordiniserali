import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/today_order_state.dart';

/// One-tap "order again" prompt shown above the empty order form: either the
/// exact last order, or a dish ordered often enough to count as a habit.
class RepeatSuggestionCard extends StatelessWidget {
  const RepeatSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onTap,
  });

  final RepeatSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    final String icon;
    final String text;
    switch (suggestion) {
      case RepeatFrequentDish(suggestion: final dish):
        icon = '🔥';
        text = l10n.repeatFrequent(dish.displayName);
        break;
      case RepeatLastOrder(:final ordine, :final accompagnamento):
        icon = '🔁';
        final summary = accompagnamento.firestoreValue.isEmpty
            ? ordine
            : '$ordine + ${accompagnamento.label}';
        text = l10n.repeatAgain(summary);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colors.paperDeep,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: colors.olive,
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(color: colors.ink, fontSize: 13),
                      children: [TextSpan(text: text)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../domain/entities/accompaniment.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/accompaniment_selector.dart';
import 'chip_suggestions.dart';

/// The editable part of the order: quick-fill chips, free-text field and
/// accompaniment choice. Dims and disables itself (but stays visible, so
/// people can still see what they typed) once the order is locked.
class OrderFormCard extends StatelessWidget {
  const OrderFormCard({
    super.key,
    required this.controller,
    required this.accompaniment,
    required this.locked,
    required this.onAccompanimentChanged,
    required this.onChipPick,
  });

  final TextEditingController controller;
  final Accompaniment accompaniment;
  final bool locked;
  final ValueChanged<Accompaniment> onAccompanimentChanged;
  final ValueChanged<String> onChipPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Stack(
      children: [
        AnimatedOpacity(
          opacity: locked ? 0.45 : 1,
          duration: const Duration(milliseconds: 250),
          child: IgnorePointer(
            ignoring: locked,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChipSuggestions(onPick: onChipPick, enabled: !locked),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  enabled: !locked,
                  maxLength: 300,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: l10n.orderPlaceholder,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 18),
                SectionLabel(l10n.sectionAccompaniment),
                AccompanimentSelector(
                  value: accompaniment,
                  onChanged: onAccompanimentChanged,
                  enabled: !locked,
                ),
              ],
            ),
          ),
        ),
        if (locked)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.ink,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: [
                      BoxShadow(
                        color: colors.ink.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔒', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        l10n.lockedBadge.toUpperCase(),
                        style: TextStyle(
                          color: colors.paper,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

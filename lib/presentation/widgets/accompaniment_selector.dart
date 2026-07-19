import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/accompaniment.dart';

/// Single-select pill row for choosing an accompaniment. Shared by the main
/// order form and the "order for a colleague" sheet.
class AccompanimentSelector extends StatelessWidget {
  const AccompanimentSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final Accompaniment value;
  final ValueChanged<Accompaniment> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        for (final option in Accompaniment.values) ...[
          if (option != Accompaniment.values.first) const SizedBox(width: 10),
          Expanded(
            child: _AccompanimentChip(
              option: option,
              selected: option == value,
              enabled: enabled,
              onTap: () => onChanged(option),
              colors: colors,
            ),
          ),
        ],
      ],
    );
  }
}

class _AccompanimentChip extends StatelessWidget {
  const _AccompanimentChip({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.colors,
  });

  final Accompaniment option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: selected ? colors.tomato : colors.paperDeep,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        elevation: selected ? 3 : 0,
        shadowColor: colors.tomato.withValues(alpha: 0.4),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Text(
              option.displayLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? Colors.white : colors.inkSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

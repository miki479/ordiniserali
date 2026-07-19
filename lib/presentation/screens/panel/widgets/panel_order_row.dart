import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../domain/entities/accompaniment.dart';
import '../../../../domain/entities/food_order.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/panel_orders_controller.dart';

/// One editable row in the "Ordini di oggi" tab: a locked order shows
/// read-only, an open one can be corrected or removed on the spot.
class PanelOrderRow extends ConsumerStatefulWidget {
  const PanelOrderRow({super.key, required this.order});

  final FoodOrder order;

  @override
  ConsumerState<PanelOrderRow> createState() => _PanelOrderRowState();
}

class _PanelOrderRowState extends ConsumerState<PanelOrderRow> {
  late final _ordineCtrl = TextEditingController(text: widget.order.ordine);
  late Accompaniment _accomp = widget.order.accompagnamento;
  bool _saving = false;
  bool _deleting = false;

  @override
  void dispose() {
    _ordineCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final cleaned = sanitizeOrderText(_ordineCtrl.text);
    if (cleaned.isEmpty) {
      showAppToast(context, l10n.panelOrderEmptyError);
      return;
    }
    if (cleaned.length > kMaxOrderLength) {
      showAppToast(context, l10n.toastTooLong(kMaxOrderLength));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(panelOrdersControllerProvider.notifier)
          .saveOrder(
            widget.order,
            ordine: cleaned,
            accompagnamento: _accomp == Accompaniment.none
                ? null
                : _accomp.firestoreValue,
          );
      if (mounted) showAppToast(context, l10n.panelOrderSaved);
    } catch (_) {
      if (mounted) showAppToast(context, l10n.panelOrderSaveError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.deleteOrderTitle,
      message: l10n.deleteOrderMessage(widget.order.fullName),
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
    );
    if (!ok) return;
    setState(() => _deleting = true);
    try {
      await ref
          .read(panelOrdersControllerProvider.notifier)
          .deleteOrder(widget.order);
      if (mounted) showAppToast(context, l10n.panelOrderDeleted);
    } catch (_) {
      if (mounted) showAppToast(context, l10n.panelOrderDeleteError);
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final locked = widget.order.locked;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.order.fullName.isEmpty ? '—' : widget.order.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
              if (locked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.tomatoDeep.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.panelBadgeLocked,
                    style: TextStyle(
                      color: colors.tomatoDeep,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ordineCtrl,
            enabled: !locked,
            maxLength: kMaxOrderLength,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(isDense: true, counterText: ''),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Accompaniment>(
            initialValue: _accomp,
            isDense: true,
            decoration: const InputDecoration(isDense: true),
            items: [
              for (final option in Accompaniment.values)
                DropdownMenuItem(
                  value: option,
                  child: Text(option.displayLabel),
                ),
            ],
            onChanged: locked
                ? null
                : (v) => setState(() => _accomp = v ?? Accompaniment.none),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!locked)
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.olive,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      l10n.panelSave,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
              if (!locked) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _deleting ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.tomatoDeep,
                    side: BorderSide(color: colors.tomatoDeep, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    l10n.panelDelete,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

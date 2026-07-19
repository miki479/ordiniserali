import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/name_utils.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../domain/entities/app_user_profile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/panel_users_controller.dart';

/// One editable row in the "Utenti" tab: fix a display name, or (superuser
/// only, when the underlying list is readable) toggle team-lead status.
class PanelUserRow extends ConsumerStatefulWidget {
  const PanelUserRow({
    super.key,
    required this.profile,
    required this.isCapolinea,
    required this.capolineaEditable,
  });

  final AppUserProfile profile;
  final bool? isCapolinea;
  final bool capolineaEditable;

  @override
  ConsumerState<PanelUserRow> createState() => _PanelUserRowState();
}

class _PanelUserRowState extends ConsumerState<PanelUserRow> {
  late final _nomeCtrl = TextEditingController(text: widget.profile.nome);
  late final _cognomeCtrl = TextEditingController(text: widget.profile.cognome);
  late bool _capolinea = widget.isCapolinea ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cognomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final nome = normalizeName(_nomeCtrl.text);
    final cognome = normalizeName(_cognomeCtrl.text);
    if (nome.isEmpty || cognome.isEmpty) {
      showAppToast(context, l10n.panelUserNamesEmpty);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(panelUsersControllerProvider.notifier)
          .saveUser(
            widget.profile,
            nome: nome,
            cognome: cognome,
            makeCapolinea: widget.capolineaEditable ? _capolinea : null,
          );
      if (mounted) showAppToast(context, l10n.panelUserSaved);
    } catch (_) {
      if (mounted) showAppToast(context, l10n.panelUserSaveError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    final String capolineaLabel;
    final bool checkboxEnabled;
    if (widget.isCapolinea == null) {
      capolineaLabel = l10n.panelCapolineaUnavailable;
      checkboxEnabled = false;
    } else if (!widget.capolineaEditable) {
      capolineaLabel = l10n.panelCapolineaSuperuserOnly;
      checkboxEnabled = false;
    } else {
      capolineaLabel = l10n.panelCapolineaLabel;
      checkboxEnabled = true;
    }

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
          TextField(
            controller: _nomeCtrl,
            maxLength: 40,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              hintText: l10n.fieldNome,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cognomeCtrl,
            maxLength: 40,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              hintText: l10n.fieldCognome,
            ),
          ),
          const SizedBox(height: 4),
          CheckboxListTile(
            value: _capolinea,
            onChanged: checkboxEnabled
                ? (v) => setState(() => _capolinea = v ?? false)
                : null,
            title: Text(
              capolineaLabel,
              style: TextStyle(fontSize: 13, color: colors.ink),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeColor: colors.wine,
          ),
          const SizedBox(height: 6),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: colors.olive,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(l10n.panelSave, style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

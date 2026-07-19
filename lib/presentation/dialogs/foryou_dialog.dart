import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/name_utils.dart';
import '../../core/utils/text_utils.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/section_label.dart';
import '../../domain/entities/accompaniment.dart';
import '../../domain/entities/app_user_profile.dart';
import '../../domain/entities/order_exception.dart';
import '../../domain/usecases/resolve_colleague_usecase.dart';
import '../../l10n/app_localizations.dart';
import '../providers/repository_providers.dart';
import '../providers/today_order_controller.dart';
import '../providers/usecase_providers.dart';
import '../widgets/accompaniment_selector.dart';

/// "Ordina per un collega": place an order under someone else's name — a
/// colleague without the app yet, or one who's asked you to order for them.
Future<void> showForYouDialog(BuildContext context) {
  return showAppSheet<void>(context, builder: (ctx) => const _ForYouSheet());
}

class _ForYouSheet extends ConsumerStatefulWidget {
  const _ForYouSheet();

  @override
  ConsumerState<_ForYouSheet> createState() => _ForYouSheetState();
}

class _ForYouSheetState extends ConsumerState<_ForYouSheet> {
  final _nomeCtrl = TextEditingController();
  final _cognomeCtrl = TextEditingController();
  final _ordineCtrl = TextEditingController();
  Accompaniment _accomp = Accompaniment.none;
  bool _busy = false;
  List<AppUserProfile>? _candidates;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cognomeCtrl.dispose();
    _ordineCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final nome = normalizeName(_nomeCtrl.text);
    final cognome = normalizeName(_cognomeCtrl.text);
    final ordine = sanitizeOrderText(_ordineCtrl.text);

    if (nome.isEmpty) {
      showAppToast(context, l10n.foryouErrorMissingNome);
      return;
    }
    if (cognome.isEmpty) {
      showAppToast(context, l10n.foryouErrorMissingCognome);
      return;
    }
    if (ordine.isEmpty) {
      showAppToast(context, l10n.foryouErrorMissingOrdine);
      return;
    }
    if (ordine.length > kMaxOrderLength) {
      showAppToast(context, l10n.toastTooLong(kMaxOrderLength));
      return;
    }

    setState(() => _busy = true);
    try {
      final match = await ref
          .read(resolveColleagueUseCaseProvider)
          .call(nome: nome, cognome: cognome);
      switch (match) {
        case ColleagueMatchResolved(:final profile):
          await _send(
            uid: profile.uid,
            nome: profile.nome,
            cognome: cognome,
            ordine: ordine,
          );
          break;
        case ColleagueMatchGuest():
          await _send(uid: null, nome: nome, cognome: cognome, ordine: ordine);
          break;
        case ColleagueMatchAmbiguous(:final candidates):
          setState(() => _candidates = candidates);
      }
    } catch (e) {
      if (mounted) _showSendError(e, nome, cognome);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send({
    required String? uid,
    required String nome,
    required String cognome,
    required String ordine,
  }) async {
    final giorno = todayKey();
    final identity = uid ?? 'ospite_${slugify(cognome)}_${slugify(nome)}';
    final docId = '${giorno}_$identity';
    try {
      await ref
          .read(orderRepositoryProvider)
          .submitOrderForColleague(
            docId: docId,
            giorno: giorno,
            uid: uid,
            nome: nome,
            cognome: cognome,
            ordine: ordine,
            accompagnamento: _accomp == Accompaniment.none
                ? null
                : _accomp.firestoreValue,
          );
      if (!mounted) return;
      showAppToast(
        context,
        AppLocalizations.of(context).foryouSuccessSaved(nome, cognome),
      );
      ref.invalidate(todayOrderControllerProvider);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _showSendError(e, nome, cognome);
    }
  }

  void _showSendError(Object e, String nome, String cognome) {
    final l10n = AppLocalizations.of(context);
    if (e is OrderException) {
      switch (e.reason) {
        case OrderFailureReason.locked:
          showAppToast(context, l10n.foryouErrorLocked(nome, cognome));
          break;
        case OrderFailureReason.dayClosed:
          showAppToast(context, l10n.foryouErrorDayClosed);
          break;
        case OrderFailureReason.timeout:
          showAppToast(context, l10n.foryouErrorTimeout);
          break;
        case OrderFailureReason.conflict:
        case OrderFailureReason.unknown:
          showAppToast(context, l10n.foryouErrorGeneric);
      }
    } else {
      showAppToast(context, l10n.foryouErrorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    if (_candidates != null) {
      return AppSheetContainer(
        title: l10n.foryouWhoDoYouMean,
        children: [
          for (final candidate in _candidates!)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton(
                onPressed: _busy
                    ? null
                    : () => _send(
                        uid: candidate.uid,
                        nome: candidate.nome,
                        cognome: normalizeName(_cognomeCtrl.text),
                        ordine: sanitizeOrderText(_ordineCtrl.text),
                      ),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.ink,
                  foregroundColor: colors.paper,
                ),
                child: Text(
                  '${candidate.nome} ${normalizeName(_cognomeCtrl.text)}',
                ),
              ),
            ),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _send(
                    uid: null,
                    nome: normalizeName(_nomeCtrl.text),
                    cognome: normalizeName(_cognomeCtrl.text),
                    ordine: sanitizeOrderText(_ordineCtrl.text),
                  ),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.inkSoft,
              side: BorderSide(color: colors.line),
            ),
            child: Text(
              l10n.foryouGuestOption(
                normalizeName(_nomeCtrl.text),
                normalizeName(_cognomeCtrl.text),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return AppSheetContainer(
      title: l10n.foryouTitle,
      children: [
        TextField(
          controller: _nomeCtrl,
          maxLength: 40,
          decoration: InputDecoration(
            hintText: l10n.foryouFieldNome,
            counterText: '',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _cognomeCtrl,
          maxLength: 40,
          decoration: InputDecoration(
            hintText: l10n.foryouFieldCognome,
            counterText: '',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _ordineCtrl,
          maxLength: 300,
          decoration: InputDecoration(
            hintText: l10n.foryouFieldOrdine,
            counterText: '',
          ),
        ),
        const SizedBox(height: 14),
        SectionLabel(
          l10n.sectionAccompaniment,
          padding: const EdgeInsets.only(bottom: 8),
        ),
        AccompanimentSelector(
          value: _accomp,
          onChanged: (a) => setState(() => _accomp = a),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _busy ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: colors.tomato),
          child: _busy
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: colors.paper,
                  ),
                )
              : Text(l10n.sendBtn),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

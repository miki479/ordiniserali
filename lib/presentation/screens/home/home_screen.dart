import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/text_utils.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/entities/accompaniment.dart';
import '../../../domain/entities/order_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../../dialogs/disclaimer_dialog.dart';
import '../../dialogs/foryou_dialog.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/pdf_export_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/session_controller.dart';
import '../../providers/session_state.dart';
import '../../providers/today_order_controller.dart';
import '../../providers/today_order_state.dart';
import '../panel/panel_sheet.dart';
import 'widgets/capolinea_zone.dart';
import 'widgets/home_header.dart';
import 'widgets/offline_banner.dart';
import 'widgets/order_form_card.dart';
import 'widgets/order_ticket_card.dart';
import 'widgets/repeat_suggestion_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _ordineCtrl = TextEditingController();
  final _ordineFocus = FocusNode();
  Accompaniment _draftAccomp = Accompaniment.none;
  bool _sending = false;
  bool _justSent = false;
  bool _generatingPdf = false;
  Timer? _stampTimer;

  @override
  void initState() {
    super.initState();
    _ordineCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ordineCtrl.dispose();
    _ordineFocus.dispose();
    _stampTimer?.cancel();
    super.dispose();
  }

  void _pickChip(String text) {
    _ordineCtrl.text = text;
    _ordineFocus.requestFocus();
  }

  void _applySuggestion(RepeatSuggestion suggestion) {
    final l10n = AppLocalizations.of(context);
    switch (suggestion) {
      case RepeatFrequentDish(suggestion: final dish):
        _ordineCtrl.text = dish.ordine;
        setState(() => _draftAccomp = dish.accompagnamento);
        showAppToast(context, l10n.toastPrefillFrequent);
        break;
      case RepeatLastOrder(:final ordine, :final accompagnamento):
        _ordineCtrl.text = ordine;
        setState(() => _draftAccomp = accompagnamento);
        showAppToast(context, l10n.toastPrefillLast);
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      ref.read(todayOrderControllerProvider.notifier).refresh(),
      ref.read(sessionControllerProvider.notifier).refreshRoles(),
    ]);
    if (mounted) {
      showAppToast(context, AppLocalizations.of(context).toastRefreshed);
    }
  }

  Future<void> _onSend(bool currentlyLocked) async {
    final l10n = AppLocalizations.of(context);
    final testo = sanitizeOrderText(_ordineCtrl.text);
    if (testo.isEmpty) {
      showAppToast(context, l10n.toastEmptyOrder);
      return;
    }
    if (testo.length > kMaxOrderLength) {
      showAppToast(context, l10n.toastTooLong(kMaxOrderLength));
      return;
    }
    if (currentlyLocked) {
      showAppToast(context, l10n.toastAlreadyLocked);
      return;
    }

    setState(() => _sending = true);
    try {
      await ref
          .read(todayOrderControllerProvider.notifier)
          .submit(ordine: testo, accompaniment: _draftAccomp);
      _ordineCtrl.clear();
      _stampTimer?.cancel();
      setState(() {
        _draftAccomp = Accompaniment.none;
        _justSent = true;
      });
      _stampTimer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _justSent = false);
      });
    } on OrderException catch (e) {
      if (!mounted) return;
      switch (e.reason) {
        case OrderFailureReason.conflict:
          showAppToast(context, l10n.toastConflict);
          await ref.read(todayOrderControllerProvider.notifier).refresh();
          break;
        case OrderFailureReason.locked:
          showAppToast(context, l10n.toastAlreadyLocked);
          await ref.read(todayOrderControllerProvider.notifier).refresh();
          break;
        case OrderFailureReason.dayClosed:
          showAppToast(context, l10n.toastDayClosed);
          await ref.read(todayOrderControllerProvider.notifier).refresh();
          break;
        case OrderFailureReason.timeout:
          showAppToast(context, l10n.toastTimeout);
          break;
        case OrderFailureReason.unknown:
          showAppToast(context, l10n.toastSendError);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _onLogout() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.logoutTitle,
      message: l10n.logoutMessage,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
    );
    if (!ok) return;
    await ref.read(sessionControllerProvider.notifier).logout();
  }

  Future<void> _onDeleteAll() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.deleteAllTitle,
      message: l10n.deleteAllMessage,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
    );
    if (!ok) return;

    final session = ref.read(sessionControllerProvider);
    if (session is! SessionActive) return;
    try {
      final giorno = todayKey();
      final orders = ref.read(orderRepositoryProvider);
      await orders.deleteOrdersForDay(giorno);
      await orders.unlockDay(giorno);
      await orders.logDeletion(
        account: session.session.email ?? session.profile.fullName,
        uid: session.session.uid,
      );
      if (!mounted) return;
      showAppToast(context, l10n.deleteAllSuccess);
      ref.invalidate(todayOrderControllerProvider);
    } catch (_) {
      if (mounted) showAppToast(context, l10n.deleteAllError);
    }
  }

  Future<void> _onDownloadPdf() async {
    setState(() => _generatingPdf = true);
    final l10n = AppLocalizations.of(context);
    try {
      final giorno = todayKey();
      final orderRepo = ref.read(orderRepositoryProvider);
      final orders = await orderRepo.getOrdersForDay(giorno);
      await ref
          .read(pdfExportServiceProvider)
          .shareOrdersPdf(giorno: giorno, orders: orders);
      await orderRepo.lockOrders(orders.map((o) => o.id).toList());
      await orderRepo.lockDay(giorno);
      if (!mounted) return;
      showAppToast(context, l10n.pdfGenerated);
      ref.invalidate(todayOrderControllerProvider);
    } catch (_) {
      if (mounted) showAppToast(context, l10n.pdfError);
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(sessionControllerProvider);
    if (session is! SessionActive) return const SizedBox.shrink();

    final orderAsync = ref.watch(todayOrderControllerProvider);
    final data = orderAsync.value;
    final isOnline = ref.watch(isOnlineProvider).value ?? true;

    final locked = (data?.dayLocked ?? false) || (data?.order?.locked ?? false);
    final draftText = _ordineCtrl.text.trim();

    final lines = <String>[];
    String? emptyPlaceholder;
    String statusText;
    if (draftText.isNotEmpty) {
      lines.add(draftText);
      if (_draftAccomp != Accompaniment.none) lines.add(_draftAccomp.label);
      statusText = data?.order != null
          ? l10n.ticketStatusEditing
          : l10n.ticketStatusToSend;
    } else if (data?.order != null) {
      final order = data!.order!;
      lines.add(order.ordine);
      if (order.accompagnamento != Accompaniment.none) {
        lines.add(order.accompagnamento.label);
      }
      statusText = order.locked
          ? l10n.ticketStatusClosed
          : l10n.ticketStatusSent;
    } else if (data?.dayLocked == true) {
      emptyPlaceholder = l10n.ticketDayClosed;
      statusText = l10n.ticketStatusClosed;
    } else {
      emptyPlaceholder = l10n.ticketEmpty;
      statusText = l10n.ticketStatusToSend;
    }

    String? stampText;
    var showSendButton = true;
    if (_justSent) {
      stampText = l10n.stampSent;
      showSendButton = false;
    } else if (data?.order?.locked == true) {
      stampText = l10n.stampSentKitchen;
      showSendButton = false;
    } else if (data?.dayLocked == true && data?.order == null) {
      stampText = l10n.stampClosed;
      showSendButton = false;
    }

    final sendLabel = data?.order != null ? l10n.updateBtn : l10n.sendBtn;
    final sendEnabled = !locked && draftText.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.paper,
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'info',
        onPressed: () => showDisclaimerDialog(context),
        backgroundColor: colors.ink,
        foregroundColor: colors.paper,
        tooltip: l10n.infoTooltip,
        child: const Icon(Icons.info_outline, size: 18),
      ),
      body: Column(
        children: [
          if (!isOnline) const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: colors.tomato,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HomeHeader(
                          userName: session.profile.fullName.isEmpty
                              ? '—'
                              : session.profile.fullName,
                          statusLabel: session.isCapolinea
                              ? (session.isSuperuser
                                    ? l10n.statusCapolineaSuperuser
                                    : l10n.statusCapolinea)
                              : null,
                          showPanelButton: session.isCapolinea,
                          onPanelTap: () => showPanelSheet(context),
                          onLogoutTap: _onLogout,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SectionLabel(l10n.sectionWhatToEat),
                              if (data?.suggestion != null)
                                RepeatSuggestionCard(
                                  suggestion: data!.suggestion!,
                                  onTap: () =>
                                      _applySuggestion(data.suggestion!),
                                ),
                              OrderFormCard(
                                controller: _ordineCtrl,
                                accompaniment: _draftAccomp,
                                locked: locked,
                                onAccompanimentChanged: (a) =>
                                    setState(() => _draftAccomp = a),
                                onChipPick: _pickChip,
                              ),
                              const SizedBox(height: 20),
                              OrderTicketCard(
                                lines: lines,
                                emptyPlaceholder: emptyPlaceholder,
                                statusText: statusText,
                                showSendButton: showSendButton,
                                sendEnabled: sendEnabled,
                                sending: _sending,
                                sendLabel: sendLabel,
                                onSend: () => _onSend(locked),
                                stampText: stampText,
                              ),
                              Center(
                                child: TextButton(
                                  onPressed: () => showForYouDialog(context),
                                  child: Text(
                                    l10n.foryouTrigger,
                                    style: TextStyle(
                                      color: colors.inkSoft,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              if (session.isCapolinea)
                                CapolineaZone(
                                  generatingPdf: _generatingPdf,
                                  onDownloadPdf: _onDownloadPdf,
                                  onDeleteAll: _onDeleteAll,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

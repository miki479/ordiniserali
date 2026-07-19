import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../core/utils/name_utils.dart';
import '../../domain/entities/accompaniment.dart';
import 'repository_providers.dart';
import 'session_controller.dart';
import 'session_state.dart';
import 'today_order_state.dart';
import 'usecase_providers.dart';

/// Loads, and lets the signed-in person submit, their order for today.
/// Only meaningful once [SessionController] reports [SessionActive] — the
/// router guarantees the home screen (the only place this is watched) is
/// unreachable otherwise.
class TodayOrderController extends AsyncNotifier<TodayOrderData> {
  @override
  Future<TodayOrderData> build() async {
    final session = ref.watch(sessionControllerProvider);
    if (session is! SessionActive) {
      return const TodayOrderData(
        order: null,
        dayLocked: false,
        suggestion: null,
      );
    }
    return _load(session);
  }

  SessionActive _requireActiveSession() {
    final s = ref.read(sessionControllerProvider);
    if (s is! SessionActive) {
      throw StateError('TodayOrderController used outside an active session');
    }
    return s;
  }

  Future<TodayOrderData> _load(SessionActive session) async {
    final orders = ref.read(orderRepositoryProvider);
    final uid = session.session.uid;
    final giorno = todayKey();
    final docId = '${giorno}_$uid';

    var order = await orders.getOrder(docId);

    // A colleague may have placed a "guest" order for me before I had an
    // account; adopt it so I never show up twice in the PDF.
    if (order == null) {
      final guest = await orders.getGuestOrder(
        giorno: giorno,
        cognomeSlug: slugify(session.profile.cognome),
        nomeSlug: slugify(session.profile.nome),
      );
      if (guest != null) {
        if (!guest.locked && guest.uid == null) {
          try {
            await orders.attachUidToOrder(docId: guest.id, uid: uid);
          } catch (_) {}
        }
        order = guest;
      }
    }

    if (order != null) {
      return TodayOrderData(
        order: order,
        dayLocked: order.locked,
        suggestion: null,
      );
    }

    final dayStatus = await orders.getDayStatus(giorno);
    if (dayStatus?.locked == true) {
      return const TodayOrderData(
        order: null,
        dayLocked: true,
        suggestion: null,
      );
    }

    return TodayOrderData(
      order: null,
      dayLocked: false,
      suggestion: await _computeSuggestion(uid),
    );
  }

  Future<RepeatSuggestion?> _computeSuggestion(String uid) async {
    final local = ref.read(localSettingsRepositoryProvider).readLastOrder(uid);
    final frequent = await ref
        .read(calculateFrequentDishUseCaseProvider)
        .call(uid);

    if (local != null && frequent != null) {
      final preferFrequent = DateTime.now().day % 2 == 0;
      return preferFrequent
          ? RepeatFrequentDish(frequent)
          : RepeatLastOrder(
              ordine: local.ordine,
              accompagnamento: Accompaniment.fromFirestoreValue(
                local.accompagnamento,
              ),
            );
    }
    if (frequent != null) return RepeatFrequentDish(frequent);
    if (local != null) {
      return RepeatLastOrder(
        ordine: local.ordine,
        accompagnamento: Accompaniment.fromFirestoreValue(
          local.accompagnamento,
        ),
      );
    }
    return null;
  }

  Future<void> refresh() async {
    final session = _requireActiveSession();
    state = await AsyncValue.guard(() => _load(session));
  }

  /// Creates or updates today's order. Throws [OrderException] on failure —
  /// callers map that to a toast message.
  Future<void> submit({
    required String ordine,
    required Accompaniment accompaniment,
  }) async {
    final session = _requireActiveSession();
    final giorno = todayKey();
    final current = state.value?.order;
    final docId = current?.id ?? '${giorno}_${session.session.uid}';
    final expectedVersion = current?.version ?? 1;
    final accompValue = accompaniment == Accompaniment.none
        ? null
        : accompaniment.firestoreValue;

    await ref
        .read(orderRepositoryProvider)
        .submitOrder(
          docId: docId,
          giorno: giorno,
          uid: session.session.uid,
          nome: session.profile.nome,
          cognome: session.profile.cognome,
          ordine: ordine,
          accompagnamento: accompValue,
          expectedVersion: expectedVersion,
        );

    await ref
        .read(localSettingsRepositoryProvider)
        .saveLastOrder(
          uid: session.session.uid,
          ordine: ordine,
          accompagnamento: accompValue,
        );

    await refresh();
  }
}

final todayOrderControllerProvider =
    AsyncNotifierProvider<TodayOrderController, TodayOrderData>(
      TodayOrderController.new,
    );

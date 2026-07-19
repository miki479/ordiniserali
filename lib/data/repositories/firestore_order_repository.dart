import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../domain/entities/food_order.dart';
import '../../domain/entities/order_exception.dart';
import '../../domain/repositories/order_repository.dart';

class FirestoreOrderRepository implements OrderRepository {
  FirestoreOrderRepository(this._db);

  final FirebaseFirestore _db;

  static const _transactionTimeout = Duration(seconds: 15);

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(FirestorePaths.orders);
  CollectionReference<Map<String, dynamic>> get _days =>
      _db.collection(FirestorePaths.days);

  @override
  Future<FoodOrder?> getOrder(String docId) async {
    final snap = await _orders.doc(docId).get();
    if (!snap.exists) return null;
    return FoodOrder.fromMap(snap.id, snap.data()!);
  }

  @override
  Future<FoodOrder?> getGuestOrder({
    required String giorno,
    required String cognomeSlug,
    required String nomeSlug,
  }) {
    return getOrder('${giorno}_ospite_${cognomeSlug}_$nomeSlug');
  }

  @override
  Future<void> attachUidToOrder({required String docId, required String uid}) {
    return _orders.doc(docId).update({'uid': uid});
  }

  @override
  Future<DayStatus?> getDayStatus(String giorno) async {
    final snap = await _days.doc(giorno).get();
    if (!snap.exists) return null;
    return DayStatus(
      giorno: giorno,
      locked: (snap.data()?['bloccato'] as bool?) ?? false,
    );
  }

  @override
  Future<void> submitOrder({
    required String docId,
    required String giorno,
    required String? uid,
    required String nome,
    required String cognome,
    required String ordine,
    required String? accompagnamento,
    required int expectedVersion,
  }) {
    return _writeOrder(
      docId: docId,
      giorno: giorno,
      uid: uid,
      nome: nome,
      cognome: cognome,
      ordine: ordine,
      accompagnamento: accompagnamento,
      expectedVersion: expectedVersion,
    );
  }

  @override
  Future<void> submitOrderForColleague({
    required String docId,
    required String giorno,
    required String? uid,
    required String nome,
    required String cognome,
    required String ordine,
    required String? accompagnamento,
  }) {
    return _writeOrder(
      docId: docId,
      giorno: giorno,
      uid: uid,
      nome: nome,
      cognome: cognome,
      ordine: ordine,
      accompagnamento: accompagnamento,
      expectedVersion: null,
    );
  }

  /// Shared transaction body for both "my order" and "order for a
  /// colleague": create-or-update, refusing a locked order or a closed day.
  /// When [expectedVersion] is given, a mismatch is treated as a conflicting
  /// concurrent edit; when it's `null` the write always wins (used for the
  /// colleague flow, where the caller can't know the current version).
  Future<void> _writeOrder({
    required String docId,
    required String giorno,
    required String? uid,
    required String nome,
    required String cognome,
    required String ordine,
    required String? accompagnamento,
    required int? expectedVersion,
  }) async {
    final ref = _orders.doc(docId);
    final future = _db.runTransaction<void>((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        final current = snap.data()!;
        if ((current['bloccato'] as bool?) ?? false) {
          throw const OrderException(OrderFailureReason.locked);
        }
        final currentVersion = (current['versione'] as num?)?.toInt() ?? 1;
        if (expectedVersion != null && currentVersion != expectedVersion) {
          throw const OrderException(OrderFailureReason.conflict);
        }
        tx.update(ref, {
          'ordine': ordine,
          'accompagnamento': accompagnamento,
          'versione': currentVersion + 1,
        });
      } else {
        final daySnap = await tx.get(_days.doc(giorno));
        if (daySnap.exists &&
            ((daySnap.data()?['bloccato'] as bool?) ?? false)) {
          throw const OrderException(OrderFailureReason.dayClosed);
        }
        tx.set(ref, {
          'uid': ?uid,
          'nome': nome,
          'cognome': cognome,
          'ordine': ordine,
          'accompagnamento': accompagnamento,
          'giorno': giorno,
          'bloccato': false,
          'versione': 1,
        });
      }
    });

    try {
      await future.timeout(_transactionTimeout);
    } on OrderException {
      rethrow;
    } on TimeoutException {
      throw const OrderException(OrderFailureReason.timeout);
    } catch (e) {
      throw OrderException(OrderFailureReason.unknown, e.toString());
    }
  }

  @override
  Future<List<FoodOrder>> getOrdersForDay(String giorno) async {
    final snap = await _orders.where('giorno', isEqualTo: giorno).get();
    final orders = snap.docs
        .map((d) => FoodOrder.fromMap(d.id, d.data()))
        .toList();
    orders.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return orders;
  }

  @override
  Future<List<FoodOrder>> getOrdersForUid(String uid) async {
    final snap = await _orders.where('uid', isEqualTo: uid).get();
    return snap.docs.map((d) => FoodOrder.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<void> updateOrderContent({
    required String docId,
    required String ordine,
    required String? accompagnamento,
    required int expectedVersion,
  }) {
    return _orders.doc(docId).update({
      'ordine': ordine,
      'accompagnamento': accompagnamento,
      'versione': expectedVersion + 1,
    });
  }

  @override
  Future<void> deleteOrder(String docId) => _orders.doc(docId).delete();

  @override
  Future<void> deleteOrdersForDay(String giorno) async {
    final snap = await _orders.where('giorno', isEqualTo: giorno).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<void> lockOrders(List<String> docIds) async {
    final batch = _db.batch();
    for (final id in docIds) {
      batch.update(_orders.doc(id), {'bloccato': true});
    }
    await batch.commit();
  }

  @override
  Future<void> lockDay(String giorno) {
    return _days.doc(giorno).set({
      'bloccato': true,
      'bloccatoIl': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> unlockDay(String giorno) => _days.doc(giorno).delete();

  @override
  Future<void> logDeletion({required String account, required String uid}) {
    return _db.collection(FirestorePaths.deletionLog).add({
      'account': account,
      'uid': uid,
      'data': DateTime.now(),
    });
  }

  @override
  Future<void> deleteOrdersOlderThan(String cutoffDayKey) async {
    final snap = await _orders.where('giorno', isLessThan: cutoffDayKey).get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<void> deleteStaleDayLocks(String cutoffDayKey) async {
    final snap = await _days.get();
    final stale = snap.docs.where((d) => d.id.compareTo(cutoffDayKey) < 0);
    final batch = _db.batch();
    var any = false;
    for (final doc in stale) {
      any = true;
      batch.delete(doc.reference);
    }
    if (any) await batch.commit();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../domain/repositories/role_repository.dart';

class FirestoreRoleRepository implements RoleRepository {
  FirestoreRoleRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<bool> isCapolinea(String uid) async {
    try {
      final snap = await _db
          .collection(FirestorePaths.capolineaAuthorized)
          .doc(uid)
          .get();
      return snap.exists;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isSuperuser(String uid) async {
    try {
      final snap = await _db
          .collection(FirestorePaths.superuserAuthorized)
          .doc(uid)
          .get();
      return snap.exists;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Set<String>?> getCapolineaIds() async {
    try {
      final snap = await _db
          .collection(FirestorePaths.capolineaAuthorized)
          .get();
      return snap.docs.map((d) => d.id).toSet();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setCapolinea({required String uid, required bool value}) async {
    final ref = _db.collection(FirestorePaths.capolineaAuthorized).doc(uid);
    if (value) {
      await ref.set({'assegnatoIl': DateTime.now().millisecondsSinceEpoch});
    } else {
      await ref.delete();
    }
  }
}

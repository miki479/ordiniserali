import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../domain/entities/app_user_profile.dart';
import '../../domain/repositories/user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestorePaths.users);

  @override
  Future<void> createProfile(AppUserProfile profile) {
    return _users.doc(profile.uid).set(profile.toMap());
  }

  @override
  Future<AppUserProfile?> getProfile(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return AppUserProfile.fromMap(uid, snap.data()!);
  }

  @override
  Future<void> updateProfile(AppUserProfile profile) {
    return _users.doc(profile.uid).update(profile.toMap());
  }

  @override
  Future<List<AppUserProfile>> getAllProfiles() async {
    final snap = await _users.get();
    return snap.docs
        .map((d) => AppUserProfile.fromMap(d.id, d.data()))
        .toList();
  }

  @override
  Future<List<AppUserProfile>> findByCognome(String cognome) async {
    final snap = await _users.where('cognome', isEqualTo: cognome).get();
    return snap.docs
        .map((d) => AppUserProfile.fromMap(d.id, d.data()))
        .toList();
  }
}

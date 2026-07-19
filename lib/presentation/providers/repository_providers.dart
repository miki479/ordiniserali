import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_profile_store.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firestore_order_repository.dart';
import '../../data/repositories/firestore_role_repository.dart';
import '../../data/repositories/firestore_user_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/local_settings_repository.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/repositories/role_repository.dart';
import '../../domain/repositories/user_repository.dart';
import 'firebase_providers.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(ref.watch(firebaseAuthProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirestoreUserRepository(ref.watch(firestoreProvider));
});

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  return FirestoreRoleRepository(ref.watch(firestoreProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return FirestoreOrderRepository(ref.watch(firestoreProvider));
});

final localSettingsRepositoryProvider = Provider<LocalSettingsRepository>((
  ref,
) {
  return LocalProfileStore(ref.watch(sharedPreferencesProvider));
});

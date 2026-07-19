import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final fb.FirebaseAuth _auth;

  AuthSession _toSession(fb.User user) =>
      AuthSession(uid: user.uid, email: user.email);

  @override
  AuthSession? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : _toSession(user);
  }

  @override
  Stream<AuthSession?> authStateChanges() {
    return _auth.authStateChanges().map(
      (user) => user == null ? null : _toSession(user),
    );
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toSession(credential.user!);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toSession(credential.user!);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AuthException _mapException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return AuthException(AuthFailure.duplicateAccount, e.message ?? '');
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
        return const AuthException(
          AuthFailure.wrongCredentials,
          'Nome, cognome o password non corretti.',
        );
      case 'weak-password':
        return const AuthException(
          AuthFailure.weakPassword,
          'Password troppo debole (minimo 6 caratteri).',
        );
      default:
        return AuthException(AuthFailure.other, e.message ?? e.code);
    }
  }
}

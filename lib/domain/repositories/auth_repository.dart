import '../entities/auth_session.dart';

enum AuthFailure { duplicateAccount, wrongCredentials, weakPassword, other }

class AuthException implements Exception {
  const AuthException(this.failure, this.message);
  final AuthFailure failure;
  final String message;
}

abstract class AuthRepository {
  Stream<AuthSession?> authStateChanges();
  AuthSession? get currentUser;

  Future<AuthSession> signIn({required String email, required String password});

  Future<AuthSession> register({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

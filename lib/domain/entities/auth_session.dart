/// Minimal, framework-agnostic view of "who is signed in", so the domain
/// layer never depends on `package:firebase_auth` types directly.
class AuthSession {
  const AuthSession({required this.uid, this.email});

  final String uid;
  final String? email;
}

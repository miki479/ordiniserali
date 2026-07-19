import '../../domain/entities/app_user_profile.dart';
import '../../domain/entities/auth_session.dart';

/// Where the app currently is in the auth/identity flow. Drives both what
/// screen [AppRouter] shows and what data the home screen has available.
sealed class SessionState {
  const SessionState();
}

/// Firebase hasn't reported an auth state yet — splash screen.
class SessionUnknown extends SessionState {
  const SessionUnknown();
}

/// No signed-in user — auth (login/register) screen.
class SessionLoggedOut extends SessionState {
  const SessionLoggedOut();
}

/// Signed in, but this device hasn't confirmed "is this still you?" recently
/// enough — shown once every 7 days rather than on every app open.
class SessionNeedsWelcomeBack extends SessionState {
  const SessionNeedsWelcomeBack({required this.session, this.profile});

  final AuthSession session;
  final ({String nome, String cognome})? profile;
}

/// Signed in and confirmed: the home screen and its data are available.
class SessionActive extends SessionState {
  const SessionActive({
    required this.session,
    required this.profile,
    required this.isCapolinea,
    required this.isSuperuser,
  });

  final AuthSession session;
  final AppUserProfile profile;
  final bool isCapolinea;
  final bool isSuperuser;

  SessionActive copyWith({
    AppUserProfile? profile,
    bool? isCapolinea,
    bool? isSuperuser,
  }) {
    return SessionActive(
      session: session,
      profile: profile ?? this.profile,
      isCapolinea: isCapolinea ?? this.isCapolinea,
      isSuperuser: isSuperuser ?? this.isSuperuser,
    );
  }
}

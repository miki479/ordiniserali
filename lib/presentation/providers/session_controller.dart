import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user_profile.dart';
import '../../domain/entities/auth_session.dart';
import 'repository_providers.dart';
import 'session_state.dart';
import 'usecase_providers.dart';

/// How often the "is this still you?" screen is shown on an already-signed-in
/// device — frequent enough to catch someone else picking up the phone,
/// rare enough not to be annoying.
const Duration kIdentityReconfirmWindow = Duration(days: 7);

final authStateChangesProvider = StreamProvider<AuthSession?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Owns the sign-in/identity state machine described in [SessionState] and
/// is the single source of truth [AppRouter] redirects against.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    ref.listen<AsyncValue<AuthSession?>>(authStateChangesProvider, (
      previous,
      next,
    ) {
      next.whenData(_handleAuthChange);
    });
    final initial = ref.read(authStateChangesProvider);
    if (initial case AsyncData(:final value)) {
      // Defer so `state = ...` never runs synchronously inside build().
      Future.microtask(() => _handleAuthChange(value));
    }
    return const SessionUnknown();
  }

  Future<void> _handleAuthChange(AuthSession? session) async {
    if (session == null) {
      state = const SessionLoggedOut();
      return;
    }

    // Already active for this exact user (e.g. we just drove the transition
    // ourselves via [enterAfterAuthSuccess]) — the stream firing again must
    // not bounce the user back to the welcome-back screen.
    final current = state;
    if (current is SessionActive && current.session.uid == session.uid) return;

    final localSettings = ref.read(localSettingsRepositoryProvider);
    var profile = localSettings.readProfile();
    if (profile == null) {
      try {
        final remote = await ref
            .read(userRepositoryProvider)
            .getProfile(session.uid);
        if (remote != null) {
          profile = (nome: remote.nome, cognome: remote.cognome);
          await localSettings.saveProfile(
            nome: remote.nome,
            cognome: remote.cognome,
          );
        }
      } catch (_) {
        // No network / no permission: fall through with whatever we have.
      }
    }

    final recentlyConfirmed = localSettings.isIdentityConfirmationRecent(
      kIdentityReconfirmWindow,
    );
    if (profile != null && profile.cognome.isNotEmpty && recentlyConfirmed) {
      await _enterApp(session, profile.nome, profile.cognome);
      return;
    }

    state = SessionNeedsWelcomeBack(session: session, profile: profile);
  }

  /// "Sì, sono io" on the welcome-back screen.
  Future<void> confirmWelcomeBack() async {
    final s = state;
    if (s is! SessionNeedsWelcomeBack) return;
    if (s.profile == null || s.profile!.cognome.isEmpty) {
      await rejectWelcomeBack();
      return;
    }
    await ref.read(localSettingsRepositoryProvider).markIdentityConfirmedNow();
    await _enterApp(s.session, s.profile!.nome, s.profile!.cognome);
  }

  /// "Non sono io, esci dall'account" on the welcome-back screen.
  Future<void> rejectWelcomeBack() async {
    await ref.read(localSettingsRepositoryProvider).clearProfile();
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {}
    // authStateChangesProvider drives the transition to SessionLoggedOut.
  }

  /// Called right after a successful sign-in/registration on the auth
  /// screen, where we already know nome/cognome without a round trip.
  Future<void> enterAfterAuthSuccess(
    AuthSession session,
    String nome,
    String cognome,
  ) async {
    await ref.read(localSettingsRepositoryProvider).markIdentityConfirmedNow();
    await _enterApp(session, nome, cognome);
  }

  Future<void> _enterApp(
    AuthSession session,
    String nome,
    String cognome,
  ) async {
    final localSettings = ref.read(localSettingsRepositoryProvider);
    await localSettings.saveProfile(nome: nome, cognome: cognome);

    final roles = ref.read(roleRepositoryProvider);
    final isCapolinea = await roles.isCapolinea(session.uid);
    final isSuperuser = isCapolinea
        ? await roles.isSuperuser(session.uid)
        : false;

    state = SessionActive(
      session: session,
      profile: AppUserProfile(uid: session.uid, nome: nome, cognome: cognome),
      isCapolinea: isCapolinea,
      isSuperuser: isSuperuser,
    );

    // Housekeeping: only capolinea accounts have delete rights, so only they
    // can effectively run the retention cleanup.
    if (isCapolinea) {
      unawaited(ref.read(cleanupOldOrdersUseCaseProvider).call());
    }
  }

  /// Re-checks capolinea/superuser status without a full re-entry — used by
  /// pull-to-refresh, since a promotion made from another device wouldn't
  /// otherwise be visible until the next login.
  Future<void> refreshRoles() async {
    final s = state;
    if (s is! SessionActive) return;
    final roles = ref.read(roleRepositoryProvider);
    final isCapolinea = await roles.isCapolinea(s.session.uid);
    final isSuperuser = isCapolinea
        ? await roles.isSuperuser(s.session.uid)
        : false;
    state = s.copyWith(isCapolinea: isCapolinea, isSuperuser: isSuperuser);
  }

  /// Keeps the header in sync right after the signed-in user edits their own
  /// name from the admin panel.
  void applyOwnProfileEdit({required String nome, required String cognome}) {
    final s = state;
    if (s is! SessionActive) return;
    state = s.copyWith(
      profile: s.profile.copyWith(nome: nome, cognome: cognome),
    );
  }

  Future<void> logout() async {
    await ref.read(localSettingsRepositoryProvider).clearProfile();
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {}
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

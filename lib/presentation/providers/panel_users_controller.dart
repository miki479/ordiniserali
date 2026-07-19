import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user_profile.dart';
import 'repository_providers.dart';
import 'session_controller.dart';
import 'session_state.dart';

/// The full member roster plus which of them are capolinea — `null` for
/// [capolineaIds] means that collection couldn't be read (e.g. restrictive
/// security rules for a non-capolinea account), in which case the toggle is
/// shown disabled rather than silently wrong.
class PanelUsersData {
  const PanelUsersData({required this.users, required this.capolineaIds});
  final List<AppUserProfile> users;
  final Set<String>? capolineaIds;
}

class PanelUsersController extends AsyncNotifier<PanelUsersData> {
  @override
  Future<PanelUsersData> build() => _load();

  Future<PanelUsersData> _load() async {
    final users = await ref.read(userRepositoryProvider).getAllProfiles();
    users.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    final capolineaIds = await ref
        .read(roleRepositoryProvider)
        .getCapolineaIds();
    return PanelUsersData(users: users, capolineaIds: capolineaIds);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  /// [makeCapolinea] is ignored unless the signed-in account is a superuser
  /// and the capolinea list was actually readable — mirrors the web app's
  /// server-trusting-but-UI-hinting behaviour.
  Future<void> saveUser(
    AppUserProfile original, {
    required String nome,
    required String cognome,
    bool? makeCapolinea,
  }) async {
    final data = state.value;
    await ref
        .read(userRepositoryProvider)
        .updateProfile(original.copyWith(nome: nome, cognome: cognome));

    final session = ref.read(sessionControllerProvider);
    final isSuperuser = session is SessionActive && session.isSuperuser;
    if (makeCapolinea != null && data?.capolineaIds != null && isSuperuser) {
      final wasCapolinea = data!.capolineaIds!.contains(original.uid);
      if (makeCapolinea && !wasCapolinea) {
        await ref
            .read(roleRepositoryProvider)
            .setCapolinea(uid: original.uid, value: true);
      } else if (!makeCapolinea && wasCapolinea) {
        await ref
            .read(roleRepositoryProvider)
            .setCapolinea(uid: original.uid, value: false);
      }
    }

    await refresh();

    if (session is SessionActive && session.session.uid == original.uid) {
      ref
          .read(sessionControllerProvider.notifier)
          .applyOwnProfileEdit(nome: nome, cognome: cognome);
    }
  }
}

final panelUsersControllerProvider =
    AsyncNotifierProvider<PanelUsersController, PanelUsersData>(
      PanelUsersController.new,
    );

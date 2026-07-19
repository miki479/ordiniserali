import '../entities/app_user_profile.dart';
import '../repositories/user_repository.dart';

/// Outcome of trying to match a typed "nome cognome" against registered
/// accounts before placing an order on someone's behalf.
sealed class ColleagueMatch {
  const ColleagueMatch();
}

/// Exactly one registered account matches: safe to send straight away.
class ColleagueMatchResolved extends ColleagueMatch {
  const ColleagueMatchResolved(this.profile);
  final AppUserProfile profile;
}

/// Several registered accounts could be the intended recipient (e.g. two
/// "Mario Rossi" where one goes by "Mario B. Rossi") — the caller must ask.
class ColleagueMatchAmbiguous extends ColleagueMatch {
  const ColleagueMatchAmbiguous(this.candidates);
  final List<AppUserProfile> candidates;
}

/// Nobody registered matches: the order is placed under a "guest" identity
/// that gets adopted automatically once that person creates an account.
class ColleagueMatchGuest extends ColleagueMatch {
  const ColleagueMatchGuest();
}

class ResolveColleagueUseCase {
  const ResolveColleagueUseCase(this._users);

  final UserRepository _users;

  Future<ColleagueMatch> call({
    required String nome,
    required String cognome,
  }) async {
    List<AppUserProfile> sameSurname = [];
    try {
      sameSurname = await _users.findByCognome(cognome);
    } catch (_) {
      sameSurname = [];
    }

    // A candidate if the first name matches exactly, or if one is the other
    // plus something extra ("Mario" vs "Mario B.") — that's precisely where
    // mix-ups between homonyms happen.
    final candidates = sameSurname.where((u) {
      return u.nome == nome ||
          u.nome.startsWith('$nome ') ||
          nome.startsWith('${u.nome} ');
    }).toList();

    final exact = candidates.where((c) => c.nome == nome);

    if (candidates.length == 1 && exact.isNotEmpty) {
      return ColleagueMatchResolved(candidates.first);
    }
    if (candidates.isEmpty) {
      return const ColleagueMatchGuest();
    }
    return ColleagueMatchAmbiguous(candidates);
  }
}

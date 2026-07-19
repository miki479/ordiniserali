/// Firestore collection names, centralized so a rename never turns into a
/// scattered find-and-replace across repositories.
class FirestorePaths {
  const FirestorePaths._();

  static const orders = 'ordini';
  static const users = 'utenti';
  static const days = 'giorni';
  static const capolineaAuthorized = 'capolinea_autorizzati';
  static const superuserAuthorized = 'superuser_autorizzati';
  static const deletionLog = 'eliminazioni_log';
}

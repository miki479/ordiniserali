import '../entities/app_user_profile.dart';

abstract class UserRepository {
  Future<void> createProfile(AppUserProfile profile);

  Future<AppUserProfile?> getProfile(String uid);

  Future<void> updateProfile(AppUserProfile profile);

  Future<List<AppUserProfile>> getAllProfiles();

  /// Registered people sharing a surname — used to disambiguate "order for
  /// a colleague" when several people could match the typed first name.
  Future<List<AppUserProfile>> findByCognome(String cognome);
}

abstract class RoleRepository {
  Future<bool> isCapolinea(String uid);

  Future<bool> isSuperuser(String uid);

  /// `null` when the collection couldn't be read (restrictive security
  /// rules) — callers should degrade gracefully rather than assume "none".
  Future<Set<String>?> getCapolineaIds();

  Future<void> setCapolinea({required String uid, required bool value});
}

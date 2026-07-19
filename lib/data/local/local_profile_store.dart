import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/local_settings_repository.dart';

/// [LocalSettingsRepository] backed by `shared_preferences` — the Flutter
/// counterpart of the web app's `localStorage` usage.
class LocalProfileStore implements LocalSettingsRepository {
  LocalProfileStore(this._prefs);

  final SharedPreferences _prefs;

  static const _profileKey = 'profiloVisuale';
  static const _lastConfirmKey = 'ultimaConfermaIdentita';
  static const _lastCleanupKey = 'ultimaPulizia';
  static const _lastOrderPrefix = 'ultimoOrdine_';

  @override
  Future<void> saveProfile({required String nome, required String cognome}) {
    return _prefs.setString(
      _profileKey,
      jsonEncode({'nome': nome, 'cognome': cognome}),
    );
  }

  @override
  ({String nome, String cognome})? readProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return (
        nome: map['nome'] as String? ?? '',
        cognome: map['cognome'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearProfile() => _prefs.remove(_profileKey);

  @override
  Future<void> markIdentityConfirmedNow() {
    return _prefs.setInt(
      _lastConfirmKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  bool isIdentityConfirmationRecent(Duration within) {
    final millis = _prefs.getInt(_lastConfirmKey) ?? 0;
    final last = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateTime.now().difference(last) < within;
  }

  @override
  String? readLastCleanupDay() => _prefs.getString(_lastCleanupKey);

  @override
  Future<void> saveLastCleanupDay(String dayKey) =>
      _prefs.setString(_lastCleanupKey, dayKey);

  @override
  Future<void> saveLastOrder({
    required String uid,
    required String ordine,
    required String? accompagnamento,
  }) {
    return _prefs.setString(
      '$_lastOrderPrefix$uid',
      jsonEncode({'ordine': ordine, 'accompagnamento': accompagnamento}),
    );
  }

  @override
  ({String ordine, String? accompagnamento})? readLastOrder(String uid) {
    final raw = _prefs.getString('$_lastOrderPrefix$uid');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final ordine = map['ordine'] as String?;
      if (ordine == null || ordine.isEmpty) return null;
      return (
        ordine: ordine,
        accompagnamento: map['accompagnamento'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

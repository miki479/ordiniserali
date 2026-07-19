/// The three accompaniment choices offered alongside a main order.
/// [firestoreValue] is what's actually persisted (empty string means "none",
/// stored as `null` in Firestore to keep documents tidy).
enum Accompaniment {
  none(firestoreValue: '', label: 'Nessuno', emoji: null),
  bread(firestoreValue: 'Pane', label: 'Pane', emoji: '🍞'),
  flatbread(firestoreValue: 'Spianata', label: 'Spianata', emoji: '🫓');

  const Accompaniment({
    required this.firestoreValue,
    required this.label,
    required this.emoji,
  });

  final String firestoreValue;
  final String label;
  final String? emoji;

  String get displayLabel => emoji == null ? label : '$emoji $label';

  static Accompaniment fromFirestoreValue(String? value) {
    if (value == null || value.isEmpty) return Accompaniment.none;
    return Accompaniment.values.firstWhere(
      (a) => a.firestoreValue == value,
      orElse: () => Accompaniment.none,
    );
  }
}

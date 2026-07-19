import 'accompaniment.dart';

/// One person's order for one evening ("ordini/{giorno}_{uid}").
class FoodOrder {
  const FoodOrder({
    required this.id,
    required this.uid,
    required this.nome,
    required this.cognome,
    required this.ordine,
    required this.accompagnamento,
    required this.giorno,
    required this.locked,
    required this.version,
  });

  final String id;
  final String? uid;
  final String nome;
  final String cognome;
  final String ordine;
  final Accompaniment accompagnamento;
  final String giorno;
  final bool locked;
  final int version;

  String get fullName => '$nome $cognome'.trim();

  factory FoodOrder.fromMap(String id, Map<String, dynamic> map) {
    return FoodOrder(
      id: id,
      uid: map['uid'] as String?,
      nome: (map['nome'] as String?) ?? '',
      cognome: (map['cognome'] as String?) ?? '',
      ordine: (map['ordine'] as String?) ?? '',
      accompagnamento: Accompaniment.fromFirestoreValue(
        map['accompagnamento'] as String?,
      ),
      giorno: (map['giorno'] as String?) ?? '',
      locked: (map['bloccato'] as bool?) ?? false,
      version: (map['versione'] as num?)?.toInt() ?? 1,
    );
  }
}

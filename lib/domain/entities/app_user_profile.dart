/// A registered person's visible identity ("utenti/{uid}" document).
class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.nome,
    required this.cognome,
  });

  final String uid;
  final String nome;
  final String cognome;

  String get fullName => '$nome $cognome'.trim();

  factory AppUserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return AppUserProfile(
      uid: uid,
      nome: (map['nome'] as String?) ?? '',
      cognome: (map['cognome'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'nome': nome, 'cognome': cognome};

  AppUserProfile copyWith({String? nome, String? cognome}) {
    return AppUserProfile(
      uid: uid,
      nome: nome ?? this.nome,
      cognome: cognome ?? this.cognome,
    );
  }
}

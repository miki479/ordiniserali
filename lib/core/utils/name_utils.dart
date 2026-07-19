/// Identity normalization shared by registration, the colleague-order flow
/// and the admin panel, so "Mario", "mario " and "MARIO" always resolve to
/// the same account ("Mario").
library;

final RegExp _disallowedNameChars = RegExp("[^a-zA-ZÀ-ſ\\s'\\-.’‘`´]");
final RegExp _fancyApostrophes = RegExp('[’‘`´]');
final RegExp _spacesAroundApostrophe = RegExp("\\s*'\\s*");
final RegExp _spacesAroundDash = RegExp(r'\s*-\s*');
final RegExp _multiSpace = RegExp(r'\s+');
final RegExp _capitalizeAfter = RegExp("(^|[\\s'\\-])([a-zà-ú])");

/// "  mario  ROSSI-bianchi " -> "Mario Rossi-Bianchi"
String normalizeName(String? raw) {
  var value = raw ?? '';
  value = value.replaceAll(_disallowedNameChars, '');
  value = value.replaceAll(_fancyApostrophes, "'");
  value = value.replaceAll(_spacesAroundApostrophe, "'");
  value = value.replaceAll(_spacesAroundDash, '-');
  value = value.trim().replaceAll(_multiSpace, ' ').toLowerCase();
  value = value.replaceAllMapped(_capitalizeAfter, (m) {
    return '${m[1]}${m[2]!.toUpperCase()}';
  });
  return value;
}

const Map<String, String> _diacritics = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ý': 'y',
  'ÿ': 'y',
  'ñ': 'n',
  'ç': 'c',
};

String stripDiacritics(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_diacritics[ch] ?? ch);
  }
  return buffer.toString();
}

final RegExp _nonSlug = RegExp('[^a-z0-9]+');
final RegExp _edgeDashes = RegExp(r'(^-|-$)');

/// "D'Amico Gian-Luca" -> "d-amico-gian-luca"
String slugify(String? raw) {
  var value = (raw ?? '').trim().toLowerCase();
  value = stripDiacritics(value);
  value = value.replaceAll(_nonSlug, '-').replaceAll(_edgeDashes, '');
  return value.isEmpty ? 'x' : value;
}

/// Firebase Auth needs an email; nobody ever sees it, sign-in always happens
/// with nome + cognome + password.
String pseudoEmail(String nome, String cognome) {
  return '${slugify(cognome)}.${slugify(nome)}@vicomeal.local';
}

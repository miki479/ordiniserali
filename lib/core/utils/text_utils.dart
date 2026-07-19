/// Maximum length accepted for an order's free-text description, enforced
/// both client-side and mirrored in Firestore security rules.
const int kMaxOrderLength = 300;

final RegExp _outsideLatin1 = RegExp('[^ -ÿ\n]');
final RegExp _repeatedSpaces = RegExp('[ \t]+');
final RegExp _repeatedBlankLines = RegExp('\n{3,}');

/// Strips emoji/exotic symbols (they'd render as boxes in the PDF export),
/// collapses whitespace, and trims — applied to every order before it's
/// written to Firestore.
String sanitizeOrderText(String? raw) {
  var value = raw ?? '';
  value = value.replaceAll(_outsideLatin1, '');
  value = value.replaceAll(_repeatedSpaces, ' ');
  value = value.replaceAll(_repeatedBlankLines, '\n\n');
  return value.trim();
}

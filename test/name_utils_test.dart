import 'package:flutter_test/flutter_test.dart';
import 'package:vico_meal/core/utils/name_utils.dart';
import 'package:vico_meal/core/utils/text_utils.dart';

void main() {
  group('normalizeName', () {
    test('trims, lowercases then title-cases each word', () {
      expect(normalizeName('  mario  ROSSI '), 'Mario Rossi');
    });

    test('keeps a single capital after apostrophes and dashes', () {
      expect(normalizeName("d'amico gian-luca"), "D'Amico Gian-Luca");
    });

    test('strips emoji and symbols', () {
      expect(normalizeName('Mario 🍝👋'), 'Mario');
    });
  });

  group('slugify / pseudoEmail', () {
    test('strips accents and joins with dashes', () {
      expect(slugify("D'Amico Perù"), 'd-amico-peru');
    });

    test('falls back to "x" for an empty input', () {
      expect(slugify(''), 'x');
    });

    test('builds a stable, collision-free technical email', () {
      expect(pseudoEmail('Mario', 'Rossi'), 'rossi.mario@vicomeal.local');
    });
  });

  group('sanitizeOrderText', () {
    test('collapses repeated whitespace and blank lines', () {
      expect(sanitizeOrderText('  panino   con salsiccia\n\n\n\nno cipolla  '), 'panino con salsiccia\n\nno cipolla');
    });

    test('strips characters outside the PDF-safe Latin-1 range', () {
      expect(sanitizeOrderText('pasta 🍝 al ragù'), 'pasta al ragù');
    });
  });
}

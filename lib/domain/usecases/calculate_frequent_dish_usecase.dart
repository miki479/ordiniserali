import '../../core/utils/name_utils.dart';
import '../entities/accompaniment.dart';
import '../repositories/order_repository.dart';

/// Suggests the dish someone orders most often, so it can be offered as a
/// one-tap "order again" shortcut.
class FrequentDishSuggestion {
  const FrequentDishSuggestion({
    required this.word,
    required this.ordine,
    required this.accompagnamento,
  });

  final String word;
  final String ordine;
  final Accompaniment accompagnamento;

  String get displayName =>
      word.isEmpty ? word : word[0].toUpperCase() + word.substring(1);
}

/// Words too generic to identify a dish ("con", "senza", "extra"...) —
/// excluding them keeps "grigliata mista senza cipolla" and "grigliata e
/// patatine" both counted under "grigliata".
const Set<String> _stopwords = {
  'con',
  'e',
  'ed',
  'al',
  'alla',
  'allo',
  'ai',
  'agli',
  'alle',
  'di',
  'del',
  'della',
  'dello',
  'dei',
  'degli',
  'delle',
  'da',
  'in',
  'su',
  'per',
  'senza',
  'no',
  'non',
  'un',
  'una',
  'uno',
  'il',
  'lo',
  'la',
  'le',
  'i',
  'gli',
  'ben',
  'poco',
  'poca',
  'molto',
  'molta',
  'extra',
  'doppia',
  'doppio',
  'tanto',
  'tanta',
  'piu',
  'solo',
  'anche',
  'oppure',
  'cotta',
  'cotto',
  'bene',
};

const int _minOccurrences = 7;

class CalculateFrequentDishUseCase {
  const CalculateFrequentDishUseCase(this._orders);

  final OrderRepository _orders;

  Future<FrequentDishSuggestion?> call(String uid) async {
    try {
      final myOrders = await _orders.getOrdersForUid(uid);
      final counts = <String, int>{};
      final latestByWord =
          <String, ({String ordine, String giorno, Accompaniment accomp})>{};

      for (final order in myOrders) {
        for (final word in _extractWords(order.ordine)) {
          counts[word] = (counts[word] ?? 0) + 1;
          final existing = latestByWord[word];
          if (existing == null ||
              order.giorno.compareTo(existing.giorno) >= 0) {
            latestByWord[word] = (
              ordine: order.ordine,
              giorno: order.giorno,
              accomp: order.accompagnamento,
            );
          }
        }
      }

      String? bestWord;
      var bestCount = 0;
      for (final entry in counts.entries) {
        if (entry.value >= _minOccurrences && entry.value > bestCount) {
          bestWord = entry.key;
          bestCount = entry.value;
        }
      }
      if (bestWord == null) return null;
      final example = latestByWord[bestWord]!;
      return FrequentDishSuggestion(
        word: bestWord,
        ordine: example.ordine,
        accompagnamento: example.accomp,
      );
    } catch (_) {
      return null;
    }
  }

  /// Unique, meaningful words in an order's free text ("grigliata mista con
  /// zucchine" -> {grigliata, mista, zucchine}).
  Set<String> _extractWords(String testo) {
    final normalized = stripDiacritics(testo.toLowerCase());
    return normalized
        .split(RegExp('[^a-z]+'))
        .where((w) => w.length >= 4 && !_stopwords.contains(w))
        .toSet();
  }
}

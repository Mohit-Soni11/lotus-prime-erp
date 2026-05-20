// ==========================================
// FILE: fuzzy_search_helper.dart
// LOCATION: lib/helpers/search/fuzzy_search_helper.dart
// DESCRIPTION: Google-style Smart Search Engine
//              ✅ Typo tolerant — "Ramsh" → "Ramesh" dhundh lega
//              ✅ Case insensitive — "gold" = "Gold" = "GOLD"
//              ✅ Partial match — "ring" → "Gold Ring", "Silver Ring"
//              ✅ Score-based ranking — best match pehle aata hai
// ==========================================

class FuzzySearchHelper {
  // ============================================================
  // MAIN FUNCTION — Yahi use karo items filter karne ke liye
  // ============================================================
  // [items]      : Saari strings ki list (jisme search karna hai)
  // [query]      : User ne jo likha hai
  // [maxResults] : Kitne results chahiye (default: 8)
  // [threshold]  : 0.0 to 1.0 — kitna match hona chahiye (default: 0.3)
  //
  // EXAMPLE:
  //   final results = FuzzySearchHelper.search(
  //     items: ['Ramesh Kumar', 'Suresh Singh', 'Rajesh Gupta'],
  //     query: 'ramsh',
  //   );
  //   // → ['Ramesh Kumar'] ✅
  // ============================================================
  static List<String> search({
    required List<String> items,
    required String query,
    int maxResults = 8,
    double threshold = 0.25,
  }) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    // Step 1: Har item ko score do
    final scored = <_ScoredItem>[];
    for (final item in items) {
      final score = _scoreMatch(item.toLowerCase(), q);
      if (score >= threshold) {
        scored.add(_ScoredItem(item, score));
      }
    }

    // Step 2: Score ke hisaab se sort karo (best first)
    scored.sort((a, b) => b.score.compareTo(a.score));

    // Step 3: Top N results return karo
    return scored.take(maxResults).map((e) => e.text).toList();
  }

  // ============================================================
  // GENERIC OBJECT SEARCH — Custom objects ke liye
  // ============================================================
  // Jab aapko CustomerListItemModel ya koi bhi object filter karna ho
  //
  // EXAMPLE:
  //   final results = FuzzySearchHelper.searchObjects(
  //     items: customerList,
  //     query: 'ramsh',
  //     getSearchText: (c) => '${c.name} ${c.mobile}',
  //   );
  // ============================================================
  static List<T> searchObjects<T>({
    required List<T> items,
    required String query,
    required String Function(T item) getSearchText,
    int maxResults = 8,
    double threshold = 0.25,
  }) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    final scored = <_ScoredObject<T>>[];
    for (final item in items) {
      final text = getSearchText(item).toLowerCase();
      final score = _scoreMatch(text, q);
      if (score >= threshold) {
        scored.add(_ScoredObject(item, score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(maxResults).map((e) => e.item).toList();
  }

  // ============================================================
  // SCORE CALCULATOR — Ye decide karta hai kitna match hua
  // ============================================================
  static double _scoreMatch(String text, String query) {
    // Rule 1: Exact match — sabse zyada score (1.0)
    if (text == query) return 1.0;

    // Rule 2: Exact start match — bahut accha (0.9)
    if (text.startsWith(query)) return 0.9;

    // Rule 3: Contains exact query — accha (0.8)
    if (text.contains(query)) return 0.8;

    // Rule 4: Har word mein se check karo
    final textWords = text.split(RegExp(r'\s+'));
    final queryWords = query.split(RegExp(r'\s+'));

    double wordScore = 0.0;
    for (final qWord in queryWords) {
      if (qWord.isEmpty) continue;
      double bestWordScore = 0.0;
      for (final tWord in textWords) {
        if (tWord.isEmpty) continue;
        // Word exact match
        if (tWord == qWord) {
          bestWordScore = 1.0;
          break;
        }
        // Word starts with query word
        if (tWord.startsWith(qWord)) {
          bestWordScore = _max(bestWordScore, 0.85);
          continue;
        }
        // Word contains query word
        if (tWord.contains(qWord)) {
          bestWordScore = _max(bestWordScore, 0.7);
          continue;
        }
        // Levenshtein similarity (typo detection)
        final sim = _levenshteinSimilarity(tWord, qWord);
        bestWordScore = _max(bestWordScore, sim);
      }
      wordScore += bestWordScore;
    }

    // Average word score
    final avgWordScore =
        queryWords.isNotEmpty ? wordScore / queryWords.length : 0.0;

    // Rule 5: Character-level bigram similarity (catches scattered typos)
    final bigramScore = _bigramSimilarity(text, query);

    // Final score: weighted average
    return (avgWordScore * 0.7) + (bigramScore * 0.3);
  }

  // ============================================================
  // LEVENSHTEIN DISTANCE — Kitne characters alag hain
  // ============================================================
  // "Ramsh" vs "Ramesh" → distance = 1 (sirf 'e' missing)
  // "gold" vs "gild"   → distance = 1 (o→i)
  // ============================================================
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    // DP matrix
    final rows = s1.length + 1;
    final cols = s2.length + 1;
    final matrix = List.generate(rows, (_) => List.filled(cols, 0));

    for (int i = 0; i < rows; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j < cols; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i < rows; i++) {
      for (int j = 1; j < cols; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = _min3(
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        );
      }
    }
    return matrix[rows - 1][cols - 1];
  }

  // Levenshtein ko 0.0-1.0 similarity mein convert karo
  static double _levenshteinSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    final dist = _levenshteinDistance(s1, s2);
    final maxLen = _max(s1.length.toDouble(), s2.length.toDouble());
    if (maxLen == 0) return 1.0;
    return 1.0 - (dist / maxLen);
  }

  // ============================================================
  // BIGRAM SIMILARITY — 2-character pairs kitne match karte hain
  // ============================================================
  // "night" → {ni, ig, gh, ht}
  // "nght"  → {ng, gh, ht}  → 2/4 = 50% match
  // ============================================================
  static double _bigramSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    if (s1.length == 1 || s2.length == 1) {
      return s1.contains(s2[0]) || s2.contains(s1[0]) ? 0.5 : 0.0;
    }

    final bigrams1 = _getBigrams(s1);
    final bigrams2 = _getBigrams(s2);

    // Common bigrams dhundho
    int commonCount = 0;
    final temp = List<String>.from(bigrams2);
    for (final b in bigrams1) {
      final idx = temp.indexOf(b);
      if (idx != -1) {
        commonCount++;
        temp.removeAt(idx);
      }
    }

    return (2.0 * commonCount) / (bigrams1.length + bigrams2.length);
  }

  static List<String> _getBigrams(String s) {
    final bigrams = <String>[];
    for (int i = 0; i < s.length - 1; i++) {
      bigrams.add(s.substring(i, i + 2));
    }
    return bigrams;
  }

  // ============================================================
  // UTILITY FUNCTIONS
  // ============================================================
  static int _min3(int a, int b, int c) =>
      a < b ? (a < c ? a : c) : (b < c ? b : c);
  static double _max(double a, double b) => a > b ? a : b;
}

// ============================================================
// PRIVATE HELPER CLASSES
// ============================================================
class _ScoredItem {
  final String text;
  final double score;
  _ScoredItem(this.text, this.score);
}

class _ScoredObject<T> {
  final T item;
  final double score;
  _ScoredObject(this.item, this.score);
}

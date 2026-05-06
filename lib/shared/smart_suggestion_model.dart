// =============================================================================
// FILE        : smart_suggestion_model.dart
// MODULE      : Shared → Smart Input
// LAYER       : Model
// PURPOSE     : Claude API se jo response aata hai uska immutable model.
//               Controller state hold karta hai, yeh sirf data shape hai.
// =============================================================================

class SmartSuggestionModel {
  /// Spell correction — agar input galat hai to sahi spelling.
  /// null = input theek hai, koi correction nahi.
  final String? spellCorrection;

  /// Context-aware suggestions:
  ///   Name   → Hindi Devanagari transliterations
  ///   Address→ Indian city/area completions
  ///   Item   → Jewellery item names
  ///   Company→ Business name suggestions
  ///   Remark → Empty list
  final List<String> suggestions;

  const SmartSuggestionModel({
    this.spellCorrection,
    this.suggestions = const [],
  });

  /// Empty/fallback model — no suggestions
  factory SmartSuggestionModel.empty() => const SmartSuggestionModel(
        spellCorrection: null,
        suggestions: [],
      );

  /// Parse from Claude API JSON response
  factory SmartSuggestionModel.fromJson(Map<String, dynamic> json) {
    final raw = json['spellCorrection'];
    final corr = (raw is String && raw.isNotEmpty && raw != 'null')
        ? raw
        : null;

    final rawSugg = json['suggestions'];
    final sugg = rawSugg is List
        ? rawSugg.whereType<String>().take(3).toList()
        : <String>[];

    return SmartSuggestionModel(spellCorrection: corr, suggestions: sugg);
  }

  bool get hasSpellCorrection => spellCorrection != null;
  bool get hasSuggestions     => suggestions.isNotEmpty;
  bool get isEmpty             => !hasSpellCorrection && !hasSuggestions;
}

// =============================================================================
// FILE        : smart_input_controller.dart
// MODULE      : Shared → Smart Input
// LAYER       : Logic / Controller
// PURPOSE     : Har SmartInputField ka apna controller hota hai.
//               - State own karta hai (spell, suggestions, loading)
//               - 450ms debounce handle karta hai
//               - UI ko sirf ek notifyListeners() se update karta hai
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'smart_field_type.dart';
//import 'smart_suggestion_model.dart';
import 'smart_input_service.dart';

class SmartInputController extends ChangeNotifier {
  // ── Dependencies ──────────────────────────────────────────────────────────
  final SmartFieldType fieldType;
  final SmartInputService _service;

  SmartInputController({
    required this.fieldType,
    SmartInputService? service,
  }) : _service = service ?? SmartInputService();

  // ── Public Observable State ───────────────────────────────────────────────
  String? spellCorrection;
  List<String> suggestions = [];
  bool isLoading = false;
  String currentQuery = '';

  // ── Private ───────────────────────────────────────────────────────────────
  Timer? _debounceTimer;

  // 450ms — sweet spot for Indian name inputs (not too fast, not too slow)
  static const Duration _debounceDuration = Duration(milliseconds: 450);

  // ════════════════════════════════════════════════════════════════════════════
  // ENTRY POINT — TextField.onChanged se call hota hai
  // ════════════════════════════════════════════════════════════════════════════
  void onTextChanged(String query) {
    currentQuery = query;

    // Pichla pending timer cancel karo — wasteful API call avoid ho
    _debounceTimer?.cancel();

    // Suggestions reset karo — snappy UX ke liye
    _clearState();

    if (query.trim().length < fieldType.minQueryLength) {
      isLoading = false;
      notifyListeners();
      return;
    }

    // Shimmer/loading indicator immediately dikhao
    isLoading = true;
    notifyListeners();

    // 450ms ke baad actual API call
    _debounceTimer = Timer(_debounceDuration, () => _fetch(query.trim()));
  }

  // ── API Fetch ─────────────────────────────────────────────────────────────
  Future<void> _fetch(String query) async {
    try {
      final result = await _service.fetchSuggestions(query, fieldType);
      spellCorrection =
          result.hasSpellCorrection ? result.spellCorrection : null;
      suggestions = fieldType.showSuggestionChips ? result.suggestions : [];
    } catch (_) {
      spellCorrection = null;
      suggestions = [];
    } finally {
      isLoading = false;
      notifyListeners(); // Single notify → single rebuild
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // USER ACTIONS — UI se call hoti hain
  // ════════════════════════════════════════════════════════════════════════════

  /// User ne "Search instead for X" tap kiya
  /// Returns: accepted text (UI TextField update karega)
  String acceptSpellCorrection() {
    final text = spellCorrection ?? '';
    _clearState();
    notifyListeners();
    return text;
  }

  /// User ne suggestion chip tap kiya
  /// Returns: chosen chip text (UI TextField update karega)
  String acceptSuggestion(String chip) {
    _clearState();
    notifyListeners();
    return chip;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _clearState() {
    spellCorrection = null;
    suggestions = [];
  }

  bool get hasAnySuggestion =>
      spellCorrection != null || suggestions.isNotEmpty;

  // ── Cleanup ───────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _service.dispose();
    super.dispose();
  }
}

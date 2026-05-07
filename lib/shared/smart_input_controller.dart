// =============================================================================
// FILE        : smart_input_controller.dart
// MODULE      : Shared → Smart Input
// LAYER       : Logic / Controller
// PURPOSE     : Har SmartInputField ka apna controller hota hai.
//               - State own karta hai (spell, suggestions, loading, error)
//               - 450ms debounce handle karta hai
//               - UI ko sirf ek notifyListeners() se update karta hai
//
// ✅ FIXES APPLIED:
//   1. Gemini API Key check lagaya gaya hai
//   2. Error messages updated for GEMINI_API_KEY
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'smart_field_type.dart';
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
  String? errorMessage;

  // ── Private ───────────────────────────────────────────────────────────────
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 450);

  // ── Convenience getters ───────────────────────────────────────────────────
  bool get hasError => errorMessage != null;

  // ✅ FIX: Now checking Gemini key instead of Anthropic
  bool get isApiKeyMissing => SmartInputService.geminiKey.isEmpty;

  bool get hasAnySuggestion =>
      spellCorrection != null || suggestions.isNotEmpty;

  // ════════════════════════════════════════════════════════════════════════════
  // ENTRY POINT — TextField.onChanged se call hota hai
  // ════════════════════════════════════════════════════════════════════════════
  void onTextChanged(String query) {
    currentQuery = query;

    _debounceTimer?.cancel();
    _clearState();

    if (query.trim().length < fieldType.minQueryLength) {
      isLoading = false;
      notifyListeners();
      return;
    }

    // API key nahi hai — loading dikhao hi mat, error dikhao
    if (isApiKeyMissing) {
      errorMessage = '⚠️ Smart suggestions ke liye Gemini API key set karo.\n'
          'Run: flutter run --dart-define=GEMINI_API_KEY=AIza...';
      notifyListeners();
      return;
    }

    // Shimmer immediately
    isLoading = true;
    notifyListeners();

    _debounceTimer = Timer(_debounceDuration, () => _fetch(query.trim()));
  }

  // ── API Fetch ─────────────────────────────────────────────────────────────
  Future<void> _fetch(String query) async {
    final result = await _service.fetchSuggestions(query, fieldType);

    if (result.isSuccess) {
      final model = result.model!;
      spellCorrection = model.hasSpellCorrection ? model.spellCorrection : null;
      suggestions = fieldType.showSuggestionChips ? model.suggestions : [];
      errorMessage = null;
    } else if (result.isError) {
      spellCorrection = null;
      suggestions = [];
      errorMessage = result.errorMessage;
    } else {
      // isEmpty — koi suggestions nahi mila, that's fine
      spellCorrection = null;
      suggestions = [];
      errorMessage = null;
    }

    isLoading = false;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // USER ACTIONS
  // ════════════════════════════════════════════════════════════════════════════

  String acceptSpellCorrection() {
    final text = spellCorrection ?? '';
    _clearState();
    notifyListeners();
    return text;
  }

  String acceptSuggestion(String chip) {
    _clearState();
    notifyListeners();
    return chip;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _clearState() {
    spellCorrection = null;
    suggestions = [];
    errorMessage = null;
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _service.dispose();
    super.dispose();
  }
}

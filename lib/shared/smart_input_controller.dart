import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';
import 'smart_field_type.dart';
import 'smart_input_service.dart';

class SmartInputController extends ChangeNotifier {
  final SmartFieldType fieldType;
  final SmartInputService _service;

  SmartInputController({
    required this.fieldType,
    SmartInputService? service,
  }) : _service = service ?? SmartInputService();

  String? spellCorrection;
  List<String> suggestions = [];
  bool isLoading = false;
  String currentQuery = '';
  String? errorMessage;

  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 600);

  bool get hasError => errorMessage != null;
  bool get isApiKeyMissing => !EnvConfig.hasValidGeminiKey;
  bool get hasAnySuggestion =>
      spellCorrection != null || suggestions.isNotEmpty;

  void onTextChanged(String query) {
    currentQuery = query;
    _debounceTimer?.cancel();
    _clearState();

    if (query.trim().length < fieldType.minQueryLength) {
      isLoading = false;
      notifyListeners();
      return;
    }

    // DEBUG: Key check — agar key nahi hai to clearly dikhao
    if (isApiKeyMissing) {
      errorMessage =
          '⚠️ API key nahi mili. App dobara run karo:\nflutter run -d windows --dart-define=GEMINI_API_KEY=AIzaXXX';
      notifyListeners();
      return;
    }

    // Key hai — loading start karo
    isLoading = true;
    notifyListeners();

    _debounceTimer = Timer(_debounceDuration, () => _fetch(query.trim()));
  }

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
      // DEBUG: Error dikhao taaki pata chale kya problem hai
      errorMessage = result.errorMessage;
    } else {
      spellCorrection = null;
      suggestions = [];
      errorMessage = null;
    }

    isLoading = false;
    notifyListeners();
  }

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

  void _clearState() {
    spellCorrection = null;
    suggestions = [];
    errorMessage = null;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _service.dispose();
    super.dispose();
  }
}

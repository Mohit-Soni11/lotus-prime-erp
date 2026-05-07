// =============================================================================
// FILE        : smart_input_service.dart
// MODULE      : Shared → Smart Input
// LAYER       : Service
// PURPOSE     : STRICTLY raw API calls only. No UI, no state, no logic.
//               SmartFieldType ke hisaab se alag-alag prompt build karta hai.
//
// ✅ FIXES APPLIED:
//   1. Anthropic se Google Gemini 1.5 Flash par shift kiya (Free & Fast)
//   2. Native JSON response_mime_type use kiya
//   3. API key String.fromEnvironment('GEMINI_API_KEY') se read hoti hai
//   4. Added missing SmartSuggestionResult class at the bottom.
// =============================================================================

import 'dart:convert';
import 'dart:io';
import 'dart:async'; // TimeoutException ke liye
import 'package:http/http.dart' as http;
import '../config/env_config.dart'; // Ensure EnvConfig import is correct based on your folder structure
import 'smart_field_type.dart';
import 'smart_suggestion_model.dart';

class SmartInputService {
  final http.Client _client;

  SmartInputService({http.Client? client}) : _client = client ?? http.Client();

  // ── Gemini API Config ──────────────────────────────────────────────────────
  // EnvConfig se key read kar rahe hain
  static String get geminiKey => EnvConfig.geminiApiKey;

  static const _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  static const _timeout = Duration(seconds: 10);

  // ════════════════════════════════════════════════════════════════════════════
  // MAIN ENTRY POINT
  // ════════════════════════════════════════════════════════════════════════════
  Future<SmartSuggestionResult> fetchSuggestions(
    String query,
    SmartFieldType fieldType,
  ) async {
    // ── Min length check ─────────────────────────────────────────────────────
    if (query.trim().length < fieldType.minQueryLength) {
      return SmartSuggestionResult.empty();
    }

    // ── API Key check ────────────────────────────────────────────────────────
    if (!EnvConfig.hasValidGeminiKey) {
      return SmartSuggestionResult.error(
        'Gemini API key missing.\n'
        'Run: flutter run --dart-define-from-file=.env',
      );
    }

    try {
      final url = Uri.parse('$_apiUrl?key=$geminiKey');

      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": _buildPrompt(query.trim(), fieldType)}
                  ]
                }
              ],
              "generationConfig": {
                // Ye Gemini ko strictly valid JSON return karne force karta hai
                "response_mime_type": "application/json"
              }
            }),
          )
          .timeout(_timeout);

      // ── Non-200 responses ─────────────────────────────────────────────────
      if (response.statusCode == 400 || response.statusCode == 403) {
        return SmartSuggestionResult.error('Invalid Gemini API key.');
      }
      if (response.statusCode == 429) {
        return SmartSuggestionResult.error('Rate limit hit. Wait a moment.');
      }
      if (response.statusCode != HttpStatus.ok) {
        return SmartSuggestionResult.error('API error: ${response.statusCode}');
      }

      // ── Parse Gemini response ─────────────────────────────────────────────
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = body['candidates'] as List?;

      if (candidates == null || candidates.isEmpty) {
        return SmartSuggestionResult.empty();
      }

      final rawText =
          candidates.first['content']?['parts']?[0]?['text'] as String? ?? '';
      if (rawText.isEmpty) return SmartSuggestionResult.empty();

      final jsonMap = jsonDecode(rawText) as Map<String, dynamic>;
      return SmartSuggestionResult.success(
        SmartSuggestionModel.fromJson(jsonMap),
      );
    } on FormatException catch (e) {
      return SmartSuggestionResult.error('Parse error: $e');
    } on SocketException {
      return SmartSuggestionResult.error('No internet connection.');
    } on TimeoutException {
      return SmartSuggestionResult.error('Request timed out.');
    } catch (e) {
      return SmartSuggestionResult.error('Unexpected error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CONTEXT-AWARE PROMPT BUILDER
  // ════════════════════════════════════════════════════════════════════════════
  String _buildPrompt(String query, SmartFieldType fieldType) {
    const jsonFormat = 'Return ONLY this exact JSON structure:\n'
        '{"spellCorrection":"corrected if misspelled else null","suggestions":["s1","s2","s3"]}';

    switch (fieldType) {
      case SmartFieldType.name:
        return 'You are an Indian ERP assistant.\n'
            'User typed a CUSTOMER NAME: "$query"\n\n$jsonFormat\n\n'
            'Rules:\n'
            '- spellCorrection: If "$query" is a misspelled Indian name (e.g. "ramech"→"Ramesh"), correct it. Else null.\n'
            '- suggestions: Give 2-3 standard Indian name completions or variations for "$query".';

      case SmartFieldType.address:
        return 'You are an Indian ERP assistant.\n'
            'User typed an ADDRESS/CITY: "$query"\n\n$jsonFormat\n\n'
            'Rules:\n'
            '- spellCorrection: If misspelled Indian city/area (e.g. "mumabi"→"Mumbai"), correct it. Else null.\n'
            '- suggestions: Give 2-3 relevant Indian city/area completions for "$query".';

      case SmartFieldType.item:
        return 'You are a jewellery ERP assistant.\n'
            'User typed a JEWELLERY ITEM: "$query"\n\n$jsonFormat\n\n'
            'Rules:\n'
            '- spellCorrection: If misspelled (e.g. "rnig"→"Ring"), correct it. Else null.\n'
            '- suggestions: Give 2-3 standard jewellery item names (e.g. "Gold Ring 22K", "Diamond Chain").';

      case SmartFieldType.remark:
        return 'You are an ERP assistant.\n'
            'User typed a REMARK: "$query"\n\n$jsonFormat\n\n'
            'Rules:\n'
            '- spellCorrection: Fix obvious spelling mistakes. Else null.\n'
            '- suggestions: Always return empty array [].';

      case SmartFieldType.company:
        return 'You are an Indian ERP assistant.\n'
            'User typed a COMPANY NAME: "$query"\n\n$jsonFormat\n\n'
            'Rules:\n'
            '- spellCorrection: Correct obvious business name misspellings. Else null.\n'
            '- suggestions: Give 2-3 common Indian business name completions for "$query".';

      case SmartFieldType.generic:
      default:
        return 'You are an ERP assistant.\n'
            'User typed: "$query"\n\n$jsonFormat\n\n'
            'Rules:\n'
            '- spellCorrection: Fix typos. Else null.\n'
            '- suggestions: 1-2 relevant completions. Else empty array.';
    }
  }

  void dispose() => _client.close();
}

// =============================================================================
// SmartSuggestionResult — Success / Empty / Error states
// Controller ko pata chale kya hua
// =============================================================================
class SmartSuggestionResult {
  final SmartSuggestionModel? model;
  final String? errorMessage;
  final bool _isEmpty;

  const SmartSuggestionResult._({
    this.model,
    this.errorMessage,
    bool isEmpty = false,
  }) : _isEmpty = isEmpty;

  factory SmartSuggestionResult.success(SmartSuggestionModel m) =>
      SmartSuggestionResult._(model: m);

  factory SmartSuggestionResult.empty() =>
      const SmartSuggestionResult._(isEmpty: true);

  factory SmartSuggestionResult.error(String msg) =>
      SmartSuggestionResult._(errorMessage: msg);

  bool get isSuccess => model != null;
  bool get isEmpty => _isEmpty;
  bool get isError => errorMessage != null;
}

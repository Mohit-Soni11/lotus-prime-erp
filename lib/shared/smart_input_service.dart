// =============================================================================
// FILE        : smart_input_service.dart
// MODULE      : Shared → Smart Input
// LAYER       : Service
// PURPOSE     : Google Gemini API se smart suggestions fetch karta hai.
//               BILKUL FREE — Gemini 1.5 Flash model use hota hai.
//
// FREE LIMITS:
//   ✅ 15 req/min | 1500 req/day | 1M tokens/min | Cost = ZERO
//
// API KEY: https://aistudio.google.com/app/apikey
// =============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import 'smart_field_type.dart';
import 'smart_suggestion_model.dart';

class SmartInputService {
  final http.Client _client;

  SmartInputService({http.Client? client}) : _client = client ?? http.Client();

  // ── Gemini API Config ──────────────────────────────────────────────────────
  static const _model = 'gemini-2.0-flash';
  static const _timeout = Duration(seconds: 10);

  String get _apiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=${EnvConfig.geminiApiKey}';

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
      return SmartSuggestionResult.empty(); // Silently skip — no error shown
    }

    try {
      final response = await _client
          .post(
            Uri.parse(_apiUrl),
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': _buildPrompt(query.trim(), fieldType)}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.3,
                'maxOutputTokens': 200,
              },
            }),
          )
          .timeout(_timeout);

      // ── Non-200 responses ─────────────────────────────────────────────────
      if (response.statusCode == 400) {
        return SmartSuggestionResult.error(
            'Invalid API key. Check GEMINI_API_KEY.');
      }
      if (response.statusCode == 429) {
        return SmartSuggestionResult.error(
            'Rate limit. Thodi der baad try karo.');
      }
      if (response.statusCode != HttpStatus.ok) {
        return SmartSuggestionResult.error('API error: ${response.statusCode}');
      }

      // ── Parse Gemini Response ─────────────────────────────────────────────
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = body['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return SmartSuggestionResult.empty();
      }

      final parts = candidates.first['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        return SmartSuggestionResult.empty();
      }

      final rawText = (parts.first['text'] as String? ?? '').trim();
      if (rawText.isEmpty) return SmartSuggestionResult.empty();

      // Clean markdown fences agar Gemini ne laga diya
      final cleaned = rawText
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll('```', '')
          .trim();

      final jsonMap = jsonDecode(cleaned) as Map<String, dynamic>;
      return SmartSuggestionResult.success(
        SmartSuggestionModel.fromJson(jsonMap),
      );
    } on FormatException catch (e) {
      return SmartSuggestionResult.error('Parse error: $e');
    } on SocketException {
      return SmartSuggestionResult.error('No internet connection.');
    } on HttpException {
      return SmartSuggestionResult.error('Network error.');
    } catch (e) {
      return SmartSuggestionResult.error('Unexpected error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CONTEXT-AWARE PROMPT BUILDER
  // ════════════════════════════════════════════════════════════════════════════
  String _buildPrompt(String query, SmartFieldType fieldType) {
    const jsonFormat =
        'Return ONLY this exact JSON (no markdown, no explanation):\n'
        '{"spellCorrection":"corrected if misspelled else null","suggestions":["s1","s2","s3"]}';

    switch (fieldType) {
      case SmartFieldType.name:
        return 'You are a smart input assistant for an Indian jewellery shop ERP.\n'
            'User typed in a CUSTOMER/PERSON NAME field: "$query"\n\n'
            '$jsonFormat\n\n'
            'Rules:\n'
            '- spellCorrection: If "$query" looks like a misspelled Indian personal name '
            '(e.g. "chaodhari"→"Chaudhari", "ramech"→"Ramesh", "prya"→"Priya"), return corrected form. '
            'If already correct, return null.\n'
            '- suggestions: Give 2-3 Hindi Devanagari script versions of "$query" as a personal name '
            '(e.g. "Ramesh" → ["रमेश","रामेश"]). Always provide at least 2.';

      case SmartFieldType.address:
        return 'You are a smart input assistant for an Indian jewellery shop ERP.\n'
            'User typed in an ADDRESS/CITY/AREA field: "$query"\n\n'
            '$jsonFormat\n\n'
            'Rules:\n'
            '- spellCorrection: If "$query" looks like a misspelled Indian city/area '
            '(e.g. "mumabi"→"Mumbai", "patana"→"Patna"), return correction. Else null.\n'
            '- suggestions: Give 2-3 relevant Indian city names or area completions '
            '(e.g. "pat"→["Patna","Patiala","Pathankot"]).';

      case SmartFieldType.item:
        return 'You are a smart input assistant for an Indian jewellery shop ERP.\n'
            'User typed in a JEWELLERY ITEM field: "$query"\n\n'
            '$jsonFormat\n\n'
            'Rules:\n'
            '- spellCorrection: If "$query" looks like a misspelled jewellery item '
            '(e.g. "rnig"→"Ring", "chanin"→"Chain"), return correction. Else null.\n'
            '- suggestions: Give 2-3 specific Indian jewellery item names '
            '(e.g. "ring"→["Gold Ring 22K","Silver Ring","Diamond Ring"]).';

      case SmartFieldType.remark:
        return 'You are a smart input assistant for an Indian jewellery shop ERP.\n'
            'User typed in a REMARK/NOTE field: "$query"\n\n'
            '$jsonFormat\n\n'
            'Rules:\n'
            '- spellCorrection: Fix obvious spelling mistakes. Return corrected full text. '
            'If correct, return null.\n'
            '- suggestions: Always return empty array [].';

      case SmartFieldType.company:
        return 'You are a smart input assistant for an Indian jewellery shop ERP.\n'
            'User typed in a COMPANY/SHOP NAME field: "$query"\n\n'
            '$jsonFormat\n\n'
            'Rules:\n'
            '- spellCorrection: If "$query" looks like a misspelled business name, return correction. Else null.\n'
            '- suggestions: Give 2-3 common Indian business name completions '
            '(e.g. "lotus"→["Lotus Jewellers","Lotus Gold & Silver","Lotus Jewellery Pvt Ltd"]).';

      case SmartFieldType.generic:
      default:
        return 'You are a smart input assistant for an Indian ERP system.\n'
            'User typed: "$query"\n\n'
            '$jsonFormat\n\n'
            'Rules:\n'
            '- spellCorrection: Fix obvious spelling mistakes. Else null.\n'
            '- suggestions: Give 1-2 relevant completions if applicable. Else empty array.';
    }
  }

  void dispose() => _client.close();
}

// =============================================================================
// SmartSuggestionResult — Success / Empty / Error states
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

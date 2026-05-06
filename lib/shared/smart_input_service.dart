// =============================================================================
// FILE        : smart_input_service.dart
// MODULE      : Shared → Smart Input
// LAYER       : Service
// PURPOSE     : STRICTLY raw API calls only. No UI, no state, no logic.
//               SmartFieldType ke hisaab se alag-alag prompt build karta hai.
// =============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'smart_field_type.dart';
import 'smart_suggestion_model.dart';

class SmartInputService {
  final http.Client _client;

  SmartInputService({http.Client? client}) : _client = client ?? http.Client();

  // ── API Config ─────────────────────────────────────────────────────────────
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-20250514';
  static const _maxTokens = 250;
  static const _timeout = Duration(seconds: 8);

  // 🔑 IMPORTANT: apna Anthropic API key yahan rakho
  // Best practice: Firebase Remote Config ya --dart-define se lena
  // Example build command:
  //   flutter run --dart-define=ANTHROPIC_KEY=sk-ant-xxxx
  static const _apiKey = String.fromEnvironment(
    'ANTHROPIC_KEY',
    defaultValue: 'YOUR_KEY_HERE', // ← Yahan replace karo
  );

  // ════════════════════════════════════════════════════════════════════════════
  // MAIN ENTRY POINT
  // Controller yahan se call karta hai — fieldType se decide hota hai
  // kaunsa prompt bhejni hai Claude ko.
  // ════════════════════════════════════════════════════════════════════════════
  Future<SmartSuggestionModel> fetchSuggestions(
    String query,
    SmartFieldType fieldType,
  ) async {
    if (query.trim().length < fieldType.minQueryLength) {
      return SmartSuggestionModel.empty();
    }

    try {
      final response = await _client
          .post(
            Uri.parse(_apiUrl),
            headers: _headers,
            body: jsonEncode({
              'model': _model,
              'max_tokens': _maxTokens,
              'messages': [
                {
                  'role': 'user',
                  'content': _buildPrompt(query.trim(), fieldType),
                }
              ],
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != HttpStatus.ok) {
        return SmartSuggestionModel.empty();
      }

      final body = jsonDecode(response.body);
      final rawText =
          (body['content'] as List?)?.firstOrNull?['text']?.toString().trim() ??
              '{}';

      // Clean markdown fences agar Claude ne laga diya
      final cleaned = rawText.replaceAll(RegExp(r'```json|```'), '').trim();

      final jsonMap = jsonDecode(cleaned) as Map<String, dynamic>;
      return SmartSuggestionModel.fromJson(jsonMap);
    } catch (_) {
      // Service silently swallows — controller decides UX response
      return SmartSuggestionModel.empty();
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CONTEXT-AWARE PROMPT BUILDER
  // Har field type ke liye alag prompt — Claude ko exact context milta hai
  // ════════════════════════════════════════════════════════════════════════════
  String _buildPrompt(String query, SmartFieldType fieldType) {
    const jsonFormat =
        '''Return ONLY this exact JSON (no markdown, no explanation):
{"spellCorrection":"corrected if misspelled else null","suggestions":["s1","s2","s3"]}''';

    switch (fieldType) {
      // ── 👤 Name Field ──────────────────────────────────────────────────────
      case SmartFieldType.name:
        return '''You are a smart input assistant for an Indian jewellery shop ERP system.
User typed in a CUSTOMER/PERSON NAME field: "$query"

$jsonFormat

Rules:
- spellCorrection: If "$query" looks like a misspelled Indian personal name (e.g. "chaodhari"→"Chaudhari", "ramech"→"Ramesh", "prya"→"Priya"), return the corrected form. If already correct, return null.
- suggestions: Give 2-3 Hindi Devanagari script versions of "$query" as a personal name (e.g. "Ramesh" → ["रमेश","रामेश"]). Always provide at least 2.''';

      // ── 🏠 Address Field ───────────────────────────────────────────────────
      case SmartFieldType.address:
        return '''You are a smart input assistant for an Indian jewellery shop ERP system.
User typed in an ADDRESS/CITY/AREA field: "$query"

$jsonFormat

Rules:
- spellCorrection: If "$query" looks like a misspelled Indian city, area, street, or locality name (e.g. "mumbai"→null correct, "mumabi"→"Mumbai", "patana"→"Patna"), return correction. Else null.
- suggestions: Give 2-3 relevant Indian city names, area names, or common address completions related to "$query". Examples: "pat"→["Patna","Patiala","Pathankot"].''';

      // ── 💍 Item Field ──────────────────────────────────────────────────────
      case SmartFieldType.item:
        return '''You are a smart input assistant for an Indian jewellery shop ERP system.
User typed in a JEWELLERY ITEM field: "$query"

$jsonFormat

Rules:
- spellCorrection: If "$query" looks like a misspelled jewellery item (e.g. "rnig"→"Ring", "chanin"→"Chain"), return correction. Else null.
- suggestions: Give 2-3 specific Indian jewellery item names related to "$query". Be specific with metal/type (e.g. "ring"→["Gold Ring 22K","Silver Ring","Diamond Ring","Platinum Ring"], "chain"→["Gold Chain 22K","Silver Chain","Mangalsutra"]).''';

      // ── 📝 Remark Field ────────────────────────────────────────────────────
      case SmartFieldType.remark:
        return '''You are a smart input assistant for an Indian jewellery shop ERP system.
User typed in a REMARK/NOTE/NOTICE field: "$query"

$jsonFormat

Rules:
- spellCorrection: Fix obvious spelling mistakes in "$query" if present. Return corrected full text. If correct, return null.
- suggestions: Always return empty array [] — remarks are freeform, no suggestions needed.''';

      // ── 🏢 Company Field ───────────────────────────────────────────────────
      case SmartFieldType.company:
        return '''You are a smart input assistant for an Indian jewellery shop ERP system.
User typed in a COMPANY/SHOP NAME field: "$query"

$jsonFormat

Rules:
- spellCorrection: If "$query" looks like a misspelled Indian business name, return correction. Else null.
- suggestions: Give 2-3 common Indian business name completions or suffixes for "$query" (e.g. "lotus"→["Lotus Jewellers","Lotus Gold & Silver","Lotus Jewellery Pvt Ltd"]).''';

      // ── 🔖 Generic Field ───────────────────────────────────────────────────
      case SmartFieldType.generic:
      default:
        return '''You are a smart input assistant for an Indian ERP system.
User typed: "$query"

$jsonFormat

Rules:
- spellCorrection: Fix obvious spelling mistakes. Else null.
- suggestions: Give 1-2 relevant completions if applicable. Else empty array.''';
    }
  }

  // ── Shared Request Headers ─────────────────────────────────────────────────
  Map<String, String> get _headers => {
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
        HttpHeaders.acceptHeader: 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-dangerous-direct-browser-access': 'true',
      };

  void dispose() => _client.close();
}

// =============================================================================
// FILE        : smart_input_service.dart
// MODULE      : Shared → Smart Input
// LAYER       : Service
// PURPOSE     : STRICTLY raw API calls only. No UI, no state, no logic.
//               SmartFieldType ke hisaab se alag-alag prompt build karta hai.
//
// ✅ FIXES APPLIED:
//   1. http package properly use ho raha hai (pubspec mein add kiya)
//   2. API key EnvConfig se aata hai — hardcode nahi
//   3. Silent catch hata diya — error properly propagate hota hai
//   4. Key missing ho to meaningful error return hota hai
//   5. Response parsing robust banaya (null safety)
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

  // ── API Config ─────────────────────────────────────────────────────────────
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-20250514';
  static const _maxTok = 250;
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
    if (!EnvConfig.hasValidAnthropicKey) {
      return SmartSuggestionResult.error(
        'Anthropic API key missing.\n'
        'Run: flutter run --dart-define=ANTHROPIC_KEY=sk-ant-xxxx',
      );
    }

    try {
      final response = await _client
          .post(
            Uri.parse(_apiUrl),
            headers: _buildHeaders(),
            body: jsonEncode({
              'model': _model,
              'max_tokens': _maxTok,
              'messages': [
                {
                  'role': 'user',
                  'content': _buildPrompt(query.trim(), fieldType),
                }
              ],
            }),
          )
          .timeout(_timeout);

      // ── Non-200 responses ─────────────────────────────────────────────────
      if (response.statusCode == 401) {
        return SmartSuggestionResult.error(
            'Invalid API key. Check your ANTHROPIC_KEY.');
      }
      if (response.statusCode == 429) {
        return SmartSuggestionResult.error(
            'Rate limit hit. Thodi der baad try karo.');
      }
      if (response.statusCode != HttpStatus.ok) {
        return SmartSuggestionResult.error(
          'API error: ${response.statusCode}',
        );
      }

      // ── Parse response ────────────────────────────────────────────────────
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final content = body['content'] as List?;
      final rawText = content?.isNotEmpty == true
          ? (content!.first['text'] as String? ?? '').trim()
          : '';

      if (rawText.isEmpty) return SmartSuggestionResult.empty();

      // Clean markdown fences agar Claude ne laga diya
      final cleaned = rawText
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll('```', '')
          .trim();

      final jsonMap = jsonDecode(cleaned) as Map<String, dynamic>;
      return SmartSuggestionResult.success(
        SmartSuggestionModel.fromJson(jsonMap),
      );
    } on FormatException catch (e) {
      // JSON parse fail — Claude ne unexpected format diya
      return SmartSuggestionResult.error('Parse error: $e');
    } on SocketException {
      return SmartSuggestionResult.error('No internet connection.');
    } on HttpException {
      return SmartSuggestionResult.error(
          'Network error. Check your connection.');
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
      // ── 👤 Name Field ──────────────────────────────────────────────────────
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

      // ── 🏠 Address Field ───────────────────────────────────────────────────
      case SmartFieldType.address:
        return 'You are a smart input assistant for an Indian jewellery shop ERP.\n'
            'User typed in an ADDRESS/CITY/AREA field: "$query"\n\n'
            '$jsonFormat\n\n'
            'Rules:\n'
            '- spellCorrection: If "$query" looks like a misspelled Indian city, area, or locality '
            '(e.g. "mumabi"→"Mumbai", "patana"→"Patna"), return correction. Else null.\n'
            '- suggestions: Give 2-3 relevant Indian city names or area completions related to "$query" '
            '(e.g. "pat"→["Patna","Patiala","Pathankot"]).';

      // ── 💍 Item Field ──────────────────────────────────────────────────────
      case SmartFieldType.item:
        return 'You are a smart input assistant for an Indian jewellery shop ERP.\n'
            'User typed in a JEWELLERY ITEM field: "$query"\n\n'
            '$jsonFormat\n\n'
            'Rules:\n'
            '- spellCorrection: If "$query" looks like a misspelled jewellery item '
            '(e.g. "rnig"→"Ring", "chanin"→"Chain"), return correction. Else null.\n'
            '- suggestions: Give 2-3 specific Indian jewellery item names related to "$query" '
            '(e.g. "ring"→["Gold Ring 22K","Silver Ring","Diamond Ring"], '
            '"chain"→["Gold Chain 22K","Silver Chain","Mangalsutra"]).';

      // ── 📝 Remark Field ────────────────────────────────────────────────────
      case SmartFieldType.remark:
        return 'You are a smart input assistant for an Indian jewellery shop ERP.\n'
            'User typed in a REMARK/NOTE field: "$query"\n\n'
            '$jsonFormat\n\n'
            'Rules:\n'
            '- spellCorrection: Fix obvious spelling mistakes in "$query". Return corrected full text. '
            'If correct, return null.\n'
            '- suggestions: Always return empty array [] — remarks are freeform.';

      // ── 🏢 Company Field ───────────────────────────────────────────────────
      case SmartFieldType.company:
        return 'You are a smart input assistant for an Indian jewellery shop ERP.\n'
            'User typed in a COMPANY/SHOP NAME field: "$query"\n\n'
            '$jsonFormat\n\n'
            'Rules:\n'
            '- spellCorrection: If "$query" looks like a misspelled business name, return correction. Else null.\n'
            '- suggestions: Give 2-3 common Indian business name completions for "$query" '
            '(e.g. "lotus"→["Lotus Jewellers","Lotus Gold & Silver","Lotus Jewellery Pvt Ltd"]).';

      // ── 🔖 Generic Field ───────────────────────────────────────────────────
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

  // ── Request Headers ────────────────────────────────────────────────────────
  Map<String, String> _buildHeaders() => {
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
        HttpHeaders.acceptHeader: 'application/json',
        'x-api-key': EnvConfig.anthropicApiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-dangerous-direct-browser-access': 'true',
      };

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

// ============================================================
// FILE    : lib/models/setting/tax_gst/hsn_code_model.dart
// MODULE  : Tax & GST Configuration
// AUTHOR  : Lotus Prime ERP
// VERSION : 1.0.0
// ============================================================

import 'dart:convert';
import '../../../theme/settings/tax_gst/tax_gst_strings.dart';

/// Domain model representing a single HSN/SAC code entry.
class HsnCodeModel {
  final String category;
  final String hsnCode;
  final String gstRate;

  const HsnCodeModel({
    required this.category,
    required this.hsnCode,
    required this.gstRate,
  });

  // ── Factory constructors ──────────────────────────────────────
  factory HsnCodeModel.fromMap(Map<String, dynamic> map) => HsnCodeModel(
        category: map['category']?.toString() ?? '',
        hsnCode: map['hsn']?.toString() ?? '',
        gstRate: map['rate']?.toString() ?? '3%',
      );

  factory HsnCodeModel.empty() =>
      const HsnCodeModel(category: '', hsnCode: '', gstRate: '3%');

  // ── Serialization ─────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'category': category,
        'hsn': hsnCode,
        'rate': gstRate,
      };

  // ── copyWith ─────────────────────────────────────────────────
  HsnCodeModel copyWith({
    String? category,
    String? hsnCode,
    String? gstRate,
  }) =>
      HsnCodeModel(
        category: category ?? this.category,
        hsnCode: hsnCode ?? this.hsnCode,
        gstRate: gstRate ?? this.gstRate,
      );

  // ── Equality ──────────────────────────────────────────────────
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HsnCodeModel &&
          other.category == category &&
          other.hsnCode == hsnCode &&
          other.gstRate == gstRate;

  @override
  int get hashCode => Object.hash(category, hsnCode, gstRate);

  @override
  String toString() =>
      'HsnCodeModel(category: $category, hsn: $hsnCode, rate: $gstRate)';
}

// ── JSON List helpers ─────────────────────────────────────────────────────────

/// Encode a list of [HsnCodeModel] to a JSON string for DB storage.
String hsnListToJson(List<HsnCodeModel> list) =>
    jsonEncode(list.map((e) => e.toMap()).toList());

/// Decode a JSON string from DB to a list of [HsnCodeModel].
/// Returns [kDefaultHsnCodes] if json is null, empty or malformed.
List<HsnCodeModel> hsnListFromJson(String? json) {
  if (json == null || json.trim().isEmpty) {
    return defaultHsnCodeModels();
  }
  try {
    final decoded = jsonDecode(json) as List<dynamic>;
    return decoded
        .map((e) => HsnCodeModel.fromMap(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return defaultHsnCodeModels();
  }
}

/// Returns the factory-default HSN code list from [TaxGstStrings].
List<HsnCodeModel> defaultHsnCodeModels() =>
    TaxGstStrings.defaultHsnCodes.map((m) => HsnCodeModel.fromMap(m)).toList();

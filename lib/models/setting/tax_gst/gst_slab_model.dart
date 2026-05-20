// ============================================================
// FILE    : lib/models/setting/tax_gst/gst_slab_model.dart
// MODULE  : Tax & GST Configuration
// AUTHOR  : Lotus Prime ERP
// VERSION : 1.0.0
// ============================================================

import 'dart:convert';
import '../../../theme/settings/tax_gst/tax_gst_strings.dart';

// ── Enums ────────────────────────────────────────────────────────────────────

/// GST taxpayer registration types.
enum TaxpayerType {
  regular('Regular'),
  composition('Composition Scheme'),
  unregistered('Unregistered'),
  consumer('Consumer'),
  deemedExport('Deemed Export'),
  sezUnit('SEZ Unit'),
  sezDeveloper('SEZ Developer');

  const TaxpayerType(this.label);
  final String label;

  static TaxpayerType fromLabel(String label) => TaxpayerType.values
      .firstWhere((e) => e.label == label, orElse: () => TaxpayerType.regular);
}

/// Supported GST rate slabs for jewellery.
enum GstRateSlab {
  zero('0%'),
  quarterPct('0.25%'),
  oneHalfPct('1.5%'),
  three('3%'),
  five('5%'),
  twelve('12%'),
  eighteen('18%'),
  twentyEight('28%');

  const GstRateSlab(this.label);
  final String label;

  static GstRateSlab fromLabel(String label) => GstRateSlab.values
      .firstWhere((e) => e.label == label, orElse: () => GstRateSlab.three);
}

// ── GST Slab Model ────────────────────────────────────────────────────────────

/// Domain model for a single category → GST rate mapping.
class GstSlabModel {
  final String category;
  final String rate;

  const GstSlabModel({required this.category, required this.rate});

  factory GstSlabModel.fromMap(Map<String, dynamic> m) => GstSlabModel(
        category: m['category']?.toString() ?? '',
        rate: m['rate']?.toString() ?? '3%',
      );

  Map<String, dynamic> toMap() => {'category': category, 'rate': rate};

  GstSlabModel copyWith({String? category, String? rate}) => GstSlabModel(
        category: category ?? this.category,
        rate: rate ?? this.rate,
      );

  @override
  bool operator ==(Object other) =>
      other is GstSlabModel && other.category == category && other.rate == rate;

  @override
  int get hashCode => Object.hash(category, rate);

  @override
  String toString() => 'GstSlabModel(category: $category, rate: $rate)';
}

// ── JSON helpers ──────────────────────────────────────────────────────────────

String gstSlabListToJson(List<GstSlabModel> list) =>
    jsonEncode(list.map((e) => e.toMap()).toList());

List<GstSlabModel> gstSlabListFromJson(String? json) {
  if (json == null || json.trim().isEmpty) return defaultGstSlabModels();
  try {
    final decoded = jsonDecode(json) as List<dynamic>;
    return decoded
        .map((e) => GstSlabModel.fromMap(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return defaultGstSlabModels();
  }
}

List<GstSlabModel> defaultGstSlabModels() =>
    TaxGstStrings.defaultGstSlabs.map((m) => GstSlabModel.fromMap(m)).toList();

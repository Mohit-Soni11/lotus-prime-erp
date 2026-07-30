import 'dart:convert';

import '../../../theme/settings/tax_gst/tax_gst_strings.dart';

class HsnCodeModel {
  final String category;
  final String hsnCode;
  final String gstRate;
  final String appliesTo;
  final String displayCode;
  final String effectiveFrom;
  final bool isActive;

  const HsnCodeModel({
    required this.category,
    required this.hsnCode,
    required this.gstRate,
    this.appliesTo = TaxGstStrings.hsnAppliesProductSale,
    this.displayCode = '',
    this.effectiveFrom = '',
    this.isActive = true,
  });

  factory HsnCodeModel.fromMap(Map<String, dynamic> map) {
    final category = map['category']?.toString() ?? '';
    final hsnCode = map['hsn']?.toString() ?? '';
    final inferred = _defaultMapForCategory(category);
    return HsnCodeModel(
      category: category,
      hsnCode: hsnCode,
      gstRate: map['rate']?.toString() ?? inferred?['rate'] ?? '3%',
      appliesTo: map['appliesTo']?.toString() ??
          map['applies_to']?.toString() ??
          inferred?['appliesTo'] ??
          TaxGstStrings.hsnAppliesProductSale,
      displayCode: map['displayCode']?.toString() ??
          map['display_code']?.toString() ??
          inferred?['displayCode'] ??
          '',
      effectiveFrom: map['effectiveFrom']?.toString() ??
          map['effective_from']?.toString() ??
          '',
      isActive: map['active'] is bool
          ? map['active'] as bool
          : (map['isActive'] is bool ? map['isActive'] as bool : true),
    );
  }

  factory HsnCodeModel.empty() => const HsnCodeModel(
        category: '',
        hsnCode: '',
        gstRate: '3%',
      );

  String get billingDisplayCode {
    final cleanDisplay = displayCode.trim();
    if (cleanDisplay.isNotEmpty) {
      return cleanDisplay;
    }
    final cleanHsn = hsnCode.trim();
    if (cleanHsn.length >= 4 && cleanHsn.startsWith('7113')) {
      return '7113';
    }
    if (cleanHsn.length >= 4) {
      return cleanHsn.substring(0, 4);
    }
    return cleanHsn;
  }

  String get normalizedCategory => category.trim().toLowerCase();

  double? get ratePercent {
    final normalized = gstRate.replaceAll('%', '').trim();
    return double.tryParse(normalized);
  }

  Map<String, dynamic> toMap() => {
        'category': category,
        'hsn': hsnCode,
        'rate': gstRate,
        'appliesTo': appliesTo,
        'displayCode': displayCode,
        'effectiveFrom': effectiveFrom,
        'active': isActive,
      };

  HsnCodeModel copyWith({
    String? category,
    String? hsnCode,
    String? gstRate,
    String? appliesTo,
    String? displayCode,
    String? effectiveFrom,
    bool? isActive,
  }) {
    return HsnCodeModel(
      category: category ?? this.category,
      hsnCode: hsnCode ?? this.hsnCode,
      gstRate: gstRate ?? this.gstRate,
      appliesTo: appliesTo ?? this.appliesTo,
      displayCode: displayCode ?? this.displayCode,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HsnCodeModel &&
          other.category == category &&
          other.hsnCode == hsnCode &&
          other.gstRate == gstRate &&
          other.appliesTo == appliesTo &&
          other.displayCode == displayCode &&
          other.effectiveFrom == effectiveFrom &&
          other.isActive == isActive;

  @override
  int get hashCode => Object.hash(
        category,
        hsnCode,
        gstRate,
        appliesTo,
        displayCode,
        effectiveFrom,
        isActive,
      );

  @override
  String toString() {
    return 'HsnCodeModel(category: $category, hsn: $hsnCode, '
        'rate: $gstRate, appliesTo: $appliesTo)';
  }
}

String hsnListToJson(List<HsnCodeModel> list) {
  return jsonEncode(list.map((entry) => entry.toMap()).toList());
}

List<HsnCodeModel> hsnListFromJson(String? json) {
  if (json == null || json.trim().isEmpty) {
    return defaultHsnCodeModels();
  }
  try {
    final decoded = jsonDecode(json) as List<dynamic>;
    final savedCodes = decoded
        .map((entry) => HsnCodeModel.fromMap(entry as Map<String, dynamic>))
        .toList();
    return _mergeMissingCoreDefaults(savedCodes);
  } catch (_) {
    return defaultHsnCodeModels();
  }
}

List<HsnCodeModel> defaultHsnCodeModels() {
  return TaxGstStrings.defaultHsnCodes
      .map((entry) => HsnCodeModel.fromMap(entry))
      .toList();
}

List<HsnCodeModel> _mergeMissingCoreDefaults(List<HsnCodeModel> savedCodes) {
  final merged = <HsnCodeModel>[];
  final consumedSavedCategories = <String>{};
  final defaults = defaultHsnCodeModels();

  for (final defaultCode in defaults) {
    HsnCodeModel? savedMatch;
    for (final savedCode in savedCodes) {
      if (savedCode.normalizedCategory == defaultCode.normalizedCategory) {
        savedMatch = savedCode;
        break;
      }
    }
    if (savedMatch == null) {
      merged.add(defaultCode);
    } else {
      merged.add(savedMatch);
      consumedSavedCategories.add(savedMatch.normalizedCategory);
    }
  }

  for (final savedCode in savedCodes) {
    if (!consumedSavedCategories.contains(savedCode.normalizedCategory)) {
      merged.add(savedCode);
    }
  }

  return merged;
}

Map<String, String>? _defaultMapForCategory(String category) {
  final normalized = category.trim().toLowerCase();
  for (final defaultCode in TaxGstStrings.defaultHsnCodes) {
    if ((defaultCode['category'] ?? '').trim().toLowerCase() == normalized) {
      return defaultCode;
    }
  }
  return null;
}

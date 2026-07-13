import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lotus_erp/features/stock/gold/domain/models/gold_purity_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoldPurityCatalogController extends ChangeNotifier {
  static const String _storageKey = 'gold_custom_purity_profiles_v1';

  static const List<GoldPurityProfile> systemProfiles = [
    GoldPurityProfile(
      id: 'gold_24kt_999',
      name: '24KT Fine Gold',
      displayValue: '24KT (999)',
      description: 'Investment grade bullion, coins and bars',
      purityPercent: 99.9,
      isSystem: true,
    ),
    GoldPurityProfile(
      id: 'gold_22kt_916',
      name: '22KT Hallmark Gold',
      displayValue: '22KT (916)',
      description: 'Standard hallmarked jewellery stock',
      purityPercent: 91.6,
      isSystem: true,
    ),
    GoldPurityProfile(
      id: 'gold_18kt_750',
      name: '18KT Studded Gold',
      displayValue: '18KT (750)',
      description: 'Diamond and gemstone jewellery',
      purityPercent: 75.0,
      isSystem: true,
    ),
    GoldPurityProfile(
      id: 'gold_14kt_585',
      name: '14KT Lightweight Gold',
      displayValue: '14KT (585)',
      description: 'Lightweight modern jewellery stock',
      purityPercent: 58.5,
      isSystem: true,
    ),
    GoldPurityProfile(
      id: 'gold_9kt_375',
      name: '9KT Low Karat Gold',
      displayValue: '9KT (375)',
      description: 'Imported, repair and low karat stock',
      purityPercent: 37.5,
      isSystem: true,
    ),
  ];

  final List<GoldPurityProfile> _customProfiles = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<GoldPurityProfile> get customProfiles =>
      List.unmodifiable(_customProfiles);

  List<GoldPurityProfile> get profiles => [
        ...systemProfiles,
        ..._customProfiles,
      ];

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_storageKey) ?? const [];
      _customProfiles
        ..clear()
        ..addAll(
          raw
              .map((entry) => jsonDecode(entry))
              .whereType<Map<String, Object?>>()
              .map(GoldPurityProfile.fromJson)
              .where((profile) => profile.id.isNotEmpty)
              .toList(growable: false),
        );
    } catch (_) {
      _customProfiles.clear();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<GoldPurityProfile?> createCustomProfile({
    required String name,
    required String karatText,
    required String hallmarkText,
    required String purityPercentText,
    required String description,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return null;
    }

    final percent = _resolvePurityPercent(
      karatText: karatText,
      hallmarkText: hallmarkText,
      purityPercentText: purityPercentText,
    );
    if (percent <= 0 || percent > 100) {
      return null;
    }

    final displayValue = _buildDisplayValue(
      karatText: karatText,
      hallmarkText: hallmarkText,
      purityPercent: percent,
    );
    final profile = GoldPurityProfile(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      name: cleanName,
      displayValue: displayValue,
      description: description.trim().isEmpty
          ? 'Custom gold purity profile'
          : description.trim(),
      purityPercent: percent,
      isSystem: false,
    );

    _customProfiles.add(profile);
    await _persist();
    notifyListeners();
    return profile;
  }

  Future<void> deleteCustomProfile(String id) async {
    _customProfiles.removeWhere((profile) => profile.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _customProfiles
        .map((profile) => jsonEncode(profile.toJson()))
        .toList(growable: false);
    await prefs.setStringList(_storageKey, encoded);
  }

  double _resolvePurityPercent({
    required String karatText,
    required String hallmarkText,
    required String purityPercentText,
  }) {
    final directPercent = _parseNumber(purityPercentText);
    if (directPercent > 0) {
      return directPercent > 100 ? directPercent / 10 : directPercent;
    }

    final hallmark = _parseNumber(hallmarkText);
    if (hallmark > 0) {
      return hallmark > 100 ? hallmark / 10 : hallmark;
    }

    final karat = _parseNumber(karatText);
    if (karat > 0) {
      return karat / 24 * 100;
    }

    return 0;
  }

  String _buildDisplayValue({
    required String karatText,
    required String hallmarkText,
    required double purityPercent,
  }) {
    final karat = _parseNumber(karatText);
    final hallmark = _parseNumber(hallmarkText);

    if (karat > 0 && hallmark > 0) {
      return '${_formatWhole(karat)}KT (${_formatWhole(hallmark)})';
    }
    if (karat > 0) {
      return '${_formatWhole(karat)}KT';
    }
    if (hallmark > 0) {
      return '${_formatWhole(hallmark)} Hallmark';
    }
    return '${_formatDecimal(purityPercent)}% Touch';
  }

  double _parseNumber(String raw) {
    final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(raw);
    return double.tryParse(match?.group(0) ?? '') ?? 0;
  }

  String _formatWhole(double value) {
    return value.roundToString();
  }

  String _formatDecimal(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

extension on double {
  String roundToString() {
    return roundToDouble() == this ? toStringAsFixed(0) : toStringAsFixed(2);
  }
}

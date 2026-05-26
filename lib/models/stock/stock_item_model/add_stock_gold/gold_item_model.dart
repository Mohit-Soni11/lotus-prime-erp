import 'package:flutter/material.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';

class GoldItemModel extends ChangeNotifier {
  static const List<String> categoryPresets = [
    'Ring',
    'Chain',
    'Bangle',
    'Bracelet',
    'Pendant / Locket',
    'Necklace / Set',
    'Earring / Jhumka',
    'Mangalsutra',
    'Nose Pin',
    'Anklet / Payal',
    'Kada',
    'Coin',
    'Bar / Bullion',
    'Other',
  ];

  static const List<String> purityPresets = [
    '24K (999)',
    '22K (916)',
    '18K (750)',
    '14K (585)',
    '9K (375)',
    'Other',
  ];

  final String id;

  final TextEditingController categoryCtrl = TextEditingController();
  final TextEditingController itemNameCtrl = TextEditingController();
  final TextEditingController piecesCtrl = TextEditingController();
  final TextEditingController huidCtrl = TextEditingController();
  final TextEditingController grossCtrl = TextEditingController();
  final TextEditingController lessCtrl = TextEditingController();
  final TextEditingController purityCtrl = TextEditingController();
  final TextEditingController wastageCtrl = TextEditingController();
  final TextEditingController rateCtrl = TextEditingController();
  final TextEditingController makingCtrl = TextEditingController();

  final FocusNode categoryFocus = FocusNode();
  final FocusNode itemNameFocus = FocusNode();
  final FocusNode piecesFocus = FocusNode();
  final FocusNode huidFocus = FocusNode();
  final FocusNode grossFocus = FocusNode();
  final FocusNode lessFocus = FocusNode();
  final FocusNode purityFocus = FocusNode();
  final FocusNode wastageFocus = FocusNode();
  final FocusNode makingFocus = FocusNode();

  MakingChargesType makingChargesType = MakingChargesType.perGram;

  GoldItemModel({
    required this.id,
    String initialPurityLabel = '',
    double initialWastagePercent = 0.0,
    double initialPurchaseRate = 0.0,
    int initialPieces = 1,
  }) {
    categoryCtrl.addListener(_fieldChanged);
    itemNameCtrl.addListener(_fieldChanged);
    piecesCtrl.addListener(_weightPurityFieldChanged);
    huidCtrl.addListener(_fieldChanged);
    grossCtrl.addListener(_weightPurityFieldChanged);
    lessCtrl.addListener(_weightPurityFieldChanged);
    purityCtrl.addListener(_weightPurityFieldChanged);
    wastageCtrl.addListener(_weightPurityFieldChanged);
    rateCtrl.addListener(_fieldChanged);
    makingCtrl.addListener(_fieldChanged);

    if (initialPieces > 0) {
      piecesCtrl.text = initialPieces.toString();
    }

    if (initialPurityLabel.trim().isNotEmpty) {
      purityCtrl.text = initialPurityLabel.trim().toUpperCase();
    }

    if (initialWastagePercent > 0) {
      wastageCtrl.text = _formatDecimal(initialWastagePercent, maxFraction: 2);
    }

    if (initialPurchaseRate > 0) {
      rateCtrl.text = _formatDecimal(initialPurchaseRate);
    }
  }

  double get grossWeight => _parseNumeric(grossCtrl.text);
  double get lessWeight => _parseNumeric(lessCtrl.text);
  double get netWeight =>
      (grossWeight - lessWeight).clamp(0.0, double.infinity);

  String get categoryLabel => categoryCtrl.text.trim();
  String get itemName => itemNameCtrl.text.trim();
  int get pieces => _parseWholeNumber(piecesCtrl.text);
  String get huid => huidCtrl.text.trim().toUpperCase();
  String get purityLabel => purityCtrl.text.trim().toUpperCase();

  double get basePurityPercent => _purityLabelToPercent(purityLabel);
  double get wastagePercent => _parseNumeric(wastageCtrl.text);
  double get totalPurityPercent => basePurityPercent + wastagePercent;
  double get effectiveTotalPurityPercent => totalPurityPercent;

  bool get hasValidTotalPurity =>
      effectiveTotalPurityPercent > 0 && effectiveTotalPurityPercent <= 100;
  String get totalPurityLabel =>
      totalPurityPercent <= 0 ? '--' : _formatDecimal(totalPurityPercent);
  String get effectiveTotalPurityLabel => effectiveTotalPurityPercent <= 0
      ? '--'
      : _formatDecimal(effectiveTotalPurityPercent);

  double get computedFineWeight => netWeight * (totalPurityPercent / 100.0);
  double get fineWeight => _roundGoldWeight(computedFineWeight);

  double get purchaseRate => _parseNumeric(rateCtrl.text);
  double get makingValue => _parseNumeric(makingCtrl.text);
  double get metalCost => fineWeight * purchaseRate;

  double get makingAmount {
    return switch (makingChargesType) {
      MakingChargesType.perGram => netWeight * makingValue,
      MakingChargesType.flat => makingValue,
      MakingChargesType.percent => metalCost * makingValue / 100.0,
    };
  }

  double get totalAmount => metalCost + makingAmount;

  bool get hasAnyInput =>
      categoryLabel.isNotEmpty ||
      itemName.isNotEmpty ||
      _hasMeaningfulPiecesInput ||
      huid.isNotEmpty ||
      grossWeight > 0 ||
      lessWeight > 0 ||
      makingValue > 0;

  bool get _hasMeaningfulPiecesInput {
    final raw = piecesCtrl.text.trim();
    if (raw.isEmpty) {
      return false;
    }
    return pieces != 1;
  }

  bool applyPurchaseRate(double rate, {bool onlyIfEmpty = true}) {
    if (rate <= 0) {
      return false;
    }
    if (onlyIfEmpty && purchaseRate > 0) {
      return false;
    }
    final next = _formatDecimal(rate);
    if (rateCtrl.text == next) {
      return false;
    }
    rateCtrl.text = next;
    rateCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: next.length),
    );
    return true;
  }

  void applyPurityDefaults(
    String purityLabel, {
    required double wastagePercent,
    bool overwriteWhenBlank = true,
  }) {
    final normalizedPurity = purityLabel.trim().toUpperCase();
    if (normalizedPurity.isNotEmpty &&
        (!overwriteWhenBlank || this.purityLabel.isEmpty)) {
      purityCtrl.text = normalizedPurity;
      purityCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: normalizedPurity.length),
      );
    }

    if (wastagePercent > 0 &&
        (!overwriteWhenBlank || wastageCtrl.text.trim().isEmpty)) {
      final text = _formatDecimal(wastagePercent, maxFraction: 2);
      wastageCtrl.text = text;
      wastageCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
    }
  }

  void toggleMakingType() {
    makingChargesType = switch (makingChargesType) {
      MakingChargesType.perGram => MakingChargesType.flat,
      MakingChargesType.flat => MakingChargesType.percent,
      MakingChargesType.percent => MakingChargesType.perGram,
    };
    notifyListeners();
  }

  String get makingTypeSymbol {
    return switch (makingChargesType) {
      MakingChargesType.perGram => '/g',
      MakingChargesType.flat => 'Flat',
      MakingChargesType.percent => '%',
    };
  }

  String get makingHint {
    return switch (makingChargesType) {
      MakingChargesType.perGram => 'Rate/g',
      MakingChargesType.flat => 'Flat Amt',
      MakingChargesType.percent => 'Rate %',
    };
  }

  void disposeAll() {
    categoryCtrl.removeListener(_fieldChanged);
    itemNameCtrl.removeListener(_fieldChanged);
    piecesCtrl.removeListener(_weightPurityFieldChanged);
    huidCtrl.removeListener(_fieldChanged);
    grossCtrl.removeListener(_weightPurityFieldChanged);
    lessCtrl.removeListener(_weightPurityFieldChanged);
    purityCtrl.removeListener(_weightPurityFieldChanged);
    wastageCtrl.removeListener(_weightPurityFieldChanged);
    rateCtrl.removeListener(_fieldChanged);
    makingCtrl.removeListener(_fieldChanged);

    categoryCtrl.dispose();
    itemNameCtrl.dispose();
    piecesCtrl.dispose();
    huidCtrl.dispose();
    grossCtrl.dispose();
    lessCtrl.dispose();
    purityCtrl.dispose();
    wastageCtrl.dispose();
    rateCtrl.dispose();
    makingCtrl.dispose();

    categoryFocus.dispose();
    itemNameFocus.dispose();
    piecesFocus.dispose();
    huidFocus.dispose();
    grossFocus.dispose();
    lessFocus.dispose();
    purityFocus.dispose();
    wastageFocus.dispose();
    makingFocus.dispose();

    dispose();
  }

  void _fieldChanged() => notifyListeners();

  void _weightPurityFieldChanged() => notifyListeners();

  double _purityLabelToPercent(String rawPurity) {
    final value = rawPurity.trim().toUpperCase();
    if (value.isEmpty) {
      return 0.0;
    }

    final hallmarkMatch =
        RegExp(r'\b(999|995|916|900|750|585|375)\b').firstMatch(value);
    if (hallmarkMatch != null) {
      final code = double.tryParse(hallmarkMatch.group(1) ?? '');
      if (code != null) {
        return code / 10.0;
      }
    }

    final karatMatch = RegExp(r'\b(24|22|18|14|9)\s*K\b').firstMatch(value);
    if (karatMatch != null) {
      final karat = double.tryParse(karatMatch.group(1) ?? '');
      if (karat != null) {
        return karat / 24.0 * 100.0;
      }
    }

    final percentMatch = RegExp(r'(\d+(?:\.\d+)?)\s*%?').firstMatch(value);
    if (percentMatch != null) {
      final parsed = double.tryParse(percentMatch.group(1) ?? '');
      if (parsed != null) {
        return parsed > 100 ? parsed / 10.0 : parsed;
      }
    }

    return 0.0;
  }

  double _parseNumeric(String raw) {
    final normalized = raw.replaceAll(',', '').trim();
    return double.tryParse(normalized) ?? 0.0;
  }

  int _parseWholeNumber(String raw) {
    final normalized = raw.replaceAll(',', '').trim();
    return int.tryParse(normalized) ?? 0;
  }

  String _formatDecimal(double value, {int maxFraction = 2}) {
    final fixed = value.toStringAsFixed(maxFraction);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  double _roundGoldWeight(double value) {
    if (value <= 0) {
      return 0.0;
    }
    return (value * 1000).roundToDouble() / 1000.0;
  }
}

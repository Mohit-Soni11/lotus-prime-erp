import 'package:flutter/material.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';

class SilverItemModel extends ChangeNotifier {
  static const List<String> categoryPresets = [
    'Anklet / Payal',
    'Bichhiya / Toe Ring',
    'Chain',
    'Bracelet',
    'Ring',
    'Bangle',
    'Kada',
    'Pendant / Locket',
    'Necklace / Set',
    'Earring / Jhumka',
    'Coin',
    'Idol / Murti',
    'Pooja Article',
    'Utensil',
    'Gift Item',
    'Other',
  ];

  static const List<String> segmentPresets = [
    'Ladies',
    'Gents',
    'Kids',
    'Religious',
    'Gift',
    'Utility',
    'Investment',
    'Company Stock',
    'Custom',
  ];

  static const List<String> purityPresets = [
    '99.99%',
    '92.50%',
    '80.00%',
    '70.00%',
    '60.00%',
    'Other',
  ];

  final String id;

  final TextEditingController categoryCtrl = TextEditingController();
  final TextEditingController segmentCtrl = TextEditingController();
  final TextEditingController itemNameCtrl = TextEditingController();
  final TextEditingController piecesCtrl = TextEditingController();
  final TextEditingController huidCtrl = TextEditingController();
  final List<TextEditingController> _extraHuidCtrls = [];
  final TextEditingController grossCtrl = TextEditingController();
  final TextEditingController lessCtrl = TextEditingController();
  final TextEditingController purityCtrl = TextEditingController();
  final TextEditingController wastageCtrl = TextEditingController();
  final TextEditingController rateCtrl = TextEditingController();
  final TextEditingController makingCtrl = TextEditingController();

  final FocusNode categoryFocus = FocusNode();
  final FocusNode segmentFocus = FocusNode();
  final FocusNode itemNameFocus = FocusNode();
  final FocusNode piecesFocus = FocusNode();
  final FocusNode huidFocus = FocusNode();
  final List<FocusNode> _extraHuidFocusNodes = [];
  final FocusNode grossFocus = FocusNode();
  final FocusNode lessFocus = FocusNode();
  final FocusNode purityFocus = FocusNode();
  final FocusNode wastageFocus = FocusNode();
  final FocusNode makingFocus = FocusNode();

  MakingChargesType makingChargesType = MakingChargesType.perGram;
  bool _fineRoundOffEnabled = false;
  double? _fineWeightOverride;

  SilverItemModel({
    required this.id,
    String initialPurityLabel = '',
    double initialWastagePercent = 0.0,
    double initialPurchaseRate = 0.0,
    int initialPieces = 1,
  }) {
    categoryCtrl.addListener(_fieldChanged);
    segmentCtrl.addListener(_fieldChanged);
    itemNameCtrl.addListener(_fieldChanged);
    piecesCtrl.addListener(_piecesFieldChanged);
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
  double get lessPerPieceWeight => _parseNumeric(lessCtrl.text);
  double get lessWeight => lessPerPieceWeight * (pieces > 0 ? pieces : 1);
  double get netWeight =>
      (grossWeight - lessWeight).clamp(0.0, double.infinity);

  String get categoryLabel => categoryCtrl.text.trim();
  String get segmentLabel => segmentCtrl.text.trim();
  String get itemName => itemNameCtrl.text.trim();
  int get pieces => _parseWholeNumber(piecesCtrl.text);
  String get huid => huidCtrl.text.trim().toUpperCase();
  List<String> get huidValues => huidControllers
      .map((controller) => controller.text.trim().toUpperCase())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  List<TextEditingController> get huidControllers =>
      List.unmodifiable([huidCtrl, ..._extraHuidCtrls]);
  List<FocusNode> get huidFocusNodes =>
      List.unmodifiable([huidFocus, ..._extraHuidFocusNodes]);
  String get purityLabel => purityCtrl.text.trim().toUpperCase();

  double get basePurityPercent => _purityLabelToPercent(purityLabel);
  double get wastagePercent => _parseNumeric(wastageCtrl.text);
  double get totalPurityPercent => basePurityPercent + wastagePercent;
  double get effectiveTotalPurityPercent {
    if (_fineWeightOverride != null && netWeight > 0) {
      return (fineWeight / netWeight * 100.0)
          .clamp(0.0, double.infinity)
          .toDouble();
    }
    return totalPurityPercent;
  }

  bool get hasValidTotalPurity =>
      effectiveTotalPurityPercent > 0 && effectiveTotalPurityPercent <= 100;
  String get totalPurityLabel =>
      totalPurityPercent <= 0 ? '--' : _formatDecimal(totalPurityPercent);
  String get effectiveTotalPurityLabel => effectiveTotalPurityPercent <= 0
      ? '--'
      : _formatDecimal(effectiveTotalPurityPercent);

  double get actualFineWeight => netWeight * (basePurityPercent / 100.0);
  double get computedValuationFineWeight =>
      netWeight * (totalPurityPercent / 100.0);
  double get valuationFineWeight =>
      _fineWeightOverride ?? computedValuationFineWeight;
  double get fineWeight => valuationFineWeight;
  bool get hasRoundedFineWeight =>
      _fineRoundOffEnabled || _fineWeightOverride != null;
  bool get hasFractionalFineWeight {
    final value = fineWeight;
    return value > 0 && (value - value.floorToDouble()).abs() > 0.0001;
  }

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
      segmentLabel.isNotEmpty ||
      itemName.isNotEmpty ||
      _hasMeaningfulPiecesInput ||
      huidValues.isNotEmpty ||
      grossWeight > 0 ||
      lessPerPieceWeight > 0 ||
      makingValue > 0;

  bool get _hasMeaningfulPiecesInput {
    final raw = piecesCtrl.text.trim();
    if (raw.isEmpty) {
      return false;
    }
    return pieces != 1;
  }

  void applyPurchaseRate(double rate, {bool onlyIfEmpty = true}) {
    if (rate <= 0) {
      return;
    }
    if (onlyIfEmpty && purchaseRate > 0) {
      return;
    }
    final next = _formatDecimal(rate);
    if (rateCtrl.text == next) {
      return;
    }
    rateCtrl.text = next;
    rateCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: next.length),
    );
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

  void roundFineWeightToNearestGram() {
    _fineRoundOffEnabled = true;
    _refreshFineRoundOff();
    notifyListeners();
  }

  void setFineRoundOffEnabled(bool enabled, {bool notify = true}) {
    if (_fineRoundOffEnabled == enabled) {
      if (enabled) {
        _refreshFineRoundOff();
      }
      return;
    }
    _fineRoundOffEnabled = enabled;
    _refreshFineRoundOff();
    if (notify) {
      notifyListeners();
    }
  }

  void _refreshFineRoundOff() {
    if (!_fineRoundOffEnabled) {
      _fineWeightOverride = null;
      return;
    }

    _fineWeightOverride = _roundClassic(computedValuationFineWeight);
  }

  double _roundClassic(double value) {
    if (value <= 0) {
      return 0.0;
    }
    final floorValue = value.floorToDouble();
    return value - floorValue >= 0.5 ? floorValue + 1 : floorValue;
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

  void syncHuidInputsWithPieces() {
    final requiredCount = pieces > 1 && pieces <= 12 ? pieces : 1;
    while (huidControllers.length < requiredCount) {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      controller.addListener(_fieldChanged);
      _extraHuidCtrls.add(controller);
      _extraHuidFocusNodes.add(focusNode);
    }

    while (huidControllers.length > requiredCount) {
      final controller = _extraHuidCtrls.removeLast();
      final focusNode = _extraHuidFocusNodes.removeLast();
      controller.removeListener(_fieldChanged);
      controller.dispose();
      focusNode.dispose();
    }
  }

  void disposeAll() {
    categoryCtrl.removeListener(_fieldChanged);
    segmentCtrl.removeListener(_fieldChanged);
    itemNameCtrl.removeListener(_fieldChanged);
    piecesCtrl.removeListener(_piecesFieldChanged);
    huidCtrl.removeListener(_fieldChanged);
    for (final controller in _extraHuidCtrls) {
      controller.removeListener(_fieldChanged);
    }
    grossCtrl.removeListener(_weightPurityFieldChanged);
    lessCtrl.removeListener(_weightPurityFieldChanged);
    purityCtrl.removeListener(_weightPurityFieldChanged);
    wastageCtrl.removeListener(_weightPurityFieldChanged);
    rateCtrl.removeListener(_fieldChanged);
    makingCtrl.removeListener(_fieldChanged);

    categoryCtrl.dispose();
    segmentCtrl.dispose();
    itemNameCtrl.dispose();
    piecesCtrl.dispose();
    huidCtrl.dispose();
    for (final controller in _extraHuidCtrls) {
      controller.dispose();
    }
    grossCtrl.dispose();
    lessCtrl.dispose();
    purityCtrl.dispose();
    wastageCtrl.dispose();
    rateCtrl.dispose();
    makingCtrl.dispose();

    categoryFocus.dispose();
    segmentFocus.dispose();
    itemNameFocus.dispose();
    piecesFocus.dispose();
    huidFocus.dispose();
    for (final focusNode in _extraHuidFocusNodes) {
      focusNode.dispose();
    }
    grossFocus.dispose();
    lessFocus.dispose();
    purityFocus.dispose();
    wastageFocus.dispose();
    makingFocus.dispose();

    dispose();
  }

  void _fieldChanged() => notifyListeners();

  void _piecesFieldChanged() {
    syncHuidInputsWithPieces();
    _refreshFineRoundOff();
    notifyListeners();
  }

  void _weightPurityFieldChanged() {
    _refreshFineRoundOff();
    notifyListeners();
  }

  double _purityLabelToPercent(String rawPurity) {
    final value = rawPurity.trim().toUpperCase();
    if (value.isEmpty) {
      return 0.0;
    }

    final hallmarkMatch = RegExp(r'\b(999|925|800|700)\b').firstMatch(value);
    if (hallmarkMatch != null) {
      final code = double.tryParse(hallmarkMatch.group(1) ?? '');
      if (code != null) {
        return code / 10.0;
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
}

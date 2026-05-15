import 'package:flutter/material.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';

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

  static const List<String> purityPresets = [
    '999',
    '925',
    '800',
    '700',
    'Other',
  ];

  final String id;

  final TextEditingController categoryCtrl = TextEditingController();
  final TextEditingController itemNameCtrl = TextEditingController();
  final TextEditingController huidCtrl = TextEditingController();
  final TextEditingController grossCtrl = TextEditingController();
  final TextEditingController lessCtrl = TextEditingController();
  final TextEditingController purityCtrl = TextEditingController();
  final TextEditingController wastageCtrl = TextEditingController();
  final TextEditingController rateCtrl = TextEditingController();
  final TextEditingController makingCtrl = TextEditingController();

  final FocusNode categoryFocus = FocusNode();
  final FocusNode itemNameFocus = FocusNode();
  final FocusNode huidFocus = FocusNode();
  final FocusNode grossFocus = FocusNode();
  final FocusNode lessFocus = FocusNode();
  final FocusNode purityFocus = FocusNode();
  final FocusNode wastageFocus = FocusNode();
  final FocusNode makingFocus = FocusNode();

  MakingChargesType makingChargesType = MakingChargesType.perGram;
  String _lastAutoWastageText = '';

  SilverItemModel({
    required this.id,
    String initialPurityLabel = '',
    double initialWastagePercent = 0.0,
    double initialPurchaseRate = 0.0,
  }) {
    categoryCtrl.addListener(_fieldChanged);
    itemNameCtrl.addListener(_fieldChanged);
    huidCtrl.addListener(_fieldChanged);
    grossCtrl.addListener(_fieldChanged);
    lessCtrl.addListener(_fieldChanged);
    purityCtrl.addListener(_handlePurityChanged);
    wastageCtrl.addListener(_fieldChanged);
    rateCtrl.addListener(_fieldChanged);
    makingCtrl.addListener(_fieldChanged);

    if (initialPurityLabel.trim().isNotEmpty) {
      purityCtrl.text = initialPurityLabel.trim().toUpperCase();
    }

    if (initialWastagePercent > 0) {
      final text = _formatDecimal(initialWastagePercent, maxFraction: 2);
      wastageCtrl.text = text;
      _lastAutoWastageText = text;
    } else {
      _syncAutoWastage(force: true);
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
  String get huid => huidCtrl.text.trim().toUpperCase();
  String get purityLabel => purityCtrl.text.trim().toUpperCase();

  double get purityPercent => _purityLabelToPercent(purityLabel);
  double get wastagePercent => _parseNumeric(wastageCtrl.text);
  double get effectiveWastagePercent {
    final percent = wastagePercent > 0 ? wastagePercent : purityPercent;
    return percent.clamp(0.0, 100.0);
  }

  double get fineWeight => netWeight * (effectiveWastagePercent / 100.0);
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
      huid.isNotEmpty ||
      grossWeight > 0 ||
      lessWeight > 0 ||
      makingValue > 0;

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
      _lastAutoWastageText = text;
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
    huidCtrl.removeListener(_fieldChanged);
    grossCtrl.removeListener(_fieldChanged);
    lessCtrl.removeListener(_fieldChanged);
    purityCtrl.removeListener(_handlePurityChanged);
    wastageCtrl.removeListener(_fieldChanged);
    rateCtrl.removeListener(_fieldChanged);
    makingCtrl.removeListener(_fieldChanged);

    categoryCtrl.dispose();
    itemNameCtrl.dispose();
    huidCtrl.dispose();
    grossCtrl.dispose();
    lessCtrl.dispose();
    purityCtrl.dispose();
    wastageCtrl.dispose();
    rateCtrl.dispose();
    makingCtrl.dispose();

    categoryFocus.dispose();
    itemNameFocus.dispose();
    huidFocus.dispose();
    grossFocus.dispose();
    lessFocus.dispose();
    purityFocus.dispose();
    wastageFocus.dispose();
    makingFocus.dispose();

    dispose();
  }

  void _fieldChanged() => notifyListeners();

  void _handlePurityChanged() {
    _syncAutoWastage();
    notifyListeners();
  }

  void _syncAutoWastage({bool force = false}) {
    final autoValue = _autoWastageTextFromPurity(purityCtrl.text);
    if (autoValue == null) {
      return;
    }

    final current = wastageCtrl.text.trim();
    if (force || current.isEmpty || current == _lastAutoWastageText) {
      if (current != autoValue) {
        wastageCtrl.text = autoValue;
        wastageCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: autoValue.length),
        );
      }
      _lastAutoWastageText = autoValue;
    } else {
      _lastAutoWastageText = autoValue;
    }
  }

  String? _autoWastageTextFromPurity(String rawPurity) {
    final percent = _purityLabelToPercent(rawPurity.trim());
    if (percent <= 0) {
      return null;
    }
    return _formatDecimal(percent, maxFraction: 2);
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

  String _formatDecimal(double value, {int maxFraction = 2}) {
    final fixed = value.toStringAsFixed(maxFraction);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

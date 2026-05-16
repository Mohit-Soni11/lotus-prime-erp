import 'package:flutter/material.dart';

enum SilverPaymentMode { metalToMetal, cash, upi, banking, card }

extension SilverPaymentModeLabel on SilverPaymentMode {
  String get label {
    return switch (this) {
      SilverPaymentMode.metalToMetal => 'Metal to Metal',
      SilverPaymentMode.cash => 'Cash',
      SilverPaymentMode.upi => 'UPI',
      SilverPaymentMode.banking => 'Bank Transfer',
      SilverPaymentMode.card => 'Credit / Debit Card',
    };
  }

  String get shortLabel {
    return switch (this) {
      SilverPaymentMode.metalToMetal => 'METAL',
      SilverPaymentMode.cash => 'CASH',
      SilverPaymentMode.upi => 'UPI',
      SilverPaymentMode.banking => 'BANK',
      SilverPaymentMode.card => 'CARD',
    };
  }

  IconData get icon {
    return switch (this) {
      SilverPaymentMode.metalToMetal => Icons.balance_rounded,
      SilverPaymentMode.cash => Icons.payments_rounded,
      SilverPaymentMode.upi => Icons.qr_code_rounded,
      SilverPaymentMode.banking => Icons.account_balance_rounded,
      SilverPaymentMode.card => Icons.credit_card_rounded,
    };
  }
}

enum DueSettleMode { asFine, asCash }

extension DueSettleModeLabel on DueSettleMode {
  String get label {
    return switch (this) {
      DueSettleMode.asFine => 'Fine Due',
      DueSettleMode.asCash => 'Cash Due',
    };
  }

  IconData get icon {
    return switch (this) {
      DueSettleMode.asFine => Icons.balance_rounded,
      DueSettleMode.asCash => Icons.currency_rupee_rounded,
    };
  }
}

enum ExcessSettleMode { returnMetal, returnCashValue }

extension ExcessSettleModeLabel on ExcessSettleMode {
  String get label {
    return switch (this) {
      ExcessSettleMode.returnMetal => 'Return Metal',
      ExcessSettleMode.returnCashValue => 'Return Value',
    };
  }

  IconData get icon {
    return switch (this) {
      ExcessSettleMode.returnMetal => Icons.reply_all_rounded,
      ExcessSettleMode.returnCashValue => Icons.currency_exchange_rounded,
    };
  }
}

class SilverPaymentController extends ChangeNotifier {
  static const double metalGstRatePercent = 5.0;
  static const double cashGstRatePercent = 3.0;

  final TextEditingController ratePerKgCtrl = TextEditingController();
  final TextEditingController metalGrossWeightCtrl = TextEditingController();
  final TextEditingController metalPurityCtrl = TextEditingController();
  final TextEditingController cashCtrl = TextEditingController();
  final TextEditingController upiCtrl = TextEditingController();
  final TextEditingController bankingCtrl = TextEditingController();
  final TextEditingController cardCtrl = TextEditingController();

  final Set<SilverPaymentMode> _enabledModes = {};

  DueSettleMode _dueSettleMode = DueSettleMode.asCash;
  ExcessSettleMode _excessSettleMode = ExcessSettleMode.returnCashValue;

  SilverPaymentController() {
    ratePerKgCtrl.addListener(_onChange);
    metalGrossWeightCtrl.addListener(_onChange);
    metalPurityCtrl.addListener(_onChange);
    cashCtrl.addListener(_onChange);
    upiCtrl.addListener(_onChange);
    bankingCtrl.addListener(_onChange);
    cardCtrl.addListener(_onChange);
  }

  void _onChange() => notifyListeners();

  double get ratePerKg => _parseNum(ratePerKgCtrl.text);
  double get ratePerGram => ratePerKg > 0 ? ratePerKg / 1000.0 : 0.0;
  bool get hasRate => ratePerGram > 0;

  String get ratePerKgDisplay =>
      hasRate ? 'Rs ${ratePerKg.toStringAsFixed(2)} / kg' : '--';

  String get ratePerGramDisplay =>
      hasRate ? 'Rs ${ratePerGram.toStringAsFixed(2)} / g' : '--';

  void seedRatePerGram(double perGram, {bool onlyIfEmpty = true}) {
    if (perGram <= 0) {
      return;
    }
    if (onlyIfEmpty && ratePerKg > 0) {
      return;
    }
    final next = _formatDecimal(perGram * 1000.0);
    if (ratePerKgCtrl.text == next) {
      return;
    }
    ratePerKgCtrl.text = next;
    ratePerKgCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: next.length),
    );
  }

  double get metalGrossWeight => _parseNum(metalGrossWeightCtrl.text);
  double get metalPurity => _parseNum(metalPurityCtrl.text);
  bool get hasMetalInput => metalGrossWeight > 0 || metalPurity > 0;

  bool get hasMetalCalculation =>
      metalGrossWeight > 0 && metalPurity > 0 && metalPurity <= 100;

  double get metalFineCalculated {
    if (!hasMetalCalculation) {
      return 0.0;
    }
    return (metalGrossWeight * metalPurity) / 100.0;
  }

  double get metalFineEquivalentCash => metalFineCalculated * ratePerGram;

  String get metalCalcHelperText {
    if (!hasMetalCalculation) {
      return '';
    }
    final fine = metalFineCalculated;
    final cash = metalFineEquivalentCash;
    final cashText = hasRate ? ' = Rs ${cash.toStringAsFixed(2)}' : '';
    return '${metalGrossWeight.toStringAsFixed(3)} g x '
        '${metalPurity.toStringAsFixed(2)}% = '
        '${fine.toStringAsFixed(3)} g fine$cashText';
  }

  bool isModeEnabled(SilverPaymentMode mode) => _enabledModes.contains(mode);

  void toggleMode(SilverPaymentMode mode) {
    if (_enabledModes.contains(mode)) {
      _enabledModes.remove(mode);
      _clearController(mode);
    } else {
      _enabledModes.add(mode);
    }
    notifyListeners();
  }

  void _clearController(SilverPaymentMode mode) {
    switch (mode) {
      case SilverPaymentMode.metalToMetal:
        metalGrossWeightCtrl.clear();
        metalPurityCtrl.clear();
      case SilverPaymentMode.cash:
        cashCtrl.clear();
      case SilverPaymentMode.upi:
        upiCtrl.clear();
      case SilverPaymentMode.banking:
        bankingCtrl.clear();
      case SilverPaymentMode.card:
        cardCtrl.clear();
    }
  }

  double get cashPaid => _parseNum(cashCtrl.text);
  double get upiPaid => _parseNum(upiCtrl.text);
  double get bankingPaid => _parseNum(bankingCtrl.text);
  double get cardPaid => _parseNum(cardCtrl.text);

  double get totalCashPaid => cashPaid + upiPaid + bankingPaid + cardPaid;
  double get totalPaidValue => metalFineEquivalentCash + totalCashPaid;

  double fineAmount(double totalFineGrams) => totalFineGrams * ratePerGram;

  double makingInclusiveSubtotal({
    required double totalFineGrams,
    required double makingAmount,
  }) {
    return fineAmount(totalFineGrams) + makingAmount;
  }

  double matchedMetalFineGrams(double totalFineGrams) {
    if (!hasMetalCalculation) {
      return 0.0;
    }
    return metalFineCalculated <= totalFineGrams
        ? metalFineCalculated
        : totalFineGrams;
  }

  double matchedMetalValue(double totalFineGrams) {
    if (!hasRate) {
      return 0.0;
    }
    return matchedMetalFineGrams(totalFineGrams) * ratePerGram;
  }

  double shortFineGrams(double totalFineGrams) {
    return _positive(totalFineGrams - metalFineCalculated);
  }

  double shortFineValue(double totalFineGrams) {
    return shortFineGrams(totalFineGrams) * ratePerGram;
  }

  double extraFineGrams(double totalFineGrams) {
    return _positive(metalFineCalculated - totalFineGrams);
  }

  double extraFineValue(double totalFineGrams) {
    return extraFineGrams(totalFineGrams) * ratePerGram;
  }

  double metalGstAmount({
    required bool gstEnabled,
    required double totalFineGrams,
  }) {
    if (!gstEnabled) {
      return 0.0;
    }
    return matchedMetalValue(totalFineGrams) * (metalGstRatePercent / 100.0);
  }

  double cashTaxableBase({
    required double totalFineGrams,
    required double makingAmount,
  }) {
    return shortFineValue(totalFineGrams) + makingAmount;
  }

  double cashGstAmount({
    required bool gstEnabled,
    required double totalFineGrams,
    required double makingAmount,
  }) {
    if (!gstEnabled) {
      return 0.0;
    }
    return cashTaxableBase(
          totalFineGrams: totalFineGrams,
          makingAmount: makingAmount,
        ) *
        (cashGstRatePercent / 100.0);
  }

  double totalBillAmount({
    required double totalFineGrams,
    required double makingAmount,
    required bool gstEnabled,
  }) {
    return makingInclusiveSubtotal(
          totalFineGrams: totalFineGrams,
          makingAmount: makingAmount,
        ) +
        metalGstAmount(gstEnabled: gstEnabled, totalFineGrams: totalFineGrams) +
        cashGstAmount(
          gstEnabled: gstEnabled,
          totalFineGrams: totalFineGrams,
          makingAmount: makingAmount,
        );
  }

  double balanceAmount({
    required double totalFineGrams,
    required double makingAmount,
    required bool gstEnabled,
  }) {
    return totalPaidValue -
        totalBillAmount(
          totalFineGrams: totalFineGrams,
          makingAmount: makingAmount,
          gstEnabled: gstEnabled,
        );
  }

  double dueAmount({
    required double totalFineGrams,
    required double makingAmount,
    required bool gstEnabled,
  }) {
    return _positive(
      -balanceAmount(
        totalFineGrams: totalFineGrams,
        makingAmount: makingAmount,
        gstEnabled: gstEnabled,
      ),
    );
  }

  double returnAmount({
    required double totalFineGrams,
    required double makingAmount,
    required bool gstEnabled,
  }) {
    return _positive(
      balanceAmount(
        totalFineGrams: totalFineGrams,
        makingAmount: makingAmount,
        gstEnabled: gstEnabled,
      ),
    );
  }

  double dueAmountAsFine({
    required double totalFineGrams,
    required double makingAmount,
    required bool gstEnabled,
  }) {
    if (!hasRate) {
      return 0.0;
    }
    return dueAmount(
          totalFineGrams: totalFineGrams,
          makingAmount: makingAmount,
          gstEnabled: gstEnabled,
        ) /
        ratePerGram;
  }

  double returnAmountAsFine({
    required double totalFineGrams,
    required double makingAmount,
    required bool gstEnabled,
  }) {
    if (!hasRate) {
      return 0.0;
    }
    return returnAmount(
          totalFineGrams: totalFineGrams,
          makingAmount: makingAmount,
          gstEnabled: gstEnabled,
        ) /
        ratePerGram;
  }

  bool hasDue({
    required double totalFineGrams,
    required double makingAmount,
    required bool gstEnabled,
  }) {
    return dueAmount(
          totalFineGrams: totalFineGrams,
          makingAmount: makingAmount,
          gstEnabled: gstEnabled,
        ) >
        0;
  }

  bool hasReturn({
    required double totalFineGrams,
    required double makingAmount,
    required bool gstEnabled,
  }) {
    return returnAmount(
          totalFineGrams: totalFineGrams,
          makingAmount: makingAmount,
          gstEnabled: gstEnabled,
        ) >
        0;
  }

  bool isSettled({
    required double totalFineGrams,
    required double makingAmount,
    required bool gstEnabled,
  }) {
    return !hasDue(
          totalFineGrams: totalFineGrams,
          makingAmount: makingAmount,
          gstEnabled: gstEnabled,
        ) &&
        !hasReturn(
          totalFineGrams: totalFineGrams,
          makingAmount: makingAmount,
          gstEnabled: gstEnabled,
        );
  }

  DueSettleMode get dueSettleMode => _dueSettleMode;

  void setDueSettleMode(DueSettleMode mode) {
    if (_dueSettleMode == mode) {
      return;
    }
    _dueSettleMode = mode;
    notifyListeners();
  }

  ExcessSettleMode get excessSettleMode => _excessSettleMode;

  void setExcessSettleMode(ExcessSettleMode mode) {
    if (_excessSettleMode == mode) {
      return;
    }
    _excessSettleMode = mode;
    notifyListeners();
  }

  SilverPaymentSnapshot buildSnapshot({
    required double totalFineGrams,
    required double makingAmount,
    required bool gstEnabled,
  }) {
    final fineBase = fineAmount(totalFineGrams);
    final matchedFine = matchedMetalFineGrams(totalFineGrams);
    final matchedValue = matchedMetalValue(totalFineGrams);
    final shortFine = shortFineGrams(totalFineGrams);
    final shortValue = shortFineValue(totalFineGrams);
    final extraFine = extraFineGrams(totalFineGrams);
    final extraValue = extraFineValue(totalFineGrams);
    final metalGst = metalGstAmount(
      gstEnabled: gstEnabled,
      totalFineGrams: totalFineGrams,
    );
    final cashGst = cashGstAmount(
      gstEnabled: gstEnabled,
      totalFineGrams: totalFineGrams,
      makingAmount: makingAmount,
    );
    final grandTotal = totalBillAmount(
      totalFineGrams: totalFineGrams,
      makingAmount: makingAmount,
      gstEnabled: gstEnabled,
    );
    final due = dueAmount(
      totalFineGrams: totalFineGrams,
      makingAmount: makingAmount,
      gstEnabled: gstEnabled,
    );
    final refund = returnAmount(
      totalFineGrams: totalFineGrams,
      makingAmount: makingAmount,
      gstEnabled: gstEnabled,
    );

    return SilverPaymentSnapshot(
      ratePerKg: ratePerKg,
      ratePerGram: ratePerGram,
      totalFineGrams: totalFineGrams,
      fineAmount: fineBase,
      makingAmount: makingAmount,
      subtotalAmount: fineBase + makingAmount,
      metalGrossWeight: metalGrossWeight,
      metalPurity: metalPurity,
      metalFineCalculated: metalFineCalculated,
      metalFineEquivalentCash: metalFineEquivalentCash,
      matchedMetalFineGrams: matchedFine,
      matchedMetalValue: matchedValue,
      shortFineGrams: shortFine,
      shortFineValue: shortValue,
      extraFineGrams: extraFine,
      extraFineValue: extraValue,
      metalGstAmount: metalGst,
      cashGstAmount: cashGst,
      cashPaid: cashPaid,
      upiPaid: upiPaid,
      bankingPaid: bankingPaid,
      cardPaid: cardPaid,
      totalCashPaid: totalCashPaid,
      totalPaidValue: totalPaidValue,
      totalBillAmount: grandTotal,
      dueAmount: due,
      returnAmount: refund,
      dueSettleMode: _dueSettleMode,
      excessSettleMode: _excessSettleMode,
      gstEnabled: gstEnabled,
    );
  }

  void reset() {
    ratePerKgCtrl.clear();
    metalGrossWeightCtrl.clear();
    metalPurityCtrl.clear();
    cashCtrl.clear();
    upiCtrl.clear();
    bankingCtrl.clear();
    cardCtrl.clear();
    _enabledModes.clear();
    _dueSettleMode = DueSettleMode.asCash;
    _excessSettleMode = ExcessSettleMode.returnCashValue;
    notifyListeners();
  }

  @override
  void dispose() {
    ratePerKgCtrl.removeListener(_onChange);
    metalGrossWeightCtrl.removeListener(_onChange);
    metalPurityCtrl.removeListener(_onChange);
    cashCtrl.removeListener(_onChange);
    upiCtrl.removeListener(_onChange);
    bankingCtrl.removeListener(_onChange);
    cardCtrl.removeListener(_onChange);

    ratePerKgCtrl.dispose();
    metalGrossWeightCtrl.dispose();
    metalPurityCtrl.dispose();
    cashCtrl.dispose();
    upiCtrl.dispose();
    bankingCtrl.dispose();
    cardCtrl.dispose();

    super.dispose();
  }

  double _parseNum(String raw) {
    final normalized = raw.replaceAll(',', '').trim();
    return double.tryParse(normalized) ?? 0.0;
  }

  String _formatDecimal(double value, {int maxFraction = 2}) {
    final fixed = value.toStringAsFixed(maxFraction);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  double _positive(double value) => value > 0 ? value : 0.0;
}

class SilverPaymentSnapshot {
  final double ratePerKg;
  final double ratePerGram;
  final double totalFineGrams;
  final double fineAmount;
  final double makingAmount;
  final double subtotalAmount;
  final double metalGrossWeight;
  final double metalPurity;
  final double metalFineCalculated;
  final double metalFineEquivalentCash;
  final double matchedMetalFineGrams;
  final double matchedMetalValue;
  final double shortFineGrams;
  final double shortFineValue;
  final double extraFineGrams;
  final double extraFineValue;
  final double metalGstAmount;
  final double cashGstAmount;
  final double cashPaid;
  final double upiPaid;
  final double bankingPaid;
  final double cardPaid;
  final double totalCashPaid;
  final double totalPaidValue;
  final double totalBillAmount;
  final double dueAmount;
  final double returnAmount;
  final DueSettleMode dueSettleMode;
  final ExcessSettleMode excessSettleMode;
  final bool gstEnabled;

  const SilverPaymentSnapshot({
    required this.ratePerKg,
    required this.ratePerGram,
    required this.totalFineGrams,
    required this.fineAmount,
    required this.makingAmount,
    required this.subtotalAmount,
    required this.metalGrossWeight,
    required this.metalPurity,
    required this.metalFineCalculated,
    required this.metalFineEquivalentCash,
    required this.matchedMetalFineGrams,
    required this.matchedMetalValue,
    required this.shortFineGrams,
    required this.shortFineValue,
    required this.extraFineGrams,
    required this.extraFineValue,
    required this.metalGstAmount,
    required this.cashGstAmount,
    required this.cashPaid,
    required this.upiPaid,
    required this.bankingPaid,
    required this.cardPaid,
    required this.totalCashPaid,
    required this.totalPaidValue,
    required this.totalBillAmount,
    required this.dueAmount,
    required this.returnAmount,
    required this.dueSettleMode,
    required this.excessSettleMode,
    required this.gstEnabled,
  });

  bool get isSettled => dueAmount <= 0 && returnAmount <= 0;
  bool get hasMetalPayment => metalFineCalculated > 0;
  bool get hasCashPayment => totalCashPaid > 0;
  bool get hasDue => dueAmount > 0;
  bool get hasReturn => returnAmount > 0;

  double get dueAmountAsFine => ratePerGram > 0 ? dueAmount / ratePerGram : 0.0;
  double get returnAmountAsFine =>
      ratePerGram > 0 ? returnAmount / ratePerGram : 0.0;

  String get ratePerKgDisplay => 'Rs ${ratePerKg.toStringAsFixed(2)} / kg';
  String get ratePerGramDisplay => 'Rs ${ratePerGram.toStringAsFixed(2)} / g';
  String get totalFineDisplay => '${totalFineGrams.toStringAsFixed(3)} g';
  String get fineAmountDisplay => 'Rs ${fineAmount.toStringAsFixed(2)}';
  String get makingDisplay => 'Rs ${makingAmount.toStringAsFixed(2)}';
  String get subtotalDisplay => 'Rs ${subtotalAmount.toStringAsFixed(2)}';
  String get totalBillDisplay => 'Rs ${totalBillAmount.toStringAsFixed(2)}';
  String get totalPaidDisplay => 'Rs ${totalPaidValue.toStringAsFixed(2)}';
  String get dueDisplay => 'Rs ${dueAmount.toStringAsFixed(2)}';
  String get returnDisplay => 'Rs ${returnAmount.toStringAsFixed(2)}';
}

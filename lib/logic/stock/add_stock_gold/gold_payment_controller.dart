import 'package:flutter/material.dart';

enum PaymentMode { metalToMetal, cash }

enum TaxMode { estimate, gst }

enum DueReturnType { metal, cash }

enum GoldDiscountMode { fine, cash }

class GoldMetalSettlementLine extends ChangeNotifier {
  final String id;
  final TextEditingController grossCtrl = TextEditingController();
  final TextEditingController purityCtrl = TextEditingController();
  bool _syncingText = false;

  GoldMetalSettlementLine({required this.id}) {
    grossCtrl.addListener(_handleInputChanged);
    purityCtrl.addListener(_handleInputChanged);
  }

  double get grossWeight => _parseAmount(grossCtrl.text);
  double get purity =>
      _parseAmount(purityCtrl.text).clamp(0.0, 100.0).toDouble();
  double get computedFineWeight => grossWeight * (purity / 100.0);
  double get fineWeight => computedFineWeight;
  bool get hasInput => grossWeight > 0 || purity > 0;

  void setValues(double grossWeight, double purity) {
    _syncText(grossCtrl, _formatNumber(grossWeight, maxFraction: 3));
    _syncText(purityCtrl, _formatNumber(purity, maxFraction: 2));
    notifyListeners();
  }

  Map<String, double> toPayload() {
    return {
      'grossWeight': grossWeight,
      'purity': purity,
      'fineWeight': fineWeight,
    };
  }

  void _handleInputChanged() {
    if (_syncingText) {
      return;
    }
    notifyListeners();
  }

  void _syncText(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    _syncingText = true;
    controller.text = value;
    controller.selection = TextSelection.collapsed(offset: value.length);
    _syncingText = false;
  }

  double _parseAmount(String raw) {
    final normalized =
        raw.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0.0;
  }

  String _formatNumber(double value, {required int maxFraction}) {
    if (value <= 0) {
      return '';
    }
    final fixed = value.toStringAsFixed(maxFraction);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void disposeAll() {
    grossCtrl.removeListener(_handleInputChanged);
    purityCtrl.removeListener(_handleInputChanged);
    grossCtrl.dispose();
    purityCtrl.dispose();
    dispose();
  }
}

extension PaymentModeLabel on PaymentMode {
  String get label {
    return switch (this) {
      PaymentMode.metalToMetal => 'Metal to Metal',
      PaymentMode.cash => 'Cash / Bank',
    };
  }
}

extension DueReturnTypeLabel on DueReturnType {
  String dueLabel(bool isMetalMode) {
    if (!isMetalMode) {
      return 'Cash Due';
    }
    return switch (this) {
      DueReturnType.metal => 'Fine Due',
      DueReturnType.cash => 'Cash Due',
    };
  }

  String returnLabel(bool isMetalMode) {
    if (!isMetalMode) {
      return 'Cash Return';
    }
    return switch (this) {
      DueReturnType.metal => 'Fine Return',
      DueReturnType.cash => 'Value Return',
    };
  }
}

class GoldPaymentController extends ChangeNotifier {
  static const double metalGstRatePercent = 5.0;
  static const double cashGstRatePercent = 3.0;
  static const double _epsilon = 0.005;

  final TextEditingController todayRatePer10gCtrl = TextEditingController();
  final TextEditingController metalGstPercentCtrl = TextEditingController(
    text: '5',
  );
  final TextEditingController cashGstPercentCtrl = TextEditingController(
    text: '3',
  );
  final TextEditingController cashCtrl = TextEditingController();
  final TextEditingController upiCtrl = TextEditingController();
  final TextEditingController bankCtrl = TextEditingController();
  final TextEditingController cardCtrl = TextEditingController();
  final TextEditingController previousDueAdjustmentCtrl =
      TextEditingController();
  final TextEditingController discountCtrl = TextEditingController();

  double _todayRatePer10g = 0.0;
  double _totalFineFromItems = 0.0;
  double _totalMakingFromItems = 0.0;
  double _supplierPreviousDue = 0.0;
  bool _gstEnabled = false;
  PaymentMode _paymentMode = PaymentMode.metalToMetal;
  DueReturnType _metalDueReturnType = DueReturnType.cash;
  GoldDiscountMode _discountMode = GoldDiscountMode.fine;
  DateTime? _promiseDate;
  bool _adjustPreviousDue = false;
  bool _syncingText = false;
  final List<GoldMetalSettlementLine> _metalLines = [];

  GoldPaymentController() {
    todayRatePer10gCtrl.addListener(_handleRateChanged);
    metalGstPercentCtrl.addListener(_handleInputChanged);
    cashGstPercentCtrl.addListener(_handleInputChanged);
    cashCtrl.addListener(_handleInputChanged);
    upiCtrl.addListener(_handleInputChanged);
    bankCtrl.addListener(_handleInputChanged);
    cardCtrl.addListener(_handleInputChanged);
    previousDueAdjustmentCtrl.addListener(_handleInputChanged);
    discountCtrl.addListener(_handleInputChanged);
  }

  double get todayRatePer10g => _todayRatePer10g;
  double get todayRatePerGram =>
      _todayRatePer10g > 0 ? _todayRatePer10g / 10.0 : 0.0;

  double get grossFineFromItems => _totalFineFromItems;
  double get totalFineFromItems => discountedFineFromItems;
  double get totalMakingFromItems => _totalMakingFromItems;
  GoldDiscountMode get discountMode => _discountMode;
  double get discountInput => _parseAmount(discountCtrl.text);
  double get fineDiscountWeight {
    if (_discountMode != GoldDiscountMode.fine) {
      return 0.0;
    }
    return discountInput.clamp(0.0, _totalFineFromItems).toDouble();
  }

  double get discountedFineFromItems =>
      (_totalFineFromItems - fineDiscountWeight)
          .clamp(0.0, double.infinity)
          .toDouble();
  double get fineValueBeforeCashDiscount =>
      discountedFineFromItems * todayRatePerGram;
  double get cashDiscountAmount {
    if (_discountMode != GoldDiscountMode.cash) {
      return 0.0;
    }
    final preDiscount = fineValueBeforeCashDiscount + _totalMakingFromItems;
    return discountInput.clamp(0.0, preDiscount).toDouble();
  }

  bool get hasDiscount =>
      fineDiscountWeight > _epsilon || cashDiscountAmount > _epsilon;

  bool get gstEnabled => _gstEnabled;
  TaxMode get taxMode => _gstEnabled ? TaxMode.gst : TaxMode.estimate;
  PaymentMode get paymentMode => _paymentMode;
  DueReturnType get metalDueReturnType => _metalDueReturnType;
  List<GoldMetalSettlementLine> get metalLines =>
      List.unmodifiable(_metalLines);

  double get metalGivenWeight =>
      _metalLines.fold(0.0, (sum, line) => sum + line.grossWeight);
  double get metalGivenPurity =>
      metalGivenWeight > 0 ? fineReceived / metalGivenWeight * 100.0 : 0.0;

  double get cashPaid => _parseAmount(cashCtrl.text);
  double get upiPaid => _parseAmount(upiCtrl.text);
  double get bankPaid => _parseAmount(bankCtrl.text);
  double get cardPaid => _parseAmount(cardCtrl.text);
  double get metalGstPercent => _boundedPercent(
        _parseAmount(metalGstPercentCtrl.text),
        fallback: metalGstRatePercent,
      );
  double get cashGstPercent => _boundedPercent(
        _parseAmount(cashGstPercentCtrl.text),
        fallback: cashGstRatePercent,
      );
  double get amountPaid => cashPaid;
  double get cashBankPaidTotal => cashPaid + upiPaid + bankPaid + cardPaid;
  double get supplierPreviousDue => _supplierPreviousDue;
  bool get hasSupplierPreviousDue => _supplierPreviousDue > _epsilon;
  bool get adjustPreviousDue => _adjustPreviousDue;
  double get previousDueAdjustment {
    if (!_adjustPreviousDue || !hasSupplierPreviousDue) {
      return 0.0;
    }
    return _parseAmount(previousDueAdjustmentCtrl.text)
        .clamp(0.0, _supplierPreviousDue)
        .toDouble();
  }

  double get previousDueFineEquivalent =>
      todayRatePerGram > 0 ? previousDueAdjustment / todayRatePerGram : 0.0;

  double get fineValueAmount => fineValueBeforeCashDiscount;
  double get subTotalAmount =>
      (fineValueAmount + _totalMakingFromItems - cashDiscountAmount)
          .clamp(0.0, double.infinity)
          .toDouble();

  double get taxPercentage {
    if (!_gstEnabled) {
      return 0.0;
    }
    return _paymentMode == PaymentMode.metalToMetal
        ? metalGstPercent
        : cashGstPercent;
  }

  double get taxAmount => subTotalAmount * (taxPercentage / 100.0);
  double get finalBillAmount => subTotalAmount + taxAmount;

  double get fineReceived {
    if (_paymentMode != PaymentMode.metalToMetal) {
      return 0.0;
    }
    return _metalLines.fold(0.0, (sum, line) => sum + line.fineWeight);
  }

  double get fineDifference => fineReceived - totalFineFromItems;
  bool get isExtraMetal => fineDifference > _epsilon;
  bool get isDueMetal => fineDifference < -_epsilon;
  double get fineShortage => isDueMetal ? fineDifference.abs() : 0.0;
  double get fineExcess => isExtraMetal ? fineDifference : 0.0;
  double get differenceInCashValue => fineDifference.abs() * todayRatePerGram;
  double get fineShortageValue => fineShortage * todayRatePerGram;
  double get fineExcessValue => fineExcess * todayRatePerGram;
  double get metalReceivedValue => fineReceived * todayRatePerGram;
  double get metalAppliedFine {
    if (_paymentMode != PaymentMode.metalToMetal) {
      return 0.0;
    }
    return fineReceived.clamp(0.0, totalFineFromItems).toDouble();
  }

  double get metalAppliedValue => metalAppliedFine * todayRatePerGram;
  double get cashDueBeforePayment => (cashTargetAmount - cashBankPaidTotal)
      .clamp(0.0, double.infinity)
      .toDouble();
  DateTime? get promiseDate => _promiseDate;

  double get cashTargetAmount {
    if (_paymentMode == PaymentMode.cash) {
      return finalBillAmount + previousDueAdjustment;
    }

    final shortageAsCash =
        isDueMetal && _metalDueReturnType == DueReturnType.cash
            ? fineShortageValue
            : 0.0;
    return (_totalMakingFromItems +
            taxAmount +
            shortageAsCash +
            previousDueAdjustment -
            cashDiscountAmount)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  double get cashBalance => cashBankPaidTotal - cashTargetAmount;

  double get totalPaidValue {
    if (_paymentMode == PaymentMode.cash) {
      return cashBankPaidTotal;
    }
    return (metalAppliedValue + cashBankPaidTotal)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  double get dueAmount {
    if (_paymentMode == PaymentMode.cash) {
      return (cashTargetAmount - cashBankPaidTotal)
          .clamp(0.0, double.infinity)
          .toDouble();
    }

    final cashDue = (cashTargetAmount - cashBankPaidTotal)
        .clamp(0.0, double.infinity)
        .toDouble();
    final metalDueValue =
        isDueMetal && _metalDueReturnType == DueReturnType.metal
            ? fineShortageValue
            : 0.0;
    return cashDue + metalDueValue;
  }

  double get returnAmount {
    if (_paymentMode == PaymentMode.cash) {
      return (cashBankPaidTotal - cashTargetAmount)
          .clamp(0.0, double.infinity)
          .toDouble();
    }

    final cashOverpay = (cashBankPaidTotal - cashTargetAmount)
        .clamp(0.0, double.infinity)
        .toDouble();
    return cashOverpay + fineExcessValue;
  }

  bool get hasDue => dueAmount > _epsilon;
  bool get hasReturn => returnAmount > _epsilon;
  bool get isSettled => !hasDue && !hasReturn && finalBillAmount > 0;

  String get balanceLabel {
    if (hasReturn) {
      return _metalDueReturnType.returnLabel(
        _paymentMode == PaymentMode.metalToMetal,
      );
    }
    if (hasDue) {
      return _metalDueReturnType.dueLabel(
        _paymentMode == PaymentMode.metalToMetal,
      );
    }
    return 'Settled';
  }

  void updateInvoiceSummary({
    required double fine,
    required double making,
    bool notify = true,
  }) {
    final nextFine = fine < 0 ? 0.0 : fine;
    final nextMaking = making < 0 ? 0.0 : making;
    if (_near(_totalFineFromItems, nextFine) &&
        _near(_totalMakingFromItems, nextMaking)) {
      return;
    }
    _totalFineFromItems = nextFine;
    _totalMakingFromItems = nextMaking;
    if (notify) {
      notifyListeners();
    }
  }

  void syncGstEnabled(bool enabled, {bool notify = true}) {
    if (_gstEnabled == enabled) {
      return;
    }
    _gstEnabled = enabled;
    if (notify) {
      notifyListeners();
    }
  }

  void setTodayRatePer10g(double rate, {bool notify = true}) {
    final next = rate < 0 ? 0.0 : rate;
    if (_near(_todayRatePer10g, next)) {
      _syncText(todayRatePer10gCtrl, _formatNumber(next, maxFraction: 2));
      return;
    }
    _todayRatePer10g = next;
    _syncText(todayRatePer10gCtrl, _formatNumber(next, maxFraction: 2));
    if (notify) {
      notifyListeners();
    }
  }

  void setPaymentMode(PaymentMode mode) {
    if (_paymentMode == mode) {
      return;
    }
    _paymentMode = mode;
    notifyListeners();
  }

  void setDiscountMode(GoldDiscountMode mode) {
    if (_discountMode == mode) {
      return;
    }
    _discountMode = mode;
    notifyListeners();
  }

  void setMetalInput(double weight, double purity) {
    if (_metalLines.isEmpty) {
      addMetalLine(notify: false);
    }
    _metalLines.first.setValues(weight, purity);
    notifyListeners();
  }

  void addMetalLine({bool notify = true}) {
    final line = GoldMetalSettlementLine(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
    );
    line.addListener(_handleInputChanged);
    _metalLines.add(line);
    if (notify) {
      notifyListeners();
    }
  }

  void removeMetalLine(String id) {
    final index = _metalLines.indexWhere((line) => line.id == id);
    if (index == -1) {
      return;
    }
    final line = _metalLines.removeAt(index);
    line.removeListener(_handleInputChanged);
    line.disposeAll();
    notifyListeners();
  }

  List<Map<String, double>> get metalLinePayloads => _metalLines
      .where((line) => line.hasInput)
      .map((line) => line.toPayload())
      .toList(growable: false);

  void setSupplierPreviousDue(double amount) {
    final next = amount < 0 ? 0.0 : amount;
    _supplierPreviousDue = next;
    if (next <= _epsilon) {
      _adjustPreviousDue = false;
      _syncText(previousDueAdjustmentCtrl, '');
    } else if (_adjustPreviousDue &&
        (previousDueAdjustment <= 0 || previousDueAdjustment > next)) {
      _syncText(previousDueAdjustmentCtrl, _formatNumber(next, maxFraction: 2));
    }
    notifyListeners();
  }

  void setAdjustPreviousDue(bool value) {
    if (!hasSupplierPreviousDue) {
      value = false;
    }
    _adjustPreviousDue = value;
    if (value && previousDueAdjustmentCtrl.text.trim().isEmpty) {
      _syncText(
        previousDueAdjustmentCtrl,
        _formatNumber(_supplierPreviousDue, maxFraction: 2),
      );
    }
    notifyListeners();
  }

  void setMetalDueReturnType(DueReturnType type) {
    if (_metalDueReturnType == type) {
      return;
    }
    _metalDueReturnType = type;
    notifyListeners();
  }

  void setAmountPaid(double amount) {
    _syncText(cashCtrl, _formatNumber(amount, maxFraction: 2));
    notifyListeners();
  }

  void setPromiseDate(DateTime? value) {
    final current = _promiseDate;
    final isSameDay = current?.year == value?.year &&
        current?.month == value?.month &&
        current?.day == value?.day;
    if (isSameDay) {
      return;
    }
    _promiseDate = value;
    notifyListeners();
  }

  void resetSettlement() {
    _paymentMode = PaymentMode.metalToMetal;
    _metalDueReturnType = DueReturnType.cash;
    _promiseDate = null;
    for (final line in _metalLines) {
      line.removeListener(_handleInputChanged);
      line.disposeAll();
    }
    _metalLines.clear();
    _syncText(metalGstPercentCtrl, '5');
    _syncText(cashGstPercentCtrl, '3');
    _syncText(cashCtrl, '');
    _syncText(upiCtrl, '');
    _syncText(bankCtrl, '');
    _syncText(cardCtrl, '');
    _discountMode = GoldDiscountMode.fine;
    _syncText(discountCtrl, '');
    _adjustPreviousDue = false;
    _syncText(previousDueAdjustmentCtrl, '');
    notifyListeners();
  }

  void _handleRateChanged() {
    if (_syncingText) {
      return;
    }
    _todayRatePer10g = _parseAmount(todayRatePer10gCtrl.text);
    notifyListeners();
  }

  void _handleInputChanged() {
    if (_syncingText) {
      return;
    }
    notifyListeners();
  }

  void _syncText(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    _syncingText = true;
    controller.text = value;
    controller.selection = TextSelection.collapsed(offset: value.length);
    _syncingText = false;
  }

  double _parseAmount(String raw) {
    final normalized =
        raw.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0.0;
  }

  String _formatNumber(double value, {required int maxFraction}) {
    if (value <= 0) {
      return '';
    }
    final fixed = value.toStringAsFixed(maxFraction);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  bool _near(double left, double right) => (left - right).abs() < 0.0001;

  double _boundedPercent(double value, {required double fallback}) {
    final next = value <= 0 ? fallback : value;
    return next.clamp(0.0, 100.0).toDouble();
  }

  @override
  void dispose() {
    todayRatePer10gCtrl.dispose();
    for (final line in _metalLines) {
      line.removeListener(_handleInputChanged);
      line.disposeAll();
    }
    _metalLines.clear();
    metalGstPercentCtrl.dispose();
    cashGstPercentCtrl.dispose();
    cashCtrl.dispose();
    upiCtrl.dispose();
    bankCtrl.dispose();
    cardCtrl.dispose();
    previousDueAdjustmentCtrl.dispose();
    discountCtrl.dispose();
    super.dispose();
  }
}

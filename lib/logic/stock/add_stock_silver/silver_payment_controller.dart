import 'package:flutter/material.dart';

enum PaymentMode { metalToMetal, cash }

enum TaxMode { estimate, gst }

enum DueReturnType { metal, cash }

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

class SilverPaymentController extends ChangeNotifier {
  static const double metalGstRatePercent = 5.0;
  static const double cashGstRatePercent = 3.0;
  static const double _epsilon = 0.005;

  final TextEditingController todayRatePerKgCtrl = TextEditingController();
  final TextEditingController metalGrossCtrl = TextEditingController();
  final TextEditingController metalPurityCtrl = TextEditingController();
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

  double _todayRatePerKg = 0.0;
  double _totalFineFromItems = 0.0;
  double _totalMakingFromItems = 0.0;
  bool _gstEnabled = false;
  PaymentMode _paymentMode = PaymentMode.metalToMetal;
  DueReturnType _metalDueReturnType = DueReturnType.cash;
  DateTime? _promiseDate;
  bool _syncingText = false;

  SilverPaymentController() {
    todayRatePerKgCtrl.addListener(_handleRateChanged);
    metalGrossCtrl.addListener(_handleInputChanged);
    metalPurityCtrl.addListener(_handleInputChanged);
    metalGstPercentCtrl.addListener(_handleInputChanged);
    cashGstPercentCtrl.addListener(_handleInputChanged);
    cashCtrl.addListener(_handleInputChanged);
    upiCtrl.addListener(_handleInputChanged);
    bankCtrl.addListener(_handleInputChanged);
    cardCtrl.addListener(_handleInputChanged);
  }

  double get todayRatePerKg => _todayRatePerKg;
  double get todayRatePerGram =>
      _todayRatePerKg > 0 ? _todayRatePerKg / 1000 : 0.0;

  double get totalFineFromItems => _totalFineFromItems;
  double get totalMakingFromItems => _totalMakingFromItems;

  bool get gstEnabled => _gstEnabled;
  TaxMode get taxMode => _gstEnabled ? TaxMode.gst : TaxMode.estimate;
  PaymentMode get paymentMode => _paymentMode;
  DueReturnType get metalDueReturnType => _metalDueReturnType;

  double get metalGivenWeight => _parseAmount(metalGrossCtrl.text);
  double get metalGivenPurity =>
      _parseAmount(metalPurityCtrl.text).clamp(0.0, 100.0).toDouble();

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

  double get fineValueAmount => _totalFineFromItems * todayRatePerGram;
  double get subTotalAmount => fineValueAmount + _totalMakingFromItems;

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
    return metalGivenWeight * (metalGivenPurity / 100.0);
  }

  double get fineDifference => fineReceived - _totalFineFromItems;
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
    return fineReceived.clamp(0.0, _totalFineFromItems).toDouble();
  }

  double get metalAppliedValue => metalAppliedFine * todayRatePerGram;
  double get cashDueBeforePayment => (cashTargetAmount - cashBankPaidTotal)
      .clamp(0.0, double.infinity)
      .toDouble();
  DateTime? get promiseDate => _promiseDate;

  double get cashTargetAmount {
    if (_paymentMode == PaymentMode.cash) {
      return finalBillAmount;
    }

    final shortageAsCash =
        isDueMetal && _metalDueReturnType == DueReturnType.cash
            ? fineShortageValue
            : 0.0;
    return _totalMakingFromItems + taxAmount + shortageAsCash;
  }

  double get cashBalance => cashBankPaidTotal - cashTargetAmount;

  double get totalPaidValue {
    if (_paymentMode == PaymentMode.cash) {
      return cashBankPaidTotal;
    }

    final metalDueValue =
        isDueMetal && _metalDueReturnType == DueReturnType.metal
            ? fineShortageValue
            : 0.0;
    return (finalBillAmount - dueAmount + returnAmount - metalDueValue)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  double get dueAmount {
    if (_paymentMode == PaymentMode.cash) {
      return (finalBillAmount - cashBankPaidTotal)
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
      return (cashBankPaidTotal - finalBillAmount)
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

  void setTodayRate(double rate, {bool notify = true}) {
    final next = rate < 0 ? 0.0 : rate;
    if (_near(_todayRatePerKg, next)) {
      _syncText(todayRatePerKgCtrl, _formatNumber(next, maxFraction: 2));
      return;
    }
    _todayRatePerKg = next;
    _syncText(todayRatePerKgCtrl, _formatNumber(next, maxFraction: 2));
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

  void setMetalInput(double weight, double purity) {
    _syncText(metalGrossCtrl, _formatNumber(weight, maxFraction: 3));
    _syncText(metalPurityCtrl, _formatNumber(purity, maxFraction: 2));
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
    _syncText(metalGrossCtrl, '');
    _syncText(metalPurityCtrl, '');
    _syncText(metalGstPercentCtrl, '5');
    _syncText(cashGstPercentCtrl, '3');
    _syncText(cashCtrl, '');
    _syncText(upiCtrl, '');
    _syncText(bankCtrl, '');
    _syncText(cardCtrl, '');
    notifyListeners();
  }

  void _handleRateChanged() {
    if (_syncingText) {
      return;
    }
    _todayRatePerKg = _parseAmount(todayRatePerKgCtrl.text);
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
    todayRatePerKgCtrl.dispose();
    metalGrossCtrl.dispose();
    metalPurityCtrl.dispose();
    metalGstPercentCtrl.dispose();
    cashGstPercentCtrl.dispose();
    cashCtrl.dispose();
    upiCtrl.dispose();
    bankCtrl.dispose();
    cardCtrl.dispose();
    super.dispose();
  }
}

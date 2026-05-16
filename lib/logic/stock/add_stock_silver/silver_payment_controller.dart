// =============================================================================
// FILE        : silver_payment_controller.dart
// MODULE      : Stock & Inventory — Silver
// LAYER       : Logic / Payment
// DESCRIPTION : Payment Record logic for Silver Add Stock.
//
//   ✅ Rate per KG input → auto-converts to per gram
//   ✅ Total Bill Amount = totalFine × ratePerGram
//   ✅ Payment Modes:
//        — Metal to Metal  (fine in grams → equivalent cash)
//        — Cash
//        — UPI
//        — Banking Transfer
//        — Credit Card
//   ✅ Due Amount = totalBillAmount − totalPaid
//   ✅ Full lifecycle: init, reset, dispose
//
// HOW TO USE:
//   1. Create in SilverStockController:
//        final payment = SilverPaymentController();
//   2. In dispose():
//        payment.dispose();
//   3. In resetForNewBatch():
//        payment.reset();
//   4. Pass to SilverPaymentRecordCard:
//        SilverPaymentRecordCard(ctrl: _ctrl, payment: _ctrl.payment)
// =============================================================================

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT MODE ENUM
// ─────────────────────────────────────────────────────────────────────────────

enum SilverPaymentMode {
  metalToMetal,
  cash,
  upi,
  banking,
  card,
}

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

// ─────────────────────────────────────────────────────────────────────────────
// SILVER PAYMENT CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────

class SilverPaymentController extends ChangeNotifier {
  // ── RATE INPUT ────────────────────────────────────────────────────────────
  /// Operator enters rate in ₹/kg  (e.g. 90000 for ₹90,000 per kg).
  final TextEditingController ratePerKgCtrl = TextEditingController();

  // ── PAYMENT MODE CONTROLLERS ──────────────────────────────────────────────

  /// Metal to Metal — fine given in grams.
  final TextEditingController metalFineCtrl = TextEditingController();

  /// Cash paid — in ₹.
  final TextEditingController cashCtrl = TextEditingController();

  /// UPI paid — in ₹.
  final TextEditingController upiCtrl = TextEditingController();

  /// Banking / NEFT / RTGS / IMPS — in ₹.
  final TextEditingController bankingCtrl = TextEditingController();

  /// Credit / Debit card — in ₹.
  final TextEditingController cardCtrl = TextEditingController();

  // ── ENABLED PAYMENT MODES ─────────────────────────────────────────────────
  final Set<SilverPaymentMode> _enabledModes = {};

  SilverPaymentController() {
    ratePerKgCtrl.addListener(_onChange);
    metalFineCtrl.addListener(_onChange);
    cashCtrl.addListener(_onChange);
    upiCtrl.addListener(_onChange);
    bankingCtrl.addListener(_onChange);
    cardCtrl.addListener(_onChange);
  }

  void _onChange() => notifyListeners();

  // ─────────────────────────────────────────────────────────────────────────
  // RATE COMPUTED GETTERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Rate per KG as entered by the operator.
  double get ratePerKg => _parseNum(ratePerKgCtrl.text);

  /// Converted rate per gram (ratePerKg ÷ 1000).
  double get ratePerGram => ratePerKg > 0 ? ratePerKg / 1000.0 : 0.0;

  /// Whether a valid rate has been entered.
  bool get hasRate => ratePerGram > 0;

  /// Display string for rate per gram.
  String get ratePerGramDisplay =>
      hasRate ? '₹ ${ratePerGram.toStringAsFixed(2)} / g' : '—';

  // ─────────────────────────────────────────────────────────────────────────
  // BILL AMOUNT COMPUTED FROM FINE
  // ─────────────────────────────────────────────────────────────────────────

  /// Total bill amount = totalFineWeight (grams) × ratePerGram.
  /// Pass totalFineWeight from SilverStockController.
  double totalBillAmount(double totalFineGrams) => totalFineGrams * ratePerGram;

  /// Display string for total bill amount.
  String totalBillAmountDisplay(double totalFineGrams) {
    if (!hasRate) return '—';
    return '₹ ${totalBillAmount(totalFineGrams).toStringAsFixed(2)}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAYMENT MODE TOGGLE
  // ─────────────────────────────────────────────────────────────────────────

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
        metalFineCtrl.clear();
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

  // ─────────────────────────────────────────────────────────────────────────
  // PAYMENT AMOUNTS
  // ─────────────────────────────────────────────────────────────────────────

  /// Fine given in grams (Metal to Metal).
  double get metalFineGiven => _parseNum(metalFineCtrl.text);

  /// Cash equivalent of metal fine given = metalFineGiven × ratePerGram.
  double get metalFineEquivalentCash => metalFineGiven * ratePerGram;

  double get cashPaid => _parseNum(cashCtrl.text);
  double get upiPaid => _parseNum(upiCtrl.text);
  double get bankingPaid => _parseNum(bankingCtrl.text);
  double get cardPaid => _parseNum(cardCtrl.text);

  /// Total of all cash-equivalent payments.
  double get totalCashPaid => cashPaid + upiPaid + bankingPaid + cardPaid;

  /// Total paid = metal fine (in cash equiv) + all cash modes.
  double get totalPaid => metalFineEquivalentCash + totalCashPaid;

  /// Due amount = total bill − total paid.
  double dueAmount(double totalFineGrams) =>
      (totalBillAmount(totalFineGrams) - totalPaid).clamp(0.0, double.infinity);

  /// Whether there is any remaining due.
  bool hasDue(double totalFineGrams) => dueAmount(totalFineGrams) > 0;

  /// Whether payment is fully settled.
  bool isSettled(double totalFineGrams) => dueAmount(totalFineGrams) == 0;

  // ─────────────────────────────────────────────────────────────────────────
  // PAYMENT SUMMARY SNAPSHOT
  // ─────────────────────────────────────────────────────────────────────────

  SilverPaymentSnapshot buildSnapshot(double totalFineGrams) {
    final bill = totalBillAmount(totalFineGrams);
    return SilverPaymentSnapshot(
      ratePerKg: ratePerKg,
      ratePerGram: ratePerGram,
      totalFineGrams: totalFineGrams,
      totalBillAmount: bill,
      metalFineGiven: metalFineGiven,
      metalFineEquivalentCash: metalFineEquivalentCash,
      cashPaid: cashPaid,
      upiPaid: upiPaid,
      bankingPaid: bankingPaid,
      cardPaid: cardPaid,
      totalPaid: totalPaid,
      dueAmount: (bill - totalPaid).clamp(0.0, double.infinity),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────────

  /// Reset all payment fields (call on new batch).
  void reset() {
    ratePerKgCtrl.clear();
    metalFineCtrl.clear();
    cashCtrl.clear();
    upiCtrl.clear();
    bankingCtrl.clear();
    cardCtrl.clear();
    _enabledModes.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    ratePerKgCtrl.removeListener(_onChange);
    metalFineCtrl.removeListener(_onChange);
    cashCtrl.removeListener(_onChange);
    upiCtrl.removeListener(_onChange);
    bankingCtrl.removeListener(_onChange);
    cardCtrl.removeListener(_onChange);

    ratePerKgCtrl.dispose();
    metalFineCtrl.dispose();
    cashCtrl.dispose();
    upiCtrl.dispose();
    bankingCtrl.dispose();
    cardCtrl.dispose();

    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  double _parseNum(String raw) {
    final normalized = raw.replaceAll(',', '').trim();
    return double.tryParse(normalized) ?? 0.0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT SNAPSHOT  (immutable — passed to UI / persistence)
// ─────────────────────────────────────────────────────────────────────────────

class SilverPaymentSnapshot {
  final double ratePerKg;
  final double ratePerGram;
  final double totalFineGrams;
  final double totalBillAmount;
  final double metalFineGiven;
  final double metalFineEquivalentCash;
  final double cashPaid;
  final double upiPaid;
  final double bankingPaid;
  final double cardPaid;
  final double totalPaid;
  final double dueAmount;

  const SilverPaymentSnapshot({
    required this.ratePerKg,
    required this.ratePerGram,
    required this.totalFineGrams,
    required this.totalBillAmount,
    required this.metalFineGiven,
    required this.metalFineEquivalentCash,
    required this.cashPaid,
    required this.upiPaid,
    required this.bankingPaid,
    required this.cardPaid,
    required this.totalPaid,
    required this.dueAmount,
  });

  bool get isSettled => dueAmount <= 0;
  bool get hasMetalPayment => metalFineGiven > 0;
  bool get hasCashPayment => cashPaid > 0;
  bool get hasUpiPayment => upiPaid > 0;
  bool get hasBankingPayment => bankingPaid > 0;
  bool get hasCardPayment => cardPaid > 0;

  // ── FORMATTED DISPLAY HELPERS ──────────────────────────────────────────────
  String get ratePerKgDisplay => '₹ ${ratePerKg.toStringAsFixed(0)} / kg';
  String get ratePerGramDisplay => '₹ ${ratePerGram.toStringAsFixed(2)} / g';
  String get totalFineDisplay => '${totalFineGrams.toStringAsFixed(3)} g';
  String get totalBillDisplay => '₹ ${totalBillAmount.toStringAsFixed(2)}';
  String get metalFineDisplay =>
      '${metalFineGiven.toStringAsFixed(3)} g → ₹ ${metalFineEquivalentCash.toStringAsFixed(2)}';
  String get cashDisplay => '₹ ${cashPaid.toStringAsFixed(2)}';
  String get upiDisplay => '₹ ${upiPaid.toStringAsFixed(2)}';
  String get bankingDisplay => '₹ ${bankingPaid.toStringAsFixed(2)}';
  String get cardDisplay => '₹ ${cardPaid.toStringAsFixed(2)}';
  String get totalPaidDisplay => '₹ ${totalPaid.toStringAsFixed(2)}';
  String get dueDisplay => '₹ ${dueAmount.toStringAsFixed(2)}';
}

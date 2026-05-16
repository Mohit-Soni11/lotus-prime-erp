// =============================================================================
// FILE        : silver_payment_controller.dart
// MODULE      : Stock & Inventory — Silver
// LAYER       : Logic / Payment
// DESCRIPTION : Payment Record logic for Silver Add Stock.
//
//   ✅ Rate per KG input → auto-converts to per gram
//   ✅ Total Bill Amount = totalFine × ratePerGram
//   ✅ Payment Modes:
//        — Metal to Metal  → Gross Weight + Purity % → Fine auto-calculated
//        — Cash
//        — UPI
//        — Banking Transfer
//        — Credit Card
//   ✅ Metal to Metal: Fine = grossWeight × purity / 100
//   ✅ Fine equivalent cash = fine × ratePerGram
//   ✅ Due Settlement Mode: asFine (grams) OR asCash (₹)
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
// DUE SETTLEMENT MODE ENUM
// ─────────────────────────────────────────────────────────────────────────────

/// Jab due amount bacha ho — usse kaise settle karna hai?
/// [asFine]  → supplier fine weight (grams) dega baad mein
/// [asCash]  → supplier cash/UPI/bank se paisa dega baad mein
enum DueSettleMode { asFine, asCash }

extension DueSettleModeLabel on DueSettleMode {
  String get label {
    return switch (this) {
      DueSettleMode.asFine => 'Fine dena hai (Metal)',
      DueSettleMode.asCash => 'Paisa dena hai (Cash)',
    };
  }

  IconData get icon {
    return switch (this) {
      DueSettleMode.asFine => Icons.balance_rounded,
      DueSettleMode.asCash => Icons.currency_rupee_rounded,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SILVER PAYMENT CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────

class SilverPaymentController extends ChangeNotifier {
  // ── RATE INPUT ────────────────────────────────────────────────────────────
  /// Operator enters rate in Rs/kg  (e.g. 90000 for Rs 90,000 per kg)
  final TextEditingController ratePerKgCtrl = TextEditingController();

  // ── METAL TO METAL — TWO-STEP INPUT ──────────────────────────────────────

  /// Step 1: Gross weight of silver given by supplier (grams)
  final TextEditingController metalGrossWeightCtrl = TextEditingController();

  /// Step 2: Purity percentage (e.g. 92.5 for 92.5% pure)
  final TextEditingController metalPurityCtrl = TextEditingController();

  // ── OTHER PAYMENT MODE CONTROLLERS ───────────────────────────────────────

  /// Cash paid — in Rs
  final TextEditingController cashCtrl = TextEditingController();

  /// UPI paid — in Rs
  final TextEditingController upiCtrl = TextEditingController();

  /// Banking / NEFT / RTGS / IMPS — in Rs
  final TextEditingController bankingCtrl = TextEditingController();

  /// Credit / Debit card — in Rs
  final TextEditingController cardCtrl = TextEditingController();

  // ── ENABLED PAYMENT MODES ─────────────────────────────────────────────────
  final Set<SilverPaymentMode> _enabledModes = {};

  // ── DUE SETTLEMENT MODE ───────────────────────────────────────────────────
  DueSettleMode _dueSettleMode = DueSettleMode.asCash;

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

  // ─────────────────────────────────────────────────────────────────────────
  // RATE COMPUTED GETTERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Rate per KG as entered by the operator
  double get ratePerKg => _parseNum(ratePerKgCtrl.text);

  /// Converted rate per gram (ratePerKg / 1000)
  double get ratePerGram => ratePerKg > 0 ? ratePerKg / 1000.0 : 0.0;

  /// Whether a valid rate has been entered
  bool get hasRate => ratePerGram > 0;

  /// Display string for rate per gram
  String get ratePerGramDisplay =>
      hasRate ? 'Rs ${ratePerGram.toStringAsFixed(2)} / g' : '—';

  // ─────────────────────────────────────────────────────────────────────────
  // METAL TO METAL — FINE CALCULATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Gross weight of silver given (grams)
  double get metalGrossWeight => _parseNum(metalGrossWeightCtrl.text);

  /// Purity percentage (0–100)
  double get metalPurity => _parseNum(metalPurityCtrl.text);

  /// Fine weight = grossWeight * purity / 100
  double get metalFineCalculated {
    if (metalGrossWeight <= 0 || metalPurity <= 0) return 0.0;
    return (metalGrossWeight * metalPurity) / 100.0;
  }

  /// Cash equivalent of fine = fine * ratePerGram
  double get metalFineEquivalentCash => metalFineCalculated * ratePerGram;

  /// Whether metal inputs are valid enough to show calculation
  bool get hasMetalCalculation =>
      metalGrossWeight > 0 && metalPurity > 0 && metalPurity <= 100;

  /// Helper text for metal calculation display
  String get metalCalcHelperText {
    if (!hasMetalCalculation) return '';
    final fine = metalFineCalculated;
    final cash = metalFineEquivalentCash;
    final cashStr = hasRate ? ' = Rs ${cash.toStringAsFixed(2)}' : '';
    return '${metalGrossWeight.toStringAsFixed(3)} g x ${metalPurity.toStringAsFixed(2)}% = ${fine.toStringAsFixed(3)} g fine$cashStr';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BILL AMOUNT COMPUTED FROM FINE
  // ─────────────────────────────────────────────────────────────────────────

  /// Total bill amount = totalFineWeight (grams) * ratePerGram
  /// Pass totalFineWeight from SilverStockController
  double totalBillAmount(double totalFineGrams) => totalFineGrams * ratePerGram;

  /// Display string for total bill amount
  String totalBillAmountDisplay(double totalFineGrams) {
    if (!hasRate) return '—';
    return 'Rs ${totalBillAmount(totalFineGrams).toStringAsFixed(2)}';
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

  // ─────────────────────────────────────────────────────────────────────────
  // PAYMENT AMOUNTS
  // ─────────────────────────────────────────────────────────────────────────

  double get cashPaid => _parseNum(cashCtrl.text);
  double get upiPaid => _parseNum(upiCtrl.text);
  double get bankingPaid => _parseNum(bankingCtrl.text);
  double get cardPaid => _parseNum(cardCtrl.text);

  /// Total of all payments (metal fine cash equiv + all cash modes)
  double get totalPaid =>
      metalFineEquivalentCash + cashPaid + upiPaid + bankingPaid + cardPaid;

  /// Due amount = total bill − total paid
  double dueAmount(double totalFineGrams) =>
      (totalBillAmount(totalFineGrams) - totalPaid).clamp(0.0, double.infinity);

  /// Due amount expressed as fine grams (if settling as fine)
  double dueAmountAsFine(double totalFineGrams) {
    if (!hasRate) return 0.0;
    return dueAmount(totalFineGrams) / ratePerGram;
  }

  /// Whether there is any remaining due
  bool hasDue(double totalFineGrams) => dueAmount(totalFineGrams) > 0;

  /// Whether payment is fully settled
  bool isSettled(double totalFineGrams) => dueAmount(totalFineGrams) == 0;

  // ─────────────────────────────────────────────────────────────────────────
  // DUE SETTLEMENT MODE
  // ─────────────────────────────────────────────────────────────────────────

  DueSettleMode get dueSettleMode => _dueSettleMode;

  void setDueSettleMode(DueSettleMode mode) {
    _dueSettleMode = mode;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAYMENT SUMMARY SNAPSHOT
  // ─────────────────────────────────────────────────────────────────────────

  SilverPaymentSnapshot buildSnapshot(double totalFineGrams) {
    final bill = totalBillAmount(totalFineGrams);
    final due = (bill - totalPaid).clamp(0.0, double.infinity);
    return SilverPaymentSnapshot(
      ratePerKg: ratePerKg,
      ratePerGram: ratePerGram,
      totalFineGrams: totalFineGrams,
      totalBillAmount: bill,
      metalGrossWeight: metalGrossWeight,
      metalPurity: metalPurity,
      metalFineCalculated: metalFineCalculated,
      metalFineEquivalentCash: metalFineEquivalentCash,
      cashPaid: cashPaid,
      upiPaid: upiPaid,
      bankingPaid: bankingPaid,
      cardPaid: cardPaid,
      totalPaid: totalPaid,
      dueAmount: due,
      dueSettleMode: _dueSettleMode,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────────

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

  // Metal to Metal
  final double metalGrossWeight;
  final double metalPurity;
  final double metalFineCalculated;
  final double metalFineEquivalentCash;

  final double cashPaid;
  final double upiPaid;
  final double bankingPaid;
  final double cardPaid;
  final double totalPaid;
  final double dueAmount;
  final DueSettleMode dueSettleMode;

  const SilverPaymentSnapshot({
    required this.ratePerKg,
    required this.ratePerGram,
    required this.totalFineGrams,
    required this.totalBillAmount,
    required this.metalGrossWeight,
    required this.metalPurity,
    required this.metalFineCalculated,
    required this.metalFineEquivalentCash,
    required this.cashPaid,
    required this.upiPaid,
    required this.bankingPaid,
    required this.cardPaid,
    required this.totalPaid,
    required this.dueAmount,
    required this.dueSettleMode,
  });

  bool get isSettled => dueAmount <= 0;
  bool get hasMetalPayment => metalFineCalculated > 0;
  bool get hasCashPayment => cashPaid > 0;
  bool get hasUpiPayment => upiPaid > 0;
  bool get hasBankingPayment => bankingPaid > 0;
  bool get hasCardPayment => cardPaid > 0;

  double get dueAmountAsFine => ratePerGram > 0 ? dueAmount / ratePerGram : 0.0;

  String get ratePerKgDisplay => 'Rs ${ratePerKg.toStringAsFixed(0)} / kg';
  String get ratePerGramDisplay => 'Rs ${ratePerGram.toStringAsFixed(2)} / g';
  String get totalFineDisplay => '${totalFineGrams.toStringAsFixed(3)} g';
  String get totalBillDisplay => 'Rs ${totalBillAmount.toStringAsFixed(2)}';
  String get metalGrossDisplay => '${metalGrossWeight.toStringAsFixed(3)} g';
  String get metalPurityDisplay => '${metalPurity.toStringAsFixed(2)}%';
  String get metalFineDisplay => '${metalFineCalculated.toStringAsFixed(3)} g';
  String get metalCashEquivDisplay =>
      'Rs ${metalFineEquivalentCash.toStringAsFixed(2)}';
  String get cashDisplay => 'Rs ${cashPaid.toStringAsFixed(2)}';
  String get upiDisplay => 'Rs ${upiPaid.toStringAsFixed(2)}';
  String get bankingDisplay => 'Rs ${bankingPaid.toStringAsFixed(2)}';
  String get cardDisplay => 'Rs ${cardPaid.toStringAsFixed(2)}';
  String get totalPaidDisplay => 'Rs ${totalPaid.toStringAsFixed(2)}';
  String get dueDisplay => 'Rs ${dueAmount.toStringAsFixed(2)}';
  String get dueAsFineDisplay => '${dueAmountAsFine.toStringAsFixed(3)} g fine';
}

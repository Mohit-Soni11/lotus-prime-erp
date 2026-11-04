import 'day_book_money_flow.dart';
import 'day_book_custody_position.dart';
import 'day_book_document.dart';
import 'day_book_activity_event.dart';
import 'day_book_expense_record.dart';
import 'day_book_stock_movement.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Payment Mode Breakup
// Maps to CashTransactions.paymentMode values: CASH | UPI | CARD | BANK | CHEQUE
// ─────────────────────────────────────────────────────────────────────────────
class PaymentBreakup {
  final double cash;
  final double upi;
  final double card;
  final double bank;
  final double cheque;

  const PaymentBreakup({
    this.cash = 0,
    this.upi = 0,
    this.card = 0,
    this.bank = 0,
    this.cheque = 0,
  });

  double get total => cash + upi + card + bank + cheque;

  PaymentBreakup operator +(PaymentBreakup o) => PaymentBreakup(
        cash: cash + o.cash,
        upi: upi + o.upi,
        card: card + o.card,
        bank: bank + o.bank,
        cheque: cheque + o.cheque,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// GST Bill Summary
// Source: Bills WHERE bill_type = 'GST' AND status = 'ACTIVE'
// Tax components are read from the finalized invoice, without estimating rates.
// ─────────────────────────────────────────────────────────────────────────────
class GstBillSummary {
  final int billCount;
  final double taxableAmount;
  final double cgst;
  final double sgst;
  final double igst;
  final double finalAmount; // total invoice value (taxable + gst)
  final PaymentBreakup payments;

  const GstBillSummary({
    this.billCount = 0,
    this.taxableAmount = 0,
    this.cgst = 0,
    this.sgst = 0,
    this.igst = 0,
    this.finalAmount = 0,
    this.payments = const PaymentBreakup(),
  });

  double get gstCollected => cgst + sgst + igst;
}

// ─────────────────────────────────────────────────────────────────────────────
// Non-GST Bill Summary
// Source: Bills WHERE bill_type = 'NORMAL' AND status = 'ACTIVE'
// ─────────────────────────────────────────────────────────────────────────────
class NonGstBillSummary {
  final int billCount;
  final double totalAmount; // sum of Bills.finalAmount
  final PaymentBreakup payments;

  const NonGstBillSummary({
    this.billCount = 0,
    this.totalAmount = 0,
    this.payments = const PaymentBreakup(),
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Cash Inward
// ─────────────────────────────────────────────────────────────────────────────
class CashInflow {
  final GstBillSummary gstSales;
  final NonGstBillSummary nonGstSales;

  // CashTransactions WHERE type='INCOME' — by category
  final double dueCollection; // category = 'DUE_COLLECTION'
  final double advance; // category = 'ADVANCE'
  final double orderDelivery; // category = 'ORDER_DELIVERY'
  final double girviReturn; // category = 'GIRVI_RETURN'
  final double loanReceived; // category = 'LOAN_RECEIVED'
  final double interestRec; // category = 'INTEREST_RECEIVED'
  final double miscIncome; // category = 'MISC_INCOME'
  final double otherIncome; // category = 'OTHER_INCOME'

  const CashInflow({
    this.gstSales = const GstBillSummary(),
    this.nonGstSales = const NonGstBillSummary(),
    this.dueCollection = 0,
    this.advance = 0,
    this.orderDelivery = 0,
    this.girviReturn = 0,
    this.loanReceived = 0,
    this.interestRec = 0,
    this.miscIncome = 0,
    this.otherIncome = 0,
  });

  double get retailSalesTotal =>
      gstSales.payments.cash + nonGstSales.payments.cash;

  double get manualIncomeTotal =>
      dueCollection +
      advance +
      orderDelivery +
      girviReturn +
      loanReceived +
      interestRec +
      miscIncome +
      otherIncome;

  double get total => retailSalesTotal + manualIncomeTotal;
}

// ─────────────────────────────────────────────────────────────────────────────
// Cash Outward
// Source: CashTransactions WHERE type='EXPENSE' AND isVoided=false
// ─────────────────────────────────────────────────────────────────────────────
class CashOutflow {
  final double shopRent; // SHOP_RENT
  final double staffSalary; // STAFF_SALARY
  final double electricity; // ELECTRICITY
  final double purchasePayment; // PURCHASE_PAYMENT
  final double girviGiven; // GIRVI_GIVEN
  final double maintenance; // MAINTENANCE
  final double advertising; // ADVERTISING
  final double transport; // TRANSPORT
  final double bankCharges; // BANK_CHARGES
  final double govtFees; // GOVT_FEES
  final double miscExpense; // MISC_EXPENSE
  final double otherExpense; // OTHER_EXPENSE

  const CashOutflow({
    this.shopRent = 0,
    this.staffSalary = 0,
    this.electricity = 0,
    this.purchasePayment = 0,
    this.girviGiven = 0,
    this.maintenance = 0,
    this.advertising = 0,
    this.transport = 0,
    this.bankCharges = 0,
    this.govtFees = 0,
    this.miscExpense = 0,
    this.otherExpense = 0,
  });

  double get operationalExpenses =>
      shopRent +
      staffSalary +
      electricity +
      maintenance +
      advertising +
      transport +
      bankCharges +
      govtFees;

  double get total =>
      shopRent +
      staffSalary +
      electricity +
      purchasePayment +
      girviGiven +
      maintenance +
      advertising +
      transport +
      bankCharges +
      govtFees +
      miscExpense +
      otherExpense;
}

// ─────────────────────────────────────────────────────────────────────────────
// Metal Weight (grams)
// ─────────────────────────────────────────────────────────────────────────────
class MetalWeight {
  final double gold22k; // purity = '22K' (916)
  final double gold18k; // purity = '18K'
  final double silver; // metalType = 'Silver'
  final Map<String, double> additionalEntries;

  const MetalWeight({
    this.gold22k = 0,
    this.gold18k = 0,
    this.silver = 0,
    this.additionalEntries = const {},
  });

  factory MetalWeight.fromEntries(Map<String, double> entries) {
    return MetalWeight(additionalEntries: Map.unmodifiable(entries));
  }

  static String entryKey(String metal, String purity) => '$metal::$purity';

  Map<String, double> get entries {
    final values = <String, double>{...additionalEntries};
    _addEntry(values, entryKey('Gold', '22K'), gold22k);
    _addEntry(values, entryKey('Gold', '18K'), gold18k);
    _addEntry(values, entryKey('Silver', 'Standard'), silver);
    values.removeWhere((_, value) => value.abs() < 0.000001);
    return values;
  }

  Set<String> get metals => entries.keys
      .map((key) => key.split('::').first)
      .where((metal) => metal.isNotEmpty)
      .toSet();

  Map<String, double> puritiesFor(String metal) {
    final values = <String, double>{};
    for (final entry in entries.entries) {
      final parts = entry.key.split('::');
      if (parts.length != 2 || parts.first != metal) continue;
      values[parts.last] = (values[parts.last] ?? 0) + entry.value;
    }
    return values;
  }

  double totalForMetal(String metal) =>
      puritiesFor(metal).values.fold(0.0, (sum, value) => sum + value);

  double get totalGold => totalForMetal('Gold');
  double get totalSilver => totalForMetal('Silver');
  double get totalPlatinum => totalForMetal('Platinum');
  double get totalDiamond => totalForMetal('Diamond');
  double get totalWeight =>
      entries.values.fold(0.0, (sum, value) => sum + value);
  bool get isEmpty => entries.isEmpty;

  MetalWeight operator +(MetalWeight other) =>
      MetalWeight.fromEntries(_mergeEntries(entries, other.entries, 1));

  MetalWeight operator -(MetalWeight other) =>
      MetalWeight.fromEntries(_mergeEntries(entries, other.entries, -1));

  static void _addEntry(
    Map<String, double> target,
    String key,
    double value,
  ) {
    if (value == 0) return;
    target[key] = (target[key] ?? 0) + value;
  }

  static Map<String, double> _mergeEntries(
    Map<String, double> left,
    Map<String, double> right,
    double multiplier,
  ) {
    final result = <String, double>{...left};
    for (final entry in right.entries) {
      _addEntry(result, entry.key, entry.value * multiplier);
    }
    return result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metal Inward — Vault Additions
// ─────────────────────────────────────────────────────────────────────────────
class MetalInflow {
  // Girvi collateral is customer property, never owned stock.
  final MetalWeight girviSecurityDeposit;
  final MetalWeight urdPurchase;
  final MetalWeight salesReturnReversal;

  const MetalInflow({
    this.girviSecurityDeposit = const MetalWeight(),
    this.urdPurchase = const MetalWeight(),
    this.salesReturnReversal = const MetalWeight(),
  });

  /// Customer collateral is custody, never shop-owned stock.
  MetalWeight get total => urdPurchase + salesReturnReversal;
  MetalWeight get custodyReceived => girviSecurityDeposit;
}

// ─────────────────────────────────────────────────────────────────────────────
// Metal Outward — Vault Deductions
// ─────────────────────────────────────────────────────────────────────────────
class MetalOutflow {
  // BillItems for today's active bills — metal sold
  final MetalWeight retailDispatch;

  const MetalOutflow({
    this.retailDispatch = const MetalWeight(),
  });

  MetalWeight get total => retailDispatch;
}

// ─────────────────────────────────────────────────────────────────────────────
// Anomaly Alert
// ─────────────────────────────────────────────────────────────────────────────
class AnomalyAlert {
  final String message;
  final String category;
  final double todayValue;
  final double avgValue;
  final double percentChange;

  const AnomalyAlert({
    required this.message,
    required this.category,
    required this.todayValue,
    required this.avgValue,
    required this.percentChange,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Predicted Closing
// ─────────────────────────────────────────────────────────────────────────────
class PredictedClosing {
  final double predictedCash;
  final double vsYesterdayPct;
  final bool isPositiveTrend;

  const PredictedClosing({
    this.predictedCash = 0,
    this.vsYesterdayPct = 0,
    this.isPositiveTrend = true,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// EOD Denomination Count
// ─────────────────────────────────────────────────────────────────────────────
class DenominationCount {
  int note500;
  int note200;
  int note100;
  int note50;
  int note20;
  int note10;
  double coins;

  DenominationCount({
    this.note500 = 0,
    this.note200 = 0,
    this.note100 = 0,
    this.note50 = 0,
    this.note20 = 0,
    this.note10 = 0,
    this.coins = 0,
  });

  double get physicalTotal =>
      (note500 * 500) +
      (note200 * 200) +
      (note100 * 100) +
      (note50 * 50) +
      (note20 * 20) +
      (note10 * 10) +
      coins;
}

// ─────────────────────────────────────────────────────────────────────────────
// MASTER: Complete Day Book Summary
// ─────────────────────────────────────────────────────────────────────────────
class DayBookSummary {
  final DateTime date;
  final DayBookMoneyFlow? moneyFlow;
  final List<DayBookStockMovement> stockMovements;
  final DayBookCustodyPosition? custodyPosition;
  final List<DayBookDocument> documents;
  final List<DayBookActivityEvent> activityEvents;
  final List<DayBookExpenseRecord> expenseRecords;
  final bool metalPositionVerified;

  // Opening balances (from ShopProfile or previous day closing)
  final double openingCash;
  final double openingGoldGrams;
  final double openingSilverGrams;

  // Core flows
  final CashInflow cashIn;
  final CashOutflow cashOut;
  final MetalInflow metalIn;
  final MetalOutflow metalOut;

  // Combined payment breakup (across GST + Non-GST sales)
  final PaymentBreakup paymentBreakup;

  // Smart features
  final List<AnomalyAlert> anomalies;
  final PredictedClosing? prediction;
  final bool isDayLocked;

  const DayBookSummary({
    required this.date,
    this.moneyFlow,
    this.stockMovements = const [],
    this.custodyPosition,
    this.documents = const [],
    this.activityEvents = const [],
    this.expenseRecords = const [],
    this.metalPositionVerified = false,
    this.openingCash = 0,
    this.openingGoldGrams = 0,
    this.openingSilverGrams = 0,
    this.cashIn = const CashInflow(),
    this.cashOut = const CashOutflow(),
    this.metalIn = const MetalInflow(),
    this.metalOut = const MetalOutflow(),
    this.paymentBreakup = const PaymentBreakup(),
    this.anomalies = const [],
    this.prediction,
    this.isDayLocked = false,
  });

  // ── Computed ──────────────────────────────────────────────────────────────
  double get cashReceived => moneyFlow?.cashIn ?? cashIn.total;
  double get cashPaid => moneyFlow?.cashOut ?? cashOut.total;
  double get netCash => cashReceived - cashPaid;
  double get closingCash => openingCash + netCash;

  MetalWeight get netMetal => metalIn.total - metalOut.total;
  double get closingGold => openingGoldGrams + netMetal.totalGold;
  double get closingSilver => openingSilverGrams + netMetal.totalSilver;

  double get totalGstCollected => cashIn.gstSales.gstCollected;
  int get totalGstBills => cashIn.gstSales.billCount;
  int get totalNonGstBills => cashIn.nonGstSales.billCount;
}

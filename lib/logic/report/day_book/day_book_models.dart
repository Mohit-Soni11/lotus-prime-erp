// =============================================================================
// FILE        : day_book_models.dart
// MODULE      : Reports & Analytics → Day Book
// LAYER       : Logic / Models
// DESCRIPTION : Pure data models for Day Book aggregation.
//               No Flutter imports — plain Dart only.
//               GST and Non-GST bills tracked separately per requirement.
// =============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// Payment Mode Breakup
// ─────────────────────────────────────────────────────────────────────────────
class PaymentBreakup {
  final double cash;
  final double upi;
  final double card;
  final double bankTransfer;

  const PaymentBreakup({
    this.cash = 0,
    this.upi = 0,
    this.card = 0,
    this.bankTransfer = 0,
  });

  double get total => cash + upi + card + bankTransfer;

  PaymentBreakup operator +(PaymentBreakup other) => PaymentBreakup(
    cash: cash + other.cash,
    upi: upi + other.upi,
    card: card + other.card,
    bankTransfer: bankTransfer + other.bankTransfer,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// GST Bill Summary (TAX invoices only)
// ─────────────────────────────────────────────────────────────────────────────
class GstBillSummary {
  final int billCount;
  final double taxableAmount;   // Amount before GST
  final double cgst;            // 1.5%
  final double sgst;            // 1.5%
  final double totalGstAmount;  // Taxable + CGST + SGST (final invoice value)
  final PaymentBreakup paymentBreakup;

  const GstBillSummary({
    this.billCount = 0,
    this.taxableAmount = 0,
    this.cgst = 0,
    this.sgst = 0,
    this.totalGstAmount = 0,
    this.paymentBreakup = const PaymentBreakup(),
  });

  double get gstCollected => cgst + sgst;
}

// ─────────────────────────────────────────────────────────────────────────────
// Non-GST Bill Summary (Normal / Estimate bills)
// ─────────────────────────────────────────────────────────────────────────────
class NonGstBillSummary {
  final int billCount;
  final double totalAmount;
  final PaymentBreakup paymentBreakup;

  const NonGstBillSummary({
    this.billCount = 0,
    this.totalAmount = 0,
    this.paymentBreakup = const PaymentBreakup(),
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Cash Inward — All sources combined
// ─────────────────────────────────────────────────────────────────────────────
class CashInflow {
  // GST bills: shown separately in GST section
  final GstBillSummary gstSales;
  // Normal bills: shown separately in Non-GST section
  final NonGstBillSummary nonGstSales;
  // Other inflows
  final double dueReceipts;       // Udhaar wapas
  final double bookingAdvances;   // Custom order advances
  final double vendorRefunds;     // Purchase return from supplier
  final double girviReceipts;     // Girvi release — principal + interest

  const CashInflow({
    this.gstSales = const GstBillSummary(),
    this.nonGstSales = const NonGstBillSummary(),
    this.dueReceipts = 0,
    this.bookingAdvances = 0,
    this.vendorRefunds = 0,
    this.girviReceipts = 0,
  });

  // Total retail sales = GST bills + Non-GST bills
  double get totalRetailSales =>
      gstSales.totalGstAmount + nonGstSales.totalAmount;

  double get total =>
      totalRetailSales +
      dueReceipts +
      bookingAdvances +
      vendorRefunds +
      girviReceipts;

  // Combined payment mode breakup across all sales
  PaymentBreakup get combinedPaymentBreakup =>
      gstSales.paymentBreakup + nonGstSales.paymentBreakup;
}

// ─────────────────────────────────────────────────────────────────────────────
// Cash Outward — All sources combined
// ─────────────────────────────────────────────────────────────────────────────
class CashOutflow {
  final double expenses;       // Operational & admin expenses
  final double girviGiven;     // Mortgage disbursements
  final double karigarPayments; // Artisan settlements
  final double vendorPayments; // Accounts payable
  final double salesReturns;   // Customer refunds

  const CashOutflow({
    this.expenses = 0,
    this.girviGiven = 0,
    this.karigarPayments = 0,
    this.vendorPayments = 0,
    this.salesReturns = 0,
  });

  double get total =>
      expenses +
      girviGiven +
      karigarPayments +
      vendorPayments +
      salesReturns;
}

// ─────────────────────────────────────────────────────────────────────────────
// Metal Weight (grams) — per metal type
// ─────────────────────────────────────────────────────────────────────────────
class MetalWeight {
  final double gold22k;
  final double gold18k;
  final double silver;

  const MetalWeight({
    this.gold22k = 0,
    this.gold18k = 0,
    this.silver = 0,
  });

  double get totalGold => gold22k + gold18k;
  double get totalSilver => silver;

  MetalWeight operator +(MetalWeight other) => MetalWeight(
    gold22k: gold22k + other.gold22k,
    gold18k: gold18k + other.gold18k,
    silver: silver + other.silver,
  );

  MetalWeight operator -(MetalWeight other) => MetalWeight(
    gold22k: gold22k - other.gold22k,
    gold18k: gold18k - other.gold18k,
    silver: silver - other.silver,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Metal Inward — Vault Additions
// ─────────────────────────────────────────────────────────────────────────────
class MetalInflow {
  final MetalWeight urdScrapPurchase;   // Old gold bought from customer
  final MetalWeight karigarFinishedGoods; // Ready jewellery from karigar
  final MetalWeight girviSecurityDeposit; // Gold pledged for mortgage
  final MetalWeight salesReturnReversal;  // Sold item returned by customer

  const MetalInflow({
    this.urdScrapPurchase = const MetalWeight(),
    this.karigarFinishedGoods = const MetalWeight(),
    this.girviSecurityDeposit = const MetalWeight(),
    this.salesReturnReversal = const MetalWeight(),
  });

  MetalWeight get total =>
      urdScrapPurchase +
      karigarFinishedGoods +
      girviSecurityDeposit +
      salesReturnReversal;
}

// ─────────────────────────────────────────────────────────────────────────────
// Metal Outward — Vault Deductions
// ─────────────────────────────────────────────────────────────────────────────
class MetalOutflow {
  final MetalWeight retailDispatch;   // Sold jewellery delivered
  final MetalWeight karigarIssue;     // Raw gold issued to artisan
  final MetalWeight vendorReturn;     // Defective stock returned

  const MetalOutflow({
    this.retailDispatch = const MetalWeight(),
    this.karigarIssue = const MetalWeight(),
    this.vendorReturn = const MetalWeight(),
  });

  MetalWeight get total =>
      retailDispatch + karigarIssue + vendorReturn;
}

// ─────────────────────────────────────────────────────────────────────────────
// Anomaly Alert
// ─────────────────────────────────────────────────────────────────────────────
class AnomalyAlert {
  final String message;
  final String category;   // 'expense' | 'cash_in' | 'cash_out' | 'metal'
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
// Predictive Closing Balance
// ─────────────────────────────────────────────────────────────────────────────
class PredictedClosing {
  final double predictedCash;
  final double vsYesterdayPercent;
  final double vsLastWeekPercent;
  final bool isPositiveTrend;

  const PredictedClosing({
    this.predictedCash = 0,
    this.vsYesterdayPercent = 0,
    this.vsLastWeekPercent = 0,
    this.isPositiveTrend = true,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// EOD Denomination Input
// ─────────────────────────────────────────────────────────────────────────────
class DenominationCount {
  int note2000;
  int note500;
  int note200;
  int note100;
  int note50;
  int note20;
  int note10;
  int coins;

  DenominationCount({
    this.note2000 = 0,
    this.note500 = 0,
    this.note200 = 0,
    this.note100 = 0,
    this.note50 = 0,
    this.note20 = 0,
    this.note10 = 0,
    this.coins = 0,
  });

  double get physicalTotal =>
      (note2000 * 2000) +
      (note500 * 500) +
      (note200 * 200) +
      (note100 * 100) +
      (note50 * 50) +
      (note20 * 20) +
      (note10 * 10) +
      coins.toDouble();
}

// ─────────────────────────────────────────────────────────────────────────────
// MASTER: Complete Day Book Summary
// ─────────────────────────────────────────────────────────────────────────────
class DayBookSummary {
  final DateTime date;

  // Opening Balances
  final double openingCash;
  final MetalWeight openingGold;   // grams
  final double openingSilver;       // grams

  // Core Flows
  final CashInflow cashIn;
  final CashOutflow cashOut;
  final MetalInflow metalIn;
  final MetalOutflow metalOut;

  // Derived
  final List<AnomalyAlert> anomalies;
  final PredictedClosing? prediction;
  final bool isDayLocked;

  const DayBookSummary({
    required this.date,
    this.openingCash = 0,
    this.openingGold = const MetalWeight(),
    this.openingSilver = 0,
    this.cashIn = const CashInflow(),
    this.cashOut = const CashOutflow(),
    this.metalIn = const MetalInflow(),
    this.metalOut = const MetalOutflow(),
    this.anomalies = const [],
    this.prediction,
    this.isDayLocked = false,
  });

  // ── Computed: Net Cash ────────────────────────────────────────────────────
  double get netCash => cashIn.total - cashOut.total;
  double get closingCash => openingCash + netCash;

  // ── Computed: Net Metal ───────────────────────────────────────────────────
  MetalWeight get netMetal => metalIn.total - metalOut.total;
  double get closingGold => openingGold.totalGold + netMetal.totalGold;
  double get closingSilver => openingSilver + netMetal.totalSilver;

  // ── Computed: GST Total ───────────────────────────────────────────────────
  double get totalGstCollected => cashIn.gstSales.gstCollected;

  // ── Computed: Combined Payment Breakup ───────────────────────────────────
  PaymentBreakup get totalPaymentBreakup => cashIn.combinedPaymentBreakup;
}

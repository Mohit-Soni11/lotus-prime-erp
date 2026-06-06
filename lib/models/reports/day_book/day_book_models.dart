// =============================================================================
// FILE        : day_book_models.dart
// MODULE      : Reports & Analytics → Day Book
// LAYER       : Models
// DESCRIPTION : Pure Dart data models — production grade.
//               All field names match EXACT DB column names from:
//               CashTransactions, Bills, BillItems, GirviLoans,
//               GirviPayments, KarigarIssues, KarigarReceipts,
//               SalesOrders, OrderAdvances, StockItems.
//
//               GST Bill (billNo starts 'TAX-') tracked SEPARATELY from
//               Normal Bill (billNo starts 'EST-') as required.
// =============================================================================

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
// Source: Bills WHERE billNo LIKE 'TAX-%' AND status = 'ACTIVE'
// GST on jewellery = 3% (1.5% CGST + 1.5% SGST)
// Bills.finalAmount already INCLUDES GST.
// ─────────────────────────────────────────────────────────────────────────────
class GstBillSummary {
  final int billCount;
  final double taxableAmount; // finalAmount / 1.03
  final double cgst; // taxable × 1.5%
  final double sgst; // taxable × 1.5%
  final double finalAmount; // total invoice value (taxable + gst)
  final PaymentBreakup payments;

  const GstBillSummary({
    this.billCount = 0,
    this.taxableAmount = 0,
    this.cgst = 0,
    this.sgst = 0,
    this.finalAmount = 0,
    this.payments = const PaymentBreakup(),
  });

  double get gstCollected => cgst + sgst;
}

// ─────────────────────────────────────────────────────────────────────────────
// Non-GST Bill Summary
// Source: Bills WHERE billNo LIKE 'EST-%' AND status = 'ACTIVE'
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

  double get retailSalesTotal => gstSales.finalAmount + nonGstSales.totalAmount;

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

  const MetalWeight({
    this.gold22k = 0,
    this.gold18k = 0,
    this.silver = 0,
  });

  double get totalGold => gold22k + gold18k;
  double get totalSilver => silver;

  MetalWeight operator +(MetalWeight o) => MetalWeight(
        gold22k: gold22k + o.gold22k,
        gold18k: gold18k + o.gold18k,
        silver: silver + o.silver,
      );

  MetalWeight operator -(MetalWeight o) => MetalWeight(
        gold22k: (gold22k - o.gold22k).clamp(0, double.infinity),
        gold18k: (gold18k - o.gold18k).clamp(0, double.infinity),
        silver: (silver - o.silver).clamp(0, double.infinity),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Metal Inward — Vault Additions
// ─────────────────────────────────────────────────────────────────────────────
class MetalInflow {
  // BillItems from today's sales WHERE purity in ('22K','18K') — items SOLD
  // are OUT, but items returned come back IN via salesReturnReversal

  // KarigarReceipts.netWeightReceived grouped by issue.metalType + issue.purity
  final MetalWeight karigarFinishedGoods;

  // GirviLoans created today → netWeight pledged
  final MetalWeight girviSecurityDeposit;

  // StockItems created today WHERE source = 'URD' (old gold purchase)
  // No 'source' column in StockItems — we use supplierName IS NULL logic
  // Actually: URD purchase = manual stock added with no supplier
  // For now: sum from CashTransactions category='MISC_INCOME' cross-ref
  // BEST approach: use StockItems WHERE supplierId IS NULL AND createdAt = today
  final MetalWeight urdPurchase;

  // Future: salesReturnReversal — items returned by customer
  final MetalWeight salesReturnReversal;

  const MetalInflow({
    this.karigarFinishedGoods = const MetalWeight(),
    this.girviSecurityDeposit = const MetalWeight(),
    this.urdPurchase = const MetalWeight(),
    this.salesReturnReversal = const MetalWeight(),
  });

  MetalWeight get total =>
      karigarFinishedGoods +
      girviSecurityDeposit +
      urdPurchase +
      salesReturnReversal;
}

// ─────────────────────────────────────────────────────────────────────────────
// Metal Outward — Vault Deductions
// ─────────────────────────────────────────────────────────────────────────────
class MetalOutflow {
  // BillItems for today's active bills — metal sold
  final MetalWeight retailDispatch;

  // KarigarIssues.netWeightIssued grouped by metalType + purity
  final MetalWeight karigarIssue;

  const MetalOutflow({
    this.retailDispatch = const MetalWeight(),
    this.karigarIssue = const MetalWeight(),
  });

  MetalWeight get total => retailDispatch + karigarIssue;
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
  double get netCash => cashIn.total - cashOut.total;
  double get closingCash => openingCash + netCash;

  MetalWeight get netMetal => metalIn.total - metalOut.total;
  double get closingGold => openingGoldGrams + netMetal.totalGold;
  double get closingSilver => openingSilverGrams + netMetal.totalSilver;

  double get totalGstCollected => cashIn.gstSales.gstCollected;
  int get totalGstBills => cashIn.gstSales.billCount;
  int get totalNonGstBills => cashIn.nonGstSales.billCount;
}

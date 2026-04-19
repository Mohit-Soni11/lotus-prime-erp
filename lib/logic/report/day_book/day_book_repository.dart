// =============================================================================
// FILE        : day_book_repository.dart
// MODULE      : Reports & Analytics → Day Book
// LAYER       : Logic / Repository
// DESCRIPTION : Aggregates data from ALL modules into DayBookSummary.
//               Uses parallel Future.wait for performance.
//               GST and Non-GST bills tracked separately.
//               No manual entry — purely reads from existing module tables.
// =============================================================================

import '../../../database/db/app_database.dart';
import 'day_book_models.dart';

class DayBookRepository {
  final AppDatabase _db;

  DayBookRepository(this._db);

  // ─────────────────────────────────────────────────────────────────────────
  // MASTER: Fetch complete Day Book for a date
  // ─────────────────────────────────────────────────────────────────────────
  Future<DayBookSummary> getDayBook(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Run all queries in parallel for speed
    final results = await Future.wait([
      _getGstBillSummary(startOfDay, endOfDay), // 0
      _getNonGstBillSummary(startOfDay, endOfDay), // 1
      _getDueReceipts(startOfDay, endOfDay), // 2
      _getBookingAdvances(startOfDay, endOfDay), // 3
      _getVendorRefunds(startOfDay, endOfDay), // 4
      _getGirviReceipts(startOfDay, endOfDay), // 5
      _getExpenses(startOfDay, endOfDay), // 6
      _getGirviDisbursements(startOfDay, endOfDay), // 7
      _getKarigarPayments(startOfDay, endOfDay), // 8
      _getVendorPayments(startOfDay, endOfDay), // 9
      _getSalesReturns(startOfDay, endOfDay), // 10
      _getMetalInflow(startOfDay, endOfDay), // 11
      _getMetalOutflow(startOfDay, endOfDay), // 12
      _getOpeningCash(startOfDay), // 13
    ]);

    final cashIn = CashInflow(
      gstSales: results[0] as GstBillSummary,
      nonGstSales: results[1] as NonGstBillSummary,
      dueReceipts: results[2] as double,
      bookingAdvances: results[3] as double,
      vendorRefunds: results[4] as double,
      girviReceipts: results[5] as double,
    );

    final cashOut = CashOutflow(
      expenses: results[6] as double,
      girviGiven: results[7] as double,
      karigarPayments: results[8] as double,
      vendorPayments: results[9] as double,
      salesReturns: results[10] as double,
    );

    final metalIn = results[11] as MetalInflow;
    final metalOut = results[12] as MetalOutflow;
    final openingCash = results[13] as double;

    // Anomaly detection (7-day average comparison)
    final anomalies = await _detectAnomalies(
      date: date,
      cashIn: cashIn,
      cashOut: cashOut,
    );

    // Predictive closing (linear projection based on hours elapsed)
    final prediction = _buildPrediction(
      date: date,
      openingCash: openingCash,
      cashIn: cashIn,
      cashOut: cashOut,
    );

    return DayBookSummary(
      date: date,
      openingCash: openingCash,
      cashIn: cashIn,
      cashOut: cashOut,
      metalIn: metalIn,
      metalOut: metalOut,
      anomalies: anomalies,
      prediction: prediction,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CASH IN: GST Bills (BillType = 'GST' / prefix 'TAX')
  // ─────────────────────────────────────────────────────────────────────────
  Future<GstBillSummary> _getGstBillSummary(
    DateTime start,
    DateTime end,
  ) async {
    try {
      // Bills where billNo starts with 'TAX-' (GST invoices)
      final bills = await (_db.select(_db.bills)
            ..where((b) =>
                b.billDate.isBetweenValues(start, end) &
                b.billNo.like('TAX-%') &
                b.status.equals('ACTIVE')))
          .get();

      if (bills.isEmpty) return const GstBillSummary();

      double totalFinalAmount = 0;
      double totalPaid = 0;
      double cash = 0, upi = 0, card = 0;

      for (final bill in bills) {
        totalFinalAmount += bill.finalAmount;
        totalPaid += bill.paidAmount;
        // Payment mode breakdown from bill — extend Bills table if needed
        // For now: approximate by paidAmount split (to be refined with
        // actual payment_mode column in Bills table)
      }

      // GST on jewellery: 3% total (1.5 CGST + 1.5 SGST)
      // finalAmount already includes GST
      final taxable = totalFinalAmount / 1.03;
      final totalGst = totalFinalAmount - taxable;

      return GstBillSummary(
        billCount: bills.length,
        taxableAmount: taxable,
        cgst: totalGst / 2,
        sgst: totalGst / 2,
        totalGstAmount: totalFinalAmount,
        paymentBreakup: PaymentBreakup(cash: totalPaid),
      );
    } catch (_) {
      return const GstBillSummary();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CASH IN: Non-GST / Normal Bills (prefix 'EST-')
  // ─────────────────────────────────────────────────────────────────────────
  Future<NonGstBillSummary> _getNonGstBillSummary(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final bills = await (_db.select(_db.bills)
            ..where((b) =>
                b.billDate.isBetweenValues(start, end) &
                b.billNo.like('EST-%') &
                b.status.equals('ACTIVE')))
          .get();

      if (bills.isEmpty) return const NonGstBillSummary();

      double total = 0;
      for (final bill in bills) {
        total += bill.finalAmount;
      }

      return NonGstBillSummary(
        billCount: bills.length,
        totalAmount: total,
        paymentBreakup: PaymentBreakup(cash: total),
      );
    } catch (_) {
      return const NonGstBillSummary();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CASH IN: Due Receipts (pending udhaar collected)
  // Source: cash_transactions WHERE type = 'due_receipt'
  // ─────────────────────────────────────────────────────────────────────────
  Future<double> _getDueReceipts(DateTime start, DateTime end) async {
    try {
      final rows = await (_db.select(_db.cashTransactions)
            ..where((t) =>
                t.transactionDate.isBetweenValues(start, end) &
                t.transactionType.equals('due_receipt')))
          .get();
      return rows.fold(0.0, (sum, r) => sum + r.amount);
    } catch (_) {
      return 0.0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CASH IN: Booking Advances
  // Source: sales_orders WHERE status = 'booked' — advance received
  // ─────────────────────────────────────────────────────────────────────────
  Future<double> _getBookingAdvances(DateTime start, DateTime end) async {
    try {
      final rows = await (_db.select(_db.salesOrders)
            ..where((o) =>
                o.createdAt.isBetweenValues(start, end) &
                o.status.equals('booked')))
          .get();
      return rows.fold(0.0, (sum, r) => sum + (r.advancePaid ?? 0.0));
    } catch (_) {
      return 0.0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CASH IN: Vendor Refunds (purchase return — supplier refund)
  // Source: cash_transactions WHERE type = 'vendor_refund'
  // ─────────────────────────────────────────────────────────────────────────
  Future<double> _getVendorRefunds(DateTime start, DateTime end) async {
    try {
      final rows = await (_db.select(_db.cashTransactions)
            ..where((t) =>
                t.transactionDate.isBetweenValues(start, end) &
                t.transactionType.equals('vendor_refund')))
          .get();
      return rows.fold(0.0, (sum, r) => sum + r.amount);
    } catch (_) {
      return 0.0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CASH IN: Girvi Receipts (principal + interest on release)
  // Source: girvi_payments WHERE payment_type = 'release'
  // ─────────────────────────────────────────────────────────────────────────
  Future<double> _getGirviReceipts(DateTime start, DateTime end) async {
    try {
      final rows = await (_db.select(_db.girviPayments)
            ..where((p) =>
                p.paymentDate.isBetweenValues(start, end) &
                p.paymentType.equals('release')))
          .get();
      return rows.fold(0.0, (sum, r) => sum + r.amount);
    } catch (_) {
      return 0.0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CASH OUT: Operational Expenses
  // Source: cash_transactions WHERE type = 'expense'
  // ─────────────────────────────────────────────────────────────────────────
  Future<double> _getExpenses(DateTime start, DateTime end) async {
    try {
      final rows = await (_db.select(_db.cashTransactions)
            ..where((t) =>
                t.transactionDate.isBetweenValues(start, end) &
                t.transactionType.equals('expense')))
          .get();
      return rows.fold(0.0, (sum, r) => sum + r.amount);
    } catch (_) {
      return 0.0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CASH OUT: Girvi Disbursements (loan given)
  // Source: girvi_loans WHERE created_date = today
  // ─────────────────────────────────────────────────────────────────────────
  Future<double> _getGirviDisbursements(DateTime start, DateTime end) async {
    try {
      final rows = await (_db.select(_db.girviLoans)
            ..where((l) =>
                l.loanDate.isBetweenValues(start, end) &
                l.status.equals('active')))
          .get();
      return rows.fold(0.0, (sum, r) => sum + r.loanAmount);
    } catch (_) {
      return 0.0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CASH OUT: Karigar Payments
  // Source: karigar_receipts WHERE received_date = today (cash paid)
  // ─────────────────────────────────────────────────────────────────────────
  Future<double> _getKarigarPayments(DateTime start, DateTime end) async {
    try {
      final rows = await (_db.select(_db.karigarReceipts)
            ..where((r) => r.receiptDate.isBetweenValues(start, end)))
          .get();
      return rows.fold(0.0, (sum, r) => sum + (r.cashPaid ?? 0.0));
    } catch (_) {
      return 0.0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CASH OUT: Vendor Payments
  // Source: cash_transactions WHERE type = 'vendor_payment'
  // ─────────────────────────────────────────────────────────────────────────
  Future<double> _getVendorPayments(DateTime start, DateTime end) async {
    try {
      final rows = await (_db.select(_db.cashTransactions)
            ..where((t) =>
                t.transactionDate.isBetweenValues(start, end) &
                t.transactionType.equals('vendor_payment')))
          .get();
      return rows.fold(0.0, (sum, r) => sum + r.amount);
    } catch (_) {
      return 0.0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CASH OUT: Sales Returns (customer refund)
  // Source: cash_transactions WHERE type = 'sales_return'
  // ─────────────────────────────────────────────────────────────────────────
  Future<double> _getSalesReturns(DateTime start, DateTime end) async {
    try {
      final rows = await (_db.select(_db.cashTransactions)
            ..where((t) =>
                t.transactionDate.isBetweenValues(start, end) &
                t.transactionType.equals('sales_return')))
          .get();
      return rows.fold(0.0, (sum, r) => sum + r.amount);
    } catch (_) {
      return 0.0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // METAL INWARD
  // ─────────────────────────────────────────────────────────────────────────
  Future<MetalInflow> _getMetalInflow(DateTime start, DateTime end) async {
    try {
      // URD / Old Gold: from stock_items WHERE source = 'urd_purchase'
      final urdRows = await (_db.select(_db.stockItems)
            ..where((s) =>
                s.createdAt.isBetweenValues(start, end) &
                s.source.equals('urd_purchase')))
          .get();

      // Karigar finished goods: stock_items WHERE source = 'karigar'
      final karigarRows = await (_db.select(_db.stockItems)
            ..where((s) =>
                s.createdAt.isBetweenValues(start, end) &
                s.source.equals('karigar')))
          .get();

      // Girvi security: girvi_loans WHERE item_type = 'gold'
      final girviRows = await (_db.select(_db.girviLoans)
            ..where((l) => l.loanDate.isBetweenValues(start, end)))
          .get();

      double urdGold22 = 0, urdGold18 = 0, urdSilver = 0;
      for (final r in urdRows) {
        if (r.purity == '22K')
          urdGold22 += r.netWeight ?? 0;
        else if (r.purity == '18K')
          urdGold18 += r.netWeight ?? 0;
        else if (r.metalType == 'silver') urdSilver += r.netWeight ?? 0;
      }

      double karGold22 = 0, karGold18 = 0;
      for (final r in karigarRows) {
        if (r.purity == '22K')
          karGold22 += r.netWeight ?? 0;
        else if (r.purity == '18K') karGold18 += r.netWeight ?? 0;
      }

      double girviGold = 0;
      for (final r in girviRows) {
        girviGold += r.goldWeight ?? 0;
      }

      return MetalInflow(
        urdScrapPurchase: MetalWeight(
          gold22k: urdGold22,
          gold18k: urdGold18,
          silver: urdSilver,
        ),
        karigarFinishedGoods: MetalWeight(
          gold22k: karGold22,
          gold18k: karGold18,
        ),
        girviSecurityDeposit: MetalWeight(gold22k: girviGold),
      );
    } catch (_) {
      return const MetalInflow();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // METAL OUTWARD
  // ─────────────────────────────────────────────────────────────────────────
  Future<MetalOutflow> _getMetalOutflow(DateTime start, DateTime end) async {
    try {
      // Retail dispatch: bill_items for today's bills
      final bills = await (_db.select(_db.bills)
            ..where((b) =>
                b.billDate.isBetweenValues(start, end) &
                b.status.equals('ACTIVE')))
          .get();

      double retailGold22 = 0, retailGold18 = 0, retailSilver = 0;
      for (final bill in bills) {
        final items = await (_db.select(_db.billItems)
              ..where((i) => i.billId.equals(bill.id)))
            .get();
        for (final item in items) {
          if (item.purity == '22K')
            retailGold22 += item.netWeight;
          else if (item.purity == '18K')
            retailGold18 += item.netWeight;
          else if (item.purity == 'SLV') retailSilver += item.netWeight;
        }
      }

      // Karigar issue: karigar_issues today
      final karigarIssues = await (_db.select(_db.karigarIssues)
            ..where((i) => i.issueDate.isBetweenValues(start, end)))
          .get();

      double karigarGold22 = 0, karigarGold18 = 0;
      for (final r in karigarIssues) {
        karigarGold22 += r.goldWeight22k ?? 0;
        karigarGold18 += r.goldWeight18k ?? 0;
      }

      return MetalOutflow(
        retailDispatch: MetalWeight(
          gold22k: retailGold22,
          gold18k: retailGold18,
          silver: retailSilver,
        ),
        karigarIssue: MetalWeight(
          gold22k: karigarGold22,
          gold18k: karigarGold18,
        ),
      );
    } catch (_) {
      return const MetalOutflow();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Opening Cash Balance (previous day's closing)
  // ─────────────────────────────────────────────────────────────────────────
  Future<double> _getOpeningCash(DateTime today) async {
    // Previous day's closing = opening + net cash of that day
    // For MVP: fetch cash_transactions running total up to start of today
    try {
      final allTx = await (_db.select(_db.cashTransactions)
            ..where((t) => t.transactionDate.isSmallerThanValue(today))
            ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
          .get();

      // Sum: inflow types (+) vs outflow types (-)
      double balance = 0;
      for (final tx in allTx) {
        const inTypes = ['due_receipt', 'vendor_refund', 'sale'];
        const outTypes = ['expense', 'vendor_payment', 'sales_return'];
        if (inTypes.contains(tx.transactionType)) {
          balance += tx.amount;
        } else if (outTypes.contains(tx.transactionType)) {
          balance -= tx.amount;
        }
      }
      return balance < 0 ? 0 : balance;
    } catch (_) {
      return 0.0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Anomaly Detection (30% threshold vs 7-day average)
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<AnomalyAlert>> _detectAnomalies({
    required DateTime date,
    required CashInflow cashIn,
    required CashOutflow cashOut,
  }) async {
    final anomalies = <AnomalyAlert>[];
    const threshold = 0.30; // 30% above average triggers alert

    try {
      // Get last 7 days expense average
      final sevenDaysAgo = date.subtract(const Duration(days: 7));
      final pastExpenses = await (_db.select(_db.cashTransactions)
            ..where((t) =>
                t.transactionDate.isBetweenValues(sevenDaysAgo, date) &
                t.transactionType.equals('expense')))
          .get();

      if (pastExpenses.isNotEmpty) {
        final avgExpense = pastExpenses.fold(0.0, (s, r) => s + r.amount) / 7;
        if (avgExpense > 0 && cashOut.expenses > avgExpense * (1 + threshold)) {
          final pct = ((cashOut.expenses - avgExpense) / avgExpense * 100);
          anomalies.add(AnomalyAlert(
            message:
                'Operational expenses are ${pct.toStringAsFixed(0)}% above 7-day average',
            category: 'expense',
            todayValue: cashOut.expenses,
            avgValue: avgExpense,
            percentChange: pct,
          ));
        }
      }
    } catch (_) {}

    return anomalies;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Predictive Closing (linear projection)
  // ─────────────────────────────────────────────────────────────────────────
  PredictedClosing? _buildPrediction({
    required DateTime date,
    required double openingCash,
    required CashInflow cashIn,
    required CashOutflow cashOut,
  }) {
    final now = DateTime.now();
    if (now.day != date.day) return null; // Only for today

    final shopOpenHour = 10; // 10 AM
    final shopCloseHour = 20; // 8 PM
    final totalHours = shopCloseHour - shopOpenHour;
    final elapsedHours = (now.hour - shopOpenHour).clamp(0, totalHours);

    if (elapsedHours <= 0) return null;

    final currentNet = cashIn.total - cashOut.total;
    final projectedNet = (currentNet / elapsedHours) * totalHours;
    final predictedClosing = openingCash + projectedNet;

    return PredictedClosing(
      predictedCash: predictedClosing < 0 ? 0 : predictedClosing,
      vsYesterdayPercent: 0, // Extend with yesterday's data
      vsLastWeekPercent: 0,
      isPositiveTrend: predictedClosing > openingCash,
    );
  }
}

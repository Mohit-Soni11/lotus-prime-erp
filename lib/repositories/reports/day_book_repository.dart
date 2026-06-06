// =============================================================================
// FILE        : day_book_repository.dart
// MODULE      : Reports & Analytics → Day Book
// LAYER       : Repository / Data Access
// PATH        : lib/repositories/reports/day_book_repository.dart
//
// ✅ THIS IS THE ONLY REPOSITORY — DELETE the old duplicate at:
//    lib/logic/report/day_book/day_book_repository.dart
//
// DESCRIPTION : PRODUCTION GRADE — All Drift queries use EXACT column names
//               from the actual database tables.
//
//               DB Tables used:
//               ┌─────────────────────────────────────────────────────────┐
//               │ Bills            → GST (TAX-) & Non-GST (EST-) sales    │
//               │ BillItems        → Metal weight dispatched in sales      │
//               │ CashTransactions → All income & expense flows            │
//               │ GirviLoans       → Girvi disbursed + metal pledged       │
//               │ GirviPayments    → Girvi receipts (INTEREST/FULL_RELEASE)│
//               │ KarigarIssues    → Metal issued to karigar               │
//               │ KarigarReceipts  → Finished goods + making charge paid   │
//               │ ShopProfiles     → Opening cash balance                  │
//               └─────────────────────────────────────────────────────────┘
//
//               CashTransactions column names (from app_database.dart):
//               type      → 'INCOME' | 'EXPENSE'
//               category  → 'ADVANCE' | 'ORDER_DELIVERY' | 'GIRVI_RETURN' |
//                           'LOAN_RECEIVED' | 'INTEREST_RECEIVED' |
//                           'MISC_INCOME' | 'OTHER_INCOME' |
//                           'SHOP_RENT' | 'STAFF_SALARY' | 'ELECTRICITY' |
//                           'PURCHASE_PAYMENT' | 'GIRVI_GIVEN' |
//                           'MAINTENANCE' | 'ADVERTISING' | 'TRANSPORT' |
//                           'BANK_CHARGES' | 'GOVT_FEES' |
//                           'MISC_EXPENSE' | 'OTHER_EXPENSE'
//               txnDate   → DateTime of transaction
//               isVoided  → bool (false = active)
//               paymentMode → 'CASH' | 'UPI' | 'CARD' | 'BANK' | 'CHEQUE'
// =============================================================================

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../database/db/app_database.dart';
import '../../models/reports/day_book/day_book_models.dart';

class DayBookRepository {
  final AppDatabase _db;
  DayBookRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  // ==========================================================================
  // MASTER: Fetch complete Day Book for a given date
  // All queries run in parallel via Future.wait for performance
  // ==========================================================================
  Future<DayBookSummary> fetchDayBook(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      // ── Run all queries in parallel ────────────────────────────────────────
      final results = await Future.wait([
        _fetchGstBills(start, end), // 0: GstBillSummary
        _fetchNonGstBills(start, end), // 1: NonGstBillSummary
        _fetchIncomeByCategory(start, end), // 2: Map<String, double>
        _fetchExpenseByCategory(start, end), // 3: Map<String, double>
        _fetchKarigarFinishedGoods(start, end), // 4: MetalWeight
        _fetchGirviSecurityDeposit(start, end), // 5: MetalWeight
        _fetchRetailMetalDispatch(start, end), // 6: MetalWeight
        _fetchKarigarIssues(start, end), // 7: MetalWeight
        _fetchOpeningCash(), // 8: double
        _fetch7DayExpenseAvg(date), // 9: double
        _fetchPaymentBreakup(start, end), // 10: PaymentBreakup
        _fetchDueCollectionReceipts(start, end), // 11: double
      ]);

      final gstSales = results[0] as GstBillSummary;
      final nonGstSales = results[1] as NonGstBillSummary;
      final incomeMap = results[2] as Map<String, double>;
      final expenseMap = results[3] as Map<String, double>;
      final karigarMetal = results[4] as MetalWeight;
      final girviMetal = results[5] as MetalWeight;
      final retailMetal = results[6] as MetalWeight;
      final karigarIssue = results[7] as MetalWeight;
      final openingCash = results[8] as double;
      final avgExpense = results[9] as double;
      final payBreakup = results[10] as PaymentBreakup;
      final dueCollection = results[11] as double;

      // ── Build CashInflow ───────────────────────────────────────────────────
      final cashIn = CashInflow(
        gstSales: gstSales,
        nonGstSales: nonGstSales,
        dueCollection: dueCollection,
        advance: incomeMap['ADVANCE'] ?? 0,
        orderDelivery: incomeMap['ORDER_DELIVERY'] ?? 0,
        girviReturn: incomeMap['GIRVI_RETURN'] ?? 0,
        loanReceived: incomeMap['LOAN_RECEIVED'] ?? 0,
        interestRec: incomeMap['INTEREST_RECEIVED'] ?? 0,
        miscIncome: incomeMap['MISC_INCOME'] ?? 0,
        otherIncome: incomeMap['OTHER_INCOME'] ?? 0,
      );

      // ── Build CashOutflow ─────────────────────────────────────────────────
      final cashOut = CashOutflow(
        shopRent: expenseMap['SHOP_RENT'] ?? 0,
        staffSalary: expenseMap['STAFF_SALARY'] ?? 0,
        electricity: expenseMap['ELECTRICITY'] ?? 0,
        purchasePayment: expenseMap['PURCHASE_PAYMENT'] ?? 0,
        girviGiven: expenseMap['GIRVI_GIVEN'] ?? 0,
        maintenance: expenseMap['MAINTENANCE'] ?? 0,
        advertising: expenseMap['ADVERTISING'] ?? 0,
        transport: expenseMap['TRANSPORT'] ?? 0,
        bankCharges: expenseMap['BANK_CHARGES'] ?? 0,
        govtFees: expenseMap['GOVT_FEES'] ?? 0,
        miscExpense: expenseMap['MISC_EXPENSE'] ?? 0,
        otherExpense: expenseMap['OTHER_EXPENSE'] ?? 0,
      );

      // ── Build Metal flows ─────────────────────────────────────────────────
      final metalIn = MetalInflow(
        karigarFinishedGoods: karigarMetal,
        girviSecurityDeposit: girviMetal,
      );
      final metalOut = MetalOutflow(
        retailDispatch: retailMetal,
        karigarIssue: karigarIssue,
      );

      // ── Anomaly Detection ─────────────────────────────────────────────────
      final anomalies = _detectAnomalies(
        todayExpense: cashOut.total,
        avgExpense: avgExpense,
        cashInTotal: cashIn.total,
      );

      // ── Prediction ────────────────────────────────────────────────────────
      final prediction = _buildPrediction(
        date: date,
        openingCash: openingCash,
        netSoFar: cashIn.total - cashOut.total,
      );

      return DayBookSummary(
        date: date,
        openingCash: openingCash,
        cashIn: cashIn,
        cashOut: cashOut,
        metalIn: metalIn,
        metalOut: metalOut,
        paymentBreakup: payBreakup,
        anomalies: anomalies,
        prediction: prediction,
      );
    } catch (e, stack) {
      debugPrint('❌ DayBookRepository.fetchDayBook: $e\n$stack');
      rethrow;
    }
  }

  // ==========================================================================
  // 1. GST BILLS — billNo LIKE 'TAX-%' AND status='ACTIVE'
  // ==========================================================================
  Future<GstBillSummary> _fetchGstBills(DateTime start, DateTime end) async {
    try {
      final rows = await (_db.select(_db.bills)
            ..where((b) =>
                b.billNo.like('TAX-%') &
                b.status.equals('ACTIVE') &
                b.billDate.isBiggerOrEqualValue(start) &
                b.billDate.isSmallerOrEqualValue(end)))
          .get();

      if (rows.isEmpty) return const GstBillSummary();

      double finalTotal = 0;
      double paidTotal = 0;

      for (final b in rows) {
        finalTotal += b.finalAmount;
        paidTotal += b.paidAmount;
      }

      // GST = 3% included in finalAmount
      final taxable = finalTotal / 1.03;
      final gst = finalTotal - taxable;

      return GstBillSummary(
        billCount: rows.length,
        taxableAmount: taxable,
        cgst: gst / 2,
        sgst: gst / 2,
        finalAmount: finalTotal,
        payments: PaymentBreakup(cash: paidTotal),
      );
    } catch (e) {
      debugPrint('❌ _fetchGstBills: $e');
      return const GstBillSummary();
    }
  }

  // ==========================================================================
  // 2. NON-GST BILLS — billNo LIKE 'EST-%' AND status='ACTIVE'
  // ==========================================================================
  Future<NonGstBillSummary> _fetchNonGstBills(
      DateTime start, DateTime end) async {
    try {
      final rows = await (_db.select(_db.bills)
            ..where((b) =>
                (b.billNo.like('INV-%') | b.billNo.like('EST-%')) &
                b.status.equals('ACTIVE') &
                b.billDate.isBiggerOrEqualValue(start) &
                b.billDate.isSmallerOrEqualValue(end)))
          .get();

      if (rows.isEmpty) return const NonGstBillSummary();

      double total = 0;
      double paid = 0;
      for (final b in rows) {
        total += b.finalAmount;
        paid += b.paidAmount;
      }

      return NonGstBillSummary(
        billCount: rows.length,
        totalAmount: total,
        payments: PaymentBreakup(cash: paid),
      );
    } catch (e) {
      debugPrint('❌ _fetchNonGstBills: $e');
      return const NonGstBillSummary();
    }
  }

  // ==========================================================================
  // 3. INCOME by Category
  // CashTransactions WHERE type='INCOME' AND isVoided=false
  // ==========================================================================
  Future<Map<String, double>> _fetchIncomeByCategory(
      DateTime start, DateTime end) async {
    try {
      final rows = await (_db.select(_db.cashTransactions)
            ..where((t) =>
                t.type.equals('INCOME') &
                t.isVoided.equals(false) &
                t.txnDate.isBiggerOrEqualValue(start) &
                t.txnDate.isSmallerOrEqualValue(end)))
          .get();

      final map = <String, double>{};
      for (final r in rows) {
        map[r.category] = (map[r.category] ?? 0) + r.amount;
      }
      return map;
    } catch (e) {
      debugPrint('❌ _fetchIncomeByCategory: $e');
      return {};
    }
  }

  // ==========================================================================
  // 4. EXPENSE by Category
  // CashTransactions WHERE type='EXPENSE' AND isVoided=false
  // ==========================================================================
  Future<Map<String, double>> _fetchExpenseByCategory(
      DateTime start, DateTime end) async {
    try {
      final rows = await (_db.select(_db.cashTransactions)
            ..where((t) =>
                t.type.equals('EXPENSE') &
                t.isVoided.equals(false) &
                t.txnDate.isBiggerOrEqualValue(start) &
                t.txnDate.isSmallerOrEqualValue(end)))
          .get();

      final map = <String, double>{};
      for (final r in rows) {
        map[r.category] = (map[r.category] ?? 0) + r.amount;
      }
      return map;
    } catch (e) {
      debugPrint('❌ _fetchExpenseByCategory: $e');
      return {};
    }
  }

  // ==========================================================================
  // 5. METAL IN: Karigar Finished Goods
  // KarigarReceipts WHERE receiptDate in range
  // ==========================================================================
  Future<MetalWeight> _fetchKarigarFinishedGoods(
      DateTime start, DateTime end) async {
    try {
      final receipts = await (_db.select(_db.karigarReceipts)
            ..where((r) =>
                r.receiptDate.isBiggerOrEqualValue(start) &
                r.receiptDate.isSmallerOrEqualValue(end)))
          .get();

      if (receipts.isEmpty) return const MetalWeight();

      final totals = <String, double>{};

      for (final receipt in receipts) {
        final issue = await (_db.select(_db.karigarIssues)
              ..where((i) => i.id.equals(receipt.issueId)))
            .getSingleOrNull();

        if (issue == null) continue;

        _addMetal(
          totals,
          metalType: issue.metalType,
          purity: issue.purity,
          weight: receipt.netWeightReceived,
        );
      }

      return MetalWeight.fromEntries(totals);
    } catch (e) {
      debugPrint('❌ _fetchKarigarFinishedGoods: $e');
      return const MetalWeight();
    }
  }

  // ==========================================================================
  // 6. METAL IN: Girvi Security Deposit
  // GirviLoans WHERE startDate in range AND status='ACTIVE'
  // ==========================================================================
  Future<MetalWeight> _fetchGirviSecurityDeposit(
      DateTime start, DateTime end) async {
    try {
      final loans = await (_db.select(_db.girviLoans)
            ..where((l) =>
                l.startDate.isBiggerOrEqualValue(start) &
                l.startDate.isSmallerOrEqualValue(end) &
                l.status.equals('ACTIVE')))
          .get();

      if (loans.isEmpty) return const MetalWeight();

      final totals = <String, double>{};
      for (final loan in loans) {
        _addMetal(
          totals,
          metalType: loan.metalType,
          purity: loan.metalPurity,
          weight: loan.netWeight,
        );
      }

      return MetalWeight.fromEntries(totals);
    } catch (e) {
      debugPrint('❌ _fetchGirviSecurityDeposit: $e');
      return const MetalWeight();
    }
  }

  // ==========================================================================
  // 7. METAL OUT: Retail Dispatch
  // BillItems for today's active Bills
  // ==========================================================================
  Future<MetalWeight> _fetchRetailMetalDispatch(
      DateTime start, DateTime end) async {
    try {
      final bills = await (_db.select(_db.bills)
            ..where((b) =>
                b.status.equals('ACTIVE') &
                b.billDate.isBiggerOrEqualValue(start) &
                b.billDate.isSmallerOrEqualValue(end)))
          .get();

      if (bills.isEmpty) return const MetalWeight();

      final totals = <String, double>{};

      for (final bill in bills) {
        final items = await (_db.select(_db.billItems)
              ..where((i) => i.billId.equals(bill.id)))
            .get();

        for (final item in items) {
          _addMetal(
            totals,
            metalType: item.metalType,
            purity: item.purity,
            weight: item.netWeight,
          );
        }
      }

      return MetalWeight.fromEntries(totals);
    } catch (e) {
      debugPrint('❌ _fetchRetailMetalDispatch: $e');
      return const MetalWeight();
    }
  }

  // ==========================================================================
  // 8. METAL OUT: Karigar Issue
  // KarigarIssues WHERE issueDate in range AND status != 'Cancelled'
  // ==========================================================================
  Future<MetalWeight> _fetchKarigarIssues(DateTime start, DateTime end) async {
    try {
      final issues = await (_db.select(_db.karigarIssues)
            ..where((i) =>
                i.issueDate.isBiggerOrEqualValue(start) &
                i.issueDate.isSmallerOrEqualValue(end) &
                i.status.isNotIn(['Cancelled'])))
          .get();

      if (issues.isEmpty) return const MetalWeight();

      final totals = <String, double>{};
      for (final issue in issues) {
        _addMetal(
          totals,
          metalType: issue.metalType,
          purity: issue.purity,
          weight: issue.netWeightIssued,
        );
      }

      return MetalWeight.fromEntries(totals);
    } catch (e) {
      debugPrint('❌ _fetchKarigarIssues: $e');
      return const MetalWeight();
    }
  }

  // ==========================================================================
  // 9. OPENING CASH — from ShopProfiles.openingCashBalance
  // ==========================================================================
  Future<double> _fetchOpeningCash() async {
    try {
      final profile = await (_db.select(_db.shopProfiles)).getSingleOrNull();
      return profile?.openingCashBalance ?? 0.0;
    } catch (e) {
      debugPrint('❌ _fetchOpeningCash: $e');
      return 0.0;
    }
  }

  // ==========================================================================
  // 10. 7-DAY AVERAGE EXPENSE (for anomaly detection)
  // ==========================================================================
  Future<double> _fetch7DayExpenseAvg(DateTime today) async {
    try {
      final sevenDaysAgo = today.subtract(const Duration(days: 7));
      final start =
          DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);
      final end = DateTime(today.year, today.month, today.day, 0, 0, 0)
          .subtract(const Duration(seconds: 1));

      final rows = await (_db.select(_db.cashTransactions)
            ..where((t) =>
                t.type.equals('EXPENSE') &
                t.isVoided.equals(false) &
                t.txnDate.isBiggerOrEqualValue(start) &
                t.txnDate.isSmallerOrEqualValue(end)))
          .get();

      if (rows.isEmpty) return 0;
      final total = rows.fold(0.0, (sum, r) => sum + r.amount);
      return total / 7;
    } catch (e) {
      debugPrint('❌ _fetch7DayExpenseAvg: $e');
      return 0;
    }
  }

  // ==========================================================================
  // 11. PAYMENT MODE BREAKUP
  // CashTransactions WHERE type='INCOME' AND isVoided=false
  // paymentMode: CASH | UPI | CARD | BANK | CHEQUE
  // ==========================================================================
  Future<PaymentBreakup> _fetchPaymentBreakup(
      DateTime start, DateTime end) async {
    try {
      final cashRows = await (_db.select(_db.cashTransactions)
            ..where((t) =>
                t.type.equals('INCOME') &
                t.isVoided.equals(false) &
                t.referenceType.equals('BILL') &
                t.txnDate.isBiggerOrEqualValue(start) &
                t.txnDate.isSmallerOrEqualValue(end)))
          .get();

      final bankRows = await (_db.select(_db.bankTransactions)
            ..where((t) =>
                t.type.equals('CREDIT') &
                t.isVoided.equals(false) &
                t.referenceType.equals('BILL') &
                t.txnDate.isBiggerOrEqualValue(start) &
                t.txnDate.isSmallerOrEqualValue(end)))
          .get();

      double cash = 0, upi = 0, card = 0, bank = 0, cheque = 0;
      for (final r in cashRows) {
        switch (r.paymentMode.toUpperCase()) {
          case 'CASH':
            cash += r.amount;
            break;
          case 'UPI':
            upi += r.amount;
            break;
          case 'CARD':
            card += r.amount;
            break;
          case 'BANK':
            bank += r.amount;
            break;
          case 'CHEQUE':
            cheque += r.amount;
            break;
        }
      }

      for (final r in bankRows) {
        switch (r.paymentMode.toUpperCase()) {
          case 'UPI':
            upi += r.amount;
            break;
          case 'CARD':
            card += r.amount;
            break;
          case 'CHEQUE':
            cheque += r.amount;
            break;
          default:
            bank += r.amount;
            break;
        }
      }

      return PaymentBreakup(
        cash: cash,
        upi: upi,
        card: card,
        bank: bank,
        cheque: cheque,
      );
    } catch (e) {
      debugPrint('❌ _fetchPaymentBreakup: $e');
      return const PaymentBreakup();
    }
  }

  Future<double> _fetchDueCollectionReceipts(
      DateTime start, DateTime end) async {
    try {
      final cashRows = await (_db.select(_db.cashTransactions)
            ..where((t) =>
                t.type.equals('INCOME') &
                t.category.equals('DUE_COLLECTION') &
                t.isVoided.equals(false) &
                t.txnDate.isBiggerOrEqualValue(start) &
                t.txnDate.isSmallerOrEqualValue(end)))
          .get();

      final bankRows = await (_db.select(_db.bankTransactions)
            ..where((t) =>
                t.type.equals('CREDIT') &
                t.category.equals('DUE_COLLECTION') &
                t.isVoided.equals(false) &
                t.txnDate.isBiggerOrEqualValue(start) &
                t.txnDate.isSmallerOrEqualValue(end)))
          .get();

      final cashTotal = cashRows.fold<double>(0, (sum, r) => sum + r.amount);
      final bankTotal = bankRows.fold<double>(0, (sum, r) => sum + r.amount);
      return cashTotal + bankTotal;
    } catch (e) {
      debugPrint('_fetchDueCollectionReceipts: $e');
      return 0;
    }
  }

  // ==========================================================================
  // ANOMALY DETECTION (30% above 7-day average)
  // ==========================================================================
  List<AnomalyAlert> _detectAnomalies({
    required double todayExpense,
    required double avgExpense,
    required double cashInTotal,
  }) {
    final alerts = <AnomalyAlert>[];
    const threshold = 0.30; // 30%

    if (avgExpense > 0 && todayExpense > avgExpense * (1 + threshold)) {
      final pct = ((todayExpense - avgExpense) / avgExpense * 100);
      alerts.add(AnomalyAlert(
        message:
            'Expenses are ${pct.toStringAsFixed(0)}% above the 7-day average '
            '(average: INR ${avgExpense.toStringAsFixed(0)}).',
        category: 'expense',
        todayValue: todayExpense,
        avgValue: avgExpense,
        percentChange: pct,
      ));
    }

    return alerts;
  }

  // ==========================================================================
  // PREDICTIVE CLOSING (linear projection for today only)
  // ==========================================================================
  PredictedClosing? _buildPrediction({
    required DateTime date,
    required double openingCash,
    required double netSoFar,
  }) {
    final now = DateTime.now();
    if (date.day != now.day ||
        date.month != now.month ||
        date.year != now.year) {
      return null; // Only predict for today
    }

    const shopOpenHour = 10; // 10 AM
    const shopCloseHour = 20; // 8 PM
    const totalHours = shopCloseHour - shopOpenHour;

    final elapsedHours = (now.hour - shopOpenHour).clamp(0, totalHours);
    if (elapsedHours <= 0) return null;

    final projectedNet = (netSoFar / elapsedHours) * totalHours;
    final predictedClosing =
        (openingCash + projectedNet).clamp(0.0, double.infinity);

    return PredictedClosing(
      predictedCash: predictedClosing,
      vsYesterdayPct: 0,
      isPositiveTrend: predictedClosing > openingCash,
    );
  }

  // ==========================================================================
  // LIVE STREAM — Real-time auto-refresh for today's screen
  // Watches CashTransactions — any change triggers full rebuild
  // ==========================================================================
  Stream<void> watchTodayChanges() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _db
        .customSelect(
          '''
          SELECT id FROM cash_transactions
          WHERE txn_date >= ? AND txn_date <= ?
          UNION ALL
          SELECT id FROM bank_transactions
          WHERE txn_date >= ? AND txn_date <= ?
          UNION ALL
          SELECT id FROM bills
          WHERE bill_date >= ? AND bill_date <= ?
          UNION ALL
          SELECT bill_items.id
          FROM bill_items
          INNER JOIN bills ON bills.id = bill_items.bill_id
          WHERE bills.bill_date >= ? AND bills.bill_date <= ?
          ''',
          variables: [
            Variable.withDateTime(start),
            Variable.withDateTime(end),
            Variable.withDateTime(start),
            Variable.withDateTime(end),
            Variable.withDateTime(start),
            Variable.withDateTime(end),
            Variable.withDateTime(start),
            Variable.withDateTime(end),
          ],
          readsFrom: {
            _db.cashTransactions,
            _db.bankTransactions,
            _db.bills,
            _db.billItems,
          },
        )
        .watch()
        .asyncMap((_) async {});
  }

  void _addMetal(
    Map<String, double> totals, {
    required String metalType,
    required String? purity,
    required double weight,
  }) {
    if (weight == 0) return;
    final metal = _normalizeMetal(metalType);
    final grade = _normalizePurity(metal, purity);
    final key = MetalWeight.entryKey(metal, grade);
    totals[key] = (totals[key] ?? 0) + weight;
  }

  String _normalizeMetal(String rawValue) {
    final value = rawValue.trim().toLowerCase();
    if (value.contains('gold')) return 'Gold';
    if (value.contains('silver')) return 'Silver';
    if (value.contains('platinum')) return 'Platinum';
    if (value.contains('diamond')) return 'Diamond';
    if (value.isEmpty) return 'Other';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String _normalizePurity(String metal, String? rawValue) {
    final value = (rawValue ?? '').trim().toUpperCase();
    if (metal == 'Gold') {
      const aliases = {
        '999': '24K',
        '995': '24K',
        '916': '22K',
        '875': '21K',
        '833': '20K',
        '750': '18K',
        '585': '14K',
      };
      return aliases[value] ?? (value.isEmpty ? 'Unspecified' : value);
    }
    return value.isEmpty ? 'Standard' : value;
  }
}

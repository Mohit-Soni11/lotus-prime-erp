// ==========================================
// FILE: defaulter_repository.dart
// MODULE: Customer → Defaulter List
// DESCRIPTION: Database layer. All Drift queries for defaulter data.
//              Fetches active loans with overdue calculation,
//              maps raw DB rows to DefaulterModel objects.
// ==========================================

import 'package:drift/drift.dart';

import '../../database/db/app_database.dart';
import '../../models/customer/defaulter_model.dart';
import '../../core/logging/app_logger.dart';

class DefaulterRepository {
  // Singleton pattern — same as DashboardRepository
  final AppDatabase _db = AppDatabase();

  // ==========================================
  // MAIN FETCH: All Defaulters
  // ==========================================
  // Rule:
  //   Primary source = Loans table (ACTIVE status)
  //   A loan is "defaulting" when it is ACTIVE and the customer
  //   hasn't closed it (any ACTIVE loan qualifies as a receivable).
  //   Overdue days = today - startDate.
  //   Interest is accrued via Simple Interest formula.
  // ==========================================

  Future<List<DefaulterModel>> fetchAllDefaulters() async {
    try {
      final today = DateTime.now();

      // --- STEP 1: Fetch all ACTIVE loans with customer info (JOIN) ---
      final query = _db.select(_db.loans).join([
        leftOuterJoin(
          _db.customers,
          _db.customers.id.equalsExp(_db.loans.customerId),
        ),
      ])
        ..where(_db.loans.status.equals('ACTIVE'));

      final rows = await query.get();

      final List<DefaulterModel> defaulters = [];

      for (final row in rows) {
        final loan = row.readTable(_db.loans);
        final customer = row.readTableOrNull(_db.customers);

        // Guard: skip if customer deleted (loan has cascade but safety net)
        if (customer == null) continue;

        // Calculate overdue
        final int daysOverdue = today.difference(loan.startDate).inDays;

        // Calculate Simple Interest: P × R × T (months) / 100
        final double months = daysOverdue / 30.0;
        final double interestAccrued =
            (loan.loanAmount * loan.interestRate * months) / 100.0;
        final double totalDue = loan.loanAmount + interestAccrued;

        // Determine risk level
        final riskLevel = DefaulterModel.riskFromDays(daysOverdue);

        defaulters.add(DefaulterModel(
          customerId: customer.id,
          customerName: customer.name,
          mobile: customer.mobile,
          city: customer.city ?? '—',
          customerType: customer.type,
          defaulterType: DefaulterType.loan,
          referenceNo: loan.loanNo,
          principalAmount: loan.loanAmount,
          interestRate: loan.interestRate,
          interestAccrued: interestAccrued,
          totalDue: totalDue,
          startDate: loan.startDate,
          daysOverdue: daysOverdue,
          riskLevel: riskLevel,
        ));
      }

      // --- STEP 2: Sort by days overdue descending (most critical first) ---
      defaulters.sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));

      AppLogger.debug(
          '✅ DefaulterRepository: ${defaulters.length} defaulters fetched.');
      return defaulters;
    } catch (e) {
      AppLogger.debug('❌ DefaulterRepository.fetchAllDefaulters Error: $e');
      rethrow;
    }
  }

  // ==========================================
  // LIVE STREAM: Watch defaulters in real-time
  // ==========================================
  // Returns a stream that emits whenever loans table changes.
  // UI rebuilds automatically.
  // ==========================================

  Stream<List<DefaulterModel>> watchAllDefaulters() {
    final today = DateTime.now();

    final query = _db.select(_db.loans).join([
      leftOuterJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.loans.customerId),
      ),
    ])
      ..where(_db.loans.status.equals('ACTIVE'));

    return query.watch().map((rows) {
      final List<DefaulterModel> defaulters = [];

      for (final row in rows) {
        final loan = row.readTable(_db.loans);
        final customer = row.readTableOrNull(_db.customers);

        if (customer == null) continue;

        final int daysOverdue = today.difference(loan.startDate).inDays;
        final double months = daysOverdue / 30.0;
        final double interestAccrued =
            (loan.loanAmount * loan.interestRate * months) / 100.0;
        final double totalDue = loan.loanAmount + interestAccrued;
        final riskLevel = DefaulterModel.riskFromDays(daysOverdue);

        defaulters.add(DefaulterModel(
          customerId: customer.id,
          customerName: customer.name,
          mobile: customer.mobile,
          city: customer.city ?? '—',
          customerType: customer.type,
          defaulterType: DefaulterType.loan,
          referenceNo: loan.loanNo,
          principalAmount: loan.loanAmount,
          interestRate: loan.interestRate,
          interestAccrued: interestAccrued,
          totalDue: totalDue,
          startDate: loan.startDate,
          daysOverdue: daysOverdue,
          riskLevel: riskLevel,
        ));
      }

      defaulters.sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));
      return defaulters;
    });
  }

  // ==========================================
  // STATS ONLY (lightweight count query)
  // ==========================================

  Future<int> fetchDefaulterCount() async {
    try {
      final count = await (_db.select(_db.loans)
            ..where((tbl) => tbl.status.equals('ACTIVE')))
          .get()
          .then((list) => list.length);
      return count;
    } catch (e) {
      AppLogger.debug('❌ DefaulterRepository.fetchDefaulterCount Error: $e');
      return 0;
    }
  }
}
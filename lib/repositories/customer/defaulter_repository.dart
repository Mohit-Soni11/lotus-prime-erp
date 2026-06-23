// =============================================================================
// FILE        : defaulter_repository.dart
// MODULE      : Risk & Collections
// LAYER       : Repository
// DESCRIPTION : Real-time Girvi risk queue backed by girvi_loans/payments.
// =============================================================================

import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../core/logging/app_logger.dart';
import '../../database/db/app_database.dart';
import '../../models/customer/defaulter_model.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../girvi/girvi_repository.dart';

class DefaulterRepository {
  final AppDatabase _db;

  DefaulterRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  Future<List<DefaulterModel>> fetchAllDefaulters({
    bool syncStatuses = true,
  }) async {
    try {
      if (syncStatuses) {
        final girviRepo = GirviRepository(_db);
        await girviRepo.syncOverdueStatus();
        await girviRepo.syncSettlementStatus();
      }

      final now = DateTime.now();
      final openStatuses = [
        GirviStatus.active.dbValue,
        GirviStatus.overdue.dbValue,
        GirviStatus.partialRelease.dbValue,
      ];

      final query = _db.select(_db.girviLoans).join([
        innerJoin(
          _db.customers,
          _db.customers.id.equalsExp(_db.girviLoans.customerId),
        ),
      ])
        ..where(_db.girviLoans.status.isIn(openStatuses));

      final rows = await query.get();
      final loanIds =
          rows.map((row) => row.readTable(_db.girviLoans).id).toList();
      final paymentSummary = await _loadPaymentSummary(loanIds);

      final accounts = <DefaulterModel>[];
      for (final row in rows) {
        final loan = row.readTable(_db.girviLoans);
        final customer = row.readTable(_db.customers);
        final summary = paymentSummary[loan.id] ?? _PaymentSummary.empty();
        final account = _mapRiskAccount(
          loan: loan,
          customer: customer,
          summary: summary,
          now: now,
        );
        if (account != null) accounts.add(account);
      }

      accounts.sort((a, b) {
        final riskCompare = b.daysOverdue.compareTo(a.daysOverdue);
        if (riskCompare != 0) return riskCompare;
        return b.totalDue.compareTo(a.totalDue);
      });

      AppLogger.debug(
        'Risk & Collections: ${accounts.length} Girvi risk accounts loaded.',
      );
      return accounts;
    } catch (e) {
      AppLogger.debug('Risk & Collections fetch failed: $e');
      rethrow;
    }
  }

  Stream<List<DefaulterModel>> watchAllDefaulters() {
    return _db
        .customSelect(
          'SELECT 1 AS watch_key',
          readsFrom: {
            _db.girviLoans,
            _db.girviPayments,
            _db.customers,
          },
        )
        .watch()
        .asyncMap((_) => fetchAllDefaulters());
  }

  Future<int> fetchDefaulterCount() async {
    try {
      final accounts = await fetchAllDefaulters();
      return accounts.length;
    } catch (e) {
      AppLogger.debug('Risk & Collections count failed: $e');
      return 0;
    }
  }

  Future<Map<int, _PaymentSummary>> _loadPaymentSummary(
    List<int> loanIds,
  ) async {
    if (loanIds.isEmpty) return const {};

    final payments = await (_db.select(_db.girviPayments)
          ..where((payment) => payment.girviId.isIn(loanIds)))
        .get();

    final byLoan = <int, _PaymentSummary>{};
    for (final payment in payments) {
      final current = byLoan[payment.girviId] ?? _PaymentSummary.empty();
      byLoan[payment.girviId] = current.add(payment);
    }
    return byLoan;
  }

  DefaulterModel? _mapRiskAccount({
    required GirviLoan loan,
    required Customer customer,
    required _PaymentSummary summary,
    required DateTime now,
  }) {
    final status = GirviStatus.fromDb(loan.status);
    final maturityDate = loan.maturityDate ??
        GirviLoanModel.addChargeableMonths(
          loan.startDate,
          loan.durationMonths,
        );
    final overdueDays = _daysAfter(maturityDate, now);
    final isMatured = overdueDays > 0;
    final isTrackedStatus = status == GirviStatus.overdue ||
        status == GirviStatus.partialRelease ||
        (status == GirviStatus.active && isMatured);

    if (!isTrackedStatus) return null;

    final interestMonths =
        GirviLoanModel.chargeableMonthsBetween(loan.startDate, now);
    final originalPrincipal = loan.loanAmount + summary.legacyPrincipalRepaid;
    final grossInterest = GirviLoanModel.calculateCompoundInterest(
      principal: originalPrincipal,
      monthlyRatePercent: loan.interestRate,
      months: interestMonths,
    );
    final interestOutstanding = math.max(
      0.0,
      grossInterest - summary.interestPaid - summary.interestDiscount,
    );
    final principalOutstanding = math.max(
      0.0,
      loan.loanAmount - summary.principalPaid - summary.principalDiscount,
    );
    final totalDue = principalOutstanding + interestOutstanding;

    if (totalDue <= 0.01 && status != GirviStatus.partialRelease) {
      return null;
    }

    final lastActivityAt = _latestDate(
      loan.updatedAt,
      summary.lastPaymentDate,
      loan.createdAt,
    );
    final effectiveOverdueDays = math.max(overdueDays, 0);

    return DefaulterModel(
      loanId: loan.id,
      customerId: customer.id,
      customerName: customer.name,
      mobile: customer.mobile,
      city: _clean(customer.city, fallback: 'Not specified'),
      address: _formatCustomerAddress(customer),
      customerType: customer.customerTier,
      defaulterType: DefaulterType.loan,
      referenceNo: loan.ticketNo,
      itemSummary: _itemSummary(loan),
      statusLabel: status == GirviStatus.partialRelease
          ? 'Settlement Pending'
          : (isMatured ? 'Overdue' : status.displayName),
      statusValue: status.dbValue,
      principalAmount: originalPrincipal,
      principalOutstanding: principalOutstanding,
      interestRate: loan.interestRate,
      interestAccrued: grossInterest,
      interestOutstanding: interestOutstanding,
      totalDue: totalDue,
      totalReceived: summary.totalReceived,
      totalItemValue: loan.totalValue,
      netWeight: loan.netWeight,
      startDate: loan.startDate,
      maturityDate: maturityDate,
      lastPaymentDate: summary.lastPaymentDate,
      lastActivityAt: lastActivityAt,
      daysOverdue: effectiveOverdueDays,
      monthsOverdue: effectiveOverdueDays / 30.0,
      riskLevel: status == GirviStatus.partialRelease
          ? DefaulterRiskLevel.low
          : DefaulterModel.riskFromDays(effectiveOverdueDays),
    );
  }

  String _itemSummary(GirviLoan loan) {
    final pieces = loan.itemCount <= 0 ? 1 : loan.itemCount;
    final weight = loan.netWeight.toStringAsFixed(2);
    final itemName = loan.itemDescription.trim().isEmpty
        ? loan.metalType
        : loan.itemDescription.trim();
    return '$itemName | $pieces item${pieces == 1 ? '' : 's'} | $weight g';
  }

  String _formatCustomerAddress(Customer customer) {
    final parts = <String>[
      customer.addressLine1 ?? '',
      customer.addressLine2 ?? '',
      customer.city ?? '',
      customer.state ?? '',
      customer.pincode ?? '',
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? 'Address not available' : parts.join(', ');
  }

  String _clean(String? value, {required String fallback}) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    return trimmed;
  }

  int _daysAfter(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  DateTime _latestDate(DateTime? a, DateTime? b, DateTime fallback) {
    var latest = fallback;
    for (final value in [a, b]) {
      if (value != null && value.isAfter(latest)) latest = value;
    }
    return latest;
  }
}

class _PaymentSummary {
  final double totalReceived;
  final double interestPaid;
  final double principalPaid;
  final double interestDiscount;
  final double principalDiscount;
  final double legacyPrincipalRepaid;
  final DateTime? lastPaymentDate;

  const _PaymentSummary({
    required this.totalReceived,
    required this.interestPaid,
    required this.principalPaid,
    required this.interestDiscount,
    required this.principalDiscount,
    required this.legacyPrincipalRepaid,
    required this.lastPaymentDate,
  });

  factory _PaymentSummary.empty() {
    return const _PaymentSummary(
      totalReceived: 0,
      interestPaid: 0,
      principalPaid: 0,
      interestDiscount: 0,
      principalDiscount: 0,
      legacyPrincipalRepaid: 0,
      lastPaymentDate: null,
    );
  }

  _PaymentSummary add(GirviPayment payment) {
    final type = GirviPaymentType.fromDb(payment.paymentType);
    var nextInterestPaid = interestPaid;
    var nextPrincipalPaid = principalPaid;
    var nextInterestDiscount = interestDiscount;
    var nextPrincipalDiscount = principalDiscount;
    var nextLegacyPrincipalRepaid = legacyPrincipalRepaid;

    if (type == GirviPaymentType.interest ||
        type == GirviPaymentType.partialInterest) {
      nextInterestPaid += payment.amount;
    } else if (type == GirviPaymentType.fullRelease) {
      nextInterestPaid += payment.interestComponent;
      nextPrincipalPaid += payment.principalComponent;
      nextInterestDiscount += payment.interestDiscountComponent;
      nextPrincipalDiscount += payment.principalDiscountComponent;
    } else if (type == GirviPaymentType.partialPrincipal) {
      nextLegacyPrincipalRepaid += payment.amount;
    }

    final nextLastPaymentDate =
        lastPaymentDate == null || payment.paymentDate.isAfter(lastPaymentDate!)
            ? payment.paymentDate
            : lastPaymentDate;

    return _PaymentSummary(
      totalReceived: totalReceived + payment.amount,
      interestPaid: nextInterestPaid,
      principalPaid: nextPrincipalPaid,
      interestDiscount: nextInterestDiscount,
      principalDiscount: nextPrincipalDiscount,
      legacyPrincipalRepaid: nextLegacyPrincipalRepaid,
      lastPaymentDate: nextLastPaymentDate,
    );
  }
}

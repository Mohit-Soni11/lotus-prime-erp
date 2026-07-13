// =============================================================================
// FILE        : defaulter_repository.dart
// MODULE      : Risk & Collections
// LAYER       : Repository
// DESCRIPTION : Real-time Girvi risk queue backed by girvi_loans/payments.
// =============================================================================

import 'dart:math' as math;

import 'package:drift/drift.dart';

import 'package:lotus_erp/core/logging/app_logger.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import '../../logic/girvi/girvi_risk_policy.dart';
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
      final itemSnapshots = await _loadItemSnapshots(loanIds);

      final accounts = <DefaulterModel>[];
      for (final row in rows) {
        final loan = row.readTable(_db.girviLoans);
        final customer = row.readTable(_db.customers);
        final summary = paymentSummary[loan.id] ?? _PaymentSummary.empty();
        final itemSnapshot =
            itemSnapshots[loan.id] ?? _PledgedItemSnapshot.fromLoan(loan);
        final account = _mapRiskAccount(
          loan: loan,
          customer: customer,
          summary: summary,
          itemSnapshot: itemSnapshot,
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

  Future<Map<int, _PledgedItemSnapshot>> _loadItemSnapshots(
    List<int> loanIds,
  ) async {
    if (loanIds.isEmpty) return const {};

    final items = await (_db.select(_db.girviLoanItems)
          ..where((item) => item.girviId.isIn(loanIds))
          ..orderBy([
            (item) => OrderingTerm.asc(item.girviId),
            (item) => OrderingTerm.asc(item.serialNo),
          ]))
        .get();

    final grouped = <int, List<GirviLoanItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.girviId, () => <GirviLoanItem>[]).add(item);
    }

    return grouped.map(
      (loanId, items) => MapEntry(
        loanId,
        _PledgedItemSnapshot.fromItems(items),
      ),
    );
  }

  DefaulterModel? _mapRiskAccount({
    required GirviLoan loan,
    required Customer customer,
    required _PaymentSummary summary,
    required _PledgedItemSnapshot itemSnapshot,
    required DateTime now,
  }) {
    final status = GirviStatus.fromDb(loan.status);
    final maturityDate = loan.maturityDate ??
        GirviLoanModel.addChargeableMonths(
          loan.startDate,
          loan.durationMonths,
        );

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
    final assessment = GirviRiskPolicy.assess(
      status: status,
      startDate: loan.startDate,
      maturityDate: maturityDate,
      lastInterestPaidDate: loan.lastInterestPaidDate,
      principalDue: principalOutstanding,
      interestDue: interestOutstanding,
      now: now,
    );

    if (!assessment.isRiskAccount) return null;

    final lastActivityAt = _latestDate(
      loan.updatedAt,
      summary.lastPaymentDate,
      loan.createdAt,
    );

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
      itemSummary: itemSnapshot.summary,
      pledgedItemCount: itemSnapshot.itemCount,
      itemName: itemSnapshot.itemName,
      metalType: itemSnapshot.metalType,
      purity: itemSnapshot.purity,
      pieces: itemSnapshot.pieces,
      grossWeight: itemSnapshot.grossWeight,
      lessWeight: itemSnapshot.lessWeight,
      statusLabel: assessment.statusLabel,
      statusValue: status.dbValue,
      principalAmount: originalPrincipal,
      principalOutstanding: principalOutstanding,
      interestRate: loan.interestRate,
      interestAccrued: grossInterest,
      interestOutstanding: interestOutstanding,
      totalDue: totalDue,
      totalReceived: summary.totalReceived,
      totalItemValue: itemSnapshot.totalValue > 0
          ? itemSnapshot.totalValue
          : loan.totalValue,
      netWeight:
          itemSnapshot.netWeight > 0 ? itemSnapshot.netWeight : loan.netWeight,
      startDate: loan.startDate,
      maturityDate: maturityDate,
      lastPaymentDate: summary.lastPaymentDate,
      lastActivityAt: lastActivityAt,
      daysOverdue: assessment.riskAgeDays,
      monthsOverdue: assessment.riskAgeDays / 30.0,
      unpaidInterestMonths: assessment.unpaidInterestMonths,
      maturityOverdueDays: assessment.maturityOverdueDays,
      isInterestOverdue: assessment.isInterestOverdue,
      isMaturityOverdue: assessment.isMaturityOverdue,
      riskLevel: _mapSeverity(assessment.severity),
      collectionStage: assessment.stageLabel,
      nextActionLabel: assessment.nextActionLabel,
    );
  }

  DefaulterRiskLevel _mapSeverity(GirviRiskSeverity severity) {
    switch (severity) {
      case GirviRiskSeverity.critical:
        return DefaulterRiskLevel.critical;
      case GirviRiskSeverity.high:
        return DefaulterRiskLevel.high;
      case GirviRiskSeverity.medium:
        return DefaulterRiskLevel.medium;
      case GirviRiskSeverity.low:
      case GirviRiskSeverity.none:
        return DefaulterRiskLevel.low;
    }
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

  DateTime _latestDate(DateTime? a, DateTime? b, DateTime fallback) {
    var latest = fallback;
    for (final value in [a, b]) {
      if (value != null && value.isAfter(latest)) latest = value;
    }
    return latest;
  }
}

class _PledgedItemSnapshot {
  final int itemCount;
  final String itemName;
  final String metalType;
  final String purity;
  final int pieces;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double totalValue;

  const _PledgedItemSnapshot({
    required this.itemCount,
    required this.itemName,
    required this.metalType,
    required this.purity,
    required this.pieces,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.totalValue,
  });

  factory _PledgedItemSnapshot.fromItems(List<GirviLoanItem> items) {
    if (items.isEmpty) {
      return const _PledgedItemSnapshot(
        itemCount: 0,
        itemName: 'Pledged item',
        metalType: 'Not specified',
        purity: 'Not specified',
        pieces: 0,
        grossWeight: 0,
        lessWeight: 0,
        netWeight: 0,
        totalValue: 0,
      );
    }

    final sorted = List<GirviLoanItem>.from(items)
      ..sort((a, b) => a.serialNo.compareTo(b.serialNo));
    final first = sorted.first;
    final itemName = _itemDisplayName(first.itemName, fallback: 'Pledged item');
    final suffix = sorted.length > 1 ? ' + ${sorted.length - 1} more' : '';

    return _PledgedItemSnapshot(
      itemCount: sorted.length,
      itemName: '$itemName$suffix',
      metalType: _singleOrMixed(sorted.map((item) => item.metalType)),
      purity: _singleOrMixed(sorted.map((item) => item.purity)),
      pieces: sorted.fold(0, (sum, item) => sum + item.pieces),
      grossWeight: sorted.fold(0.0, (sum, item) => sum + item.grossWeight),
      lessWeight: sorted.fold(0.0, (sum, item) => sum + item.lessWeight),
      netWeight: sorted.fold(0.0, (sum, item) => sum + item.netWeight),
      totalValue: sorted.fold(0.0, (sum, item) => sum + item.valuationAmount),
    );
  }

  factory _PledgedItemSnapshot.fromLoan(GirviLoan loan) {
    final itemName = _fallbackItemName(loan);
    final pieces = loan.itemCount <= 0 ? 1 : loan.itemCount;

    return _PledgedItemSnapshot(
      itemCount: pieces,
      itemName: itemName,
      metalType: _readableText(loan.metalType, fallback: 'Not specified'),
      purity: _readableText(loan.metalPurity, fallback: 'Not specified'),
      pieces: pieces,
      grossWeight: loan.grossWeight,
      lessWeight: loan.stoneWeight,
      netWeight: loan.netWeight,
      totalValue: loan.totalValue,
    );
  }

  String get summary {
    final parts = <String>[
      itemName,
      metalType,
      purity,
      '$pieces pc${pieces == 1 ? '' : 's'}',
      'Net ${netWeight.toStringAsFixed(3)} g',
    ];
    return parts.join(' | ');
  }

  static String _fallbackItemName(GirviLoan loan) {
    final raw = loan.itemDescription.trim();
    if (raw.isEmpty) return _readableText(loan.metalType, fallback: 'Item');
    final firstLine = raw.split(RegExp(r'\r?\n')).first.trim();
    final firstSegment = firstLine.split('|').first.trim();
    final withoutSerial = firstSegment
        .replaceFirst(RegExp(r'^#?\d+\s*'), '')
        .replaceFirst(RegExp(r'^-\s*'), '')
        .trim();
    return _itemDisplayName(withoutSerial, fallback: 'Pledged item');
  }

  static String _singleOrMixed(Iterable<String> values) {
    final cleanValues = values
        .map((value) => _readableText(value, fallback: ''))
        .where((value) => value.isNotEmpty)
        .toSet();
    if (cleanValues.isEmpty) return 'Not specified';
    if (cleanValues.length == 1) return cleanValues.first;
    return 'Mixed';
  }

  static String _itemDisplayName(String value, {required String fallback}) {
    final text = _readableText(value, fallback: fallback);
    if (text.length <= 36) return text;
    return '${text.substring(0, 33).trimRight()}...';
  }

  static String _readableText(String? value, {required String fallback}) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    return trimmed;
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

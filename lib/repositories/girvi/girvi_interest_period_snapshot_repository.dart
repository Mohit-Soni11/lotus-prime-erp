import 'package:drift/drift.dart' as drift;

import '../../database/db/app_database.dart';
import '../../models/girvi/girvi_interest_period_snapshot.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_loan_model.dart';
import 'girvi_interest_payment_adjustments.dart';

/// Owns the persisted financial timeline used by notices and recovery.
///
/// This repository is deliberately separate from document generation. A
/// snapshot is calculated by the financial domain once, then documents only
/// read the stored result.
class GirviInterestPeriodSnapshotRepository {
  GirviInterestPeriodSnapshotRepository(this._db);

  final AppDatabase _db;

  Future<Map<int, List<GirviInterestPeriodSnapshot>>> synchronizeForLoans(
    List<GirviLoanWithCustomer> accounts, {
    required DateTime asOf,
  }) async {
    await _db.ensureGirviInterestPeriodSnapshotSchema();
    final result = <int, List<GirviInterestPeriodSnapshot>>{};
    for (final account in accounts) {
      result[account.loan.id] = await _synchronizeLoan(
        loan: account.loan,
        principal: account.originalPrincipal,
        asOf: asOf,
        adjustments: account.interestAdjustments,
      );
    }
    return result;
  }

  Future<List<GirviInterestPeriodSnapshot>> getForLoan(int girviId) async {
    final rows = await _db.customSelect(
      '''
      SELECT id, girvi_id, period_sequence, period_from, period_to,
             interest_type, opening_amount, monthly_rate_percent,
             interest_per_month, chargeable_months, period_interest,
             closing_amount, is_finalized, source
      FROM girvi_interest_period_snapshots
      WHERE girvi_id = ?
      ORDER BY period_sequence ASC
      ''',
      variables: [drift.Variable.withInt(girviId)],
    ).get();
    return rows.map(_map).toList(growable: false);
  }

  Future<List<GirviInterestPeriodSnapshot>> synchronizeLoan({
    required GirviLoanModel loan,
    required double principal,
    required DateTime asOf,
  }) async {
    await _db.ensureGirviInterestPeriodSnapshotSchema();
    final payments = await (_db.select(_db.girviPayments)
          ..where((payment) => payment.girviId.equals(loan.id)))
        .get();
    return _synchronizeLoan(
      loan: loan,
      principal: principal,
      asOf: asOf,
      adjustments: GirviInterestPaymentAdjustments.fromPayments(payments),
    );
  }

  Future<List<GirviInterestPeriodSnapshot>> _synchronizeLoan({
    required GirviLoanModel loan,
    required double principal,
    required DateTime asOf,
    required List<GirviInterestAdjustment> adjustments,
  }) async {
    final existing = await getForLoan(loan.id);
    final end = loan.releaseDate ?? asOf;
    final months = GirviLoanModel.chargeableMonthsBetween(loan.startDate, end);
    if (months <= 0 || principal <= 0 || loan.interestRate <= 0) {
      return existing;
    }

    final desired = _buildDesired(
      loan: loan,
      principal: principal,
      months: months,
      end: end,
      adjustments: adjustments,
    );
    if (existing.isEmpty) {
      await _insertAll(desired);
      return getForLoan(loan.id);
    }

    final current = {for (final row in existing) row.sequence: row};
    final changed = existing.length != desired.length ||
        desired.any((wanted) {
          final stored = current[wanted.sequence];
          return stored == null ||
              stored.periodFrom != wanted.periodFrom ||
              stored.periodTo != wanted.periodTo ||
              stored.interestType != wanted.interestType ||
              (stored.openingAmount - wanted.openingAmount).abs() > 0.01 ||
              (stored.periodInterest - wanted.periodInterest).abs() > 0.01 ||
              (stored.closingAmount - wanted.closingAmount).abs() > 0.01 ||
              stored.finalized != wanted.finalized ||
              stored.source != wanted.source;
        });
    if (changed) {
      await _db.transaction(() async {
        await _db.customStatement(
          'DELETE FROM girvi_interest_period_snapshots WHERE girvi_id = ?',
          [loan.id],
        );
        await _insertAll(desired);
      });
      return getForLoan(loan.id);
    }
    return existing;
  }

  List<_SnapshotDraft> _buildDesired({
    required GirviLoanModel loan,
    required double principal,
    required int months,
    required DateTime end,
    required List<GirviInterestAdjustment> adjustments,
  }) {
    final normalizedType =
        GirviInterestCalculationType.forChargeableMonths(months);
    final quote = GirviInterestCalculator.quoteAt(
      principal: principal,
      monthlyRatePercent: loan.interestRate,
      startDate: loan.startDate,
      asOf: end,
      adjustments: adjustments,
    );
    if (GirviInterestCalculationType.isSimple(normalizedType)) {
      final line = quote.cycles.single;
      return [
        _draft(
          loan: loan,
          type: normalizedType,
          sequence: 1,
          from: loan.startDate,
          to: end,
          opening: principal,
          months: months,
          interest: line.interestAmount,
          closing: line.closingAmount,
          // A simple-interest account has one continually growing period. It
          // becomes immutable only once the loan itself is released.
          finalized: loan.releaseDate != null ||
              loan.girviStatus == GirviStatus.auctioned,
        ),
      ];
    }

    final lines = quote.cycles;
    return [
      for (final line in lines)
        _draft(
          loan: loan,
          type: normalizedType,
          sequence: line.cycleNumber,
          from: GirviLoanModel.addChargeableMonths(
            loan.startDate,
            GirviLoanModel.compoundCycleMonths * (line.cycleNumber - 1),
          ),
          to: line.cycleNumber == lines.length && !line.capitalizedAfterLine
              ? end
              : GirviLoanModel.addChargeableMonths(
                  loan.startDate,
                  GirviLoanModel.compoundCycleMonths * (line.cycleNumber - 1) +
                      line.months,
                ),
          opening: line.principalBase,
          months: line.months,
          interest: line.interestAmount,
          closing: line.closingAmount,
          finalized: line.months == GirviLoanModel.compoundCycleMonths,
        ),
    ];
  }

  _SnapshotDraft _draft({
    required GirviLoanModel loan,
    required String type,
    required int sequence,
    required DateTime from,
    required DateTime to,
    required double opening,
    required int months,
    required double interest,
    required double closing,
    required bool finalized,
  }) {
    return _SnapshotDraft(
      girviId: loan.id,
      sequence: sequence,
      periodFrom: from,
      periodTo: to,
      interestType: type,
      openingAmount: opening,
      monthlyRatePercent: loan.interestRate,
      interestPerMonth: opening * (loan.interestRate / 100),
      chargeableMonths: months,
      periodInterest: interest,
      closingAmount: closing,
      finalized: finalized,
      source: 'DATED_UNPAID_INTEREST_POLICY',
    );
  }

  Future<void> _insertAll(List<_SnapshotDraft> drafts) async {
    for (final draft in drafts) {
      await _insert(draft);
    }
  }

  Future<void> _insert(_SnapshotDraft draft) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customStatement('''
      INSERT OR IGNORE INTO girvi_interest_period_snapshots
      (girvi_id, period_sequence, period_from, period_to, interest_type,
       opening_amount, monthly_rate_percent, interest_per_month,
       chargeable_months, period_interest, closing_amount, is_finalized,
       source, created_at, updated_at)
      VALUES (
        ${draft.girviId}, ${draft.sequence},
        ${draft.periodFrom.millisecondsSinceEpoch},
        ${draft.periodTo.millisecondsSinceEpoch},
        '${_sqlText(draft.interestType)}',
        ${draft.openingAmount}, ${draft.monthlyRatePercent},
        ${draft.interestPerMonth}, ${draft.chargeableMonths},
        ${draft.periodInterest}, ${draft.closingAmount},
        ${draft.finalized ? 1 : 0}, '${_sqlText(draft.source)}',
        $now, $now
      )
      ''');
  }

  String _sqlText(String value) => value.replaceAll("'", "''");

  GirviInterestPeriodSnapshot _map(drift.QueryRow row) {
    final data = row.data;
    return GirviInterestPeriodSnapshot(
      id: data['id'] as int,
      girviId: data['girvi_id'] as int,
      sequence: data['period_sequence'] as int,
      periodFrom:
          DateTime.fromMillisecondsSinceEpoch(data['period_from'] as int),
      periodTo: DateTime.fromMillisecondsSinceEpoch(data['period_to'] as int),
      interestType: data['interest_type'] as String,
      openingAmount: (data['opening_amount'] as num).toDouble(),
      monthlyRatePercent: (data['monthly_rate_percent'] as num).toDouble(),
      interestPerMonth: (data['interest_per_month'] as num).toDouble(),
      chargeableMonths: data['chargeable_months'] as int,
      periodInterest: (data['period_interest'] as num).toDouble(),
      closingAmount: (data['closing_amount'] as num).toDouble(),
      finalized: (data['is_finalized'] as int) == 1,
      source: data['source'] as String,
    );
  }
}

class _SnapshotDraft {
  const _SnapshotDraft({
    required this.girviId,
    required this.sequence,
    required this.periodFrom,
    required this.periodTo,
    required this.interestType,
    required this.openingAmount,
    required this.monthlyRatePercent,
    required this.interestPerMonth,
    required this.chargeableMonths,
    required this.periodInterest,
    required this.closingAmount,
    required this.finalized,
    required this.source,
  });

  final int girviId;
  final int sequence;
  final DateTime periodFrom;
  final DateTime periodTo;
  final String interestType;
  final double openingAmount;
  final double monthlyRatePercent;
  final double interestPerMonth;
  final int chargeableMonths;
  final double periodInterest;
  final double closingAmount;
  final bool finalized;
  final String source;
}

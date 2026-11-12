import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../../../database/db/app_database.dart';
import '../../../../features/finance/ledger/data/finance_day_closure_repository.dart';
import '../../../../models/reports/day_book/day_book_models.dart';
import '../../../../repositories/reports/day_book_balance_verification_repository.dart';
import 'day_book_export_data.dart';

class DayBookExportLoader {
  DayBookExportLoader({AppDatabase? database})
      : _db = database ?? AppDatabase();

  final AppDatabase _db;

  Future<DayBookExportData> load(DayBookSummary summary) async {
    final dayKey = DateFormat('yyyyMMdd').format(summary.date);
    final verification =
        await DayBookBalanceVerificationRepository(_db).fetch(summary.date);
    final closure = await _db.customSelect(
      'SELECT closed_at, closed_by FROM finance_day_closures WHERE day_key = ?',
      variables: [Variable.withString(dayKey)],
    ).getSingleOrNull();
    final snapshot =
        await FinanceDayClosureRepository(_db).fetchSnapshot(summary.date);
    if (closure == null && snapshot != null) {
      throw StateError('Day closing snapshot has no matching day lock.');
    }
    if (snapshot != null) {
      _verifySavedPositions(summary, snapshot.json);
    }

    final closedAtEpoch = closure?.read<int>('closed_at');
    return DayBookExportData(
      summary: summary,
      openingVerification: verification,
      legacyClosedAt:
          closure != null && snapshot == null && closedAtEpoch != null
              ? DateTime.fromMillisecondsSinceEpoch(closedAtEpoch * 1000)
              : null,
      legacyClosedBy: closure != null && snapshot == null
          ? closure.readNullable<String>('closed_by')
          : null,
      closing: snapshot == null
          ? null
          : DayBookCloseEvidence.fromSnapshot(
              snapshot.json,
              sourceHash: snapshot.sourceHash,
              closedAt: closedAtEpoch == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(closedAtEpoch * 1000),
              closedBy: closure?.readNullable<String>('closed_by'),
            ),
    );
  }

  static void _verifySavedPositions(DayBookSummary summary, String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Day closing snapshot is invalid.');
    }
    final money = decoded['money'];
    final flow = summary.moneyFlow;
    if (money is! Map<String, dynamic> || flow == null) {
      throw StateError('Closed-day money position is unavailable for export.');
    }
    final amounts = <String, double>{
      'openingCash': flow.openingCash,
      'openingBank': flow.openingBank,
      'closingCash': flow.closingCash,
      'closingBank': flow.closingBank,
    };
    for (final entry in amounts.entries) {
      final saved = money[entry.key];
      if (saved is! num || (saved.toDouble() - entry.value).abs() >= 0.01) {
        throw StateError(
            'Day Book ${entry.key} differs from the saved day closing.');
      }
    }

    final savedMetal = decoded['ownedMetal'];
    final currentMetal = summary.ownedStockPosition;
    if (savedMetal is! Map<String, dynamic> || currentMetal == null) {
      throw StateError('Closed-day metal position is unavailable for export.');
    }
    for (final (name, position) in [
      ('gold', currentMetal.gold),
      ('silver', currentMetal.silver),
    ]) {
      final saved = savedMetal[name];
      if (saved is! Map<String, dynamic>) {
        throw StateError('Saved $name position is unavailable for export.');
      }
      final values = <String, double>{
        'openingGrams': position.openingGrams,
        'inwardGrams': position.inwardGrams,
        'soldGrams': position.soldGrams,
        'otherOutGrams': position.otherOutGrams,
        'closingGrams': position.closingGrams,
      };
      for (final entry in values.entries) {
        final recorded = saved[entry.key];
        if (recorded is! num ||
            (recorded.toDouble() - entry.value).abs() >= 0.001) {
          throw StateError('Day Book $name ${entry.key} differs from the '
              'saved day closing.');
        }
      }
    }
  }
}

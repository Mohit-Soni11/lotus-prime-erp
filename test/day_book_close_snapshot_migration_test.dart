import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/finance/ledger/data/finance_day_closure_repository.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('v74 closure history survives additive snapshot migration', () async {
    final directory = await Directory.systemTemp.createTemp('lotus-close-v74-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}shop.sqlite');
    final date = DateTime(2026, 6, 25, 12);
    final original = AppDatabase.forTesting(NativeDatabase(file));
    await original.into(original.cashTransactions).insert(
          CashTransactionsCompanion.insert(
            txnId: 'LEGACY-CASH',
            txnDate: date,
            type: 'INCOME',
            category: 'SALE',
            amount: const drift.Value(100),
          ),
        );
    expect(
        await FinanceDayClosureRepository(original)
            .closeDay(date, closingCash: 100, closedBy: 'owner-1'),
        isTrue);
    await original.close();

    final legacy = sqlite3.open(file.path);
    try {
      legacy.execute('DROP TRIGGER finance_day_close_snapshot_update');
      legacy.execute('DROP TRIGGER finance_day_close_snapshot_delete');
      legacy.execute('DROP TABLE finance_day_closure_snapshots');
      legacy.execute('DROP TRIGGER bill_issue_snapshot_closed_update');
      legacy.execute('DROP TRIGGER bill_issue_snapshot_closed_delete');
      legacy.execute('DROP TABLE bill_issue_snapshots');
      legacy.execute('PRAGMA user_version=74');
    } finally {
      legacy.dispose();
    }

    final migrated = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(migrated.close);
    final closure = FinanceDayClosureRepository(migrated);
    expect(await closure.isClosed(date), isTrue);
    expect(await closure.fetchSnapshot(date), isNull,
        reason: 'Old closures must not receive invented audit evidence.');
    expect(
        (await migrated.select(migrated.cashTransactions).get()).single.amount,
        100);
    final schema = await migrated
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'finance_day_closure_snapshots'",
        )
        .get();
    expect(schema, hasLength(1));
    final invoiceSchema = await migrated
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'bill_issue_snapshots'",
        )
        .get();
    expect(invoiceSchema, hasLength(1));
  });
}

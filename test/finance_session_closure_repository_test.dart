import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/finance/ledger/data/finance_day_closure_repository.dart';
import 'package:lotus_erp/features/finance/ledger/data/finance_session_closure_repository.dart';

void main() {
  late AppDatabase db;
  late FinanceSessionClosureRepository repository;
  final day = DateTime(2026, 11, 25, 14);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FinanceSessionClosureRepository(db);
  });
  tearDown(() => db.close());

  Map<String, num> denominations() => {
        '500': 0,
        '200': 0,
        '100': 0,
        '50': 0,
        '20': 0,
        '10': 0,
        'coins': 0,
      };

  test('stores numbered session snapshots without permanently locking the day',
      () async {
    expect(
      await repository.closeSession(
        day,
        closingCash: 0,
        physicalBank: 0,
        closedBy: 'owner-1',
        denominationCount: denominations(),
      ),
      isTrue,
    );
    expect(await repository.sessionCount(day), 1);
    expect(await FinanceDayClosureRepository(db).isClosed(day), isFalse);

    final rows = await db.customSelect('''
      SELECT session_number, denomination_json, snapshot_json
      FROM finance_session_closures WHERE day_key = '20261125'
    ''').get();
    expect(rows, hasLength(1));
    expect(rows.single.read<int>('session_number'), 1);
    expect(
      jsonDecode(rows.single.read<String>('denomination_json')),
      containsPair('500', 0),
    );
    expect(
      jsonDecode(rows.single.read<String>('snapshot_json')),
      containsPair('version', 2),
    );
  });

  test('allows multiple reconciled closes for one business date', () async {
    for (var session = 0; session < 2; session++) {
      expect(
        await repository.closeSession(
          day,
          closingCash: 0,
          physicalBank: 0,
          closedBy: 'owner-1',
          denominationCount: denominations(),
        ),
        isTrue,
      );
    }

    final rows = await db.customSelect('''
      SELECT session_number FROM finance_session_closures
      WHERE day_key = '20261125' ORDER BY session_number
    ''').get();
    expect(rows.map((row) => row.read<int>('session_number')), [1, 2]);
    expect(await FinanceDayClosureRepository(db).isClosed(day), isFalse);
  });
}

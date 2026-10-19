import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';

void main() {
  test('v60 removes pledge valuation without losing loan or item data',
      () async {
    final directory = await Directory.systemTemp.createTemp('girvi-v60-');
    final file = File('${directory.path}/lotus.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));

    try {
      final customerId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
                name: 'Migration Customer', mobile: '9000000001'),
          );
      final loanId = await db.into(db.girviLoans).insert(
            GirviLoansCompanion.insert(
              ticketNo: 'GRV-V60-1',
              customerId: customerId,
              itemDescription: 'Gold ring',
              loanAmount: const Value(25000),
              netWeight: const Value(5),
            ),
          );
      await db.into(db.girviLoanItems).insert(
            GirviLoanItemsCompanion.insert(
              girviId: loanId,
              serialNo: 1,
              itemName: 'Gold ring',
              metalType: 'Gold',
              purity: '22K',
              netWeight: const Value(5),
            ),
          );
      for (final entry in <String, Map<String, String>>{
        'girvi_loans': {
          'rate_per_gram': 'REAL',
          'total_value': 'REAL',
          'ltv_percent': 'REAL',
        },
        'girvi_loan_items': {
          'valuation_method': 'TEXT',
          'valuation_purity_percent': 'REAL',
          'fine_weight': 'REAL',
          'rate_per_gram': 'REAL',
          'valuation_amount': 'REAL',
        },
      }.entries) {
        for (final column in entry.value.entries) {
          await db.customStatement(
            'ALTER TABLE "${entry.key}" ADD COLUMN "${column.key}" ${column.value}',
          );
        }
      }
      await db.customStatement(
        'UPDATE girvi_loans SET rate_per_gram = 7000, total_value = 35000, ltv_percent = 71.43',
      );
      await db.customStatement(
        "UPDATE girvi_loan_items SET valuation_method = 'PURITY', valuation_purity_percent = 91.6, fine_weight = 4.58, rate_per_gram = 7000, valuation_amount = 32060",
      );
      await db.customStatement('PRAGMA user_version = 59');
      await db.close();

      db = AppDatabase.forTesting(NativeDatabase(file));
      final loan = await (db.select(db.girviLoans)
            ..where((row) => row.id.equals(loanId)))
          .getSingle();
      final items = await (db.select(db.girviLoanItems)
            ..where((row) => row.girviId.equals(loanId)))
          .get();
      expect(loan.loanAmount, 25000);
      expect(loan.netWeight, 5);
      expect(items.single.itemName, 'Gold ring');
      for (final entry in <String, List<String>>{
        'girvi_loans': ['rate_per_gram', 'total_value', 'ltv_percent'],
        'girvi_loan_items': [
          'valuation_method',
          'valuation_purity_percent',
          'fine_weight',
          'rate_per_gram',
          'valuation_amount',
        ],
      }.entries) {
        final columns =
            await db.customSelect('PRAGMA table_info("${entry.key}")').get();
        final names = columns.map((row) => row.read<String>('name')).toSet();
        for (final column in entry.value) {
          expect(names, isNot(contains(column)));
        }
      }
    } finally {
      await db.close();
      await directory.delete(recursive: true);
    }
  });
}

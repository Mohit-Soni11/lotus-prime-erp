import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/config/db_config.dart';
import 'package:lotus_erp/database/db/app_database.dart';

void main() {
  test('v77 bank receipts migrate without losing assigned transactions',
      () async {
    final directory = await Directory.systemTemp.createTemp('lotus_pos_v77_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}shop.sqlite');

    final original = AppDatabase.forTesting(NativeDatabase(file));
    await original.customSelect('SELECT 1').get();
    final accountId = await original.into(original.bankAccounts).insert(
          BankAccountsCompanion.insert(
            accountName: 'Existing account',
            bankName: 'Bank',
            accountNumber: 'MIGRATION-ACCOUNT',
          ),
        );
    final createSql = (await original
            .customSelect(
              "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'bank_transactions'",
            )
            .getSingle())
        .read<String>('sql');
    expect(createSql, contains('"account_id" INTEGER'));
    await original.customStatement('DROP TABLE bank_transactions');
    await original.customStatement(createSql.replaceFirst(
      '"account_id" INTEGER',
      '"account_id" INTEGER NOT NULL',
    ));
    await original.customStatement(
      'CREATE INDEX idx_btxn_ref ON bank_transactions (reference_id)',
    );
    await original.customStatement('''
      CREATE TRIGGER bank_day_closed_update
      BEFORE UPDATE ON bank_transactions
      WHEN OLD.account_id != NEW.account_id
      BEGIN SELECT RAISE(ABORT, 'Finance day is closed'); END
    ''');
    await original.into(original.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: 'BTXN-OLD',
            accountId: drift.Value(accountId),
            txnDate: DateTime(2026, 11, 11),
            type: 'CREDIT',
            category: 'SALE_PAYMENT',
            amount: const drift.Value(100),
            paymentMode: const drift.Value('UPI'),
          ),
        );
    await original.customStatement('PRAGMA user_version = 77');
    await original.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);
    final columns = await upgraded
        .customSelect('PRAGMA table_info(bank_transactions)')
        .get();
    final accountColumn = columns.singleWhere(
      (row) => row.read<String>('name') == 'account_id',
    );
    final existing = await upgraded.select(upgraded.bankTransactions).get();
    expect(accountColumn.read<int>('notnull'), 0);
    expect(existing.single.txnId, 'BTXN-OLD');
    expect(existing.single.accountId, accountId);
    final trigger = await upgraded
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE type = 'trigger' AND name = 'bank_day_closed_update'",
        )
        .getSingle();
    expect(trigger.read<String>('sql'), contains('IS NOT'));
    final index = await upgraded
        .customSelect(
          "SELECT 1 FROM sqlite_master WHERE type = 'index' AND name = 'idx_btxn_ref'",
        )
        .getSingleOrNull();
    expect(index, isNotNull);

    await upgraded.into(upgraded.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: 'BTXN-UNASSIGNED',
            txnDate: DateTime(2026, 11, 12),
            type: 'CREDIT',
            category: 'SALE_PAYMENT',
            amount: const drift.Value(1111.60),
            paymentMode: const drift.Value('UPI'),
          ),
        );
    final unassigned = await (upgraded.select(upgraded.bankTransactions)
          ..where((row) => row.txnId.equals('BTXN-UNASSIGNED')))
        .getSingle();
    expect(unassigned.accountId, isNull);
    final version =
        await upgraded.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), DbConfig.schemaVersion);
  });
}

import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/finance/ledger/data/finance_day_closure_repository.dart';
import 'package:lotus_erp/logic/report/day_book/day_book_export_service.dart';
import 'package:lotus_erp/logic/report/day_book/export/day_book_export_loader.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_metal_count.dart';
import 'package:lotus_erp/repositories/reports/day_book_metal_verification_repository.dart';
import 'package:lotus_erp/repositories/reports/day_book_repository.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('physical item count is append-only and goes stale after stock changes',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final today = DateTime.now();
    final stockId = await db.into(db.stockItems).insert(
          StockItemsCompanion.insert(
            sku: 'COUNT-GOLD-1',
            itemName: 'Gold Ring',
            category: 'Gold',
            subCategory: 'Ring',
            metalType: const drift.Value('Gold'),
            purity: const drift.Value('22K'),
            netWeight: const drift.Value(10),
            grossWeight: const drift.Value(11),
          ),
        );
    await db.customStatement('''
      INSERT INTO stock_item_units
        (stock_item_id, unit_code, piece_no, metal_type, item_name,
         purity_percent, gross_weight, net_weight, actual_fine_weight,
         status, created_at)
      VALUES (?, 'COUNT-U1', 1, 'Gold', 'Gold Ring', 91.6, 11, 10,
              9.16, 'Available', ?)
    ''', [stockId, today.millisecondsSinceEpoch]);
    final repo = DayBookMetalVerificationRepository(db);
    final lines = await repo.expected();
    expect(lines, hasLength(1));
    expect(lines.single.fineGrams, 9.16);
    DayBookPhysicalMetalCount counted({double net = 10}) =>
        DayBookPhysicalMetalCount(
          key: lines.single.key,
          pieces: 1,
          grossGrams: 11,
          netGrams: net,
          fineGrams: 9.16,
        );

    await expectLater(
      repo.verify(
        day: today,
        actor: 'owner-1',
        physical: [counted(net: 9)],
        emptyStockConfirmed: false,
      ),
      throwsA(isA<StateError>()),
    );
    expect(await repo.latest(today), isNull);
    final saved = await repo.verify(
      day: today,
      actor: 'owner-1',
      physical: [counted()],
      emptyStockConfirmed: false,
    );
    expect(saved.physicalCounts.single.netGrams, 10);
    expect(await repo.isVerified(today), isTrue);

    await db.customStatement('''
      UPDATE stock_item_units SET net_weight = 9 WHERE unit_code = 'COUNT-U1'
    ''');
    expect(await repo.isVerified(today), isFalse);
    await expectLater(
      FinanceDayClosureRepository(db).closeDay(today,
          closingCash: 0,
          physicalBank: 0,
          requireVerifiedMetal: true,
          closedBy: 'owner-1'),
      throwsA(isA<StateError>()),
    );
    await db.customStatement('''
      UPDATE stock_item_units SET net_weight = 10 WHERE unit_code = 'COUNT-U1'
    ''');
    expect(await repo.isVerified(today), isTrue);
    expect(
      await FinanceDayClosureRepository(db).closeDay(today,
          closingCash: 0,
          physicalBank: 0,
          requireVerifiedMetal: true,
          closedBy: 'owner-1'),
      isTrue,
    );
    final report = await DayBookRepository(db: db).fetchDayBook(today);
    final evidence = await DayBookExportLoader(database: db).load(report);
    final csv = DayBookExportService.buildCsv(report, data: evidence);
    expect(csv, contains('Physical Metal Count'));
    expect(csv, contains('Gold Gold Ring'));
    expect(csv, contains('owner-1'));
    await expectLater(
      repo.verify(
        day: today,
        actor: 'owner-1',
        physical: [counted()],
        emptyStockConfirmed: false,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('empty stock needs explicit physical confirmation', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final today = DateTime.now();
    final repo = DayBookMetalVerificationRepository(db);
    await expectLater(
      repo.verify(
        day: today,
        actor: 'owner-1',
        physical: const [],
        emptyStockConfirmed: false,
      ),
      throwsA(isA<StateError>()),
    );
    await repo.verify(
      day: today,
      actor: 'owner-1',
      physical: const [],
      emptyStockConfirmed: true,
    );
    expect(await repo.isVerified(today), isTrue);
  });

  test('v76 upgrade creates metal count storage without changing stock',
      () async {
    final directory = await Directory.systemTemp.createTemp('lotus-metal-v76-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}shop.sqlite');
    final original = AppDatabase.forTesting(NativeDatabase(file));
    await original.into(original.stockItems).insert(
          StockItemsCompanion.insert(
            sku: 'LEGACY-STOCK',
            itemName: 'Silver Chain',
            category: 'Silver',
            subCategory: 'Chain',
            metalType: const drift.Value('Silver'),
            purity: const drift.Value('925'),
            netWeight: const drift.Value(25),
          ),
        );
    await original.close();
    final legacy = sqlite3.open(file.path);
    try {
      legacy.execute('DROP TRIGGER day_book_metal_verification_closed_insert');
      legacy
          .execute('DROP TRIGGER day_book_metal_verification_immutable_update');
      legacy
          .execute('DROP TRIGGER day_book_metal_verification_immutable_delete');
      legacy.execute('DROP INDEX idx_day_book_metal_verification_day');
      legacy.execute('DROP TABLE day_book_metal_verifications');
      legacy.execute('PRAGMA user_version=76');
    } finally {
      legacy.dispose();
    }
    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);
    expect((await upgraded.select(upgraded.stockItems).get()).single.netWeight,
        25);
    expect(
      (await upgraded.customSelect('''
        SELECT name FROM sqlite_master
        WHERE type = 'table' AND name = 'day_book_metal_verifications'
      ''').get()),
      hasLength(1),
    );
  });
}

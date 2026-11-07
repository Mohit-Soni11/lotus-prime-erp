import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/add_stock_models.dart';
import 'package:lotus_erp/features/stock/shared/data/repositories/direct_stock_intake_repository.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('direct Add Stock posts one batch, saleable units and inward movements',
      () async {
    final first = _row('Diamond Pendant', quantity: 2, netWeight: 3.5);
    final second = _row('Diamond Ring', quantity: 1, netWeight: 2);
    final result = await DirectStockIntakeRepository(db).save(
      metal: StockCategory.diamond,
      rows: [first, second],
      purityLabel: (_) => 'Diamond',
      fallbackTouch: 100,
      defaultHsnCode: '7113',
    );

    expect(result.itemCount, 2);
    final stock = await db.select(db.stockItems).get();
    final movements = await db.select(db.stockMovements).get();
    final units = await db
        .customSelect(
          'SELECT batch_code, unit_code, net_weight, status FROM stock_item_units ORDER BY id',
        )
        .get();
    expect(stock, hasLength(2));
    expect(movements, hasLength(2));
    expect(movements.map((row) => row.sourceType),
        everyElement('ADD_STOCK_DIRECT'));
    expect(
        movements.map((row) => row.sourceId), everyElement(result.batchCode));
    expect(movements.first.quantityDelta, 2);
    expect(movements.first.netWeightDelta, 7);
    expect(units, hasLength(2));
    expect(units.first.read<String>('batch_code'), result.batchCode);
    expect(units.first.read<String>('unit_code'), contains('LOT'));
    expect(units.first.read<double>('net_weight'), 7);
    expect(units.first.read<String>('status'), StockStatus.available.label);
    expect(await db.customSelect('SELECT id FROM purchase_vouchers').get(),
        isEmpty);
  });

  test('duplicate HUID rolls back all rows in the direct batch', () async {
    final first = _row('Platinum Ring', quantity: 1, netWeight: 4);
    final second = _row('Platinum Band', quantity: 1, netWeight: 5);
    first.huid = 'HUID-123';
    second.huid = 'HUID-123';

    await expectLater(
      DirectStockIntakeRepository(db).save(
        metal: StockCategory.platinum,
        rows: [first, second],
        purityLabel: (_) => '950',
        fallbackTouch: 95,
        defaultHsnCode: '7113',
      ),
      throwsA(isA<StateError>()),
    );
    expect(await db.select(db.stockItems).get(), isEmpty);
    expect(await db.select(db.stockMovements).get(), isEmpty);
    expect(await db.customSelect('SELECT id FROM stock_item_units').get(),
        isEmpty);
  });
}

StockRowEntry _row(String name,
    {required int quantity, required double netWeight}) {
  final row = StockRowEntry(id: name, hsnCode: '7113');
  row.itemName = name;
  row.quantity = quantity;
  row.grossWeight = netWeight;
  row.purchaseRate = 1000;
  return row;
}

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_quick_stock_intake_model.dart';
import 'package:lotus_erp/repositories/sales_orders/pos/pos_quick_stock_repository.dart';
import 'package:lotus_erp/repositories/sales_orders/pos/pos_stock_lookup_repository.dart';

void main() {
  test('quick stock creates sale-ready inventory unit for POS linking',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final repository = PosQuickStockRepository(db: db);
    final stock = await repository.createSaleReadyStock(
      const PosQuickStockIntakeModel(
        rowIndex: 0,
        itemName: 'Advance Ring',
        metal: MetalType.gold,
        purityLabel: '18KT',
        grossWeight: 5.5,
        lessWeight: 0.2,
        netWeight: 5.3,
        wastagePercent: 8,
        purchaseRate: 6200,
        huid: 'abc123',
        supplierId: null,
        supplierName: 'Test Supplier',
      ),
    );

    expect(stock.stockItemId, greaterThan(0));
    expect(stock.stockUnitId, isNotNull);
    expect(stock.itemName, 'Advance Ring');
    expect(stock.huid, 'ABC123');
    expect(stock.netWeight, closeTo(5.3, 0.0001));
    expect(stock.unitCost, closeTo(32860, 0.0001));

    final lookup = await PosStockLookupRepository(db: db).findExactByHuid(
      query: 'ABC123',
      metal: MetalType.gold,
      purityLabel: '18KT',
    );
    expect(lookup, isNotNull);
    expect(lookup!.stockItemId, stock.stockItemId);
    expect(lookup.stockUnitId, stock.stockUnitId);

    final movement = await db.customSelect(
      '''
      SELECT movement_type, source_type, quantity_delta, net_weight_delta
      FROM stock_movements
      WHERE stock_item_id = ?
      ''',
      variables: [Variable<int>(stock.stockItemId)],
    ).getSingle();

    expect(movement.read<String>('movement_type'), 'IN');
    expect(movement.read<String>('source_type'), 'POS_QUICK_STOCK');
    expect(movement.read<int>('quantity_delta'), 1);
    expect(movement.read<double>('net_weight_delta'), closeTo(5.3, 0.0001));
  });
}

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/data/repositories/stock_transfer_repository.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart'
    as stock;
import 'package:lotus_erp/features/stock/shared/domain/models/stock_transfer/stock_transfer_models.dart';

void main() {
  late AppDatabase database;
  late StockTransferRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = StockTransferRepository(database);
  });

  tearDown(() => database.close());

  test('create and receive transfer updates unit status and movement ledger',
      () async {
    final now = DateTime.now();
    final stockItemId = await _insertStockItem(
      database,
      sku: 'LJ-GOLD-TR-001',
      itemName: 'Gold Ring',
      subCategory: 'Ring',
      metal: 'Gold',
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: stockItemId,
      unitCode: 'UNIT-GOLD-TR-001',
      metal: 'Gold',
      itemType: 'Ring',
      itemName: 'Gold Ring',
      status: stock.StockStatus.available.label,
      netWeight: 8.5,
      unitCost: 51000,
      createdAt: now,
    );

    final available = await repository.searchAvailableUnits(query: 'TR-001');
    expect(available, hasLength(1));

    final created = await repository.createTransfer(
      form: StockTransferForm(
        fromLocation: 'Main Showroom',
        toLocation: 'Vault',
        transferType: 'Vault Movement',
        carrierName: 'Amit',
        authorizedBy: 'Owner',
        expectedDate: now,
        notes: 'Seal packet checked',
      ),
      units: available,
    );

    expect(created.transferNo, startsWith('ST-'));
    expect(created.unitCount, 1);

    var unitStatus = await _readUnitStatus(database);
    expect(unitStatus.status, stock.StockStatus.transferred.label);
    expect(unitStatus.location, 'In Transit: Vault');

    final transfer = (await repository.loadRecentTransfers()).single;
    expect(transfer.status, StockTransferStatus.inTransit);

    await repository.receiveTransfer(
      transfer: transfer,
      receivedBy: 'Vault Manager',
    );

    unitStatus = await _readUnitStatus(database);
    expect(unitStatus.status, stock.StockStatus.available.label);
    expect(unitStatus.location, 'Vault');

    final movements = await database.customSelect(
      '''
      SELECT movement_type, quantity_delta
      FROM stock_movements
      WHERE source_number = ?
      ORDER BY id
      ''',
      variables: [drift.Variable.withString(created.transferNo)],
    ).get();

    expect(movements.map((row) => row.data['movement_type']), [
      'TRANSFER_OUT',
      'TRANSFER_IN',
    ]);
    expect(movements.map((row) => row.data['quantity_delta']), [-1, 1]);
  });
}

Future<int> _insertStockItem(
  AppDatabase database, {
  required String sku,
  required String itemName,
  required String subCategory,
  required String metal,
  required DateTime createdAt,
}) {
  return database.into(database.stockItems).insert(
        StockItemsCompanion.insert(
          createdAt: drift.Value(createdAt),
          sku: sku,
          itemName: itemName,
          category: metal,
          subCategory: subCategory,
          metalType: drift.Value(metal),
          purity: const drift.Value(''),
          grossWeight: const drift.Value(0),
          netWeight: const drift.Value(0),
          quantity: const drift.Value(1),
          status: drift.Value(stock.StockStatus.available.label),
          isActive: const drift.Value(true),
        ),
      );
}

Future<void> _insertStockUnit(
  AppDatabase database, {
  required int stockItemId,
  required String unitCode,
  required String metal,
  required String itemType,
  required String itemName,
  required String status,
  required double netWeight,
  required double unitCost,
  required DateTime createdAt,
}) {
  return database.customStatement(
    '''
    INSERT INTO stock_item_units (
      stock_item_id,
      batch_code,
      unit_code,
      piece_no,
      metal_type,
      item_type,
      segment,
      item_name,
      gross_weight,
      less_weight,
      net_weight,
      purity_percent,
      actual_fine_weight,
      valuation_fine_weight,
      unit_cost,
      supplier_name,
      status,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      stockItemId,
      'BATCH-$unitCode',
      unitCode,
      1,
      metal,
      itemType,
      'General',
      itemName,
      netWeight,
      0.0,
      netWeight,
      91.6,
      netWeight * 0.916,
      netWeight * 0.916,
      unitCost,
      'Lotus Supplier',
      status,
      createdAt.millisecondsSinceEpoch,
    ],
  );
}

Future<_UnitStatus> _readUnitStatus(AppDatabase database) async {
  final row = await database.customSelect(
    '''
    SELECT status, COALESCE(current_location, '') AS current_location
    FROM stock_item_units
    WHERE unit_code = 'UNIT-GOLD-TR-001'
    ''',
  ).getSingle();
  return _UnitStatus(
    status: row.data['status'] as String,
    location: row.data['current_location'] as String,
  );
}

class _UnitStatus {
  final String status;
  final String location;

  const _UnitStatus({required this.status, required this.location});
}

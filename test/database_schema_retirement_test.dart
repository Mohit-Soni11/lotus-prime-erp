import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/config/db_config.dart';
import 'package:lotus_erp/database/db/app_database.dart';

void main() {
  test('fresh databases do not create retired sales tables', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        )
        .get();
    final names = tables.map((row) => row.read<String>('name')).toSet();

    expect(names, isNot(contains('delivery_orders')));
    expect(names, isNot(contains('delivery_items')));
    expect(names, contains('sales_orders'));
  });

  test('upgrade removes retired sales records without affecting advances',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('lotus_schema_retirement_');
    addTearDown(() => directory.delete(recursive: true));
    final file =
        File('${directory.path}${Platform.pathSeparator}legacy.sqlite');

    final original = AppDatabase.forTesting(NativeDatabase(file));
    await original.customSelect('SELECT 1').get();
    final customerId = await original.into(original.customers).insert(
          CustomersCompanion.insert(
              name: 'Advance Customer', mobile: '9000000001'),
        );
    await original.into(original.salesOrders).insert(
          SalesOrdersCompanion.insert(
            orderNo: 'BK-001',
            customerId: customerId,
            itemName: 'Ring',
          ),
        );
    await original.customStatement(
      'CREATE TABLE delivery_orders (id INTEGER PRIMARY KEY, customer_id INTEGER)',
    );
    await original.customStatement(
      'CREATE TABLE delivery_items (id INTEGER PRIMARY KEY, delivery_order_id INTEGER)',
    );
    await original.customStatement(
      'INSERT INTO delivery_orders (id, customer_id) VALUES (1, 1)',
    );
    await original.customStatement(
      'INSERT INTO delivery_items (id, delivery_order_id) VALUES (1, 1)',
    );
    await original.customStatement('PRAGMA user_version = 68');
    await original.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);
    final tables = await upgraded
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        )
        .get();
    final names = tables.map((row) => row.read<String>('name')).toSet();
    final version =
        await upgraded.customSelect('PRAGMA user_version').getSingle();

    expect(names, isNot(contains('delivery_orders')));
    expect(names, isNot(contains('delivery_items')));
    expect(names, contains('sales_orders'));
    final orders = await upgraded.select(upgraded.salesOrders).get();
    expect(orders.single.orderNo, 'BK-001');
    expect(version.read<int>('user_version'), DbConfig.schemaVersion);
  });
}

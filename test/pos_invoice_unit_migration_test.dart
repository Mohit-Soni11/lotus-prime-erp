import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/config/db_config.dart';
import 'package:lotus_erp/database/db/app_database.dart';

void main() {
  test('upgrading an existing invoice adds the display unit column', () async {
    final directory =
        await Directory.systemTemp.createTemp('lotus_invoice_unit_migration_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}legacy.sqlite');

    final legacy = AppDatabase.forTesting(NativeDatabase(file));
    await legacy.customSelect('SELECT 1').get();
    await legacy.customStatement(
      'ALTER TABLE bill_items DROP COLUMN quantity_unit_display_name',
    );
    await legacy.customStatement('PRAGMA user_version = 78');
    await legacy.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);
    final columns =
        await upgraded.customSelect('PRAGMA table_info("bill_items")').get();
    final names = columns.map((row) => row.read<String>('name')).toSet();
    final version =
        await upgraded.customSelect('PRAGMA user_version').getSingle();

    expect(names, contains('quantity_unit_display_name'));
    expect(version.read<int>('user_version'), DbConfig.schemaVersion);
  });
}

import 'package:sqflite/sqflite.dart';

import '../../../database/local_database/shop_database_helper.dart';

class LocalAccountRepository {
  LocalAccountRepository({ShopDatabaseHelper? helper})
      : _helper = helper ?? ShopDatabaseHelper();

  final ShopDatabaseHelper _helper;

  Future<Map<String, Object?>?> read() async {
    final db = await _helper.database;
    final rows = await db.query('local_owner_account', where: 'id = 1');
    return rows.isEmpty ? null : rows.single;
  }

  Future<void> create(Map<String, Object?> values) async {
    final db = await _helper.database;
    await db.insert('local_owner_account', {'id': 1, ...values},
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<void> update(Map<String, Object?> values) async {
    final db = await _helper.database;
    await db.update('local_owner_account', values, where: 'id = 1');
  }
}

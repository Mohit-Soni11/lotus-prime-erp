import 'package:lotus_erp/database/db/app_database.dart';

abstract class MetalValuationChangeStream {
  Stream<void> watch();
}

class MetalValuationChangeWatcher implements MetalValuationChangeStream {
  final AppDatabase _db;

  MetalValuationChangeWatcher({AppDatabase? database})
      : _db = database ?? AppDatabase();

  @override
  Stream<void> watch() {
    return _db
        .customSelect(
          '''
          SELECT
            (SELECT COUNT(*) FROM stock_items) AS stock_count,
            (SELECT COUNT(*) FROM stock_movements) AS movement_count,
            (SELECT COUNT(*) FROM bills) AS bill_count,
            (SELECT COUNT(*) FROM bill_items) AS bill_item_count,
            (SELECT COUNT(*) FROM customers) AS customer_count
          ''',
          readsFrom: {
            _db.stockItems,
            _db.stockMovements,
            _db.bills,
            _db.billItems,
            _db.customers,
          },
        )
        .watch()
        .map((_) {});
  }
}

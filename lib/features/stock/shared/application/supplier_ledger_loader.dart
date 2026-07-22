import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/repositories/supplier/supplier_repository.dart';

export 'package:lotus_erp/repositories/supplier/supplier_repository.dart'
    show SupplierLedgerSnapshot;

final class SupplierLedgerLoader {
  const SupplierLedgerLoader._();

  static Future<SupplierLedgerSnapshot?> load({
    required AppDatabase db,
    required int supplierId,
  }) async {
    try {
      return SupplierRepository(db).getLedgerSnapshot(supplierId);
    } catch (_) {
      return null;
    }
  }
}

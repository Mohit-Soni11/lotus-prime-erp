import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier_profile/supplier_profile_model.dart';
import 'package:lotus_erp/repositories/supplier/supplier_batch_repository.dart';
import 'package:lotus_erp/repositories/supplier/supplier_repository.dart';

void main() {
  test('supplier batch totals come from linked inventory and available units',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final supplierId = await SupplierRepository(db).addSupplier(
      const SupplierModel(businessName: 'AJ', mobile: '9905688200'),
    );
    await db.customStatement('''
      INSERT INTO purchase_vouchers
        (voucher_no, sequence_no, source_type, supplier_id, party_name, created_at)
      VALUES ('BATCH-1', 1, 'SUPPLIER', ?, 'AJ', 1),
             ('BATCH-2', 2, 'SUPPLIER', ?, 'AJ', 2)
    ''', [supplierId, supplierId]);
    await db.customStatement('''
      INSERT INTO stock_items
        (sku, item_name, category, sub_category, supplier_id)
      VALUES ('S-1', 'Ring', 'Jewellery', 'Ring', ?),
             ('S-2', 'Chain', 'Jewellery', 'Chain', ?)
    ''', [supplierId, supplierId]);
    await db.customStatement('''
      INSERT INTO stock_item_units
        (stock_item_id, purchase_voucher_id, batch_code, unit_code,
         piece_no, metal_type, item_name, supplier_id, status, created_at)
      VALUES (1, 1, 'BATCH-1', 'UNIT-1', 1, 'Gold', 'Ring', ?, 'Available', 1),
             (1, 1, 'BATCH-1', 'UNIT-2', 2, 'Gold', 'Ring', ?, 'Sold', 1),
             (2, 2, 'BATCH-2', 'UNIT-3', 1, 'Silver', 'Chain', ?, 'Sold', 2)
    ''', [supplierId, supplierId, supplierId]);

    final batches = await SupplierBatchRepository(db).getBatches(supplierId);
    final profile = SupplierProfileModel(
      id: supplierId,
      businessName: 'AJ',
      mobile: '9905688200',
      batches: batches,
    );
    expect(profile.totalBatchCount, 2);
    expect(profile.activeBatchCount, 1);
    expect(batches.first.code, 'BATCH-2');
    expect(batches.first.statusLabel, 'CLOSED');
    expect(batches.last.availableUnits, 1);
  });
}

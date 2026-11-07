import 'package:drift/drift.dart';

import '../../../features/stock/shared/domain/models/stock_item/stock_enums.dart';
import '../../../models/purchase/purchase_voucher_origin.dart';

Future<void> migratePurchaseOriginsAndCustomerIntake(
  GeneratedDatabase database,
) async {
  // Supplier vouchers before origin tracking were created by Gold/Silver Add Stock.
  await database.customStatement('''
    UPDATE purchase_vouchers
    SET entry_origin = ?
    WHERE entry_origin = ? AND UPPER(source_type) = 'SUPPLIER'
  ''', [
    PurchaseVoucherOrigin.addStock.storageValue,
    PurchaseVoucherOrigin.legacy.storageValue,
  ]);
  await database.customStatement('''
    UPDATE purchase_vouchers
    SET entry_origin = CASE
      WHEN payment_meta LIKE 'BOOKING_ADVANCE_METAL|%' THEN ?
      ELSE ?
    END
    WHERE entry_origin = ? AND UPPER(source_type) = 'CUSTOMER'
  ''', [
    PurchaseVoucherOrigin.bookingAdvanceMetal.storageValue,
    PurchaseVoucherOrigin.customerMetalPurchase.storageValue,
    PurchaseVoucherOrigin.legacy.storageValue,
  ]);

  // Customer old metal is owned intake, but must not be offered as saleable jewellery.
  await database.customStatement('''
    UPDATE stock_item_units
    SET status = ?, updated_at = COALESCE(updated_at, created_at)
    WHERE LOWER(status) = 'available'
      AND purchase_voucher_id IN (
        SELECT id FROM purchase_vouchers WHERE UPPER(source_type) = 'CUSTOMER'
      )
  ''', [StockStatus.processing.label]);
  if (await _hasTable(database, 'stock_movements')) {
    await database.customStatement('''
      UPDATE stock_movements
      SET movement_type = 'CUSTOMER_METAL_IN'
      WHERE movement_type = 'IN'
        AND UPPER(source_type) = 'PURCHASE'
        AND EXISTS (
          SELECT 1 FROM purchase_vouchers customer_voucher
          WHERE CAST(customer_voucher.id AS TEXT) = stock_movements.source_id
            AND UPPER(customer_voucher.source_type) = 'CUSTOMER'
        )
    ''');
  }
  if (await _hasTable(database, 'stock_items')) {
    await database.customStatement('''
      UPDATE stock_items
      SET status = ?, updated_at = COALESCE(updated_at, created_at)
      WHERE LOWER(status) = 'available'
        AND id IN (
          SELECT u.stock_item_id
          FROM stock_item_units u
          JOIN purchase_vouchers pv ON pv.id = u.purchase_voucher_id
          WHERE UPPER(pv.source_type) = 'CUSTOMER'
        )
    ''', [StockStatus.processing.label]);
  }
}

Future<bool> _hasTable(GeneratedDatabase database, String tableName) async {
  final row = await database.customSelect(
    "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1",
    variables: [Variable.withString(tableName)],
  ).getSingleOrNull();
  return row != null;
}

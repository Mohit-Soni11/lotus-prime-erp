import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/repositories/reports/day_book_customer_metal_sales_repository.dart';

void main() {
  test('invoice net weights include gold and silver and exclude voided bills',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final date = DateTime(2026, 11, 4);
    final goldBill = await db.into(db.bills).insert(BillsCompanion.insert(
          billNo: 'INV-1',
          billDate: drift.Value(date.add(const Duration(hours: 10))),
        ));
    final mixedBill = await db.into(db.bills).insert(BillsCompanion.insert(
          billNo: 'INV-2',
          billDate: drift.Value(date.add(const Duration(hours: 11))),
          status: const drift.Value('PARTIALLY_RETURNED'),
        ));
    final voidedBill = await db.into(db.bills).insert(BillsCompanion.insert(
          billNo: 'INV-VOID',
          billDate: drift.Value(date.add(const Duration(hours: 12))),
          status: const drift.Value('VOIDED'),
        ));
    final tomorrowBill = await db.into(db.bills).insert(BillsCompanion.insert(
          billNo: 'INV-TOMORROW',
          billDate: drift.Value(date.add(const Duration(days: 1))),
        ));
    for (final (billId, metal, weight) in [
      (goldBill, 'GOLD', 10.5),
      (mixedBill, 'Gold', 2.25),
      (mixedBill, 'SILVER', 41.125),
      (voidedBill, 'GOLD', 99.0),
      (tomorrowBill, 'SILVER', 99.0),
    ]) {
      await db.into(db.billItems).insert(BillItemsCompanion.insert(
            billId: billId,
            itemName: 'Test item',
            metalType: drift.Value(metal),
            netWeight: drift.Value(weight),
          ));
    }

    final sales = await DayBookCustomerMetalSalesRepository(db).fetch(date);
    expect(sales.goldGrams, 12.75);
    expect(sales.silverGrams, 41.125);
    expect(sales.goldInvoices, 2);
    expect(sales.silverInvoices, 1);
  });
}

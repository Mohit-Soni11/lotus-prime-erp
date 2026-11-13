import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/sales_orders/sales_pos/pos_billing_controller.dart';

void main() {
  test('Use in Sale loads booking details and preserves pending status',
      () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final customerId = await database.into(database.customers).insert(
          CustomersCompanion.insert(
            name: 'Booking Customer',
            mobile: '9876543210',
          ),
        );
    final orderId = await database.into(database.salesOrders).insert(
          SalesOrdersCompanion.insert(
            orderNo: 'AJ-BK-26-0021',
            customerId: customerId,
            itemName: 'Gold Ring',
            metalType: const drift.Value('GOLD'),
            purity: const drift.Value('22K'),
            approxWeight: const drift.Value(5.25),
            bookingType: const drift.Value('LOCKED'),
            lockedRate: const drift.Value(11900),
          ),
        );
    await database.into(database.orderAdvances).insert(
          OrderAdvancesCompanion.insert(
            orderId: orderId,
            amountPaid: const drift.Value(8000),
          ),
        );
    final controller = PosBillingController(
      database: database,
      initializeWorkspace: false,
    );
    addTearDown(controller.dispose);

    final loaded = await controller.initializeFromAdvanceOrder(orderId);

    expect(loaded, isTrue);
    expect(controller.convertedAdvanceOrderId, orderId);
    expect(controller.saleItems.single.descCtrl.text, 'Gold Ring');
    expect(controller.saleItems.single.rateCtrl.text, '11900');
    expect(controller.advCtrl.text, '8000');
    expect((await database.select(database.salesOrders).get()).single.status,
        'PENDING');
  });
}

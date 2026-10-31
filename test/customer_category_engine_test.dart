import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/customer/category/data/customer_category_repository.dart';
import 'package:lotus_erp/features/customer/category/domain/customer_category_engine.dart';
import 'package:lotus_erp/features/customer/category/domain/customer_category_score.dart';
import 'package:lotus_erp/models/customer/customer_enums/customer_list_enums.dart';

void main() {
  const engine = CustomerCategoryEngine();

  test('new customer remains Standard after the first visit', () {
    final score = engine.evaluate(const CustomerCategoryFacts(
      visitCount: 1,
      activeDueCount: 1,
      verifiedSalesContribution: -2000,
      verifiedSalesCount: 1,
      hasVerifiedSalesLoss: true,
    ));
    expect(score.category, CustomerType.standard);
    expect(score.points, 500);
    expect(score.isProvisional, isTrue);
  });

  test('verified repeat contribution earns Elite; active due caps Alert', () {
    const base = CustomerCategoryFacts(
      visitCount: 3,
      verifiedSalesContribution: 6000,
      verifiedSalesRevenue: 40000,
      verifiedSalesCount: 2,
      responsibleDiscountCount: 1,
      convertedAdvanceCount: 1,
    );
    final elite = engine.evaluate(base);
    expect(elite.category, CustomerType.elite);
    expect(elite.points, 800);

    final alert = engine.evaluate(const CustomerCategoryFacts(
      visitCount: 3,
      verifiedSalesContribution: 6000,
      verifiedSalesRevenue: 40000,
      verifiedSalesCount: 2,
      activeDueCount: 1,
    ));
    expect(alert.category, CustomerType.alert);
    expect(alert.points, 490);
  });

  test('purchase payout and unknown cost cannot create imaginary margin', () {
    final score = engine.evaluate(const CustomerCategoryFacts(
      visitCount: 2,
      customerMetalPurchaseCount: 1,
    ));
    expect(score.category, CustomerType.standard);
    expect(score.verifiedSalesContribution, isNull);
    expect(score.reasons.single.points, 0);
  });

  test('only marked customer-requested returns reduce the score', () {
    expect(
      engine
          .evaluate(const CustomerCategoryFacts(
            visitCount: 2,
            returnedSalesCount: 3,
          ))
          .category,
      CustomerType.standard,
    );
    final requested = engine.evaluate(const CustomerCategoryFacts(
      visitCount: 2,
      returnedSalesCount: 3,
      customerRequestedReturnCount: 3,
    ));
    expect(requested.points, 450);
    expect(requested.category, CustomerType.alert);
  });

  test('database facts use known stock cost and ignore legacy saved tier',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Asha',
            mobile: '9000000001',
            type: const Value('Gold'),
          ),
        );
    final otherId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Zara',
            mobile: '9000000002',
          ),
        );
    final now = DateTime.now();
    final firstBill = await db.into(db.bills).insert(BillsCompanion.insert(
          billNo: 'SCORE-1',
          customerId: Value(customerId),
          billDate: Value(now.subtract(const Duration(days: 4))),
          totalAmount: const Value(45000),
          discount: const Value(100),
          finalAmount: const Value(44900),
          paymentStatus: const Value('PAID'),
        ));
    await db.into(db.billItems).insert(BillItemsCompanion.insert(
          billId: firstBill,
          itemName: 'Ring',
          itemTotal: const Value(45000),
          stockUnitCost: const Value(38000),
        ));
    final secondBill = await db.into(db.bills).insert(BillsCompanion.insert(
          billNo: 'SCORE-2',
          customerId: Value(customerId),
          billDate: Value(now),
          totalAmount: const Value(3000),
          finalAmount: const Value(3000),
          paymentStatus: const Value('PAID'),
        ));
    await db.into(db.billItems).insert(BillItemsCompanion.insert(
          billId: secondBill,
          itemName: 'Pendant',
          itemTotal: const Value(3000),
          stockUnitCost: const Value(2500),
        ));
    final scores =
        await CustomerCategoryRepository(db).scoresFor([customerId, otherId]);
    expect(scores[customerId]!.visitCount, 2);
    expect(scores[customerId]!.category, CustomerType.elite);
    expect(scores[customerId]!.verifiedSalesContribution, 7400);
    expect(scores[otherId]!.category, CustomerType.standard);
    await CustomerCategoryRepository(db).persistCategories(scores);
    final customer = await (db.select(db.customers)
          ..where((row) => row.id.equals(customerId)))
        .getSingle();
    expect(customer.type, 'Elite');
    expect(customer.customerTier, 'Elite');

    await (db.update(db.bills)..where((bill) => bill.id.equals(secondBill)))
        .write(const BillsCompanion(
      paymentStatus: Value('UNKNOWN'),
      paidAmount: Value(2500),
      dueAmount: Value(0),
    ));
    final withDue = await CustomerCategoryRepository(db).scoreFor(customerId);
    expect(withDue.category, CustomerType.alert);
    expect(withDue.points, 490);

    await (db.update(db.bills)..where((bill) => bill.id.equals(secondBill)))
        .write(const BillsCompanion(
      paymentStatus: Value('PAID'),
      paidAmount: Value(3000),
      dueAmount: Value(0),
    ));
    expect((await CustomerCategoryRepository(db).scoreFor(customerId)).category,
        CustomerType.elite);
  });

  test('three cancelled advance orders create an Alert category', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Booking Customer',
            mobile: '9000000003',
          ),
        );
    final now = DateTime.now();
    for (var index = 0; index < 3; index++) {
      await db.into(db.salesOrders).insert(SalesOrdersCompanion.insert(
            orderNo: 'CANCEL-$index',
            customerId: customerId,
            itemName: 'Ring',
            status: const Value('CANCELLED'),
            createdAt: Value(now.subtract(Duration(days: index + 1))),
          ));
    }
    final score = await CustomerCategoryRepository(db).scoreFor(customerId);
    expect(score.visitCount, 3);
    expect(score.category, CustomerType.alert);
    expect(score.points, 400);
  });

  test('mixed-metal discounts use each saved metal allocation', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Mixed Metal Buyer',
            mobile: '9000000004',
          ),
        );
    final now = DateTime.now();
    final billId = await db.into(db.bills).insert(BillsCompanion.insert(
          billNo: 'MIXED-1',
          customerId: Value(customerId),
          billDate: Value(now.subtract(const Duration(days: 3))),
          totalAmount: const Value(15000),
          discount: const Value(300),
          finalAmount: const Value(14700),
          paymentStatus: const Value('PAID'),
        ));
    await db.into(db.billItems).insert(BillItemsCompanion.insert(
          billId: billId,
          itemName: 'Gold ring',
          metalType: const Value('GOLD'),
          itemTotal: const Value(10000),
          stockUnitCost: const Value(9000),
        ));
    await db.into(db.billItems).insert(BillItemsCompanion.insert(
          billId: billId,
          itemName: 'Silver chain',
          metalType: const Value('SILVER'),
          itemTotal: const Value(5000),
          stockUnitCost: const Value(4000),
        ));
    await db.ensureSalesMetalSettlementSchema();
    for (final allocation in [
      ('gold', 10000.0, 100.0),
      ('silver', 5000.0, 200.0),
    ]) {
      await db.customStatement('''
        INSERT INTO bill_metal_payment_allocations
          (bill_id, metal, gross_amount, discount_amount, net_payable)
        VALUES (?, ?, ?, ?, ?)
      ''', [
        billId,
        allocation.$1,
        allocation.$2,
        allocation.$3,
        allocation.$2 - allocation.$3,
      ]);
    }
    await db.into(db.bills).insert(BillsCompanion.insert(
          billNo: 'MIXED-2',
          customerId: Value(customerId),
          billDate: Value(now),
        ));
    final score = await CustomerCategoryRepository(db).scoreFor(customerId);
    expect(score.visitCount, 2);
    expect(
      score.reasons
          .any((reason) => reason.label == 'Discount within recorded margin'),
      isTrue,
    );
  });

  test('only explicitly marked return vouchers affect live category', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Return Customer',
            mobile: '9000000005',
          ),
        );
    final now = DateTime.now();
    for (var index = 0; index < 2; index++) {
      await db.into(db.bills).insert(BillsCompanion.insert(
            billNo: 'RETURN-$index',
            customerId: Value(customerId),
            billDate: Value(now.subtract(Duration(days: index + 1))),
          ));
    }
    await db.ensureReturnReversalSchema();
    for (var index = 0; index < 3; index++) {
      await db.customStatement('''
        INSERT INTO return_vouchers
          (voucher_no, operation_type, source_type, source_id,
           source_number, customer_id, settlement_mode, operator_note,
           created_at)
        VALUES (?, 'SALES_RETURN', 'SALES_INVOICE', 1,
          'RETURN-0', ?, 'REFUND_PAYABLE', ?, ?)
      ''', [
        'SR-CATEGORY-$index',
        customerId,
        index == 0 ? null : 'Customer requested return',
        now.millisecondsSinceEpoch,
      ]);
    }
    final twoMarked = await CustomerCategoryRepository(db).scoreFor(customerId);
    expect(twoMarked.category, CustomerType.standard);

    await db.customStatement('''
      UPDATE return_vouchers SET operator_note = 'Customer requested return'
      WHERE voucher_no = 'SR-CATEGORY-0'
    ''');
    final threeMarked =
        await CustomerCategoryRepository(db).scoreFor(customerId);
    expect(threeMarked.category, CustomerType.alert);
    expect(threeMarked.points, 450);
  });
}

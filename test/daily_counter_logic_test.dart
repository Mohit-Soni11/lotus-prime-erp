import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/dashboard/daily_counter/daily_counter_logic.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test(
    'dashboard sold metals use bill metal type and bought ignores purchase stock',
    () async {
      final now = DateTime.now();

      await _insertPurchaseStock(
        database,
        sku: 'PUR-GOLD-001',
        metalType: 'GOLD',
        grossWeight: 20.365,
        quantity: 15,
        createdAt: now,
      );
      await _insertPurchaseStock(
        database,
        sku: 'PUR-SILVER-001',
        metalType: 'SILVER',
        grossWeight: 520.320,
        quantity: 34,
        createdAt: now,
      );

      final billId = await _insertBill(
        database,
        billNo: 'TAX-AJ-2026-0001',
        billDate: now,
        finalAmount: 7530.58,
        paidAmount: 7530.58,
      );
      await _insertBillItem(
        database,
        billId: billId,
        lineNo: 1,
        metalType: 'GOLD',
        purity: '18K',
        grossWeight: 0.241,
        itemTotal: 3239.04,
      );
      await _insertBillItem(
        database,
        billId: billId,
        lineNo: 2,
        metalType: 'SILVER',
        purity: '60',
        grossWeight: 20.361,
        itemTotal: 4072.20,
      );

      final logic = DailyCounterLogic(db: database);
      addTearDown(logic.dispose);
      logic.init();

      final data = await logic.dataStream.first.timeout(
        const Duration(seconds: 2),
      );

      expect(data.metalMovement.soldGold.weightRaw, closeTo(0.241, 0.001));
      expect(data.metalMovement.soldGold.piecesStr, '1 Pc');
      expect(data.metalMovement.soldSilver.weightRaw, closeTo(20.361, 0.001));
      expect(data.metalMovement.soldSilver.piecesStr, '1 Pc');
      expect(data.metalMovement.boughtGold.weightRaw, 0);
      expect(data.metalMovement.boughtGold.piecesStr, '0 Pcs');
      expect(data.metalMovement.boughtSilver.weightRaw, 0);
      expect(data.metalMovement.boughtSilver.piecesStr, '0 Pcs');
    },
  );

  test('dashboard due ignores tiny floating point payment residue', () async {
    final now = DateTime.now();

    await _insertBill(
      database,
      billNo: 'TAX-AJ-2026-0002',
      billDate: now,
      finalAmount: 9981.002,
      paidAmount: 9981.000,
      dueAmount: 0,
    );

    final logic = DailyCounterLogic(db: database);
    addTearDown(logic.dispose);
    logic.init();

    final data = await logic.dataStream.first.timeout(
      const Duration(seconds: 2),
    );

    expect(data.financeDue.dueCount, '0 Customers');
    expect(data.financeDue.dueAmountRaw, 0);
  });

  test('dashboard due still counts genuine customer due', () async {
    final now = DateTime.now();

    await _insertBill(
      database,
      billNo: 'INV-AJ-2026-0001',
      billDate: now,
      customerName: 'Reyansh Soni',
      mobile: '9304479436',
      finalAmount: 1000,
      paidAmount: 900,
      dueAmount: 100,
    );

    final logic = DailyCounterLogic(db: database);
    addTearDown(logic.dispose);
    logic.init();

    final data = await logic.dataStream.first.timeout(
      const Duration(seconds: 2),
    );

    expect(data.financeDue.dueCount, '1 Customer');
    expect(data.financeDue.dueAmountRaw, 100);
  });

  test('dashboard due counts real paisa-level customer due', () async {
    final now = DateTime.now();

    await _insertBill(
      database,
      billNo: 'INV-AJ-2026-0002',
      billDate: now,
      customerName: 'Reyansh Soni',
      mobile: '9304479436',
      finalAmount: 1000.01,
      paidAmount: 1000,
      dueAmount: 0.01,
    );

    final logic = DailyCounterLogic(db: database);
    addTearDown(logic.dispose);
    logic.init();

    final data = await logic.dataStream.first.timeout(
      const Duration(seconds: 2),
    );

    expect(data.financeDue.dueCount, '1 Customer');
    expect(data.financeDue.dueAmountRaw, closeTo(0.01, 0.001));
  });

  test('dashboard due counts partially returned bills with remaining due',
      () async {
    final now = DateTime.now();

    await _insertBill(
      database,
      billNo: 'INV-AJ-2026-RETURN-DUE',
      billDate: now,
      customerName: 'Reyansh Soni',
      mobile: '9304479436',
      finalAmount: 5000,
      paidAmount: 3000,
      dueAmount: 750,
      paymentStatus: 'PARTIAL',
      status: 'PARTIALLY_RETURNED',
    );

    final logic = DailyCounterLogic(db: database);
    addTearDown(logic.dispose);
    logic.init();

    final data = await logic.dataStream.first.timeout(
      const Duration(seconds: 2),
    );

    expect(data.financeDue.dueCount, '1 Customer');
    expect(data.financeDue.dueAmountRaw, 750);
  });
}

Future<int> _insertBill(
  AppDatabase database, {
  required String billNo,
  required DateTime billDate,
  required double finalAmount,
  required double paidAmount,
  String customerName = 'Walk-in Customer',
  String mobile = '9999999999',
  double dueAmount = 0,
  String? paymentStatus,
  String status = 'ACTIVE',
}) {
  return database.into(database.bills).insert(
        BillsCompanion.insert(
          billNo: billNo,
          customerName: drift.Value(customerName),
          mobile: drift.Value(mobile),
          totalAmount: drift.Value(finalAmount),
          finalAmount: drift.Value(finalAmount),
          paidAmount: drift.Value(paidAmount),
          cashPaid: drift.Value(paidAmount),
          dueAmount: drift.Value(dueAmount),
          paymentStatus: drift.Value(
            paymentStatus ?? (dueAmount > 0 ? 'PARTIAL' : 'PAID'),
          ),
          billDate: drift.Value(billDate),
          status: drift.Value(status),
        ),
      );
}

Future<int> _insertBillItem(
  AppDatabase database, {
  required int billId,
  required int lineNo,
  required String metalType,
  required String purity,
  required double grossWeight,
  required double itemTotal,
}) {
  return database.into(database.billItems).insert(
        BillItemsCompanion.insert(
          billId: billId,
          lineNo: drift.Value(lineNo),
          metalType: drift.Value(metalType),
          itemName: metalType == 'SILVER' ? 'PAYAL' : 'NOSE PIN',
          purity: drift.Value(purity),
          grossWeight: drift.Value(grossWeight),
          netWeight: drift.Value(grossWeight),
          itemTotal: drift.Value(itemTotal),
        ),
      );
}

Future<int> _insertPurchaseStock(
  AppDatabase database, {
  required String sku,
  required String metalType,
  required double grossWeight,
  required int quantity,
  required DateTime createdAt,
}) {
  return database.into(database.stockItems).insert(
        StockItemsCompanion.insert(
          createdAt: drift.Value(createdAt),
          sku: sku,
          itemName: metalType == 'SILVER' ? 'PAYAL' : 'NOSE PIN',
          category: metalType,
          subCategory: 'Retail Stock',
          metalType: drift.Value(metalType),
          purity: drift.Value(metalType == 'SILVER' ? '60' : '18K'),
          grossWeight: drift.Value(grossWeight),
          netWeight: drift.Value(grossWeight),
          quantity: drift.Value(quantity),
          status: const drift.Value('Available'),
          isActive: const drift.Value(true),
        ),
      );
}

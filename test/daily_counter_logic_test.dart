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

  test('dashboard bought metals include customer purchases and sales returns',
      () async {
    final now = DateTime.now();
    await database.ensureReturnReversalSchema();

    await _insertCustomerPurchaseVoucherLine(
      database,
      voucherNo: 'CP-DASH-GOLD',
      metalType: 'GOLD',
      quantity: 2,
      netWeight: 1.250,
      createdAt: now,
    );
    await _insertCustomerPurchaseVoucherLine(
      database,
      voucherNo: 'MELT-SR-DASH-IGNORE',
      metalType: 'SILVER',
      quantity: 5,
      netWeight: 88,
      paymentStatus: 'RETURN_MELTING',
      status: 'MELTING',
      createdAt: now,
    );
    await _insertReturnVoucherLine(
      database,
      voucherNo: 'SR-DASH-GOLD',
      operationType: 'SALES_RETURN',
      sourceType: 'SALES_INVOICE',
      metalType: 'GOLD',
      quantity: 1,
      receivedNetWeight: 0.365,
      createdAt: now,
    );
    await _insertReturnVoucherLine(
      database,
      voucherNo: 'SR-DASH-SILVER',
      operationType: 'SALES_RETURN',
      sourceType: 'SALES_INVOICE',
      metalType: 'SILVER',
      quantity: 2,
      receivedNetWeight: 20.320,
      createdAt: now,
    );
    await _insertReturnVoucherLine(
      database,
      voucherNo: 'BC-DASH-IGNORE',
      operationType: 'BOOKING_CANCELLATION',
      sourceType: 'ADVANCE_BOOKING',
      metalType: 'GOLD',
      quantity: 1,
      receivedNetWeight: 99,
      createdAt: now,
    );

    final logic = DailyCounterLogic(db: database);
    addTearDown(logic.dispose);
    logic.init();

    final data = await logic.dataStream.first.timeout(
      const Duration(seconds: 2),
    );

    expect(data.metalMovement.boughtGold.weightRaw, closeTo(1.615, 0.001));
    expect(data.metalMovement.boughtGold.piecesStr, '3 Pcs');
    expect(data.metalMovement.boughtSilver.weightRaw, closeTo(20.320, 0.001));
    expect(data.metalMovement.boughtSilver.piecesStr, '2 Pcs');
  });

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

Future<void> _insertReturnVoucherLine(
  AppDatabase database, {
  required String voucherNo,
  required String operationType,
  required String sourceType,
  required String metalType,
  required int quantity,
  required double receivedNetWeight,
  required DateTime createdAt,
}) async {
  final createdAtMs = createdAt.millisecondsSinceEpoch;
  await database.customStatement(
    '''
    INSERT INTO return_vouchers (
      voucher_no,
      operation_type,
      source_type,
      source_id,
      source_number,
      settlement_mode,
      original_total_amount,
      return_value,
      due_adjusted_amount,
      customer_credit_amount,
      making_returned_amount,
      status,
      created_at,
      updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      voucherNo,
      operationType,
      sourceType,
      voucherNo.hashCode.abs(),
      'SRC-$voucherNo',
      'CUSTOMER_CREDIT',
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      'POSTED',
      createdAtMs,
      createdAtMs,
    ],
  );
  final voucherId = (await database
          .customSelect('SELECT last_insert_rowid() AS id')
          .getSingle())
      .read<int>('id');
  await database.customStatement(
    '''
    INSERT INTO return_voucher_lines (
      return_voucher_id,
      source_type,
      source_id,
      source_number,
      source_line_no,
      stock_disposition,
      metal_type,
      item_description,
      quantity,
      sold_net_weight,
      received_net_weight,
      line_return_value,
      status,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      voucherId,
      sourceType,
      voucherId,
      'SRC-$voucherNo',
      1,
      sourceType == 'ADVANCE_BOOKING' ? 'NOT_APPLICABLE' : 'ADD_STOCK',
      metalType,
      metalType == 'SILVER' ? 'PAYAL' : 'NOSE PIN',
      quantity,
      receivedNetWeight,
      receivedNetWeight,
      0.0,
      'POSTED',
      createdAtMs,
    ],
  );
}

Future<void> _insertCustomerPurchaseVoucherLine(
  AppDatabase database, {
  required String voucherNo,
  required String metalType,
  required int quantity,
  required double netWeight,
  required DateTime createdAt,
  String paymentStatus = 'PAID',
  String status = 'SAVED',
}) async {
  final createdAtMs = createdAt.millisecondsSinceEpoch;
  await database.customStatement(
    '''
    INSERT INTO purchase_vouchers (
      voucher_no,
      sequence_no,
      source_type,
      party_name,
      tax_type,
      gross_amount,
      taxable_amount,
      grand_total,
      total_paid,
      balance_due,
      payment_status,
      stock_entry_count,
      status,
      created_at,
      updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      voucherNo,
      voucherNo.hashCode.abs(),
      'CUSTOMER',
      'Dashboard Customer',
      'NORMAL',
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      paymentStatus,
      1,
      status,
      createdAtMs,
      createdAtMs,
    ],
  );
  final voucherId = (await database
          .customSelect('SELECT last_insert_rowid() AS id')
          .getSingle())
      .read<int>('id');
  await database.customStatement(
    '''
    INSERT INTO purchase_voucher_items (
      purchase_voucher_id,
      line_no,
      sku,
      metal_type,
      item_description,
      gross_weight,
      less_weight,
      net_weight,
      purity,
      fine_weight,
      rate,
      quantity,
      line_amount,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      voucherId,
      1,
      '$voucherNo-L001',
      metalType,
      metalType == 'SILVER' ? 'PAYAL' : 'NOSE PIN',
      netWeight,
      0.0,
      netWeight,
      metalType == 'SILVER' ? 60.0 : 18.0,
      netWeight,
      0.0,
      quantity,
      0.0,
      createdAtMs,
    ],
  );
}

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/sales/return_reversal/data/repositories/return_reversal_drift_repository.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_process.dart';

void main() {
  test('return reversal schema prepares voucher and melting dependencies',
      () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.ensureReturnReversalSchema();

    final tableRows = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
        )
        .get();
    final tables = tableRows.map((row) => row.read<String>('name')).toSet();

    expect(
      tables,
      containsAll(<String>{
        'return_vouchers',
        'return_voucher_lines',
        'purchase_vouchers',
        'purchase_voucher_items',
        'stock_item_units',
        'stock_unit_status_events',
      }),
    );

    final purchaseItemColumns = await database
        .customSelect('PRAGMA table_info(purchase_voucher_items)')
        .get();
    final columnNames =
        purchaseItemColumns.map((row) => row.read<String>('name')).toSet();

    expect(
      columnNames,
      containsAll(<String>{
        'quantity_mode',
        'packet_count',
        'pieces_per_packet',
        'valuation_fine_weight',
      }),
    );
  });

  test('processReturn remains compatible with legacy action columns', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ReturnReversalDriftRepository(database);

    await database.customStatement('DROP TABLE IF EXISTS return_voucher_lines');
    await database.customStatement('DROP TABLE IF EXISTS return_vouchers');
    await database.customStatement('''
      CREATE TABLE return_vouchers (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        voucher_no TEXT NOT NULL UNIQUE,
        action TEXT NOT NULL
      )
    ''');
    await database.customStatement('''
      CREATE TABLE return_voucher_lines (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL
      )
    ''');
    await database.ensureReturnReversalSchema();

    final customerId = await _insertCustomer(database);
    await _insertAdvanceBooking(database, customerId: customerId);
    final sourceDocument =
        await repository.findSourceDocumentByNumber('BK-RET-0001');

    final result = await repository.processReturn(
      ReturnReversalProcessRequest(
        operationType: ReturnReversalOperationType.bookingCancellation,
        sourceDocument: sourceDocument!,
        lines: const [
          ReturnReversalProcessLineInput(
            sourceLineNo: 1,
            receivedNetWeight: 0,
            huidMatched: true,
            unitMatched: true,
            includeMakingCharge: false,
            stockDisposition: ReturnReversalStockDisposition.notApplicable,
          ),
        ],
      ),
    );

    final voucherRow = await database.customSelect(
      'SELECT action FROM return_vouchers WHERE voucher_no = ?',
      variables: [drift.Variable.withString(result.voucherNo)],
    ).getSingle();
    final lineRow = await database.customSelect(
      'SELECT action FROM return_voucher_lines WHERE return_voucher_id = ?',
      variables: [drift.Variable.withInt(result.voucherId)],
    ).getSingle();

    expect(voucherRow.read<String>('action'), 'BOOKING_CANCELLATION');
    expect(lineRow.read<String>('action'), 'NOT_APPLICABLE');
  });

  test('transaction summary counts eligible sales invoices and bookings',
      () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ReturnReversalDriftRepository(database);

    await database.ensureReturnReversalSchema();
    final customerId = await _insertCustomer(database);
    await _insertSalesInvoice(database, customerId: customerId);
    await database.into(database.salesOrders).insert(
          SalesOrdersCompanion.insert(
            orderNo: 'BK-2026-0001',
            customerId: customerId,
            itemName: 'Gold Ring',
            deliveryDate: drift.Value(DateTime(2026, 9, 10)),
          ),
        );

    final summary = await repository.fetchTransactionSummary();

    expect(summary.eligibleSalesInvoices, 1);
    expect(summary.eligibleAdvanceBookings, 1);
    expect(summary.postedReturns, 0);
  });

  test('customer name lookup loads return and cancellation sources', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ReturnReversalDriftRepository(database);

    await database.ensureReturnReversalSchema();
    final customerId = await _insertCustomer(database);
    await _insertSalesInvoice(database, customerId: customerId);
    await _insertAdvanceBooking(database, customerId: customerId);
    await _insertCustomerPurchaseVoucher(database, customerId: customerId);

    final result = await repository.findCustomerHistoryByName('test cust');

    expect(
      result.salesInvoices.map((document) => document.documentNo),
      contains('INV-RET-0001'),
    );
    expect(
      result.advanceBookings.map((document) => document.documentNo),
      contains('BK-RET-0001'),
    );
    expect(
      result.customerPurchases.map((document) => document.documentNo),
      contains('CMP-RET-0001'),
    );
  });

  test('processReturn posts voucher, restores linked unit, and credits ledger',
      () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ReturnReversalDriftRepository(database);

    await database.ensureReturnReversalSchema();
    final customerId = await _insertCustomer(database);
    final stockItemId = await _insertSoldStockItem(database);
    final stockUnitId = await _insertSoldStockUnit(database, stockItemId);
    await _insertSalesInvoice(
      database,
      customerId: customerId,
      linkedStockItemId: stockItemId,
      linkedStockUnitId: stockUnitId,
    );
    final sourceDocument =
        await repository.findSourceDocumentByNumber('INV-RET-0001');

    final result = await repository.processReturn(
      ReturnReversalProcessRequest(
        operationType: ReturnReversalOperationType.salesReturn,
        sourceDocument: sourceDocument!,
        lines: const [
          ReturnReversalProcessLineInput(
            sourceLineNo: 1,
            receivedNetWeight: 10,
            huidMatched: true,
            unitMatched: true,
            includeMakingCharge: true,
            stockDisposition: ReturnReversalStockDisposition.addToStock,
          ),
        ],
      ),
    );

    expect(result.status, 'POSTED');
    expect(result.returnValue, 10500);
    expect(result.dueAdjustedAmount, 2000);
    expect(result.customerCreditAmount, 8500);

    final bill = await (database.select(database.bills)
          ..where((table) => table.billNo.equals('INV-RET-0001')))
        .getSingle();
    expect(bill.status, 'RETURNED');
    expect(bill.dueAmount, 0);
    expect(bill.paymentStatus, 'PAID');

    final unitRow = await database.customSelect(
      'SELECT status, sold_at FROM stock_item_units WHERE id = ?',
      variables: [drift.Variable.withInt(stockUnitId)],
    ).getSingle();
    expect(unitRow.read<String>('status'), 'Available');
    expect(unitRow.readNullable<int>('sold_at'), isNull);

    final movementCount = await _countRows(database, 'stock_movements');
    final ledgerCount = await _countRows(database, 'customer_account_ledger');
    expect(movementCount, 1);
    expect(ledgerCount, 1);

    final refreshed = await repository.findSourceDocumentByNumber(
      'INV-RET-0001',
    );
    final returnedLine = refreshed!.lineItems.single;
    expect(returnedLine.reversalStatus, 'POSTED');
    expect(returnedLine.reversalVoucherNo, result.voucherNo);
    expect(returnedLine.reversalDate, isNotNull);
    expect(returnedLine.reversalReceivedNetWeight, 10);
    expect(returnedLine.reversalHuidMatched, isTrue);
    expect(returnedLine.reversalUnitMatched, isTrue);
    expect(returnedLine.reversalIncludeMakingCharge, isTrue);
    expect(returnedLine.reversalStockDisposition, 'ADD_STOCK');
    expect(returnedLine.reversalMetalReturnAmount, 10000);
    expect(returnedLine.reversalMakingReturnedAmount, 500);
    expect(returnedLine.reversalLineReturnValue, 10500);
  });

  test('processReturn materializes a stock unit when legacy bill line has none',
      () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ReturnReversalDriftRepository(database);

    await database.ensureReturnReversalSchema();
    final customerId = await _insertCustomer(database);
    final stockItemId = await _insertSoldStockItem(database);
    await _insertSalesInvoice(
      database,
      customerId: customerId,
      linkedStockItemId: stockItemId,
    );
    final sourceDocument =
        await repository.findSourceDocumentByNumber('INV-RET-0001');

    await repository.processReturn(
      ReturnReversalProcessRequest(
        operationType: ReturnReversalOperationType.salesReturn,
        sourceDocument: sourceDocument!,
        lines: const [
          ReturnReversalProcessLineInput(
            sourceLineNo: 1,
            receivedNetWeight: 10,
            huidMatched: true,
            unitMatched: true,
            includeMakingCharge: false,
            stockDisposition: ReturnReversalStockDisposition.managerHold,
          ),
        ],
      ),
    );

    final unitCount = await _countRows(database, 'stock_item_units');
    final stockItem = await (database.select(database.stockItems)
          ..where((table) => table.id.equals(stockItemId)))
        .getSingle();
    expect(unitCount, 1);
    expect(stockItem.quantity, 1);
    expect(stockItem.status, 'On Hold');
  });

  test('processReturn rejects received weight above original sold weight',
      () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ReturnReversalDriftRepository(database);

    await database.ensureReturnReversalSchema();
    final customerId = await _insertCustomer(database);
    await _insertSalesInvoice(database, customerId: customerId);
    final sourceDocument =
        await repository.findSourceDocumentByNumber('INV-RET-0001');

    expect(
      () => repository.processReturn(
        ReturnReversalProcessRequest(
          operationType: ReturnReversalOperationType.salesReturn,
          sourceDocument: sourceDocument!,
          lines: const [
            ReturnReversalProcessLineInput(
              sourceLineNo: 1,
              receivedNetWeight: 10.5,
              huidMatched: true,
              unitMatched: true,
              includeMakingCharge: true,
              stockDisposition: ReturnReversalStockDisposition.addToStock,
            ),
          ],
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('processReturn cancels advance booking without stock routing', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ReturnReversalDriftRepository(database);

    await database.ensureReturnReversalSchema();
    final customerId = await _insertCustomer(database);
    await _insertAdvanceBooking(database, customerId: customerId);
    final sourceDocument =
        await repository.findSourceDocumentByNumber('BK-RET-0001');

    final result = await repository.processReturn(
      ReturnReversalProcessRequest(
        operationType: ReturnReversalOperationType.bookingCancellation,
        sourceDocument: sourceDocument!,
        lines: const [
          ReturnReversalProcessLineInput(
            sourceLineNo: 1,
            receivedNetWeight: 0,
            huidMatched: true,
            unitMatched: true,
            includeMakingCharge: false,
            stockDisposition: ReturnReversalStockDisposition.notApplicable,
          ),
        ],
      ),
    );

    expect(result.status, 'POSTED');
    expect(result.returnValue, 3000);
    expect(result.dueAdjustedAmount, 0);
    expect(result.customerCreditAmount, 3000);

    final order = await (database.select(database.salesOrders)
          ..where((table) => table.orderNo.equals('BK-RET-0001')))
        .getSingle();
    expect(order.status, 'CANCELLED');

    final returnLine = await database.customSelect(
      '''
          SELECT stock_disposition, received_net_weight, line_return_value
          FROM return_voucher_lines
          WHERE source_type = 'ADVANCE_BOOKING'
          ''',
    ).getSingle();
    expect(returnLine.read<String>('stock_disposition'), 'NOT_APPLICABLE');
    expect(returnLine.read<double>('received_net_weight'), 0);
    expect(returnLine.read<double>('line_return_value'), 3000);
    expect(await _countRows(database, 'stock_movements'), 0);
    expect(await _countRows(database, 'customer_account_ledger'), 1);
  });

  test('customer purchase lookup shows posted reversal status', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ReturnReversalDriftRepository(database);

    await database.ensureReturnReversalSchema();
    final customerId = await _insertCustomer(database);
    await _insertCustomerPurchaseVoucher(database, customerId: customerId);
    final sourceDocument =
        await repository.findSourceDocumentByNumber('CMP-RET-0001');

    await repository.processReturn(
      ReturnReversalProcessRequest(
        operationType: ReturnReversalOperationType.salesReturn,
        sourceDocument: sourceDocument!,
        lines: const [
          ReturnReversalProcessLineInput(
            sourceLineNo: 1,
            receivedNetWeight: 8,
            huidMatched: true,
            unitMatched: true,
            includeMakingCharge: false,
            stockDisposition: ReturnReversalStockDisposition.managerHold,
          ),
        ],
      ),
    );

    final refreshed = await repository.findSourceDocumentByNumber(
      'CMP-RET-0001',
    );

    expect(refreshed!.reversalStatus, 'RETURNED');
    expect(refreshed.reversedLineCount, 1);
    expect(refreshed.lineItems.single.reversalStatus, 'POSTED');
    expect(refreshed.lineItems.single.reversalVoucherNo, startsWith('SR-'));
  });
}

Future<int> _insertCustomer(AppDatabase database) {
  return database.into(database.customers).insert(
        CustomersCompanion.insert(
          name: 'Test Customer',
          mobile: '9999999999',
          city: const drift.Value('Surat'),
        ),
      );
}

Future<int> _insertSoldStockItem(AppDatabase database) {
  return database.into(database.stockItems).insert(
        StockItemsCompanion.insert(
          sku: 'RET-GOLD-RING-001',
          itemName: 'Gold Ring',
          category: 'Gold Jewellery',
          subCategory: 'Ring',
          metalType: const drift.Value('Gold'),
          purity: const drift.Value('22K'),
          grossWeight: const drift.Value(10),
          netWeight: const drift.Value(10),
          purchaseRate: const drift.Value(6000),
          purchasePrice: const drift.Value(60000),
          quantity: const drift.Value(0),
          status: const drift.Value('Sold'),
          isActive: const drift.Value(false),
        ),
      );
}

Future<int> _insertSoldStockUnit(
  AppDatabase database,
  int stockItemId,
) async {
  final nowMs = DateTime(2026, 9, 1).millisecondsSinceEpoch;
  await database.customStatement(
    '''
    INSERT INTO stock_item_units (
      stock_item_id,
      batch_code,
      unit_code,
      piece_no,
      metal_type,
      item_type,
      item_name,
      huid,
      gross_weight,
      less_weight,
      net_weight,
      purity_percent,
      actual_fine_weight,
      rate_per_gram,
      making_amount,
      unit_cost,
      status,
      created_at,
      updated_at,
      sold_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      stockItemId,
      'RET-BATCH',
      'RET-GOLD-RING-001-U001',
      1,
      'Gold',
      'Ring',
      'Gold Ring',
      'HUID123456',
      10.0,
      0.0,
      10.0,
      91.6,
      9.16,
      1000.0,
      500.0,
      10500.0,
      'Sold',
      nowMs,
      nowMs,
      nowMs,
    ],
  );
  final row = await database
      .customSelect('SELECT last_insert_rowid() AS id')
      .getSingle();
  return row.read<int>('id');
}

Future<int> _insertSalesInvoice(
  AppDatabase database, {
  required int customerId,
  int? linkedStockItemId,
  int? linkedStockUnitId,
}) async {
  final billId = await database.into(database.bills).insert(
        BillsCompanion.insert(
          billNo: 'INV-RET-0001',
          customerId: drift.Value(customerId),
          customerName: const drift.Value('Test Customer'),
          mobile: const drift.Value('9999999999'),
          totalAmount: const drift.Value(10500),
          taxableAmount: const drift.Value(10500),
          finalAmount: const drift.Value(10500),
          paidAmount: const drift.Value(8500),
          cashPaid: const drift.Value(8500),
          dueAmount: const drift.Value(2000),
          paymentStatus: const drift.Value('PARTIAL'),
          status: const drift.Value('ACTIVE'),
          billDate: drift.Value(DateTime(2026, 9, 1)),
        ),
      );
  await database.into(database.billItems).insert(
        BillItemsCompanion.insert(
          billId: billId,
          lineNo: const drift.Value(1),
          metalType: const drift.Value('GOLD'),
          itemName: 'Gold Ring',
          hsnCode: const drift.Value('7113'),
          huid: const drift.Value('HUID123456'),
          purity: const drift.Value('22K'),
          grossWeight: const drift.Value(10),
          netWeight: const drift.Value(10),
          fineWeight: const drift.Value(9.16),
          rate: const drift.Value(1000),
          makingChargeType: const drift.Value('PER_GRAM'),
          makingChargeInput: const drift.Value(50),
          makingCharge: const drift.Value(500),
          itemTotal: const drift.Value(10500),
          taxableAmountSnapshot: const drift.Value(10500),
          invoiceValueSnapshot: const drift.Value(10500),
          linkedStockItemId: drift.Value(linkedStockItemId),
          linkedStockUnitId: drift.Value(linkedStockUnitId),
          linkedStockSku: const drift.Value('RET-GOLD-RING-001'),
        ),
      );
  return billId;
}

Future<int> _insertAdvanceBooking(
  AppDatabase database, {
  required int customerId,
}) async {
  final orderId = await database.into(database.salesOrders).insert(
        SalesOrdersCompanion.insert(
          orderNo: 'BK-RET-0001',
          customerId: customerId,
          itemName: 'Gold Ring Booking',
          metalType: const drift.Value('GOLD'),
          approxWeight: const drift.Value(0),
          lockedRate: const drift.Value(0),
          deliveryDate: drift.Value(DateTime(2026, 9, 20)),
        ),
      );
  await database.into(database.orderAdvances).insert(
        OrderAdvancesCompanion.insert(
          orderId: orderId,
          amountPaid: const drift.Value(3000),
          rateOnDate: const drift.Value(0),
          paymentDate: drift.Value(DateTime(2026, 9, 1)),
        ),
      );
  return orderId;
}

Future<int> _insertCustomerPurchaseVoucher(
  AppDatabase database, {
  required int customerId,
}) async {
  final nowMs = DateTime(2026, 9, 1).millisecondsSinceEpoch;
  await database.customStatement(
    '''
    INSERT INTO purchase_vouchers (
      voucher_no,
      sequence_no,
      source_type,
      customer_id,
      party_name,
      mobile,
      city,
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
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      'CMP-RET-0001',
      1,
      'CUSTOMER',
      customerId,
      'Test Customer',
      '9999999999',
      'Surat',
      'NORMAL',
      8000.0,
      8000.0,
      8000.0,
      8000.0,
      0.0,
      'PAID',
      1,
      'SAVED',
      nowMs,
      nowMs,
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
      'CMP-RET-0001-L001',
      'GOLD',
      'Old Gold Ring',
      8.0,
      0.0,
      8.0,
      91.6,
      7.33,
      1000.0,
      1,
      8000.0,
      nowMs,
    ],
  );
  return voucherId;
}

Future<int> _countRows(AppDatabase database, String tableName) async {
  final row = await database
      .customSelect('SELECT COUNT(*) AS row_count FROM $tableName')
      .getSingle();
  return row.read<int>('row_count');
}

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/finance/bank_book/bank_book_enums.dart'
    as bank_book;
import 'package:lotus_erp/models/finance/cash_book/cash_book_enums.dart'
    as cash_book;
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart'
    as pos;
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart'
    as stock;
import 'package:lotus_erp/repositories/booking_advance/booking_advance_repository.dart';
import 'package:lotus_erp/repositories/sales_orders/pos/pos_checkout_repository.dart';

void main() {
  late AppDatabase db;
  late PosCheckoutRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = PosCheckoutRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('wholesale percentage making is calculated from metal value', () {
    final item = SaleItemModel(
      metal: pos.MetalType.gold,
      makingChargeType: pos.MakingChargeType.percentage,
    );
    item.grossCtrl.text = '10';
    item.lessCtrl.text = '0';
    item.rateCtrl.text = '1000';
    item.makingCtrl.text = '5';

    expect(item.wholesaleLabourAmt, 500);

    item.dispose();
  });

  test('old silver exchange does not treat blank purity as pure silver', () {
    final item = TradeInItemModel(metal: pos.MetalType.silver);
    item.grossCtrl.text = '10';
    item.lessCtrl.text = '0';
    item.rateCtrl.text = '100';
    item.purityCtrl.clear();

    expect(item.fineWt, 0);
    expect(item.totalValue, 0);

    item.purityCtrl.text = '92.5';
    expect(item.fineWt, 9.25);
    expect(item.totalValue, 925);

    item.dispose();
  });

  test(
    'finalizeSale saves bill, sale items, old gold, stock movement and cash ledger',
    () async {
      final stockId = await _insertStockItem(db, sku: 'GOLD-RING-SAVE');
      final saleItem = _saleItem(
        stockItemId: stockId,
        sku: 'GOLD-RING-SAVE',
        grossWeight: 10,
        rate: 100,
      );
      final tradeInItem = _tradeInItem(
        grossWeight: 2,
        purity: 90,
        rate: 50,
      );
      final invoice = _invoice(
        invoiceNumber: 'INV-LJ-2026-0001',
        saleItems: [saleItem],
        tradeInItems: [tradeInItem],
        cashPaid: 910,
      );

      final result = await repository.finalizeSale(
        invoice: invoice,
        customerId: null,
      );

      final bill = await (db.select(db.bills)
            ..where((tbl) => tbl.id.equals(result.billId)))
          .getSingle();
      final billItems = await (db.select(db.billItems)
            ..where((tbl) => tbl.billId.equals(result.billId)))
          .get();
      final tradeInRows = await (db.select(db.billTradeInItems)
            ..where((tbl) => tbl.billId.equals(result.billId)))
          .get();
      final stockRow = await _stockById(db, stockId);
      final stockMovements = await _stockMovementsFor(db, stockId);
      final cashRows = await db.select(db.cashTransactions).get();

      expect(result.invoiceNumber, 'LJ-26-001');
      expect(result.invoiceSequence, 1);
      expect(bill.finalAmount, 910);
      expect(bill.tradeInDeduction, 90);
      expect(bill.paymentStatus, 'PAID');
      expect(billItems, hasLength(1));
      expect(billItems.single.linkedStockItemId, stockId);
      expect(tradeInRows, hasLength(1));
      expect(tradeInRows.single.fineWeight, 1.8);
      expect(tradeInRows.single.lineAmount, 90);
      expect(stockRow.quantity, 0);
      expect(stockRow.status, stock.StockStatus.sold.label);
      expect(stockMovements, hasLength(1));
      expect(stockMovements.single.movementType, 'SALE');
      expect(stockMovements.single.sourceNumber, result.invoiceNumber);
      expect(stockMovements.single.sourceLineNo, 1);
      expect(stockMovements.single.quantityDelta, -1);
      expect(stockMovements.single.grossWeightDelta, -10);
      expect(stockMovements.single.netWeightDelta, -10);
      expect(cashRows, hasLength(1));
      expect(cashRows.single.referenceId, '${result.invoiceNumber}#CASH');
      expect(cashRows.single.amount, 910);
      expect(cashRows.single.isVoided, isFalse);

      _disposeItems(saleItems: [saleItem], tradeInItems: [tradeInItem]);
    },
  );

  test(
    'finalizeSale persists accounting money at paisa precision without false due',
    () async {
      final invoice = PosInvoiceModel(
        invoiceNumber: 'TAX-AJ-2026-0002',
        invoiceDate: DateTime(2026, 6, 25, 12),
        billType: pos.BillType.gst,
        billingMode: pos.BillingMode.retail,
        shopName: 'Lotus Jewellers',
        shopAddress: 'Patna',
        shopPhone: '9000000000',
        shopGstin: '10ABCDE1234F1Z5',
        customerName: 'REYANSH SONI',
        customerMobile: '9304479436',
        customerCity: 'Patna',
        customerPan: '',
        customerGstin: '',
        tradeInMode: pos.TradeInAdjustMode.cashAdjust,
        saleItems: const [],
        tradeInItems: const [],
        grossAmount: 9690.912,
        discountAmount: 0.62,
        taxableAmount: 9690.292,
        cgst: 145.355,
        sgst: 145.355,
        totalGst: 290.71,
        totalTradeInDeduction: 0,
        grandTotal: 9981.001999999999,
        cashPaid: 9981,
        upiPaid: 0,
        cardPaid: 0,
        advancePaid: 0,
        balanceDue: 0.001999999999,
        totalMakingCharge: 1038.312,
      );

      final result = await repository.finalizeSale(
        invoice: invoice,
        customerId: null,
      );

      final bill = await (db.select(db.bills)
            ..where((tbl) => tbl.id.equals(result.billId)))
          .getSingle();
      final cashRows = await db.select(db.cashTransactions).get();

      expect(bill.totalAmount, 9690.91);
      expect(bill.discount, 0.62);
      expect(bill.taxableAmount, 9690.29);
      expect(bill.cgstAmount, 145.36);
      expect(bill.sgstAmount, 145.35);
      expect(bill.gstAmount, 290.71);
      expect(bill.cgstAmount + bill.sgstAmount, closeTo(bill.gstAmount, 0.001));
      expect(bill.finalAmount, 9981);
      expect(bill.paidAmount, 9981);
      expect(bill.dueAmount, 0);
      expect(bill.paymentStatus, 'PAID');
      expect(cashRows.single.amount, 9981);
    },
  );

  test('finalizeSale stores ERP round-off separately from GST values',
      () async {
    final invoice = PosInvoiceModel(
      invoiceNumber: 'TAX-LJ-2026-ROUND',
      invoiceDate: DateTime(2026, 6, 25, 12),
      billType: pos.BillType.gst,
      billingMode: pos.BillingMode.retail,
      shopName: 'Lotus Jewellers',
      shopAddress: 'Patna',
      shopPhone: '9000000000',
      shopGstin: '10ABCDE1234F1Z5',
      customerName: 'Walk-in Customer',
      customerMobile: '',
      customerCity: 'Patna',
      customerPan: '',
      customerGstin: '',
      tradeInMode: pos.TradeInAdjustMode.cashAdjust,
      saleItems: const [],
      tradeInItems: const [],
      grossAmount: 9691.88,
      discountAmount: 0,
      taxableAmount: 9691.88,
      cgst: 145.38,
      sgst: 145.38,
      totalGst: 290.76,
      totalTradeInDeduction: 0,
      grandTotal: 9982.64,
      roundOffAmount: 0.36,
      cashPaid: 9983,
      upiPaid: 0,
      cardPaid: 0,
      advancePaid: 0,
      balanceDue: 0,
      totalMakingCharge: 0,
    );

    final result = await repository.finalizeSale(
      invoice: invoice,
      customerId: null,
    );

    final bill = await (db.select(db.bills)
          ..where((tbl) => tbl.id.equals(result.billId)))
        .getSingle();

    expect(bill.taxableAmount, 9691.88);
    expect(bill.gstAmount, 290.76);
    expect(bill.roundOffAmount, 0.36);
    expect(bill.finalAmount, 9983);
    expect(bill.paidAmount, 9983);
    expect(bill.dueAmount, 0);
    expect(bill.paymentStatus, 'PAID');
  });

  test(
    'finalizeSale maps each linked stock movement to its bill item line number',
    () async {
      final firstStockId = await _insertStockItem(db, sku: 'GOLD-LINE-001');
      final secondStockId = await _insertStockItem(db, sku: 'GOLD-LINE-002');
      final firstItem = _saleItem(
        stockItemId: firstStockId,
        sku: 'GOLD-LINE-001',
        grossWeight: 8,
        rate: 100,
      );
      final secondItem = _saleItem(
        stockItemId: secondStockId,
        sku: 'GOLD-LINE-002',
        grossWeight: 12,
        rate: 100,
      );
      final invoice = _invoice(
        invoiceNumber: 'INV-LJ-2026-0001',
        saleItems: [firstItem, secondItem],
        cashPaid: 2000,
      );

      final result = await repository.finalizeSale(
        invoice: invoice,
        customerId: null,
      );

      final billItems = await (db.select(db.billItems)
            ..where((tbl) => tbl.billId.equals(result.billId))
            ..orderBy([(tbl) => drift.OrderingTerm.asc(tbl.lineNo)]))
          .get();
      final firstMovements = await _stockMovementsFor(db, firstStockId);
      final secondMovements = await _stockMovementsFor(db, secondStockId);
      final printableItems =
          await repository.fetchPrintableSaleItems(result.billId);

      expect(billItems.map((row) => row.lineNo), [1, 2]);
      expect(billItems.map((row) => row.linkedStockSku), [
        'GOLD-LINE-001',
        'GOLD-LINE-002',
      ]);
      expect(firstMovements.single.sourceLineNo, billItems.first.lineNo);
      expect(secondMovements.single.sourceLineNo, billItems.last.lineNo);
      expect(firstMovements.single.skuSnapshot, billItems.first.linkedStockSku);
      expect(secondMovements.single.skuSnapshot, billItems.last.linkedStockSku);
      expect(printableItems, hasLength(2));
      expect(printableItems.map((item) => item.linkedStockSku), [
        'GOLD-LINE-001',
        'GOLD-LINE-002',
      ]);
      expect(printableItems.map((item) => item.huidCtrl.text), [
        'GOLD-LINE-001',
        'GOLD-LINE-002',
      ]);
      expect(printableItems.map((item) => item.grossCtrl.text), ['8', '12']);

      _disposeItems(saleItems: [firstItem, secondItem, ...printableItems]);
    },
  );

  test(
    'finalizeSale scopes selected stock unit to the linked stock item',
    () async {
      final firstStockId = await _insertStockItem(db, sku: 'GOLD-SCOPE-001');
      final secondStockId = await _insertStockItem(db, sku: 'GOLD-SCOPE-002');
      final secondUnitId = await _stockUnitIdFor(db, secondStockId);
      final saleItem = _saleItem(
        stockItemId: firstStockId,
        sku: 'GOLD-SCOPE-001',
        grossWeight: 10,
        rate: 100,
      );
      saleItem.attachStockReference(
        stockItemId: firstStockId,
        stockUnitId: secondUnitId,
        sku: 'GOLD-SCOPE-002-U001',
      );
      final invoice = _invoice(
        invoiceNumber: 'INV-LJ-2026-0003',
        saleItems: [saleItem],
        cashPaid: saleItem.totalValue,
      );

      await repository.finalizeSale(invoice: invoice, customerId: null);

      final firstStock = await _stockById(db, firstStockId);
      final secondStock = await _stockById(db, secondStockId);
      final firstUnitStatus = await _stockUnitStatusFor(db, firstStockId);
      final secondUnitStatus = await _stockUnitStatusFor(db, secondStockId);

      expect(firstStock.status, stock.StockStatus.sold.label);
      expect(firstUnitStatus, stock.StockStatus.sold.label);
      expect(secondStock.status, stock.StockStatus.available.label);
      expect(secondUnitStatus, stock.StockStatus.available.label);

      _disposeItems(saleItems: [saleItem]);
    },
  );

  test(
    'finalizeSale clears full lot stock balance on net-weight sale',
    () async {
      final stockId = await _insertSilverLotStock(
        db,
        sku: 'SIL-CHAND-LOT',
        quantity: 8,
        grossWeight: 12.45,
        lessWeight: 0.50,
        netWeight: 11.95,
      );
      final saleItem = SaleItemModel(metal: pos.MetalType.silver);
      saleItem.descCtrl.text = 'CHAND';
      saleItem.pcsCtrl.text = '8';
      saleItem.purityCtrl.text = '999';
      saleItem.grossCtrl.text = '11.95';
      saleItem.lessCtrl.text = '0';
      saleItem.rateCtrl.text = '100';
      saleItem.makingCtrl.text = '0';
      saleItem.attachStockReference(
        stockItemId: stockId,
        sku: 'SIL-CHAND-LOT-U001',
      );
      final invoice = _invoice(
        invoiceNumber: 'INV-LJ-2026-0001',
        saleItems: [saleItem],
        cashPaid: 1195,
      );

      await repository.finalizeSale(invoice: invoice, customerId: null);

      final stockRow = await _stockById(db, stockId);
      final stockMovements = await _stockMovementsFor(db, stockId);

      expect(stockRow.quantity, 0);
      expect(stockRow.status, stock.StockStatus.sold.label);
      expect(stockRow.grossWeight, 0);
      expect(stockRow.stoneWeight, 0);
      expect(stockRow.netWeight, 0);
      expect(stockMovements.single.quantityDelta, -8);
      expect(stockMovements.single.grossWeightDelta, -12.45);
      expect(stockMovements.single.netWeightDelta, -11.95);

      _disposeItems(saleItems: [saleItem]);
    },
  );

  test(
    'finalizeSale saves and reloads invoice HSN code snapshot',
    () async {
      final stockId = await _insertStockItem(db, sku: 'GOLD-HSN-001');
      final saleItem = _saleItem(
        stockItemId: stockId,
        sku: 'GOLD-HSN-001',
        grossWeight: 5,
        rate: 1000,
      );
      saleItem.setInvoiceHsnCode('71131910');
      final invoice = _invoice(
        invoiceNumber: 'INV-LJ-2026-0001',
        saleItems: [saleItem],
        cashPaid: 5000,
      );

      final result = await repository.finalizeSale(
        invoice: invoice,
        customerId: null,
      );

      final billItems = await (db.select(db.billItems)
            ..where((tbl) => tbl.billId.equals(result.billId)))
          .get();
      final printableItems =
          await repository.fetchPrintableSaleItems(result.billId);

      expect(billItems.single.hsnCode, '71131910');
      expect(printableItems.single.invoiceHsnCode, '71131910');

      _disposeItems(saleItems: [saleItem, ...printableItems]);
    },
  );

  test(
    'fetchPrintableSaleItems preserves three decimal jewellery weights',
    () async {
      final stockId = await _insertStockItem(db, sku: 'GOLD-PRECISION-001');
      final saleItem = _saleItem(
        stockItemId: stockId,
        sku: 'GOLD-PRECISION-001',
        grossWeight: 0.759,
        rate: 11400,
      );
      saleItem.grossCtrl.text = '0.759';
      saleItem.makingCtrl.text = '12';
      saleItem
        ..toggleMakingChargeType(isWholesale: false)
        ..toggleMakingChargeType(isWholesale: false);
      final invoice = _invoice(
        invoiceNumber: 'TAX-LJ-2026-0001',
        saleItems: [saleItem],
        cashPaid: saleItem.totalValue,
      );

      final result = await repository.finalizeSale(
        invoice: invoice,
        customerId: null,
      );
      final printableItems =
          await repository.fetchPrintableSaleItems(result.billId);

      expect(printableItems, hasLength(1));
      expect(printableItems.single.grossCtrl.text, '0.759');
      expect(printableItems.single.netWt, closeTo(0.759, 0.0001));
      expect(printableItems.single.totalValue, closeTo(9690.912, 0.001));

      _disposeItems(saleItems: [saleItem, ...printableItems]);
    },
  );

  test(
    'finalizeSale posts mixed cash UPI and card payments to finance ledgers',
    () async {
      await _insertPrimaryBankAccount(db);
      final saleItem = _manualSaleItem(grossWeight: 6, rate: 100);
      final invoice = _invoice(
        invoiceNumber: 'INV-LJ-2026-0001',
        saleItems: [saleItem],
        cashPaid: 100,
        upiPaid: 200,
        cardPaid: 300,
      );

      final result = await repository.finalizeSale(
        invoice: invoice,
        customerId: null,
      );

      final cashRows = await db.select(db.cashTransactions).get();
      final bankRows = await db.select(db.bankTransactions).get();

      expect(cashRows, hasLength(1));
      expect(cashRows.single.paymentMode, cash_book.PaymentMode.cash.dbValue);
      expect(cashRows.single.amount, 100);
      expect(cashRows.single.referenceId, '${result.invoiceNumber}#CASH');
      expect(bankRows, hasLength(2));
      expect(
        bankRows.map((row) => row.referenceId).toSet(),
        {'${result.invoiceNumber}#UPI', '${result.invoiceNumber}#CARD'},
      );
      expect(bankRows.map((row) => row.amount).toSet(), {200.0, 300.0});
      expect(bankRows.every((row) => !row.isVoided), isTrue);

      _disposeItems(saleItems: [saleItem]);
    },
  );

  test(
    'finalizeSale saves partial due bill without posting unpaid balance to ledger',
    () async {
      final customerId = await _insertCustomer(db);
      final saleItem = _manualSaleItem(grossWeight: 10, rate: 100);
      final invoice = _invoice(
        invoiceNumber: 'INV-LJ-2026-0001',
        saleItems: [saleItem],
        customerName: 'Reyansh Soni',
        customerMobile: '9304479436',
        cashPaid: 250,
        promiseDate: DateTime(2026, 7, 10),
      );

      final result = await repository.finalizeSale(
        invoice: invoice,
        customerId: customerId,
      );

      final bill = await (db.select(db.bills)
            ..where((tbl) => tbl.id.equals(result.billId)))
          .getSingle();
      final cashRows = await db.select(db.cashTransactions).get();
      final bankRows = await db.select(db.bankTransactions).get();

      expect(bill.customerId, customerId);
      expect(bill.paymentStatus, 'PARTIAL');
      expect(bill.finalAmount, 1000);
      expect(bill.paidAmount, 250);
      expect(bill.dueAmount, 750);
      expect(bill.promiseDate, DateTime(2026, 7, 10));
      expect(cashRows, hasLength(1));
      expect(cashRows.single.amount, 250);
      expect(bankRows, isEmpty);

      _disposeItems(saleItems: [saleItem]);
    },
  );

  test(
    'finalizeSale keeps excess payment as customer account credit',
    () async {
      final customerId = await _insertCustomer(db);
      final saleItem = _manualSaleItem(grossWeight: 10, rate: 100);
      final invoice = _invoice(
        invoiceNumber: 'INV-LJ-2026-0001',
        saleItems: [saleItem],
        customerName: 'Reyansh Soni',
        customerMobile: '9304479436',
        cashPaid: 1000,
        changeSettlementMethod: pos.RefundMethod.accountCredit,
        changeSettlementAmount: 25,
        changeSettlementPaymentMode: pos.PaymentMode.cash,
      );

      final result = await repository.finalizeSale(
        invoice: invoice,
        customerId: customerId,
      );

      final bill = await (db.select(db.bills)
            ..where((tbl) => tbl.id.equals(result.billId)))
          .getSingle();
      final customerCredits = await db.select(db.customerAccountLedger).get();
      final cashRows = await db.select(db.cashTransactions).get();

      expect(bill.finalAmount, 1000);
      expect(bill.paidAmount, 1000);
      expect(bill.paymentStatus, 'PAID');
      expect(customerCredits, hasLength(1));
      expect(customerCredits.single.customerId, customerId);
      expect(customerCredits.single.entryType, 'CREDIT');
      expect(customerCredits.single.sourceType, 'POS_CHANGE_CREDIT');
      expect(customerCredits.single.sourceReference,
          '${result.invoiceNumber}#ACCOUNT_CREDIT');
      expect(customerCredits.single.amount, 25);
      expect(customerCredits.single.isVoided, isFalse);

      expect(cashRows, hasLength(2));
      final saleCash = cashRows.singleWhere(
        (row) => row.referenceId == '${result.invoiceNumber}#CASH',
      );
      final creditCash = cashRows.singleWhere(
        (row) =>
            row.referenceId == '${result.invoiceNumber}#ACCOUNT_CREDIT#CASH',
      );
      expect(saleCash.amount, 1000);
      expect(saleCash.category, cash_book.IncomeCategory.sale.dbValue);
      expect(creditCash.amount, 25);
      expect(
        creditCash.category,
        cash_book.IncomeCategory.advanceBooking.dbValue,
      );
      expect(creditCash.referenceType, 'CUSTOMER_ACCOUNT');

      _disposeItems(saleItems: [saleItem]);
    },
  );

  test(
    'finalizeSale records cross-mode UPI change return against cash excess',
    () async {
      await _insertPrimaryBankAccount(db);
      final saleItem = _manualSaleItem(grossWeight: 10, rate: 100);
      final invoice = _invoice(
        invoiceNumber: 'INV-LJ-2026-0001',
        saleItems: [saleItem],
        cashPaid: 1000,
        changeSettlementMethod: pos.RefundMethod.upi,
        changeSettlementAmount: 30,
        changeSettlementPaymentMode: pos.PaymentMode.cash,
      );

      final result = await repository.finalizeSale(
        invoice: invoice,
        customerId: null,
      );

      final cashRows = await db.select(db.cashTransactions).get();
      final bankRows = await db.select(db.bankTransactions).get();

      expect(cashRows, hasLength(2));
      expect(
        cashRows
            .singleWhere(
              (row) => row.referenceId == '${result.invoiceNumber}#CASH',
            )
            .amount,
        1000,
      );
      final cashExcess = cashRows.singleWhere(
        (row) =>
            row.referenceId ==
            '${result.invoiceNumber}#CHANGE_RETURN#SOURCE_CASH',
      );
      expect(cashExcess.amount, 30);
      expect(cashExcess.referenceType, 'CUSTOMER_CHANGE');
      expect(cashExcess.category, cash_book.IncomeCategory.miscIncome.dbValue);

      expect(bankRows, hasLength(1));
      expect(bankRows.single.type, bank_book.BankTransactionType.debit.dbValue);
      expect(bankRows.single.category,
          bank_book.BankDebitCategory.miscDebit.dbValue);
      expect(bankRows.single.amount, 30);
      expect(
        bankRows.single.referenceId,
        '${result.invoiceNumber}#CHANGE_RETURN#RETURN_UPI',
      );

      _disposeItems(saleItems: [saleItem]);
    },
  );

  test(
    'updateSale restores previous stock, deducts updated stock, and reposts POS ledger entries',
    () async {
      await _insertPrimaryBankAccount(db);
      final firstStockId = await _insertStockItem(db, sku: 'GOLD-RING-001');
      final secondStockId = await _insertStockItem(db, sku: 'GOLD-RING-002');

      final firstItem = _saleItem(
        stockItemId: firstStockId,
        sku: 'GOLD-RING-001',
        grossWeight: 10,
        rate: 100,
      );
      final firstInvoice = _invoice(
        invoiceNumber: 'INV-LJ-2026-0001',
        saleItems: [firstItem],
        cashPaid: 400,
        upiPaid: 600,
      );

      final result = await repository.finalizeSale(
        invoice: firstInvoice,
        customerId: null,
      );

      await db.into(db.cashTransactions).insert(
            CashTransactionsCompanion.insert(
              txnId: 'TXN-DUE-0001',
              txnDate: DateTime(2026, 6, 25),
              type: cash_book.CashTransactionType.income.dbValue,
              category: cash_book.IncomeCategory.sale.dbValue,
              amount: const drift.Value(100),
              referenceId: drift.Value('${result.invoiceNumber}#DUE#CASH'),
              referenceType: const drift.Value('BILL'),
              isAutoGenerated: const drift.Value(true),
            ),
          );

      var firstStock = await _stockById(db, firstStockId);
      expect(firstStock.quantity, 0);
      expect(firstStock.status, stock.StockStatus.sold.label);
      expect(firstStock.isActive, isFalse);
      expect(await db.cashTransactions.count().getSingle(), 2);
      expect(await db.bankTransactions.count().getSingle(), 1);

      final secondItem = _saleItem(
        stockItemId: secondStockId,
        sku: 'GOLD-RING-002',
        grossWeight: 8,
        rate: 125,
      );
      final editedInvoice = _invoice(
        invoiceNumber: result.invoiceNumber,
        saleItems: [secondItem],
        cashPaid: 1000,
      );

      await repository.updateSale(
        billId: result.billId,
        invoice: editedInvoice,
        customerId: null,
      );

      firstStock = await _stockById(db, firstStockId);
      final secondStock = await _stockById(db, secondStockId);
      expect(firstStock.quantity, 1);
      expect(firstStock.status, stock.StockStatus.available.label);
      expect(firstStock.isActive, isTrue);
      expect(secondStock.quantity, 0);
      expect(secondStock.status, stock.StockStatus.sold.label);
      expect(secondStock.isActive, isFalse);

      final firstStockMovements = await _stockMovementsFor(db, firstStockId);
      final secondStockMovements = await _stockMovementsFor(db, secondStockId);
      expect(firstStockMovements.map((row) => row.movementType), [
        'SALE',
        'SALE_RESTORE',
      ]);
      expect(firstStockMovements.map((row) => row.quantityDelta), [-1, 1]);
      expect(firstStockMovements.map((row) => row.sourceLineNo), [1, 1]);
      expect(secondStockMovements.map((row) => row.movementType), ['SALE']);
      expect(secondStockMovements.single.quantityDelta, -1);
      expect(secondStockMovements.single.sourceLineNo, 1);

      final billItems = await (db.select(db.billItems)
            ..where((tbl) => tbl.billId.equals(result.billId)))
          .get();
      expect(billItems, hasLength(1));
      expect(billItems.single.linkedStockItemId, secondStockId);

      final cashRows = await db.select(db.cashTransactions).get();
      final bankRows = await db.select(db.bankTransactions).get();

      final voidedSaleCashRows = cashRows
          .where((row) =>
              row.referenceId == '${result.invoiceNumber}#CASH' && row.isVoided)
          .toList();
      final activeSaleCashRows = cashRows
          .where((row) =>
              row.referenceId == '${result.invoiceNumber}#CASH' &&
              !row.isVoided)
          .toList();
      final dueCollectionRows = cashRows
          .where((row) => row.referenceId == '${result.invoiceNumber}#DUE#CASH')
          .toList();

      expect(voidedSaleCashRows, hasLength(1));
      expect(voidedSaleCashRows.single.amount, 400);
      expect(activeSaleCashRows, hasLength(1));
      expect(activeSaleCashRows.single.amount, 1000);
      expect(dueCollectionRows, hasLength(1));
      expect(dueCollectionRows.single.isVoided, isFalse);
      expect(bankRows, hasLength(1));
      expect(bankRows.single.referenceId, '${result.invoiceNumber}#UPI');
      expect(bankRows.single.isVoided, isTrue);

      final bill = await (db.select(db.bills)
            ..where((tbl) => tbl.id.equals(result.billId)))
          .getSingle();
      expect(bill.paidAmount, 1000);
      expect(bill.cashPaid, 1000);
      expect(bill.upiPaid, 0);
      expect(bill.dueAmount, 0);
      expect(bill.paymentStatus, 'PAID');

      _disposeItems(saleItems: [firstItem, secondItem]);
    },
  );

  test(
    'updateSale restores partial lot cost, wastage and making before re-deducting updated stock',
    () async {
      final lotStockId = await _insertValuedSilverLotStock(db);
      final replacementStockId =
          await _insertStockItem(db, sku: 'GOLD-EDIT-REPLACEMENT');
      final lotSale = SaleItemModel(metal: pos.MetalType.silver);
      lotSale.descCtrl.text = 'Silver Lot Actual Weight';
      lotSale.pcsCtrl.text = '1';
      lotSale.purityCtrl.text = '60';
      lotSale.grossCtrl.text = '20';
      lotSale.lessCtrl.text = '0';
      lotSale.rateCtrl.text = '400';
      lotSale.makingCtrl.text = '2.5';
      lotSale.attachStockReference(
        stockItemId: lotStockId,
        sku: 'SIL-VALUED-LOT-U001',
      );
      final firstInvoice = _invoice(
        invoiceNumber: 'INV-LJ-2026-0001',
        saleItems: [lotSale],
        cashPaid: lotSale.totalValue,
      );

      final result = await repository.finalizeSale(
        invoice: firstInvoice,
        customerId: null,
      );

      final billItem = await _singleBillItem(db, result.billId);
      final lotAfterSale = await _stockUnitCostAuditFor(db, lotStockId);

      expect(billItem.stockUnitCost, closeTo(1300, 0.001));
      expect(billItem.stockProfitAmount, closeTo(6750, 0.001));
      expect(lotAfterSale.read<double>('net_weight'), closeTo(80, 0.001));
      expect(
          lotAfterSale.read<double>('actual_fine_weight'), closeTo(48, 0.001));
      expect(
          lotAfterSale.read<double>('wastage_fine_weight'), closeTo(4, 0.001));
      expect(lotAfterSale.read<double>('valuation_fine_weight'),
          closeTo(52, 0.001));
      expect(lotAfterSale.read<double>('unit_cost'), closeTo(5200, 0.001));
      expect(lotAfterSale.read<double>('making_amount'), closeTo(450, 0.001));

      final replacementSale = _saleItem(
        stockItemId: replacementStockId,
        sku: 'GOLD-EDIT-REPLACEMENT',
        grossWeight: 10,
        rate: 100,
      );
      final editedInvoice = _invoice(
        invoiceNumber: result.invoiceNumber,
        saleItems: [replacementSale],
        cashPaid: replacementSale.totalValue,
      );

      await repository.updateSale(
        billId: result.billId,
        invoice: editedInvoice,
        customerId: null,
      );

      final restoredLot = await _stockById(db, lotStockId);
      final restoredUnit = await _stockUnitCostAuditFor(db, lotStockId);
      final replacementStock = await _stockById(db, replacementStockId);
      final lotMovements = await _stockMovementsFor(db, lotStockId);

      expect(restoredLot.quantity, 10);
      expect(restoredLot.status, stock.StockStatus.available.label);
      expect(restoredLot.netWeight, closeTo(100, 0.001));
      expect(restoredUnit.read<double>('net_weight'), closeTo(100, 0.001));
      expect(
          restoredUnit.read<double>('actual_fine_weight'), closeTo(60, 0.001));
      expect(
          restoredUnit.read<double>('wastage_fine_weight'), closeTo(5, 0.001));
      expect(restoredUnit.read<double>('valuation_fine_weight'),
          closeTo(65, 0.001));
      expect(restoredUnit.read<double>('unit_cost'), closeTo(6500, 0.001));
      expect(restoredUnit.read<double>('making_amount'), closeTo(500, 0.001));
      expect(replacementStock.status, stock.StockStatus.sold.label);
      expect(lotMovements.map((row) => row.movementType), [
        'SALE',
        'SALE_RESTORE',
      ]);
      expect(lotMovements.map((row) => row.quantityDelta), [-1, 1]);

      _disposeItems(saleItems: [lotSale, replacementSale]);
    },
  );

  test(
    'updateSale voids previous customer account credit when excess is removed',
    () async {
      final customerId = await _insertCustomer(db);
      final saleItem = _manualSaleItem(grossWeight: 10, rate: 100);
      final firstInvoice = _invoice(
        invoiceNumber: 'INV-LJ-2026-0001',
        saleItems: [saleItem],
        customerName: 'Reyansh Soni',
        customerMobile: '9304479436',
        cashPaid: 1000,
        changeSettlementMethod: pos.RefundMethod.accountCredit,
        changeSettlementAmount: 30,
        changeSettlementPaymentMode: pos.PaymentMode.cash,
      );

      final result = await repository.finalizeSale(
        invoice: firstInvoice,
        customerId: customerId,
      );

      final editedInvoice = _invoice(
        invoiceNumber: result.invoiceNumber,
        saleItems: [saleItem],
        customerName: 'Reyansh Soni',
        customerMobile: '9304479436',
        cashPaid: 1000,
      );

      await repository.updateSale(
        billId: result.billId,
        invoice: editedInvoice,
        customerId: customerId,
      );

      final credits = await db.select(db.customerAccountLedger).get();
      final creditCashRows = (await db.select(db.cashTransactions).get())
          .where(
            (row) =>
                row.referenceId ==
                '${result.invoiceNumber}#ACCOUNT_CREDIT#CASH',
          )
          .toList();

      expect(credits, hasLength(1));
      expect(credits.single.amount, 30);
      expect(credits.single.isVoided, isTrue);
      expect(creditCashRows, hasLength(1));
      expect(creditCashRows.single.isVoided, isTrue);

      _disposeItems(saleItems: [saleItem]);
    },
  );

  test(
    'advance conversion links source booking to sale and closes booking workflow',
    () async {
      final customerId = await _insertCustomer(db);
      final bookingRepo = BookingAdvanceRepository(db: db);
      final bookingId = await bookingRepo.saveNewBooking(
        customerId: customerId,
        customerName: 'Reyansh Soni',
        customerMobile: '9304479436',
        itemName: 'Gold Ring',
        itemDesc: 'Custom ring order',
        metalType: 'GOLD',
        purity: '22KT',
        approxWeight: 10,
        bookingType: 'LOCKED',
        lockedRate: 100,
        deliveryDate: DateTime(2026, 7, 20),
        notes: 'Advance received',
        totalAdvance: 300,
        goldRate: 100,
        isGst: false,
      );
      final booking = await (db.select(db.salesOrders)
            ..where((tbl) => tbl.id.equals(bookingId)))
          .getSingle();
      final saleItem = _manualSaleItem(grossWeight: 10, rate: 100);
      final invoice = _invoice(
        invoiceNumber: 'INV-LJ-2026-0001',
        saleItems: [saleItem],
        customerName: 'Reyansh Soni',
        customerMobile: '9304479436',
        cashPaid: 700,
        advancePaid: 300,
      );

      final result = await repository.finalizeSale(
        invoice: invoice,
        customerId: customerId,
        sourceAdvanceOrderId: bookingId,
        sourceAdvanceOrderNo: booking.orderNo,
      );
      final closed = await bookingRepo.markConvertedToSale(
        orderId: bookingId,
        invoiceNumber: result.invoiceNumber,
      );

      final bill = await (db.select(db.bills)
            ..where((tbl) => tbl.id.equals(result.billId)))
          .getSingle();
      final updatedBooking = await (db.select(db.salesOrders)
            ..where((tbl) => tbl.id.equals(bookingId)))
          .getSingle();
      final cashRows = await db.select(db.cashTransactions).get();

      expect(closed, isTrue);
      expect(bill.customerId, customerId);
      expect(bill.sourceAdvanceOrderId, bookingId);
      expect(bill.sourceAdvanceOrderNo, booking.orderNo);
      expect(bill.advancePaid, 300);
      expect(bill.cashPaid, 700);
      expect(bill.paymentStatus, 'PAID');
      expect(updatedBooking.status, 'DELIVERED');
      expect(updatedBooking.notes,
          'Converted to sales invoice ${result.invoiceNumber}');
      expect(cashRows, hasLength(1));
      expect(cashRows.single.amount, 700);

      _disposeItems(saleItems: [saleItem]);
    },
  );
}

Future<int> _insertCustomer(AppDatabase db) {
  return db.into(db.customers).insert(
        CustomersCompanion.insert(
          name: 'Reyansh Soni',
          mobile: '9304479436',
          city: const drift.Value('Patna'),
        ),
      );
}

Future<int> _insertPrimaryBankAccount(AppDatabase db) {
  return db.into(db.bankAccounts).insert(
        BankAccountsCompanion.insert(
          accountName: 'Primary Current',
          bankName: 'HDFC Bank',
          accountNumber: '111122223333',
          isPrimary: const drift.Value(true),
        ),
      );
}

Future<int> _insertStockItem(AppDatabase db, {required String sku}) async {
  final stockItemId = await db.into(db.stockItems).insert(
        StockItemsCompanion.insert(
          sku: sku,
          itemName: 'Gold Ring',
          category: 'Gold',
          subCategory: 'Ring',
          metalType: const drift.Value('Gold'),
          purity: const drift.Value('22KT'),
          grossWeight: const drift.Value(10),
          netWeight: const drift.Value(10),
          quantity: const drift.Value(1),
          status: drift.Value(stock.StockStatus.available.label),
          isActive: const drift.Value(true),
        ),
      );

  final now = DateTime(2026, 6, 25, 12).millisecondsSinceEpoch;
  await db.customInsert(
    '''
    INSERT INTO stock_item_units (
      stock_item_id,
      batch_code,
      unit_code,
      piece_no,
      metal_type,
      item_type,
      segment,
      item_name,
      huid,
      gross_weight,
      less_weight,
      net_weight,
      purity_percent,
      actual_fine_weight,
      wastage_fine_weight,
      valuation_fine_weight,
      rate_per_gram,
      making_amount,
      unit_cost,
      supplier_name,
      status,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    variables: [
      drift.Variable<int>(stockItemId),
      const drift.Variable<String>('TEST-BATCH'),
      drift.Variable<String>('$sku-U001'),
      const drift.Variable<int>(1),
      const drift.Variable<String>('Gold'),
      const drift.Variable<String>('Ring'),
      const drift.Variable<String>('Ladies'),
      const drift.Variable<String>('Gold Ring'),
      drift.Variable<String>(sku),
      const drift.Variable<double>(10),
      const drift.Variable<double>(0),
      const drift.Variable<double>(10),
      const drift.Variable<double>(91.6),
      const drift.Variable<double>(9.16),
      const drift.Variable<double>(0),
      const drift.Variable<double>(9.16),
      const drift.Variable<double>(6000),
      const drift.Variable<double>(0),
      const drift.Variable<double>(60000),
      const drift.Variable<String>('Test Supplier'),
      drift.Variable<String>(stock.StockStatus.available.label),
      drift.Variable<int>(now),
    ],
  );

  return stockItemId;
}

Future<int> _insertSilverLotStock(
  AppDatabase db, {
  required String sku,
  required int quantity,
  required double grossWeight,
  required double lessWeight,
  required double netWeight,
}) async {
  final stockItemId = await db.into(db.stockItems).insert(
        StockItemsCompanion.insert(
          sku: sku,
          itemName: 'CHAND',
          category: 'Silver',
          subCategory: 'Payal',
          metalType: const drift.Value('Silver'),
          purity: const drift.Value('999'),
          grossWeight: drift.Value(grossWeight),
          stoneWeight: drift.Value(lessWeight),
          netWeight: drift.Value(netWeight),
          quantity: drift.Value(quantity),
          status: drift.Value(stock.StockStatus.available.label),
          isActive: const drift.Value(true),
        ),
      );

  final now = DateTime(2026, 7, 22, 12).millisecondsSinceEpoch;
  await db.customInsert(
    '''
    INSERT INTO stock_item_units (
      stock_item_id,
      batch_code,
      unit_code,
      piece_no,
      metal_type,
      item_type,
      segment,
      item_name,
      huid,
      gross_weight,
      less_weight,
      net_weight,
      purity_percent,
      actual_fine_weight,
      wastage_fine_weight,
      valuation_fine_weight,
      rate_per_gram,
      making_amount,
      unit_cost,
      supplier_name,
      status,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    variables: [
      drift.Variable<int>(stockItemId),
      const drift.Variable<String>('SILVER-LOT'),
      drift.Variable<String>('$sku-U001'),
      const drift.Variable<int>(1),
      const drift.Variable<String>('Silver'),
      const drift.Variable<String>('CHAND'),
      const drift.Variable<String>('Local'),
      const drift.Variable<String>('CHAND'),
      const drift.Variable<String>(''),
      drift.Variable<double>(grossWeight),
      drift.Variable<double>(lessWeight),
      drift.Variable<double>(netWeight),
      const drift.Variable<double>(99.9),
      drift.Variable<double>(netWeight * 0.999),
      const drift.Variable<double>(0),
      drift.Variable<double>(netWeight * 0.999),
      const drift.Variable<double>(100),
      const drift.Variable<double>(0),
      drift.Variable<double>(netWeight * 100),
      const drift.Variable<String>('Test Supplier'),
      drift.Variable<String>(stock.StockStatus.available.label),
      drift.Variable<int>(now),
    ],
  );

  return stockItemId;
}

Future<int> _insertValuedSilverLotStock(AppDatabase db) async {
  final createdAt = DateTime(2026, 7, 22, 12).millisecondsSinceEpoch;
  await db.customInsert(
    '''
    INSERT INTO purchase_vouchers (
      voucher_no,
      sequence_no,
      source_type,
      party_name,
      created_at
    ) VALUES (?, ?, ?, ?, ?)
    ''',
    variables: [
      const drift.Variable<String>('PV-POS-VALUED-LOT-001'),
      const drift.Variable<int>(1),
      const drift.Variable<String>('SUPPLIER'),
      const drift.Variable<String>('Test Supplier'),
      drift.Variable<int>(createdAt),
    ],
  );
  final voucherId = await _lastInsertRowId(db);

  await db.customInsert(
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
      wastage_percent,
      wastage_fine_weight,
      valuation_fine_weight,
      rate,
      quantity,
      line_amount,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    variables: [
      drift.Variable<int>(voucherId),
      const drift.Variable<int>(1),
      const drift.Variable<String>('SIL-VALUED-LOT'),
      const drift.Variable<String>('SILVER'),
      const drift.Variable<String>('Silver Lot Actual Weight'),
      const drift.Variable<double>(100),
      const drift.Variable<double>(0),
      const drift.Variable<double>(100),
      const drift.Variable<double>(60),
      const drift.Variable<double>(60),
      const drift.Variable<double>(5),
      const drift.Variable<double>(5),
      const drift.Variable<double>(65),
      const drift.Variable<double>(100),
      const drift.Variable<int>(10),
      const drift.Variable<double>(6500),
      drift.Variable<int>(createdAt),
    ],
  );
  final purchaseItemId = await _lastInsertRowId(db);

  final stockItemId = await db.into(db.stockItems).insert(
        StockItemsCompanion.insert(
          sku: 'SIL-VALUED-LOT',
          itemName: 'Silver Lot Actual Weight',
          category: 'Silver',
          subCategory: 'Lot',
          metalType: const drift.Value('Silver'),
          purity: const drift.Value('60'),
          grossWeight: const drift.Value(100),
          stoneWeight: const drift.Value(0),
          netWeight: const drift.Value(100),
          quantity: const drift.Value(10),
          purchasePrice: const drift.Value(650),
          status: drift.Value(stock.StockStatus.available.label),
          isActive: const drift.Value(true),
        ),
      );

  await db.customInsert(
    '''
    INSERT INTO stock_item_units (
      stock_item_id,
      purchase_voucher_id,
      purchase_voucher_item_id,
      batch_code,
      unit_code,
      piece_no,
      metal_type,
      item_type,
      segment,
      item_name,
      huid,
      gross_weight,
      less_weight,
      net_weight,
      purity_percent,
      actual_fine_weight,
      wastage_percent,
      wastage_fine_weight,
      valuation_fine_weight,
      rate_per_gram,
      making_amount,
      unit_cost,
      supplier_name,
      status,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    variables: [
      drift.Variable<int>(stockItemId),
      drift.Variable<int>(voucherId),
      drift.Variable<int>(purchaseItemId),
      const drift.Variable<String>('PV-POS-VALUED-LOT-001'),
      const drift.Variable<String>('SIL-VALUED-LOT-U001'),
      const drift.Variable<int>(1),
      const drift.Variable<String>('Silver'),
      const drift.Variable<String>('Lot'),
      const drift.Variable<String>('Local'),
      const drift.Variable<String>('Silver Lot Actual Weight'),
      const drift.Variable<String>(''),
      const drift.Variable<double>(100),
      const drift.Variable<double>(0),
      const drift.Variable<double>(100),
      const drift.Variable<double>(60),
      const drift.Variable<double>(60),
      const drift.Variable<double>(5),
      const drift.Variable<double>(5),
      const drift.Variable<double>(65),
      const drift.Variable<double>(100),
      const drift.Variable<double>(500),
      const drift.Variable<double>(6500),
      const drift.Variable<String>('Test Supplier'),
      drift.Variable<String>(stock.StockStatus.available.label),
      drift.Variable<int>(createdAt),
    ],
  );

  return stockItemId;
}

Future<StockItem> _stockById(AppDatabase db, int id) {
  return (db.select(db.stockItems)..where((tbl) => tbl.id.equals(id)))
      .getSingle();
}

Future<int> _lastInsertRowId(AppDatabase db) async {
  final row =
      await db.customSelect('SELECT last_insert_rowid() AS id').getSingle();
  return row.read<int>('id');
}

Future<BillItem> _singleBillItem(AppDatabase db, int billId) {
  return (db.select(db.billItems)..where((tbl) => tbl.billId.equals(billId)))
      .getSingle();
}

Future<int> _stockUnitIdFor(AppDatabase db, int stockId) async {
  final row = await db.customSelect(
    '''
    SELECT id
    FROM stock_item_units
    WHERE stock_item_id = ?
    ORDER BY id ASC
    LIMIT 1
    ''',
    variables: [drift.Variable<int>(stockId)],
  ).getSingle();
  return row.read<int>('id');
}

Future<String> _stockUnitStatusFor(AppDatabase db, int stockId) async {
  final row = await db.customSelect(
    '''
    SELECT status
    FROM stock_item_units
    WHERE stock_item_id = ?
    ORDER BY id ASC
    LIMIT 1
    ''',
    variables: [drift.Variable<int>(stockId)],
  ).getSingle();
  return row.read<String>('status');
}

Future<drift.QueryRow> _stockUnitCostAuditFor(
  AppDatabase db,
  int stockId,
) {
  return db.customSelect(
    '''
    SELECT
      net_weight,
      actual_fine_weight,
      wastage_fine_weight,
      valuation_fine_weight,
      unit_cost,
      making_amount
    FROM stock_item_units
    WHERE stock_item_id = ?
    ORDER BY id ASC
    LIMIT 1
    ''',
    variables: [drift.Variable<int>(stockId)],
  ).getSingle();
}

Future<List<StockMovement>> _stockMovementsFor(AppDatabase db, int stockId) {
  return (db.select(db.stockMovements)
        ..where((tbl) => tbl.stockItemId.equals(stockId))
        ..orderBy([(tbl) => drift.OrderingTerm.asc(tbl.id)]))
      .get();
}

SaleItemModel _manualSaleItem({
  required double grossWeight,
  required double rate,
}) {
  final item = SaleItemModel(metal: pos.MetalType.gold);
  item.descCtrl.text = 'Manual Gold Ring';
  item.pcsCtrl.text = '1';
  item.purityCtrl.text = '22KT';
  item.grossCtrl.text = _formatNumber(grossWeight);
  item.lessCtrl.text = '0';
  item.rateCtrl.text = _formatNumber(rate);
  item.makingCtrl.text = '0';
  return item;
}

SaleItemModel _saleItem({
  required int stockItemId,
  required String sku,
  required double grossWeight,
  required double rate,
}) {
  final item = SaleItemModel(metal: pos.MetalType.gold);
  item.descCtrl.text = 'Gold Ring';
  item.pcsCtrl.text = '1';
  item.huidCtrl.text = sku;
  item.purityCtrl.text = '22KT';
  item.grossCtrl.text = _formatNumber(grossWeight);
  item.lessCtrl.text = '0';
  item.attachStockReference(stockItemId: stockItemId, sku: sku);
  item.rateCtrl.text = _formatNumber(rate);
  item.makingCtrl.text = '0';
  return item;
}

TradeInItemModel _tradeInItem({
  required double grossWeight,
  required double purity,
  required double rate,
}) {
  final item = TradeInItemModel(metal: pos.MetalType.gold);
  item.descCtrl.text = 'Old Gold Exchange';
  item.grossCtrl.text = _formatNumber(grossWeight);
  item.lessCtrl.text = '0';
  item.purityCtrl.text = _formatNumber(purity);
  item.rateCtrl.text = _formatNumber(rate);
  return item;
}

PosInvoiceModel _invoice({
  required String invoiceNumber,
  required List<SaleItemModel> saleItems,
  List<TradeInItemModel> tradeInItems = const [],
  String customerName = 'Walk-in Customer',
  String customerMobile = '',
  double cashPaid = 0,
  double upiPaid = 0,
  double cardPaid = 0,
  double advancePaid = 0,
  pos.RefundMethod? changeSettlementMethod,
  double changeSettlementAmount = 0,
  pos.PaymentMode? changeSettlementPaymentMode,
  DateTime? promiseDate,
}) {
  final grossAmount =
      saleItems.fold<double>(0, (sum, item) => sum + item.totalValue);
  final tradeInDeduction =
      tradeInItems.fold<double>(0, (sum, item) => sum + item.totalValue);
  final netPayable = grossAmount - tradeInDeduction;
  final totalPaid = cashPaid + upiPaid + cardPaid + advancePaid;
  return PosInvoiceModel(
    invoiceNumber: invoiceNumber,
    invoiceDate: DateTime(2026, 6, 25, 12),
    billType: pos.BillType.normal,
    billingMode: pos.BillingMode.retail,
    shopName: 'Lotus Jewellers',
    shopAddress: 'Patna',
    shopPhone: '9000000000',
    shopGstin: '',
    customerName: customerName,
    customerMobile: customerMobile,
    customerCity: 'Patna',
    customerPan: '',
    customerGstin: '',
    tradeInMode: pos.TradeInAdjustMode.cashAdjust,
    saleItems: saleItems,
    tradeInItems: tradeInItems,
    grossAmount: grossAmount,
    discountAmount: 0,
    taxableAmount: grossAmount,
    cgst: 0,
    sgst: 0,
    totalGst: 0,
    totalTradeInDeduction: tradeInDeduction,
    grandTotal: grossAmount,
    cashPaid: cashPaid,
    upiPaid: upiPaid,
    cardPaid: cardPaid,
    advancePaid: advancePaid,
    balanceDue: netPayable - totalPaid,
    changeSettlementMethod: changeSettlementMethod,
    changeSettlementAmount: changeSettlementAmount,
    changeSettlementPaymentMode: changeSettlementPaymentMode,
    totalMakingCharge: 0,
    promiseDate: promiseDate,
  );
}

void _disposeItems({
  List<SaleItemModel> saleItems = const [],
  List<TradeInItemModel> tradeInItems = const [],
}) {
  for (final item in saleItems) {
    item.dispose();
  }
  for (final item in tradeInItems) {
    item.dispose();
  }
}

String _formatNumber(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.0001) {
    return rounded.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

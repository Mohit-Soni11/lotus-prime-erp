import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_book_enums.dart'
    as cash_book;
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart'
    as pos;
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart'
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
      final oldGoldItem = _oldGoldItem(
        grossWeight: 2,
        purity: 90,
        rate: 50,
      );
      final invoice = _invoice(
        invoiceNumber: 'INV-LJ-2026-0001',
        saleItems: [saleItem],
        oldGoldItems: [oldGoldItem],
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
      final oldGoldRows = await (db.select(db.billOldGoldItems)
            ..where((tbl) => tbl.billId.equals(result.billId)))
          .get();
      final stockRow = await _stockById(db, stockId);
      final cashRows = await db.select(db.cashTransactions).get();

      expect(result.invoiceNumber, 'INV-LJ-2026-0001');
      expect(result.invoiceSequence, 1);
      expect(bill.finalAmount, 910);
      expect(bill.oldGoldDeduction, 90);
      expect(bill.paymentStatus, 'PAID');
      expect(billItems, hasLength(1));
      expect(billItems.single.linkedStockItemId, stockId);
      expect(oldGoldRows, hasLength(1));
      expect(oldGoldRows.single.fineWeight, 1.8);
      expect(oldGoldRows.single.lineAmount, 90);
      expect(stockRow.quantity, 0);
      expect(stockRow.status, stock.StockStatus.sold.label);
      expect(cashRows, hasLength(1));
      expect(cashRows.single.referenceId, 'INV-LJ-2026-0001#CASH');
      expect(cashRows.single.amount, 910);
      expect(cashRows.single.isVoided, isFalse);

      _disposeItems(saleItems: [saleItem], oldGoldItems: [oldGoldItem]);
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

      await repository.finalizeSale(
        invoice: invoice,
        customerId: null,
      );

      final cashRows = await db.select(db.cashTransactions).get();
      final bankRows = await db.select(db.bankTransactions).get();

      expect(cashRows, hasLength(1));
      expect(cashRows.single.paymentMode, cash_book.PaymentMode.cash.dbValue);
      expect(cashRows.single.amount, 100);
      expect(cashRows.single.referenceId, 'INV-LJ-2026-0001#CASH');
      expect(bankRows, hasLength(2));
      expect(
        bankRows.map((row) => row.referenceId).toSet(),
        {'INV-LJ-2026-0001#UPI', 'INV-LJ-2026-0001#CARD'},
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
      expect(
          updatedBooking.notes, 'Converted to sales invoice INV-LJ-2026-0001');
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

Future<int> _insertStockItem(AppDatabase db, {required String sku}) {
  return db.into(db.stockItems).insert(
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
}

Future<StockItem> _stockById(AppDatabase db, int id) {
  return (db.select(db.stockItems)..where((tbl) => tbl.id.equals(id)))
      .getSingle();
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
  item.attachStockReference(stockItemId: stockItemId, sku: sku);
  item.descCtrl.text = 'Gold Ring';
  item.pcsCtrl.text = '1';
  item.huidCtrl.text = sku;
  item.purityCtrl.text = '22KT';
  item.grossCtrl.text = _formatNumber(grossWeight);
  item.lessCtrl.text = '0';
  item.rateCtrl.text = _formatNumber(rate);
  item.makingCtrl.text = '0';
  return item;
}

OldGoldItemModel _oldGoldItem({
  required double grossWeight,
  required double purity,
  required double rate,
}) {
  final item = OldGoldItemModel(metal: pos.MetalType.gold);
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
  List<OldGoldItemModel> oldGoldItems = const [],
  String customerName = 'Walk-in Customer',
  String customerMobile = '',
  double cashPaid = 0,
  double upiPaid = 0,
  double cardPaid = 0,
  double advancePaid = 0,
  DateTime? promiseDate,
}) {
  final grossAmount =
      saleItems.fold<double>(0, (sum, item) => sum + item.totalValue);
  final oldGoldDeduction =
      oldGoldItems.fold<double>(0, (sum, item) => sum + item.totalValue);
  final netPayable = grossAmount - oldGoldDeduction;
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
    oldGoldMode: pos.OldGoldAdjustMode.cashAdjust,
    saleItems: saleItems,
    oldGoldItems: oldGoldItems,
    grossAmount: grossAmount,
    discountAmount: 0,
    taxableAmount: grossAmount,
    cgst: 0,
    sgst: 0,
    totalGst: 0,
    totalOldGoldDeduction: oldGoldDeduction,
    grandTotal: grossAmount,
    cashPaid: cashPaid,
    upiPaid: upiPaid,
    cardPaid: cardPaid,
    advancePaid: advancePaid,
    balanceDue: netPayable - totalPaid,
    totalMakingCharge: 0,
    promiseDate: promiseDate,
  );
}

void _disposeItems({
  List<SaleItemModel> saleItems = const [],
  List<OldGoldItemModel> oldGoldItems = const [],
}) {
  for (final item in saleItems) {
    item.dispose();
  }
  for (final item in oldGoldItems) {
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

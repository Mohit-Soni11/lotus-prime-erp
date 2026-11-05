import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_document.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_document_collection_mapper.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/repositories/reports/day_book_document_repository.dart';

void main() {
  test('invoice explorer receives saved party, all metal lines and payment',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final date = DateTime(2026, 11, 4, 13);
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(name: 'Asha Patel', mobile: '9876543210'),
        );
    final billId = await db.into(db.bills).insert(BillsCompanion.insert(
          billNo: 'REG-025',
          customerId: drift.Value(customerId),
          billDate: drift.Value(date),
          finalAmount: const drift.Value(82000),
          paidAmount: const drift.Value(72000),
          dueAmount: const drift.Value(10000),
        ));
    for (final (metal, name, grams) in [
      ('GOLD', 'Necklace', 24.5),
      ('SILVER', 'Payal', 100.25),
    ]) {
      await db.into(db.billItems).insert(BillItemsCompanion.insert(
            billId: billId,
            itemName: name,
            metalType: drift.Value(metal),
            netWeight: drift.Value(grams),
          ));
    }

    final document = (await DayBookDocumentRepository(db).fetch(date)).single;
    expect(document.partyName, 'Asha Patel');
    expect(document.mobile, '9876543210');
    expect(document.items.map((item) => item.name), ['Necklace', 'Payal']);
    expect(document.items.map((item) => item.netWeightGrams), [24.5, 100.25]);
    expect(document.savedPaid, 72000);
    expect(document.savedDue, 10000);

    final withCollection = DayBookDocumentCollectionMapper.apply(
        [
          document,
        ],
        DayBookMoneyFlow(openingCash: 0, openingBank: 0, entries: [
          DayBookMoneyEntry(
            date: date,
            amount: 30000,
            incoming: true,
            isCash: true,
            category: 'SALE_PAYMENT',
            paymentMode: 'CASH',
            transactionId: 'TX-1',
            referenceId: 'REG-025#CASH',
            referenceType: 'BILL',
          ),
        ])).single;
    expect(withCollection.collection, 30000);
    expect(withCollection.items, hasLength(2));
    expect(withCollection.savedPaid, 72000);
  });

  test(
      'cancelled invoices do not count while returned invoices retain issue-day turnover',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final date = DateTime(2026, 6, 25, 12);
    for (final (number, status) in [
      ('INV-CANCELLED', 'CANCELLED'),
      ('INV-RETURNED', 'RETURNED'),
    ]) {
      await db.into(db.bills).insert(BillsCompanion.insert(
            billNo: number,
            billDate: drift.Value(date),
            finalAmount: const drift.Value(100),
            status: drift.Value(status),
          ));
    }
    final documents = await DayBookDocumentRepository(db).fetch(date);
    expect(documents.map((document) => document.number), ['INV-RETURNED']);
    expect(documents.single.amount, 100);
  });

  test(
      'daily source summary keeps sales, purchase, return, Girvi and advance separate',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final date = DateTime(2026, 6, 25, 12);
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(name: 'Customer', mobile: '9000000555'),
        );
    await db.into(db.bills).insert(BillsCompanion.insert(
          billNo: 'TAX-1',
          billType: const drift.Value('GST'),
          finalAmount: const drift.Value(103),
          cgstAmount: const drift.Value(1.5),
          sgstAmount: const drift.Value(1.5),
          gstAmount: const drift.Value(3),
          billDate: drift.Value(date),
        ));
    final orderId = await db.into(db.salesOrders).insert(
          SalesOrdersCompanion.insert(
              orderNo: 'ORD-1', customerId: customerId, itemName: 'Ring'),
        );
    await db.into(db.orderAdvances).insert(OrderAdvancesCompanion.insert(
          orderId: orderId,
          amountPaid: const drift.Value(50),
          paymentDate: drift.Value(date),
        ));
    await db.into(db.girviLoans).insert(GirviLoansCompanion.insert(
          ticketNo: 'GRV-1',
          customerId: customerId,
          itemDescription: 'Chain',
          loanAmount: const drift.Value(200),
          startDate: drift.Value(date),
        ));
    await db.customStatement(
      '''INSERT INTO purchase_vouchers
         (voucher_no, sequence_no, source_type, party_name, grand_total,
          gst_amount, total_paid, balance_due, created_at)
         VALUES ('PUR-1', 1, 'SUPPLIER', 'Supplier', 300, 9, 100, 200, ?)''',
      [date.millisecondsSinceEpoch],
    );
    await db.customStatement(
      '''INSERT INTO purchase_voucher_items
         (purchase_voucher_id, line_no, metal_type, item_description,
          net_weight, created_at)
         VALUES (1, 1, 'Gold', 'Old Necklace', 21.5, ?)''',
      [date.millisecondsSinceEpoch],
    );
    await db.customStatement(
      '''INSERT INTO return_vouchers
         (voucher_no, operation_type, source_type, source_id, source_number,
          settlement_mode, return_value, refund_payable_amount, created_at)
         VALUES ('RET-1', 'RETURN', 'SALE', 1, 'TAX-1',
                 'REFUND', 20, 15, ?)''',
      [date.millisecondsSinceEpoch],
    );
    await db.customStatement(
      '''INSERT INTO return_voucher_lines
         (return_voucher_id, source_type, source_id, source_number,
          source_line_no, stock_disposition, metal_type, item_description,
          received_net_weight, created_at)
         VALUES (1, 'SALE', 1, 'TAX-1', 1, 'RESTOCK', 'Silver', 'Payal',
                 50.25, ?)''',
      [date.millisecondsSinceEpoch],
    );

    final documents = await DayBookDocumentRepository(db).fetch(date);
    expect(documents, hasLength(5));
    expect(
        documents.map((record) => record.kind).toSet(),
        DayBookDocumentKind.values.toSet()
          ..remove(DayBookDocumentKind.regularInvoice)
          ..remove(DayBookDocumentKind.advanceCancellationVoucher));
    expect(
        documents
            .singleWhere(
                (record) => record.kind == DayBookDocumentKind.purchaseVoucher)
            .outstanding,
        200);
    expect(
        documents
            .singleWhere(
                (record) => record.kind == DayBookDocumentKind.returnVoucher)
            .outstanding,
        15);
    expect(
        documents
            .singleWhere(
                (record) => record.kind == DayBookDocumentKind.purchaseVoucher)
            .items
            .single
            .netWeightGrams,
        21.5);
    expect(
        documents
            .singleWhere(
                (record) => record.kind == DayBookDocumentKind.returnVoucher)
            .items
            .single
            .netWeightGrams,
        50.25);
  });

  test(
      'split sale receipts enrich invoice collection without turning old dues into sales',
      () {
    final date = DateTime(2026, 6, 25);
    final invoice = DayBookDocument(
      kind: DayBookDocumentKind.gstInvoice,
      sourceId: '1',
      number: 'TAX-1',
      date: date,
      amount: 103,
      status: 'ACTIVE',
    );
    DayBookMoneyEntry payment(String category, String bill, double amount) =>
        DayBookMoneyEntry(
          date: date,
          amount: amount,
          incoming: true,
          isCash: true,
          category: category,
          paymentMode: 'CASH',
          transactionId: '$category-$bill',
          referenceType: 'BILL',
          referenceId: '$bill#CASH',
        );
    final flow = DayBookMoneyFlow(
      openingCash: 0,
      openingBank: 0,
      entries: [
        payment('SALE', 'TAX-1', 30),
        payment('SALE_PAYMENT', 'TAX-1', 20),
        payment('DUE_COLLECTION', 'OLD-1', 80),
      ],
    );
    final result = DayBookDocumentCollectionMapper.apply([invoice], flow);
    expect(result.single.amount, 103);
    expect(result.single.collection, 50);
  });

  test('booking cancellation is not classified as a sales return', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final date = DateTime(2026, 11, 4);
    await db.customStatement(
      '''INSERT INTO return_vouchers
         (voucher_no, operation_type, source_type, source_id, source_number,
          settlement_mode, return_value, refund_payable_amount, created_at)
         VALUES ('CAN-1', 'BOOKING_CANCELLATION', 'ADVANCE_BOOKING', 7,
                 'ORD-7', 'REFUND', 3000, 2500, ?)''',
      [date.millisecondsSinceEpoch],
    );
    final documents = await DayBookDocumentRepository(db).fetch(date);
    expect(
        documents.single.kind, DayBookDocumentKind.advanceCancellationVoucher);
    expect(documents.single.originalSourceId, 7);
    expect(documents.single.outstanding, 2500);
  });
}

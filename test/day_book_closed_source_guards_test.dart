import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/finance/ledger/data/finance_day_closure_repository.dart';
import 'package:lotus_erp/repositories/reports/day_book_repository.dart';

void main() {
  test(
      'closed Girvi receipt is immutable while later handover remains possible',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final date = DateTime(2026, 6, 25, 12);
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
              name: 'Custody Customer', mobile: '9000000666'),
        );
    final loanId = await db.into(db.girviLoans).insert(
          GirviLoansCompanion.insert(
            ticketNo: 'GRV-CLOSED',
            customerId: customerId,
            itemDescription: 'Ring',
            netWeight: const drift.Value(10),
            startDate: drift.Value(date),
          ),
        );
    final itemId = await db.into(db.girviLoanItems).insert(
          GirviLoanItemsCompanion.insert(
            girviId: loanId,
            serialNo: 1,
            itemName: 'Ring',
            metalType: 'Gold',
            purity: '22K',
            netWeight: const drift.Value(10),
          ),
        );
    expect(
        await FinanceDayClosureRepository(db)
            .closeDay(date, closingCash: 0, closedBy: 'owner-1'),
        isTrue);

    await expectLater(
      db.customStatement(
          'UPDATE girvi_loan_items SET net_weight = 20 WHERE id = ?', [itemId]),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.customStatement(
          'UPDATE girvi_loans SET loan_amount = 999 WHERE id = ?', [loanId]),
      throwsA(isA<Exception>()),
    );
    await db.customStatement(
      "UPDATE girvi_loans SET status = 'RELEASED', delivered_at = ? WHERE id = ?",
      [
        date.add(const Duration(days: 2)).millisecondsSinceEpoch ~/ 1000,
        loanId
      ],
    );
    final loan = await (db.select(db.girviLoans)
          ..where((row) => row.id.equals(loanId)))
        .getSingle();
    expect(loan.status, 'RELEASED');
    expect(loan.netWeight, 10);
  });

  test(
      'closed day protects source documents and stock without blocking later due settlement',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final date = DateTime(2026, 6, 25, 12);
    final billId = await db.into(db.bills).insert(BillsCompanion.insert(
          billNo: 'INV-CLOSED',
          billDate: drift.Value(date),
          finalAmount: const drift.Value(100),
          dueAmount: const drift.Value(100),
        ));
    final itemId = await db.into(db.stockItems).insert(
          StockItemsCompanion.insert(
            sku: 'G-CLOSED',
            itemName: 'Ring',
            category: 'Jewellery',
            subCategory: 'Ring',
          ),
        );
    expect(
        await FinanceDayClosureRepository(db)
            .closeDay(date, closingCash: 0, closedBy: 'owner-1'),
        isTrue);

    await expectLater(
      db.customStatement(
          "UPDATE bills SET final_amount = 200 WHERE bill_no = 'INV-CLOSED'"),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.customStatement(
          "UPDATE bills SET status = 'CANCELLED' WHERE bill_no = 'INV-CLOSED'"),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.into(db.billItems).insert(
            BillItemsCompanion.insert(billId: billId, itemName: 'Ring'),
          ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
            stockItemId: itemId,
            movementType: 'IN',
            sourceType: 'PURCHASE',
            sourceId: 'PUR-LATE',
            skuSnapshot: 'G-CLOSED',
            metalTypeSnapshot: 'Gold',
            itemNameSnapshot: 'Ring',
            quantityDelta: 1,
            occurredAt: date,
          )),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.customStatement(
        '''INSERT INTO purchase_vouchers
           (voucher_no, sequence_no, source_type, party_name, created_at)
           VALUES ('PUR-LATE', 1, 'SUPPLIER', 'Supplier', ?)''',
        [date.millisecondsSinceEpoch],
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.customStatement(
          "DELETE FROM finance_day_closures WHERE day_key = '20260625'"),
      throwsA(isA<Exception>()),
    );

    await db.customStatement(
        "UPDATE bills SET paid_amount = 20, due_amount = 80 WHERE bill_no = 'INV-CLOSED'");
    await db.customStatement(
        "UPDATE bills SET status = 'RETURNED' WHERE bill_no = 'INV-CLOSED'");
    final bill = await (db.select(db.bills)
          ..where((row) => row.id.equals(billId)))
        .getSingle();
    expect(bill.finalAmount, 100);
    expect(bill.dueAmount, 80);
    expect(
        (await DayBookRepository(db: db).fetchDayBook(date))
            .cashIn
            .nonGstSales
            .totalAmount,
        100);
  });

  test('closed purchase and return lines cannot be changed after posting',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final date = DateTime(2026, 6, 25, 12);
    final time = date.millisecondsSinceEpoch;
    await db.customStatement('''INSERT INTO purchase_vouchers
      (voucher_no, sequence_no, source_type, party_name, grand_total, created_at)
      VALUES ('PUR-CLOSED', 1, 'SUPPLIER', 'Supplier', 100, ?)''', [time]);
    await db.customStatement('''INSERT INTO return_vouchers
      (voucher_no, operation_type, source_type, source_id, source_number,
       settlement_mode, return_value, created_at)
      VALUES ('RET-CLOSED', 'SALES_RETURN', 'BILL', 1, 'INV-CLOSED',
       'REFUND', 20, ?)''', [time]);
    expect(
        await FinanceDayClosureRepository(db)
            .closeDay(date, closingCash: 0, closedBy: 'owner-1'),
        isTrue);

    await expectLater(
      db.customStatement(
          "UPDATE purchase_vouchers SET grand_total = 200 WHERE voucher_no = 'PUR-CLOSED'"),
      throwsA(isA<Exception>()),
    );
    await db.customStatement(
        "UPDATE purchase_vouchers SET status = 'RETURNED' WHERE voucher_no = 'PUR-CLOSED'");
    await expectLater(
      db.customStatement(
          "UPDATE purchase_vouchers SET status = 'SAVED' WHERE voucher_no = 'PUR-CLOSED'"),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.customStatement('''INSERT INTO purchase_voucher_items
        (purchase_voucher_id, line_no, metal_type, created_at)
        SELECT id, 1, 'Gold', ? FROM purchase_vouchers WHERE voucher_no = 'PUR-CLOSED' ''',
          [time]),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.customStatement('''INSERT INTO return_voucher_lines
        (return_voucher_id, source_type, source_id, source_number,
         source_line_no, stock_disposition, metal_type, item_description, created_at)
        SELECT id, 'BILL', 1, 'INV-CLOSED', 1, 'RESTOCK', 'Gold', 'Ring', ?
        FROM return_vouchers WHERE voucher_no = 'RET-CLOSED' ''', [time]),
      throwsA(isA<Exception>()),
    );
  });
}

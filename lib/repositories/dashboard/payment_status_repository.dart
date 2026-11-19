import 'package:drift/drift.dart';

import '../../database/db/app_database.dart';
import '../../features/finance/due_management/domain/services/bill_due_policy.dart';
import '../../models/dashboard/payment_bill_item.dart';
import '../../models/dashboard/payment_status_model.dart';
import '../../models/finance/bank_book/bank_book_enums.dart';
import '../../models/finance/cash_book/cash_book_enums.dart';

/// Today's invoices and today's posted sales receipts are separate views.
class PaymentStatusRepository {
  const PaymentStatusRepository(this._db);

  final AppDatabase _db;

  Stream<PaymentStatusModel> watchDay(DateTime day) {
    return _db
        .customSelect(
          'SELECT 1',
          readsFrom: {
            _db.bills,
            _db.customers,
            _db.cashTransactions,
            _db.bankTransactions,
          },
        )
        .watch()
        .asyncMap((_) => loadDay(day));
  }

  Future<PaymentStatusModel> loadDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);

    final billFuture = (_db.select(_db.bills)
          ..where((b) =>
              b.billDate.isBiggerOrEqualValue(start) &
              b.billDate.isSmallerThanValue(end) &
              b.status.isIn(BillDuePolicy.eligibleBillStatuses))
          ..orderBy([
            (b) => OrderingTerm.desc(b.billDate),
            (b) => OrderingTerm.desc(b.id),
          ]))
        .get();
    final cashFuture = (_db.select(_db.cashTransactions)
          ..where((t) =>
              t.txnDate.isBiggerOrEqualValue(start) &
              t.txnDate.isSmallerThanValue(end) &
              t.isVoided.equals(false) &
              t.type.equals(CashTransactionType.income.dbValue) &
              t.referenceType.equals('BILL') &
              t.category.isIn([
                IncomeCategory.sale.dbValue,
                IncomeCategory.dueCollection.dbValue,
              ])))
        .get();
    final bankFuture = (_db.select(_db.bankTransactions)
          ..where((t) =>
              t.txnDate.isBiggerOrEqualValue(start) &
              t.txnDate.isSmallerThanValue(end) &
              t.isVoided.equals(false) &
              t.type.equals(BankTransactionType.credit.dbValue) &
              t.referenceType.equals('BILL') &
              t.category.isIn([
                BankCreditCategory.salePayment.dbValue,
                BankCreditCategory.dueCollection.dbValue,
              ])))
        .get();

    final bills = await billFuture;
    final cashReceipts = await cashFuture;
    final bankReceipts = await bankFuture;
    final customerIds =
        bills.map((bill) => bill.customerId).whereType<int>().toSet();
    final customers = customerIds.isEmpty
        ? <Customer>[]
        : await (_db.select(_db.customers)
              ..where((customer) => customer.id.isIn(customerIds)))
            .get();
    final customerNames = {
      for (final customer in customers) customer.id: customer.name
    };

    final items = bills.map((bill) {
      final snapshotName = bill.customerName?.trim();
      final name = customerNames[bill.customerId] ??
          (snapshotName != null && snapshotName.isNotEmpty
              ? snapshotName
              : 'Walk-in Customer');
      final due = BillDuePolicy.financeDue(bill);
      final paid = bill.paidAmount;
      final status = due <= BillDuePolicy.financeVisibilityTolerance
          ? PaymentStatus.paid
          : paid > BillDuePolicy.customerPrecisionTolerance
              ? PaymentStatus.partial
              : PaymentStatus.unpaid;
      return PaymentBillItem(
        billId: bill.id,
        billNo: bill.billNo,
        customerName: name,
        customerInitials: PaymentBillItem.extractInitials(name),
        customerId: bill.customerId,
        mobile: bill.mobile ?? '',
        totalAmount: bill.finalAmount,
        paidAmount: paid,
        dueAmount: due,
        billDate: bill.billDate,
        status: status,
      );
    }).toList(growable: false);

    var cashTotal = 0.0;
    var bankTotal = 0.0;
    final bankByMode = <String, double>{};
    for (final receipt in cashReceipts) {
      if (receipt.amount <= 0) continue;
      final mode = receipt.paymentMode.trim().toUpperCase();
      if (mode == 'CASH') {
        cashTotal += receipt.amount;
      } else {
        bankTotal += receipt.amount;
        bankByMode.update(mode, (amount) => amount + receipt.amount,
            ifAbsent: () => receipt.amount);
      }
    }
    for (final receipt in bankReceipts) {
      if (receipt.amount <= 0) continue;
      bankTotal += receipt.amount;
      final mode = receipt.paymentMode.trim().toUpperCase();
      bankByMode.update(mode, (amount) => amount + receipt.amount,
          ifAbsent: () => receipt.amount);
    }

    return PaymentStatusModel(
      summary: PaymentSummary(
        totalBills: items.length,
        cashCollected: cashTotal,
        bankCollected: bankTotal,
        bankByMode: Map.unmodifiable(bankByMode),
      ),
      bills: items,
    );
  }
}

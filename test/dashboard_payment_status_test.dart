import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/core/router/payment_status_navigation.dart';
import 'package:lotus_erp/models/dashboard/payment_bill_item.dart';
import 'package:lotus_erp/models/dashboard/payment_status_model.dart';
import 'package:lotus_erp/repositories/dashboard/payment_status_repository.dart';
import 'package:lotus_erp/ui/dashboard/payment_status_card.dart';

void main() {
  late AppDatabase db;
  late PaymentStatusRepository repository;
  final day = DateTime(2026, 11, 19);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = PaymentStatusRepository(db);
  });
  tearDown(() => db.close());

  Future<int> bill(String number, DateTime date,
      {int? customerId,
      double total = 1000,
      double paid = 0,
      double due = 1000,
      String paymentStatus = 'DUE',
      String status = 'ACTIVE'}) {
    return db.into(db.bills).insert(BillsCompanion.insert(
          billNo: number,
          customerId: drift.Value(customerId),
          customerName: const drift.Value('Invoice Name'),
          billDate: drift.Value(date),
          finalAmount: drift.Value(total),
          paidAmount: drift.Value(paid),
          dueAmount: drift.Value(due),
          paymentStatus: drift.Value(paymentStatus),
          status: drift.Value(status),
        ));
  }

  Future<void> cash(String id, DateTime date, double amount,
      {String category = 'SALE',
      String mode = 'CASH',
      bool voided = false,
      String referenceType = 'BILL'}) {
    return db
        .into(db.cashTransactions)
        .insert(CashTransactionsCompanion.insert(
          txnId: id,
          txnDate: date,
          type: 'INCOME',
          category: category,
          amount: drift.Value(amount),
          paymentMode: drift.Value(mode),
          isVoided: drift.Value(voided),
          referenceType: drift.Value(referenceType),
        ))
        .then((_) {});
  }

  Future<void> bank(String id, DateTime date, double amount,
      {String category = 'SALE_PAYMENT',
      String mode = 'UPI',
      bool voided = false,
      String referenceType = 'BILL'}) {
    return db
        .into(db.bankTransactions)
        .insert(BankTransactionsCompanion.insert(
          txnId: id,
          txnDate: date,
          type: 'CREDIT',
          category: category,
          amount: drift.Value(amount),
          paymentMode: drift.Value(mode),
          isVoided: drift.Value(voided),
          referenceType: drift.Value(referenceType),
        ))
        .then((_) {});
  }

  test('daily invoices, filters, and posted collection modes use real data',
      () async {
    final customerId = await db.into(db.customers).insert(
        CustomersCompanion.insert(
            name: 'Current Customer', mobile: '9000001111'));
    await bill('PAID', DateTime(2026, 11, 19, 9),
        customerId: customerId,
        total: 1500,
        paid: 1500,
        due: 0,
        paymentStatus: 'PAID');
    await bill('PARTIAL', DateTime(2026, 11, 19, 10),
        total: 2000, paid: 500, due: 1500, paymentStatus: 'PARTIAL');
    await bill('UNPAID', DateTime(2026, 11, 19, 11));
    await bill('YESTERDAY', DateTime(2026, 11, 18, 23, 59));
    await bill('VOID', DateTime(2026, 11, 19, 12), status: 'VOIDED');

    await cash('CASH', DateTime(2026, 11, 19, 9), 1000);
    await cash('DUE-CASH', DateTime(2026, 11, 19, 10), 250,
        category: 'DUE_COLLECTION');
    await bank('UPI', DateTime(2026, 11, 19, 9), 500);
    await bank('CARD', DateTime(2026, 11, 19, 10), 300, mode: 'CARD');
    await bank('NEFT', DateTime(2026, 11, 19, 11), 450,
        mode: 'NEFT', category: 'DUE_COLLECTION');
    await cash('VOID-RECEIPT', DateTime(2026, 11, 19, 12), 999, voided: true);
    await bank('OTHER', DateTime(2026, 11, 19, 12), 999,
        referenceType: 'ORDER');
    await cash('PRIOR', DateTime(2026, 11, 18, 23, 59), 999);

    final result = await repository.loadDay(day);
    expect(result.summary.totalBills, 3);
    expect(result.bills.map((b) => b.billNo), ['UNPAID', 'PARTIAL', 'PAID']);
    expect(result.bills.last.customerName, 'Current Customer');
    expect(result.summary.cashCollected, 1250);
    expect(result.summary.bankCollected, 1250);
    expect(result.summary.totalCollected, 2500);
    expect(result.summary.bankByMode, {'UPI': 500, 'CARD': 300, 'NEFT': 450});
    expect(result.withTab(PaymentFilterTab.due).filteredBills.length, 2);
    expect(result.withTab(PaymentFilterTab.paid).filteredBills.single.billNo,
        'PAID');
  });

  test('live watch refreshes when a receipt is posted', () async {
    final updates = StreamIterator(repository.watchDay(day));
    expect(await updates.moveNext(), isTrue);
    expect(updates.current.summary.totalCollected, 0);
    await cash('LIVE', DateTime(2026, 11, 19, 14), 725);
    expect(await updates.moveNext(), isTrue);
    expect(updates.current.summary.totalCollected, 725);
    await updates.cancel();
  });

  test('daily list has no ten invoice cap', () async {
    for (var index = 0; index < 12; index++) {
      await bill('INV-$index', DateTime(2026, 11, 19, 9, index));
    }
    final result = await repository.loadDay(day);
    expect(result.bills.length, 12);
  });

  test('invoice navigation focuses the profile bill, including walk-ins', () {
    final customerLocation = Uri.parse(PaymentStatusNavigation.invoice(42, 7));
    expect(customerLocation.path, '/app/customer/profile/7');
    expect(customerLocation.queryParameters['billId'], '42');

    final walkInLocation = Uri.parse(PaymentStatusNavigation.invoice(42, null));
    expect(walkInLocation.path, '/app/sales/pos');
    expect(walkInLocation.queryParameters['editBillId'], '42');
  });

  testWidgets('card flips, filters, and opens customer or focused invoice',
      (tester) async {
    const customerId = 7;
    const paidId = 101;
    const dueId = 102;
    final snapshot = PaymentStatusModel(
      summary: const PaymentSummary(
        totalBills: 2,
        cashCollected: 1200,
        bankCollected: 400,
        bankByMode: {'UPI': 400},
      ),
      bills: [
        PaymentBillItem(
          billId: dueId,
          billNo: 'DUE-1',
          customerName: 'Customer One',
          customerInitials: 'CO',
          customerId: customerId,
          mobile: '',
          totalAmount: 3000,
          paidAmount: 1000,
          dueAmount: 2000,
          billDate: day,
          status: PaymentStatus.partial,
        ),
        PaymentBillItem(
          billId: paidId,
          billNo: 'PAID-1',
          customerName: 'Customer One',
          customerInitials: 'CO',
          customerId: customerId,
          mobile: '',
          totalAmount: 123456,
          paidAmount: 123456,
          dueAmount: 0,
          billDate: day,
          status: PaymentStatus.paid,
        ),
      ],
    );
    final customers = <int>[];
    final invoices = <(int, int?)>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 260,
            child: PaymentStatusCard(
              repository: _StaticPaymentStatusRepository(db, snapshot),
              onOpenCustomer: customers.add,
              onOpenInvoice: (billId, customerId) =>
                  invoices.add((billId, customerId)),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('PENDING'), findsNothing);
    expect(find.text('₹1,600.00'), findsOneWidget);
    expect(find.byKey(const ValueKey('payment-invoice-$paidId')), findsOneWidget);
    expect(find.byKey(const ValueKey('payment-invoice-$dueId')), findsOneWidget);
    expect(find.textContaining('DUE'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('payment-collected-flip')));
    await tester.pumpAndSettle();
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('UPI'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('payment-tab-due')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('payment-invoice-$dueId')), findsOneWidget);
    expect(find.byKey(const ValueKey('payment-invoice-$paidId')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('open-customer-$dueId')));
    expect(customers.single, customerId);
    await tester.tap(find.byKey(const ValueKey('open-invoice-$dueId')));
    expect(invoices.single, (dueId, customerId));

    await tester.tap(find.byKey(const ValueKey('payment-tab-paid')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('payment-invoice-$paidId')), findsOneWidget);
    expect(find.byKey(const ValueKey('payment-invoice-$dueId')), findsNothing);
    expect(find.text('DUE'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

class _StaticPaymentStatusRepository extends PaymentStatusRepository {
  _StaticPaymentStatusRepository(super.db, this.snapshot);

  final PaymentStatusModel snapshot;

  @override
  Stream<PaymentStatusModel> watchDay(DateTime day) => Stream.value(snapshot);
}

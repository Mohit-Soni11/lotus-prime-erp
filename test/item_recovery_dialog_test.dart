import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/girvi/contact_recovery_model.dart';
import 'package:lotus_erp/models/girvi/girvi_loan_model.dart';
import 'package:lotus_erp/models/girvi/recovery_pledged_item_detail.dart';
import 'package:lotus_erp/ui/girvi/contact_recovery/item_recovery/item_recovery_dialog.dart';

void main() {
  testWidgets('melt form shows due without inventing a cash receipt',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final today = DateTime.now();
    final loan = GirviLoanModel(
      id: 20,
      ticketNo: 'GRV-0020',
      customerId: 1,
      itemDescription: 'Gold ring',
      itemCount: 1,
      metalType: 'Gold',
      metalPurity: '22KT',
      grossWeight: 5,
      stoneWeight: 0,
      netWeight: 5,
      loanAmount: 5000,
      interestRate: 0,
      durationMonths: 6,
      disbursementMode: 'Cash',
      startDate: today.subtract(const Duration(days: 180)),
      maturityDate: today.subtract(const Duration(days: 1)),
      createdAt: today.subtract(const Duration(days: 180)),
      status: 'OVERDUE',
    );
    final item = ContactRecoveryCase(
      account: GirviLoanWithCustomer(
        loan: loan,
        customerName: 'Recovery Customer',
        customerMobile: '9000000001',
      ),
      noticePeriodDays: 7,
      now: today,
    );

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: ItemRecoveryDialog(
          item: item,
          pledgedItems: const [
            RecoveryPledgedItemDetail(
              itemName: 'Ring',
              metalType: 'Gold',
              purity: '22KT',
              pieces: 1,
              netWeight: 5,
            ),
          ],
          bankAccounts: const [],
        ),
      ),
    ));

    expect(find.text('Pledge Details'), findsOneWidget);
    expect(find.text('Item name'), findsOneWidget);
    expect(find.text('Ring'), findsOneWidget);
    expect(find.text('Metal type'), findsOneWidget);
    expect(find.text('Purity'), findsOneWidget);
    expect(find.text('Net weight'), findsOneWidget);
    expect(find.text('Recovery Summary'), findsOneWidget);
    expect(find.text('Total due'), findsOneWidget);
    expect(find.text('Mark Melted & Close Account'), findsOneWidget);
    expect(find.text('Recovered today'), findsNothing);
    expect(find.text('Balance due'), findsNothing);
    expect(find.text('Cash'), findsNothing);
    expect(find.byKey(const ValueKey('item-recovery-amount')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('Item recovery method')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Item sold').last);
    await tester.pumpAndSettle();
    expect(find.text('Record Sale & Close Account'), findsOneWidget);

    expect(find.byKey(const ValueKey('item-recovery-amount')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('item-recovery-amount')))
          .controller!
          .text,
      isEmpty,
    );
    await tester.ensureVisible(find.text('Record Sale & Close Account'));
    await tester.tap(find.text('Record Sale & Close Account'));
    await tester.pump();
    expect(find.textContaining('Enter the actual sale proceeds received'),
        findsOneWidget);
  });
}

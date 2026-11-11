import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/finance/expense/expense_controller.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_book_enums.dart';
import 'package:lotus_erp/models/finance/expense/expense_draft.dart';
import 'package:lotus_erp/repositories/finance/expense_repository.dart';
import 'package:lotus_erp/ui/finance/expense/expense_entry_dialog.dart';

void main() {
  testWidgets('closing bank shortage preselects bank mode and day',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = ExpenseController(repository: ExpenseRepository(db: db));
    addTearDown(controller.dispose);
    final date = DateTime(2026, 11, 11);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ExpenseEntryDialog(
          ctrl: controller,
          initialDraft: ExpenseDraft(
            amount: 350,
            date: date,
            paymentMode: PaymentMode.bank,
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.amountCtrl.text, '350.00');
    expect(controller.entryMode, PaymentMode.bank);
    expect(controller.entryDate, date);
    expect(controller.descriptionCtrl.text, isEmpty);
    expect(find.text('Select a category'), findsOneWidget);
  });

  testWidgets('mismatch expense draft fills only the amount', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = ExpenseController(repository: ExpenseRepository(db: db));
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ExpenseEntryDialog(ctrl: controller, initialAmount: 4610),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.amountCtrl.text, '4610.00');
    expect(controller.partyNameCtrl.text, isEmpty);
    expect(controller.descriptionCtrl.text, isEmpty);
    expect(find.text('Select a category'), findsOneWidget);
    final saveGesture = tester.widget<GestureDetector>(find
        .ancestor(
          of: find.text('Save Expense'),
          matching: find.byType(GestureDetector),
        )
        .first);
    expect(saveGesture.onTap, isNull);

    await tester.tap(find.text('Save Expense'));
    await tester.pump();
    expect(find.byType(ExpenseEntryDialog), findsOneWidget);
  });
}

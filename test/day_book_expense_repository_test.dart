import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_book_enums.dart';
import 'package:lotus_erp/repositories/finance/expense_repository.dart';
import 'package:lotus_erp/repositories/reports/day_book_expense_repository.dart';

void main() {
  test('Day Book reads saved Expense Entry records without other outflows',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final date = DateTime(2026, 11, 4, 13);
    final expenses = ExpenseRepository(db: db);

    expect(
        await expenses.saveExpense(
          category: ExpenseCategory.shopRent,
          amount: 12000,
          paymentMode: PaymentMode.cash,
          expenseDate: date,
        ),
        isTrue);
    expect(
        await expenses.saveExpense(
          category: ExpenseCategory.otherExpense,
          customLabel: 'Personal expense',
          amount: 3000,
          paymentMode: PaymentMode.cash,
          expenseDate: date,
        ),
        isTrue);
    await db.into(db.cashTransactions).insert(CashTransactionsCompanion.insert(
          txnId: 'EXP-PURCHASE',
          txnDate: date,
          type: 'EXPENSE',
          category: 'PURCHASE_PAYMENT',
          amount: const drift.Value(5000),
        ));
    await db.into(db.cashTransactions).insert(CashTransactionsCompanion.insert(
          txnId: 'EXP-GIRVI',
          txnDate: date,
          type: 'EXPENSE',
          category: 'GIRVI_GIVEN',
          amount: const drift.Value(7000),
        ));
    await db.into(db.cashTransactions).insert(CashTransactionsCompanion.insert(
          txnId: 'EXP-VOID',
          txnDate: date,
          type: 'EXPENSE',
          category: 'OTHER_EXPENSE',
          amount: const drift.Value(999),
          isVoided: const drift.Value(true),
        ));
    await db.into(db.cashTransactions).insert(CashTransactionsCompanion.insert(
          txnId: 'EXP-FUTURE',
          txnDate: date,
          type: 'EXPENSE',
          category: 'PERSONAL_EXPENSE',
          amount: const drift.Value(400),
        ));

    final result = await DayBookExpenseRepository(db).fetch(date);
    expect(result, hasLength(3));
    expect(result.map((row) => row.category),
        containsAll(['Shop Rent', 'Personal expense', 'Personal Expense']));
    expect(result.fold<double>(0, (sum, row) => sum + row.amount), 15400);
    expect(result.every((row) => row.reference.startsWith('EXP-')), isTrue);
  });
}

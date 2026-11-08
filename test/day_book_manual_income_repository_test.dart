import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/finance/ledger/data/finance_day_closure_schema.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_book_enums.dart';
import 'package:lotus_erp/repositories/reports/day_book_manual_income_repository.dart';
import 'package:lotus_erp/repositories/reports/day_book_money_repository.dart';

void main() {
  test('manual income posts to the selected money ledger exactly once',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(financeDayClosureSchemaSql.first);
    final accountId = await db.into(db.bankAccounts).insert(
          BankAccountsCompanion.insert(
            accountName: 'Current Account',
            bankName: 'Test Bank',
            accountNumber: '123456789',
          ),
        );
    final repository = DayBookManualIncomeRepository(db);
    final day = DateTime(2026, 11, 8, 11);

    expect((await repository.listActiveBankAccounts()).single.id, accountId);
    expect(
      await repository.save(
        category: IncomeCategory.goldRepairIncome,
        amount: 1250,
        paymentMode: PaymentMode.cash,
        date: day,
      ),
      isTrue,
    );
    expect(
      await repository.save(
        category: IncomeCategory.silverRepairIncome,
        amount: 3200,
        paymentMode: PaymentMode.bank,
        bankAccountId: accountId,
        date: day,
      ),
      isTrue,
    );

    final cashRows = await db.select(db.cashTransactions).get();
    final bankRows = await db.select(db.bankTransactions).get();
    expect(cashRows, hasLength(1));
    expect(bankRows, hasLength(1));
    expect(cashRows.single.category, 'GOLD_REPAIR_INCOME');
    expect(cashRows.single.paymentMode, 'CASH');
    expect(cashRows.single.referenceType, 'MANUAL_INCOME');
    expect(bankRows.single.category, 'SILVER_REPAIR_INCOME');
    expect(bankRows.single.paymentMode, 'BANK');
    expect(bankRows.single.accountId, accountId);
    expect(bankRows.single.referenceType, 'MANUAL_INCOME');

    final flow = await DayBookMoneyRepository(db).fetch(day, 0);
    expect(flow.cashIn, 1250);
    expect(flow.bankIn, 3200);
  });

  test('manual income rejects invoice categories and closed dates', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(financeDayClosureSchemaSql.first);
    final repository = DayBookManualIncomeRepository(db);
    final day = DateTime(2026, 11, 8, 11);

    expect(
      await repository.save(
        category: IncomeCategory.sale,
        amount: 500,
        paymentMode: PaymentMode.cash,
        date: day,
      ),
      isFalse,
    );
    expect(
      await repository.save(
        category: IncomeCategory.dueCollection,
        amount: 500,
        paymentMode: PaymentMode.cash,
        date: day,
      ),
      isFalse,
    );
    expect(
      await repository.save(
        category: IncomeCategory.counterSaleIncome,
        amount: 500,
        paymentMode: PaymentMode.cash,
        date: day,
      ),
      isFalse,
    );
    expect(
      await repository.save(
        category: IncomeCategory.jewelleryMakingIncome,
        amount: 500,
        paymentMode: PaymentMode.cash,
        date: day,
      ),
      isFalse,
    );
    expect(
      await repository.save(
        category: IncomeCategory.otherIncome,
        amount: 500,
        paymentMode: PaymentMode.cash,
        date: day,
      ),
      isFalse,
    );
    await db.customStatement('''
      INSERT INTO finance_day_closures
      (day_key, start_epoch, end_epoch, closing_cash, closed_at)
      VALUES ('20261108', 1794096000, 1794182400, 0, 1794182400)
    ''');
    expect(
      await repository.save(
        category: IncomeCategory.silverRepairIncome,
        amount: 500,
        paymentMode: PaymentMode.cash,
        date: day,
      ),
      isFalse,
    );
    expect(await db.select(db.cashTransactions).get(), isEmpty);
  });

  test('other income keeps the user-defined category without an invoice',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(financeDayClosureSchemaSql.first);
    final repository = DayBookManualIncomeRepository(db);

    expect(
      await repository.save(
        category: IncomeCategory.otherIncome,
        amount: 750,
        paymentMode: PaymentMode.cash,
        date: DateTime(2026, 11, 8, 12),
        customLabel: 'Pearl restringing',
      ),
      isTrue,
    );
    final receipt = (await db.select(db.cashTransactions).get()).single;
    expect(receipt.customLabel, 'Pearl restringing');
    expect(receipt.description, 'Pearl restringing');
    expect(receipt.referenceType, 'MANUAL_INCOME');
    expect(await db.select(db.bankTransactions).get(), isEmpty);
  });
}

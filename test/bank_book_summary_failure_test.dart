import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/repositories/finance/bank_book_repository.dart';

void main() {
  test('missing account is an error, not a zero balance', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final summary = BankBookRepository(db: db).computeSummary(
      accountId: 404,
      from: DateTime(2026, 11, 12),
      to: DateTime(2026, 11, 13),
    );
    await expectLater(summary, throwsStateError);
  });

  test('database failure cannot be rendered as a zero balance', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final accountId = await db.into(db.bankAccounts).insert(
          BankAccountsCompanion.insert(
            accountName: 'Test Bank',
            bankName: 'Bank',
            accountNumber: 'SUMMARY-FAILURE',
          ),
        );
    await db.customStatement('DROP TABLE bank_transactions');
    final summary = BankBookRepository(db: db).computeSummary(
      accountId: accountId,
      from: DateTime(2026, 11, 12),
      to: DateTime(2026, 11, 13),
    );
    await expectLater(summary, throwsA(isA<Exception>()));
    await expectLater(
        BankBookRepository(db: db).fetchAccounts(), throwsA(isA<Exception>()));
  });
}

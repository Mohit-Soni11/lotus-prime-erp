import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/finance/account_book/account_book_export_service.dart';
import 'package:lotus_erp/models/finance/account_book/account_book_month.dart';
import 'package:lotus_erp/repositories/finance/account_book_month_repository.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test(
      'month carries opening balances, includes all posted channels and documents',
      () async {
    await db.into(db.shopProfiles).insert(
        const ShopProfilesCompanion(openingCashBalance: drift.Value(100)));
    final bankId = await db.into(db.bankAccounts).insert(
          BankAccountsCompanion.insert(
            accountName: 'Main Bank',
            bankName: 'Bank',
            accountNumber: 'AB-MAIN',
            openingBalance: const drift.Value(500),
            activeSince: drift.Value(DateTime(2026, 1)),
          ),
        );
    Future<void> cash(
        String id, DateTime date, String type, String category, double amount,
        {String mode = 'CASH', bool voided = false}) async {
      await db.into(db.cashTransactions).insert(
            CashTransactionsCompanion.insert(
              txnId: id,
              txnDate: date,
              type: type,
              category: category,
              amount: drift.Value(amount),
              paymentMode: drift.Value(mode),
              isVoided: drift.Value(voided),
            ),
          );
    }

    Future<void> bank(String id, DateTime date, String type, String category,
        double amount) async {
      await db.into(db.bankTransactions).insert(
            BankTransactionsCompanion.insert(
              txnId: id,
              accountId: drift.Value(bankId),
              txnDate: date,
              type: type,
              category: category,
              amount: drift.Value(amount),
              paymentMode: const drift.Value('UPI'),
            ),
          );
    }

    await cash('FEB', DateTime(2026, 2, 25), 'INCOME', 'SALE', 20);
    await cash('MAR-CASH', DateTime(2026, 3, 5, 10), 'INCOME', 'SALE', 100);
    await cash('MAR-TRANSFER', DateTime(2026, 3, 5, 11), 'EXPENSE',
        'CASH_DEPOSIT', 40);
    await bank(
        'MAR-UPI', DateTime(2026, 3, 6, 12), 'CREDIT', 'SALE_PAYMENT', 80);
    await bank('MAR-TRANSFER-IN', DateTime(2026, 3, 5, 11), 'CREDIT',
        'CASH_DEPOSIT', 40);
    await cash('MAR-SHADOW', DateTime(2026, 3, 6), 'INCOME', 'SALE', 80,
        mode: 'UPI');
    await cash('MAR-VOID', DateTime(2026, 3, 7), 'INCOME', 'SALE', 999,
        voided: true);
    await cash('APR', DateTime(2026, 4, 1), 'INCOME', 'SALE', 300);
    await db.into(db.bills).insert(BillsCompanion.insert(
          billNo: 'INV-MARCH',
          billDate: drift.Value(DateTime(2026, 3, 6, 9)),
          finalAmount: const drift.Value(180),
        ));

    final month =
        await AccountBookMonthRepository(db: db).fetch(DateTime(2026, 3, 19));
    expect(month.days, hasLength(31));
    expect(month.money.openingCash, 120);
    expect(month.money.openingBank, 500);
    expect(month.money.cashIn, 100);
    expect(month.money.cashOut, 40);
    expect(month.money.bankIn, 120);
    expect(month.money.closingCash, 180);
    expect(month.money.closingBank, 620);
    expect(month.money.moneyIn, 180);
    expect(month.money.internalIn, 40);
    expect(month.days[4].closingCash, 180);
    expect(month.days[5].closingBank, 620);
    expect(month.count(AccountBookActivityType.money), 4);
    expect(month.count(AccountBookActivityType.document), 1);
    expect(
        month.days[5].activities.any((item) => item.reference == 'INV-MARCH'),
        isTrue);
    final csv = AccountBookExportService.buildCsv(month);
    expect(csv, contains('INV-MARCH'));
    expect(csv, contains('MONTH CLOSE'));
    final pdf = await AccountBookExportService.buildPdf(month);
    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
  });

  test('bank account opened midmonth enters closing balance on activation day',
      () async {
    await db.into(db.bankAccounts).insert(BankAccountsCompanion.insert(
          accountName: 'New Account',
          bankName: 'Bank',
          accountNumber: 'AB-NEW',
          openingBalance: const drift.Value(250),
          activeSince: drift.Value(DateTime(2026, 3, 12)),
        ));
    final month =
        await AccountBookMonthRepository(db: db).fetch(DateTime(2026, 3));
    expect(month.money.openingBank, 0);
    expect(month.money.bankOpeningAdditions, 250);
    expect(month.count(AccountBookActivityType.balance), 1);
    expect(month.days[10].closingBank, 0);
    expect(month.days[11].closingBank, 250);
    expect(month.money.closingBank, 250);
    expect(month.money.moneyIn, 0);
  });

  test('month includes posted stock and dated Girvi activity', () async {
    final itemId = await db.into(db.stockItems).insert(
          StockItemsCompanion.insert(
            sku: 'AB-RING',
            itemName: 'Gold Ring',
            category: 'Jewellery',
            subCategory: 'Ring',
          ),
        );
    await db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
          stockItemId: itemId,
          movementType: 'IN',
          sourceType: 'PURCHASE',
          sourceId: 'P-ACCOUNT',
          skuSnapshot: 'AB-RING',
          metalTypeSnapshot: 'Gold',
          itemNameSnapshot: 'Gold Ring',
          quantityDelta: 1,
          netWeightDelta: const drift.Value(10),
          occurredAt: DateTime(2026, 3, 3, 10),
        ));
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(name: 'Customer', mobile: '9000000555'),
        );
    await db.into(db.girviLoans).insert(GirviLoansCompanion.insert(
          ticketNo: 'GRV-ACCOUNT',
          customerId: customerId,
          itemDescription: 'Chain',
          startDate: drift.Value(DateTime(2026, 2, 1)),
          releaseDate: drift.Value(DateTime(2026, 3, 9, 11)),
          status: const drift.Value('RELEASED'),
        ));
    final month =
        await AccountBookMonthRepository(db: db).fetch(DateTime(2026, 3));
    expect(month.count(AccountBookActivityType.stock), 1);
    expect(month.count(AccountBookActivityType.girvi), 1);
    expect(month.days[2].activities.single.reference, 'PURCHASE P-ACCOUNT');
    expect(month.days[8].activities.single.reference, 'GRV-ACCOUNT');
    expect(month.money.moneyIn, 0);
  });
}

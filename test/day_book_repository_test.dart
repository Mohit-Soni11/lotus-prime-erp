import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/repositories/reports/day_book_repository.dart';

void main() {
  late AppDatabase db;
  late DayBookRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DayBookRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'fetchDayBook builds sales and payment breakup from active finance ledgers',
    () async {
      final date = DateTime(2026, 6, 25, 11);
      final bankAccountId = await _insertBankAccount(db);

      await _insertBill(
        db,
        billNo: 'TAX-LJ-2026-0001',
        billDate: date,
        billType: 'GST',
        finalAmount: 1030,
        paidAmount: 600,
        taxableAmount: 1000,
        cgstAmount: 15,
        sgstAmount: 15,
        gstAmount: 30,
      );
      await _insertBill(
        db,
        billNo: 'INV-LJ-2026-0002',
        billDate: date,
        billType: 'NORMAL',
        finalAmount: 1000,
        paidAmount: 250,
      );

      await _insertCashReceipt(
        db,
        txnId: 'CASH-001',
        txnDate: date,
        category: 'SALE',
        paymentMode: 'CASH',
        amount: 100,
        referenceId: 'TAX-LJ-2026-0001#CASH',
      );
      await _insertBankReceipt(
        db,
        txnId: 'BANK-001',
        accountId: bankAccountId,
        txnDate: date,
        category: 'SALE_PAYMENT',
        paymentMode: 'UPI',
        amount: 500,
        referenceId: 'TAX-LJ-2026-0001#UPI',
      );
      await _insertBankReceipt(
        db,
        txnId: 'BANK-002',
        accountId: bankAccountId,
        txnDate: date,
        category: 'SALE_PAYMENT',
        paymentMode: 'CARD',
        amount: 250,
        referenceId: 'INV-LJ-2026-0002#CARD',
      );
      await _insertCashReceipt(
        db,
        txnId: 'CASH-002',
        txnDate: date,
        category: 'DUE_COLLECTION',
        paymentMode: 'CASH',
        amount: 150,
        referenceId: 'INV-LJ-2026-0009#DUE#CASH',
      );

      await _insertCashReceipt(
        db,
        txnId: 'CASH-VOID',
        txnDate: date,
        category: 'SALE',
        paymentMode: 'CASH',
        amount: 999,
        referenceId: 'TAX-LJ-2026-0001#CASH',
        isVoided: true,
      );
      await _insertBankReceipt(
        db,
        txnId: 'BANK-VOID',
        accountId: bankAccountId,
        txnDate: date,
        category: 'SALE_PAYMENT',
        paymentMode: 'UPI',
        amount: 999,
        referenceId: 'INV-LJ-2026-0002#UPI',
        isVoided: true,
      );

      final summary = await repository.fetchDayBook(date);

      expect(summary.cashIn.gstSales.billCount, 1);
      expect(summary.cashIn.gstSales.finalAmount, 1030);
      expect(summary.cashIn.gstSales.taxableAmount, 1000);
      expect(summary.cashIn.gstSales.gstCollected, 30);
      expect(summary.cashIn.gstSales.payments.cash, 100);
      expect(summary.cashIn.gstSales.payments.upi, 500);

      expect(summary.cashIn.nonGstSales.billCount, 1);
      expect(summary.cashIn.nonGstSales.totalAmount, 1000);
      expect(summary.cashIn.nonGstSales.payments.card, 250);

      expect(summary.cashIn.retailSalesTotal, 850);
      expect(summary.cashIn.dueCollection, 150);
      expect(summary.cashIn.total, 1000);
      expect(summary.paymentBreakup.cash, 250);
      expect(summary.paymentBreakup.upi, 500);
      expect(summary.paymentBreakup.card, 250);
      expect(summary.paymentBreakup.total, 1000);
    },
  );

  test(
    'fetchDayBook keeps legacy bill payment split when ledger rows are absent',
    () async {
      final date = DateTime(2026, 6, 25, 15);

      await _insertBill(
        db,
        billNo: 'INV-LJ-2026-0003',
        billDate: date,
        billType: 'NORMAL',
        finalAmount: 1000,
        paidAmount: 500,
        cashPaid: 300,
        upiPaid: 200,
      );

      final summary = await repository.fetchDayBook(date);

      expect(summary.cashIn.nonGstSales.payments.cash, 300);
      expect(summary.cashIn.nonGstSales.payments.upi, 200);
      expect(summary.cashIn.retailSalesTotal, 500);
      expect(summary.paymentBreakup.cash, 300);
      expect(summary.paymentBreakup.upi, 200);
      expect(summary.paymentBreakup.total, 500);
    },
  );
}

Future<int> _insertBankAccount(AppDatabase db) {
  return db.into(db.bankAccounts).insert(
        BankAccountsCompanion.insert(
          accountName: 'Primary Current',
          bankName: 'HDFC Bank',
          accountNumber: '111122223333',
          isPrimary: const drift.Value(true),
        ),
      );
}

Future<int> _insertBill(
  AppDatabase db, {
  required String billNo,
  required DateTime billDate,
  required String billType,
  required double finalAmount,
  required double paidAmount,
  double totalAmount = 0,
  double taxableAmount = 0,
  double cgstAmount = 0,
  double sgstAmount = 0,
  double gstAmount = 0,
  double cashPaid = 0,
  double upiPaid = 0,
  double cardPaid = 0,
}) {
  return db.into(db.bills).insert(
        BillsCompanion.insert(
          billNo: billNo,
          customerName: const drift.Value('Walk-in Customer'),
          billType: drift.Value(billType),
          paymentStatus: drift.Value(
            paidAmount >= finalAmount ? 'PAID' : 'PARTIAL',
          ),
          totalAmount:
              drift.Value(totalAmount == 0 ? finalAmount : totalAmount),
          taxableAmount: drift.Value(taxableAmount),
          cgstAmount: drift.Value(cgstAmount),
          sgstAmount: drift.Value(sgstAmount),
          gstAmount: drift.Value(gstAmount),
          finalAmount: drift.Value(finalAmount),
          paidAmount: drift.Value(paidAmount),
          cashPaid: drift.Value(cashPaid),
          upiPaid: drift.Value(upiPaid),
          cardPaid: drift.Value(cardPaid),
          dueAmount: drift.Value(
            (finalAmount - paidAmount).clamp(0, double.infinity).toDouble(),
          ),
          billDate: drift.Value(billDate),
          status: const drift.Value('ACTIVE'),
        ),
      );
}

Future<int> _insertCashReceipt(
  AppDatabase db, {
  required String txnId,
  required DateTime txnDate,
  required String category,
  required String paymentMode,
  required double amount,
  required String referenceId,
  bool isVoided = false,
}) {
  return db.into(db.cashTransactions).insert(
        CashTransactionsCompanion.insert(
          txnId: txnId,
          txnDate: txnDate,
          type: 'INCOME',
          category: category,
          amount: drift.Value(amount),
          paymentMode: drift.Value(paymentMode),
          referenceId: drift.Value(referenceId),
          referenceType: const drift.Value('BILL'),
          partyName: const drift.Value('Walk-in Customer'),
          isAutoGenerated: const drift.Value(true),
          isVoided: drift.Value(isVoided),
        ),
      );
}

Future<int> _insertBankReceipt(
  AppDatabase db, {
  required String txnId,
  required int accountId,
  required DateTime txnDate,
  required String category,
  required String paymentMode,
  required double amount,
  required String referenceId,
  bool isVoided = false,
}) {
  return db.into(db.bankTransactions).insert(
        BankTransactionsCompanion.insert(
          txnId: txnId,
          accountId: accountId,
          txnDate: txnDate,
          type: 'CREDIT',
          category: category,
          amount: drift.Value(amount),
          paymentMode: drift.Value(paymentMode),
          referenceId: drift.Value(referenceId),
          referenceType: const drift.Value('BILL'),
          partyName: const drift.Value('Walk-in Customer'),
          isAutoGenerated: const drift.Value(true),
          isVoided: drift.Value(isVoided),
        ),
      );
}

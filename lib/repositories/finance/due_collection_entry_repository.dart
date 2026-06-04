import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../database/db/app_database.dart';
import '../../models/finance/due_collection_entry/due_collection_entry_model.dart';

class DueCollectionEntryRepository {
  final AppDatabase _db;

  DueCollectionEntryRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  Future<List<DueCollectionBillModel>> fetchDueBills() async {
    try {
      final rows = await _baseDueQuery().get();
      return _mapDueRows(rows);
    } catch (e) {
      debugPrint('DueCollectionEntryRepository.fetchDueBills error: $e');
      return [];
    }
  }

  Stream<List<DueCollectionBillModel>> watchDueBills() {
    return _baseDueQuery().watch().map<List<DueCollectionBillModel>>(
          (rows) => _mapDueRows(rows.cast<TypedResult>()),
        );
  }

  Future<List<DueCollectionBankAccountModel>> fetchBankAccounts() async {
    try {
      final rows = await (_db.select(_db.bankAccounts)
            ..where((tbl) => tbl.isActive.equals(true))
            ..orderBy([
              (tbl) => OrderingTerm.desc(tbl.isPrimary),
              (tbl) => OrderingTerm.asc(tbl.accountName),
            ]))
          .get();
      return rows
          .map(
            (row) => DueCollectionBankAccountModel(
              id: row.id,
              accountName: row.accountName,
              bankName: row.bankName,
              isPrimary: row.isPrimary,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('DueCollectionEntryRepository.fetchBankAccounts error: $e');
      return [];
    }
  }

  Future<DueCollectionSaveResult> saveCollection({
    required int billId,
    required double amount,
    required double discountAmount,
    required DueCollectionPaymentMode mode,
    required int? bankAccountId,
    required DateTime? nextPromiseDate,
    required String notes,
  }) async {
    if (amount <= 0) {
      return const DueCollectionSaveResult(
        success: false,
        message: 'Enter collection amount.',
      );
    }
    if (discountAmount < 0) {
      return const DueCollectionSaveResult(
        success: false,
        message: 'Discount cannot be negative.',
      );
    }

    try {
      return await _db.transaction(() async {
        final bill = await (_db.select(_db.bills)
              ..where((b) => b.id.equals(billId)))
            .getSingleOrNull();
        if (bill == null) {
          return const DueCollectionSaveResult(
            success: false,
            message: 'Selected bill was not found.',
          );
        }

        final currentDue = _currentDue(bill);
        final discount = discountAmount.clamp(0.0, currentDue).toDouble();
        final settlement = amount + discount;
        if (currentDue <= 0.5) {
          return const DueCollectionSaveResult(
            success: false,
            message: 'This bill is already clear.',
          );
        }
        if (settlement > currentDue + 0.01) {
          return DueCollectionSaveResult(
            success: false,
            message:
                'Amount + discount cannot be more than due Rs ${currentDue.toStringAsFixed(2)}.',
          );
        }

        int? resolvedBankAccountId = bankAccountId;
        if (mode.usesBankLedger) {
          resolvedBankAccountId ??= await _findPreferredBankAccountId();
          if (resolvedBankAccountId == null) {
            return const DueCollectionSaveResult(
              success: false,
              message: 'No active bank account found for this payment mode.',
            );
          }
        }

        final newDue =
            (currentDue - settlement).clamp(0.0, double.infinity).toDouble();
        final newPaid = bill.paidAmount + amount;
        final newDiscount = bill.discount + discount;
        final newFinal =
            (newPaid + newDue).clamp(0.0, double.infinity).toDouble();
        final newStatus = newDue <= 0.5 ? 'PAID' : 'PARTIAL';
        final now = DateTime.now();
        final partyName = _firstText([bill.customerName, 'Walk-in Customer']);
        final narration = _buildNarration(
          bill.billNo,
          notes,
          discount,
          newDue <= 0.5 ? null : nextPromiseDate,
        );

        await (_db.update(_db.bills)..where((b) => b.id.equals(bill.id))).write(
          BillsCompanion(
            discount: Value(newDiscount),
            finalAmount: Value(newFinal),
            paidAmount: Value(newPaid),
            dueAmount: Value(newDue),
            paymentStatus: Value(newStatus),
            promiseDate: Value(newDue <= 0.5 ? null : nextPromiseDate),
          ),
        );

        final receiptNo = mode == DueCollectionPaymentMode.cash
            ? await _insertCashReceipt(
                amount: amount,
                mode: mode,
                billNo: bill.billNo,
                partyName: partyName,
                txnDate: now,
                narration: narration,
              )
            : await _insertBankReceipt(
                accountId: resolvedBankAccountId!,
                amount: amount,
                mode: mode,
                billNo: bill.billNo,
                partyName: partyName,
                txnDate: now,
                narration: narration,
              );

        final discountText = discount > 0.5
            ? ' Discount Rs ${discount.toStringAsFixed(2)} applied.'
            : '';
        return DueCollectionSaveResult(
          success: true,
          receiptNo: receiptNo,
          message: newDue <= 0.5
              ? 'Due cleared for ${bill.billNo}. Receipt $receiptNo saved.$discountText'
              : 'Partial due collected for ${bill.billNo}. Balance Rs ${newDue.toStringAsFixed(2)}.$discountText',
        );
      });
    } catch (e) {
      debugPrint('DueCollectionEntryRepository.saveCollection error: $e');
      return const DueCollectionSaveResult(
        success: false,
        message: 'Could not save due collection.',
      );
    }
  }

  _baseDueQuery() {
    final query = _db.select(_db.bills).join([
      leftOuterJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.bills.customerId),
      ),
    ])
      ..where(_db.bills.status.equals('ACTIVE'))
      ..orderBy([
        OrderingTerm.asc(_db.bills.promiseDate),
        OrderingTerm.desc(_db.bills.billDate)
      ]);
    return query;
  }

  List<DueCollectionBillModel> _mapDueRows(List<TypedResult> rows) {
    final bills = <DueCollectionBillModel>[];
    for (final row in rows) {
      final bill = row.readTable(_db.bills);
      final customer = row.readTableOrNull(_db.customers);
      final due = _currentDue(bill);
      if (due <= 0.5) continue;

      final city = _firstText([customer?.city, '']);
      bills.add(
        DueCollectionBillModel(
          id: bill.id,
          billNo: bill.billNo,
          customerId: bill.customerId,
          customerName: _firstText(
              [customer?.name, bill.customerName, 'Walk-in Customer']),
          mobile: _firstText([customer?.mobile, bill.mobile, '-']),
          city: city,
          address: _addressFor(customer, city),
          billDate: bill.billDate,
          promiseDate: bill.promiseDate,
          finalAmount: bill.finalAmount,
          discountAmount: bill.discount,
          paidAmount: bill.paidAmount,
          dueAmount: due,
          paymentStatus: bill.paymentStatus,
          billingMode: bill.billingMode,
          billType: bill.billType,
        ),
      );
    }

    bills.sort((a, b) {
      final promiseCompare =
          _promiseSortValue(a).compareTo(_promiseSortValue(b));
      if (promiseCompare != 0) return promiseCompare;
      return b.dueAmount.compareTo(a.dueAmount);
    });
    return bills;
  }

  Future<String> _insertCashReceipt({
    required double amount,
    required DueCollectionPaymentMode mode,
    required String billNo,
    required String partyName,
    required DateTime txnDate,
    required String narration,
  }) async {
    final txnId = await _generateCashTxnId();
    await _db.into(_db.cashTransactions).insert(
          CashTransactionsCompanion.insert(
            txnId: txnId,
            txnDate: txnDate,
            type: 'INCOME',
            category: 'DUE_COLLECTION',
            amount: Value(amount),
            paymentMode: Value(mode.dbValue),
            description: Value(narration),
            referenceId: Value(_buildReferenceId(billNo, mode.dbValue)),
            referenceType: const Value('BILL'),
            partyName: Value(partyName),
            isAutoGenerated: const Value(true),
            isVoided: const Value(false),
          ),
        );
    return txnId;
  }

  Future<String> _insertBankReceipt({
    required int accountId,
    required double amount,
    required DueCollectionPaymentMode mode,
    required String billNo,
    required String partyName,
    required DateTime txnDate,
    required String narration,
  }) async {
    final txnId = await _generateBankTxnId();
    await _db.into(_db.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: txnId,
            accountId: accountId,
            txnDate: txnDate,
            type: 'CREDIT',
            category: 'DUE_COLLECTION',
            amount: Value(amount),
            paymentMode: Value(_bankPaymentMode(mode)),
            description: Value(narration),
            referenceId: Value(_buildReferenceId(billNo, mode.dbValue)),
            referenceType: const Value('BILL'),
            partyName: Value(partyName),
            isAutoGenerated: const Value(true),
            isVoided: const Value(false),
          ),
        );
    return txnId;
  }

  Future<int?> _findPreferredBankAccountId() async {
    final account = await (_db.select(_db.bankAccounts)
          ..where((tbl) => tbl.isActive.equals(true))
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.isPrimary),
            (tbl) => OrderingTerm.asc(tbl.id),
          ])
          ..limit(1))
        .getSingleOrNull();
    return account?.id;
  }

  Future<String> _generateCashTxnId() async {
    final count = await _countRows('cash_transactions');
    final year = DateTime.now().year;
    return 'TXN-$year-${(count + 1).toString().padLeft(4, '0')}';
  }

  Future<String> _generateBankTxnId() async {
    final count = await _countRows('bank_transactions');
    final year = DateTime.now().year;
    return 'BTXN-$year-${(count + 1).toString().padLeft(4, '0')}';
  }

  Future<int> _countRows(String tableName) async {
    final row = await _db
        .customSelect('SELECT COUNT(*) AS total FROM $tableName')
        .getSingle();
    return row.read<int>('total');
  }

  String _buildReferenceId(String billNo, String paymentMode) =>
      '$billNo#DUE#$paymentMode';

  String _buildNarration(
    String billNo,
    String notes,
    double discountAmount,
    DateTime? nextPromiseDate,
  ) {
    final parts = <String>['Due collection against $billNo'];
    if (discountAmount > 0.5) {
      parts.add('Discount Rs ${discountAmount.toStringAsFixed(2)}');
    }
    if (nextPromiseDate != null) {
      parts.add('Next promise ${_formatDate(nextPromiseDate)}');
    }
    final cleanNotes = notes.trim();
    if (cleanNotes.isNotEmpty) parts.add(cleanNotes);
    return parts.join(' - ');
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _bankPaymentMode(DueCollectionPaymentMode mode) {
    switch (mode) {
      case DueCollectionPaymentMode.upi:
        return 'UPI';
      case DueCollectionPaymentMode.card:
        return 'CARD';
      case DueCollectionPaymentMode.cheque:
        return 'CHEQUE';
      case DueCollectionPaymentMode.bank:
        return 'NEFT';
      case DueCollectionPaymentMode.cash:
        return 'CASH_DEPOSIT';
    }
  }

  int _promiseSortValue(DueCollectionBillModel bill) {
    if (bill.promiseDate == null) return 9999999999999;
    return bill.promiseDate!.millisecondsSinceEpoch;
  }

  double _currentDue(Bill bill) {
    final computed = bill.finalAmount - bill.paidAmount;
    final due = bill.dueAmount > 0.5 ? bill.dueAmount : computed;
    return due < 0 ? 0 : due;
  }

  String _addressFor(Customer? customer, String city) {
    if (customer == null) return city;
    final parts = [
      customer.addressLine1,
      customer.addressLine2,
      customer.city,
      customer.state,
      customer.pincode,
    ]
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim())
        .toList();
    return parts.isEmpty ? city : parts.join(', ');
  }

  String _firstText(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return '-';
  }
}

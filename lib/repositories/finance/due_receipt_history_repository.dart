import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../database/db/app_database.dart';
import '../../models/finance/due_receipt_history/due_receipt_history_model.dart';

class DueReceiptHistoryRepository {
  final AppDatabase _db;

  DueReceiptHistoryRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  Future<List<DueReceiptModel>> fetchReceipts() async {
    try {
      final results = await Future.wait([
        (_db.select(_db.cashTransactions)
              ..where((t) =>
                  t.isVoided.equals(false) &
                  t.referenceType.equals('BILL') &
                  t.type.equals('INCOME'))
              ..orderBy([
                (t) => OrderingTerm.desc(t.txnDate),
                (t) => OrderingTerm.desc(t.id),
              ]))
            .get(),
        (_db.select(_db.bankTransactions)
              ..where((t) =>
                  t.isVoided.equals(false) &
                  t.referenceType.equals('BILL') &
                  t.type.equals('CREDIT'))
              ..orderBy([
                (t) => OrderingTerm.desc(t.txnDate),
                (t) => OrderingTerm.desc(t.id),
              ]))
            .get(),
        _db.select(_db.bills).get(),
        _db.select(_db.customers).get(),
        _db.select(_db.bankAccounts).get(),
      ]);

      final cashRows = results[0] as List<CashTransaction>;
      final bankRows = results[1] as List<BankTransaction>;
      final bills = results[2] as List<Bill>;
      final customers = results[3] as List<Customer>;
      final accounts = results[4] as List<BankAccount>;

      final billByNo = {for (final bill in bills) bill.billNo: bill};
      final customerById = {
        for (final customer in customers) customer.id: customer
      };
      final accountById = {for (final account in accounts) account.id: account};

      final receipts = <DueReceiptModel>[];

      for (final txn in cashRows) {
        if (txn.amount <= 0.5 ||
            !_hasDueMarker(txn.category, txn.description, txn.referenceId)) {
          continue;
        }
        final billNo = _billNoFromReference(txn.referenceId);
        final bill = billByNo[billNo];
        final customer =
            bill?.customerId == null ? null : customerById[bill!.customerId!];
        receipts.add(
          _fromCashTxn(
            txn: txn,
            billNo: billNo,
            bill: bill,
            customer: customer,
          ),
        );
      }

      for (final txn in bankRows) {
        if (txn.amount <= 0.5 ||
            !_hasDueMarker(txn.category, txn.description, txn.referenceId)) {
          continue;
        }
        final billNo = _billNoFromReference(txn.referenceId);
        final bill = billByNo[billNo];
        final customer =
            bill?.customerId == null ? null : customerById[bill!.customerId!];
        final account = accountById[txn.accountId];
        receipts.add(
          _fromBankTxn(
            txn: txn,
            billNo: billNo,
            bill: bill,
            customer: customer,
            account: account,
          ),
        );
      }

      receipts.sort((a, b) {
        final dateCompare = b.receiptDate.compareTo(a.receiptDate);
        if (dateCompare != 0) return dateCompare;
        return b.ledgerId.compareTo(a.ledgerId);
      });

      return receipts;
    } catch (e) {
      debugPrint('DueReceiptHistoryRepository.fetchReceipts error: $e');
      return [];
    }
  }

  Stream<List<DueReceiptModel>> watchReceipts() {
    return _db
        .customSelect(
          'SELECT 1',
          readsFrom: {
            _db.cashTransactions,
            _db.bankTransactions,
            _db.bills,
            _db.customers,
            _db.bankAccounts,
          },
        )
        .watch()
        .asyncMap((_) => fetchReceipts());
  }

  DueReceiptModel _fromCashTxn({
    required CashTransaction txn,
    required String billNo,
    required Bill? bill,
    required Customer? customer,
  }) {
    return DueReceiptModel(
      id: 'CASH:${txn.id}',
      ledgerId: txn.id,
      ledgerSource: 'CASH',
      receiptNo: txn.txnId,
      billNo: _firstText([bill?.billNo, billNo, '-']),
      billId: bill?.id,
      customerId: bill?.customerId,
      customerName: _firstText([
        customer?.name,
        bill?.customerName,
        txn.partyName,
        'Walk-in Customer'
      ]),
      mobile: _firstText([customer?.mobile, bill?.mobile, '-']),
      city: _firstText([customer?.city, '']),
      address: _addressFor(customer),
      receiptDate: txn.txnDate,
      billDate: bill?.billDate,
      amount: txn.amount,
      paymentMode: txn.paymentMode,
      channelLabel: 'Cash Book',
      bankAccountName: null,
      description: txn.description,
      referenceId: txn.referenceId,
      billAmount: bill?.finalAmount ?? 0,
      billPaid: bill?.paidAmount ?? 0,
      currentDue: _currentDue(bill),
      billPaymentStatus: bill?.paymentStatus ?? 'RECEIVED',
      isDueMarked:
          _hasDueMarker(txn.category, txn.description, txn.referenceId),
    );
  }

  DueReceiptModel _fromBankTxn({
    required BankTransaction txn,
    required String billNo,
    required Bill? bill,
    required Customer? customer,
    required BankAccount? account,
  }) {
    return DueReceiptModel(
      id: 'BANK:${txn.id}',
      ledgerId: txn.id,
      ledgerSource: 'BANK',
      receiptNo: txn.txnId,
      billNo: _firstText([bill?.billNo, billNo, '-']),
      billId: bill?.id,
      customerId: bill?.customerId,
      customerName: _firstText([
        customer?.name,
        bill?.customerName,
        txn.partyName,
        'Walk-in Customer'
      ]),
      mobile: _firstText([customer?.mobile, bill?.mobile, '-']),
      city: _firstText([customer?.city, '']),
      address: _addressFor(customer),
      receiptDate: txn.txnDate,
      billDate: bill?.billDate,
      amount: txn.amount,
      paymentMode: txn.paymentMode,
      channelLabel: 'Bank Book',
      bankAccountName: account?.accountName,
      description: txn.description,
      referenceId: txn.referenceId,
      billAmount: bill?.finalAmount ?? 0,
      billPaid: bill?.paidAmount ?? 0,
      currentDue: _currentDue(bill),
      billPaymentStatus: bill?.paymentStatus ?? 'RECEIVED',
      isDueMarked:
          _hasDueMarker(txn.category, txn.description, txn.referenceId),
    );
  }

  bool _hasDueMarker(
      String category, String? description, String? referenceId) {
    final value = category.trim().toUpperCase();
    final desc = (description ?? '').toLowerCase();
    final ref = (referenceId ?? '').toLowerCase();
    return value.contains('DUE') || desc.contains('due') || ref.contains('due');
  }

  String _billNoFromReference(String? referenceId) {
    final ref = (referenceId ?? '').trim();
    if (ref.isEmpty) return '-';
    final hashIndex = ref.indexOf('#');
    if (hashIndex <= 0) return ref;
    return ref.substring(0, hashIndex).trim();
  }

  double _currentDue(Bill? bill) {
    if (bill == null) return 0;
    final computed = bill.finalAmount - bill.paidAmount;
    final due = bill.dueAmount > 0.5 ? bill.dueAmount : computed;
    return due < 0 ? 0 : due;
  }

  String _addressFor(Customer? customer) {
    if (customer == null) return '';
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
    return parts.join(', ');
  }

  String _firstText(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return '-';
  }
}

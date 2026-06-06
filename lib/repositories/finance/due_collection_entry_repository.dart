import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../../database/local_database/shop_database_helper.dart';
import '../../database/db/app_database.dart';
import '../../models/finance/due_collection_entry/due_collection_entry_model.dart';
import '../setting/shop_setup/shop_session_manager.dart';

class DueCollectionEntryRepository {
  final AppDatabase _db;
  final ShopDatabaseHelper _shopDbHelper = ShopDatabaseHelper();
  static const String _legacyAutoCollectionAccountNumber =
      'LOTUS-DUE-COLLECTION-LEDGER';

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
      await _syncShopProfileBankingToFinanceAccounts();
      final rows = await (_db.select(_db.bankAccounts)
            ..where((tbl) => tbl.isActive.equals(true))
            ..orderBy([
              (tbl) => OrderingTerm.desc(tbl.isPrimary),
              (tbl) => OrderingTerm.asc(tbl.accountName),
            ]))
          .get();
      return rows
          .where(_isRealPaymentAccount)
          .map(
            (row) => DueCollectionBankAccountModel(
              id: row.id,
              accountName: row.accountName,
              bankName: row.bankName,
              accountNumber: row.accountNumber,
              upiId: row.upiId,
              isPrimary: row.isPrimary,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('DueCollectionEntryRepository.fetchBankAccounts error: $e');
      return [];
    }
  }

  Future<int?> createPaymentAccount({
    required String accountName,
    required String bankName,
    required String accountNumber,
    String? holderName,
    String? ifscCode,
    String? branchName,
    String? upiId,
    bool isPrimary = false,
  }) async {
    final cleanAccountNumber = accountNumber.trim();
    if (cleanAccountNumber.isEmpty) return null;

    try {
      late final int accountId;
      await _db.transaction(() async {
        if (isPrimary) {
          await (_db.update(_db.bankAccounts))
              .write(const BankAccountsCompanion(isPrimary: Value(false)));
        }

        final existing = await (_db.select(_db.bankAccounts)
              ..where((tbl) => tbl.accountNumber.equals(cleanAccountNumber))
              ..limit(1))
            .getSingleOrNull();

        final companion = BankAccountsCompanion(
          accountName: Value(accountName.trim().isEmpty
              ? 'Collection Account'
              : accountName.trim()),
          bankName: Value(bankName.trim().isEmpty ? 'Bank' : bankName.trim()),
          holderName: Value(_nullable(holderName)),
          accountNumber: Value(cleanAccountNumber),
          ifscCode: Value(_nullable(ifscCode)?.toUpperCase()),
          branchName: Value(_nullable(branchName)),
          upiId: Value(_nullable(upiId)),
          accountType: const Value('CURRENT'),
          openingBalance: const Value(0),
          isActive: const Value(true),
          isPrimary: Value(isPrimary || existing?.isPrimary == true),
          colorHex: const Value('#D4AF37'),
          activeSince: Value(DateTime.now()),
        );

        if (existing != null) {
          await (_db.update(_db.bankAccounts)
                ..where((tbl) => tbl.id.equals(existing.id)))
              .write(companion);
          accountId = existing.id;
        } else {
          accountId = await _db.into(_db.bankAccounts).insert(companion);
        }
      });

      await _syncPaymentAccountToShopProfile(
        financeAccountId: accountId,
        accountName: accountName,
        bankName: bankName,
        accountNumber: cleanAccountNumber,
        holderName: holderName,
        ifscCode: ifscCode,
        branchName: branchName,
        upiId: upiId,
        isPrimary: isPrimary,
      );
      return accountId;
    } catch (e) {
      debugPrint('DueCollectionEntryRepository.createPaymentAccount error: $e');
      return null;
    }
  }

  Future<bool> updatePaymentAccountUpi({
    required int accountId,
    required String upiId,
  }) async {
    final cleanUpi = upiId.trim();
    if (cleanUpi.isEmpty) return false;

    try {
      final account = await (_db.select(_db.bankAccounts)
            ..where((tbl) => tbl.id.equals(accountId))
            ..limit(1))
          .getSingleOrNull();
      if (account == null) return false;

      await (_db.update(_db.bankAccounts)
            ..where((tbl) => tbl.id.equals(accountId)))
          .write(BankAccountsCompanion(upiId: Value(cleanUpi)));

      await _syncPaymentAccountToShopProfile(
        financeAccountId: account.id,
        accountName: account.accountName,
        bankName: account.bankName,
        accountNumber: account.accountNumber,
        holderName: account.holderName,
        ifscCode: account.ifscCode,
        branchName: account.branchName,
        upiId: cleanUpi,
        isPrimary: account.isPrimary,
      );
      return true;
    } catch (e) {
      debugPrint(
          'DueCollectionEntryRepository.updatePaymentAccountUpi error: $e');
      return false;
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
              message: 'Please set your bank/UPI details first.',
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
            updatedAt: Value(now),
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
        OrderingTerm.desc(_db.bills.billDate),
        OrderingTerm.desc(_db.bills.id),
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
      final dateCompare = b.billDate.compareTo(a.billDate);
      if (dateCompare != 0) return dateCompare;
      return b.id.compareTo(a.id);
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
    final accounts = await (_db.select(_db.bankAccounts)
          ..where((tbl) => tbl.isActive.equals(true))
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.isPrimary),
            (tbl) => OrderingTerm.asc(tbl.id),
          ]))
        .get();
    for (final account in accounts) {
      if (_isRealPaymentAccount(account)) return account.id;
    }
    return null;
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

  Future<void> _syncPaymentAccountToShopProfile({
    required int financeAccountId,
    required String accountName,
    required String bankName,
    required String accountNumber,
    required String? holderName,
    required String? ifscCode,
    required String? branchName,
    required String? upiId,
    required bool isPrimary,
  }) async {
    try {
      final tenantId = await ShopSessionManager.getPermanentTenantId();
      final db = await _shopDbHelper.database;
      final existingRows = await db.query(
        'shop_bank_accounts',
        where: 'tenant_id = ? AND acc = ?',
        whereArgs: [tenantId, accountNumber],
        limit: 1,
      );
      final existing = existingRows.isEmpty ? null : existingRows.first;
      final rowId = isPrimary
          ? 'primary_1'
          : existing?['id']?.toString() ?? 'finance_$financeAccountId';
      final title = isPrimary
          ? 'Primary Operating Account'
          : (accountName.trim().isEmpty
              ? 'Additional Account'
              : accountName.trim());

      await db.insert(
        'shop_bank_accounts',
        {
          'id': rowId,
          'tenant_id': tenantId,
          'title': title,
          'holder': _nullable(holderName) ?? '',
          'bank': bankName.trim(),
          'type': 'Current',
          'acc': accountNumber,
          'ifsc': _nullable(ifscCode) ?? '',
          'branch': _nullable(branchName) ?? '',
          'upi': _nullable(upiId) ?? '',
          'qr_image_path': existing?['qr_image_path'],
          'is_active': 1,
        },
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );

      if (isPrimary) {
        final existingProfile =
            await (_db.select(_db.shopProfiles)..limit(1)).getSingleOrNull();
        final companion = ShopProfilesCompanion(
          bankHolderName: Value(_nullable(holderName)),
          bankName: Value(bankName.trim()),
          bankAccNo: Value(accountNumber),
          bankIfsc: Value(_nullable(ifscCode)),
          upiId: Value(_nullable(upiId)),
        );
        if (existingProfile != null) {
          await (_db.update(_db.shopProfiles)
                ..where((tbl) => tbl.id.equals(existingProfile.id)))
              .write(companion);
        }
      }
    } catch (e) {
      debugPrint(
          'DueCollectionEntryRepository._syncPaymentAccountToShopProfile error: $e');
    }
  }

  Future<void> _syncShopProfileBankingToFinanceAccounts() async {
    try {
      final tenantId = await ShopSessionManager.getPermanentTenantId();
      final shopDb = await _shopDbHelper.database;
      final rows = await shopDb.query(
        'shop_bank_accounts',
        where: 'tenant_id = ? AND is_active = 1',
        whereArgs: [tenantId],
      );
      if (rows.isEmpty) return;
      final sortedRows = _sortShopBankRows(rows);

      await (_db.update(_db.bankAccounts))
          .write(const BankAccountsCompanion(isPrimary: Value(false)));

      for (var index = 0; index < sortedRows.length; index++) {
        final row = sortedRows[index];
        final accountNumber = _shopAccountNumber(row);
        if (accountNumber.isEmpty ||
            accountNumber == _legacyAutoCollectionAccountNumber) {
          continue;
        }

        final existing = await (_db.select(_db.bankAccounts)
              ..where((tbl) => tbl.accountNumber.equals(accountNumber))
              ..limit(1))
            .getSingleOrNull();

        final title = _rowText(row, 'title');
        final bankName = _rowText(row, 'bank');
        final companion = BankAccountsCompanion(
          accountName: Value(title.isEmpty
              ? (index == 0
                  ? 'Primary Operating Account'
                  : 'Additional Account ${index + 1}')
              : title),
          bankName: Value(bankName.isEmpty ? 'Bank' : bankName),
          holderName: Value(_nullable(_rowText(row, 'holder'))),
          accountNumber: Value(accountNumber),
          ifscCode: Value(_nullable(_rowText(row, 'ifsc'))?.toUpperCase()),
          branchName: Value(_nullable(_rowText(row, 'branch'))),
          upiId: Value(_nullable(_rowText(row, 'upi'))),
          accountType: Value(_financeAccountType(_rowText(row, 'type'))),
          openingBalance: const Value(0),
          isActive: const Value(true),
          isPrimary: Value(index == 0),
          colorHex: const Value('#D4AF37'),
          activeSince: Value(DateTime.now()),
        );

        if (existing != null) {
          await (_db.update(_db.bankAccounts)
                ..where((tbl) => tbl.id.equals(existing.id)))
              .write(companion);
        } else {
          await _db.into(_db.bankAccounts).insert(companion);
        }
      }
    } catch (e) {
      debugPrint(
          'DueCollectionEntryRepository._syncShopProfileBankingToFinanceAccounts error: $e');
    }
  }

  bool _isRealPaymentAccount(BankAccount account) {
    return account.accountNumber != _legacyAutoCollectionAccountNumber &&
        account.accountName.trim().toLowerCase() != 'counter collection';
  }

  String _shopAccountNumber(Map<String, Object?> row) {
    final acc = _rowText(row, 'acc');
    if (acc.isNotEmpty) return acc;
    final upi = _rowText(row, 'upi');
    if (upi.isNotEmpty) return 'UPI:$upi';
    return '';
  }

  List<Map<String, Object?>> _sortShopBankRows(
      List<Map<String, Object?>> rows) {
    final sorted = List<Map<String, Object?>>.from(rows);
    sorted.sort((a, b) {
      final aPrimary = _rowText(a, 'id') == 'primary_1';
      final bPrimary = _rowText(b, 'id') == 'primary_1';
      if (aPrimary != bPrimary) return aPrimary ? -1 : 1;
      return _rowText(a, 'title').compareTo(_rowText(b, 'title'));
    });
    return sorted;
  }

  String _rowText(Map<String, Object?> row, String key) {
    return row[key]?.toString().trim() ?? '';
  }

  String _financeAccountType(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('saving')) return 'SAVINGS';
    if (normalized.contains('od') || normalized.contains('cc')) return 'OD';
    return 'CURRENT';
  }

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

  String? _nullable(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

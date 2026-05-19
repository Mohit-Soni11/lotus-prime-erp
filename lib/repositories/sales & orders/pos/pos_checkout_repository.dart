import 'package:drift/drift.dart' show OrderingTerm, Value;

import '../../../database/db/app_database.dart';
import '../../../models/finance/bank_book/bank_book_enums.dart' as bank_book;
import '../../../models/finance/cash_book/cash_book_enums.dart' as cash_book;
import '../../../models/sales & orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/sales & orders/sales_pos_models/pos_invoice_model.dart';
import '../../../models/sales & orders/sales_pos_models/sales_pos_models.dart';
import '../../../models/stock/stock_item_model/stock_enums.dart' as stock;

class PosCheckoutCommitResult {
  final int billId;
  final String invoiceNumber;
  final int invoiceSequence;

  const PosCheckoutCommitResult({
    required this.billId,
    required this.invoiceNumber,
    required this.invoiceSequence,
  });
}

class PosCheckoutRepository {
  final AppDatabase _db;

  PosCheckoutRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  Future<int> fetchNextInvoiceSequence({
    required String invoicePrefix,
    required String shopInitials,
    required String financialYear,
  }) async {
    final resolved = await _resolveInvoiceNumber(
      invoicePrefix: invoicePrefix,
      shopInitials: shopInitials,
      financialYear: financialYear,
    );
    return resolved.sequence;
  }

  Future<PosCheckoutCommitResult> finalizeSale({
    required PosInvoiceModel invoice,
    required int? customerId,
  }) async {
    return _db.transaction(() async {
      final resolved = await _resolveInvoiceNumber(
        invoicePrefix: _invoicePrefixFromBillNo(invoice.invoiceNumber),
        shopInitials: _shopInitialsFromBillNo(invoice.invoiceNumber),
        financialYear: _financialYearFromBillNo(invoice.invoiceNumber),
        preferredInvoiceNumber: invoice.invoiceNumber,
      );

      final billId = await _db.into(_db.bills).insert(
            BillsCompanion(
              billNo: Value(resolved.billNumber),
              customerId: Value(customerId),
              customerName: Value(
                invoice.customerName.trim().isNotEmpty
                    ? invoice.customerName.trim()
                    : null,
              ),
              mobile: Value(
                invoice.customerMobile.trim().isNotEmpty
                    ? invoice.customerMobile.trim()
                    : null,
              ),
              billingMode: Value(_dbBillingMode(invoice.billingMode)),
              billType: Value(_dbBillType(invoice.billType)),
              paymentStatus: Value(_resolvePaymentStatus(invoice)),
              totalAmount: Value(invoice.grossAmount),
              discount: Value(invoice.discountAmount),
              taxableAmount: Value(invoice.taxableAmount),
              cgstAmount: Value(invoice.cgst),
              sgstAmount: Value(invoice.sgst),
              gstAmount: Value(invoice.totalGst),
              makingTotal: Value(invoice.totalMakingCharge),
              finalAmount: Value(invoice.netPayable),
              paidAmount: Value(invoice.totalPaid),
              cashPaid: Value(invoice.cashPaid),
              upiPaid: Value(invoice.upiPaid),
              cardPaid: Value(invoice.cardPaid),
              advancePaid: Value(invoice.advancePaid),
              dueAmount: Value(_dueAmount(invoice)),
              oldGoldDeduction: Value(invoice.totalOldGoldDeduction),
              oldGoldMode: Value(_dbOldGoldMode(invoice.oldGoldMode)),
              billDate: Value(invoice.invoiceDate),
              promiseDate: Value(invoice.promiseDate),
              status: const Value('ACTIVE'),
            ),
          );

      for (var index = 0; index < invoice.saleItems.length; index++) {
        final item = invoice.saleItems[index];
        final itemName = item.descCtrl.text.trim().isNotEmpty
            ? item.descCtrl.text.trim()
            : item.metal.displayName;

        await _db.into(_db.billItems).insert(
              BillItemsCompanion(
                billId: Value(billId),
                lineNo: Value(index + 1),
                metalType: Value(item.metal.displayName),
                itemName: Value(itemName),
                huid: Value(
                  item.huidCtrl.text.trim().isNotEmpty
                      ? item.huidCtrl.text.trim()
                      : null,
                ),
                purity: Value(
                  item.purityCtrl.text.trim().isNotEmpty
                      ? item.purityCtrl.text.trim()
                      : '-',
                ),
                quantity: Value(item.pcs),
                grossWeight: Value(_parseSafeNumber(item.grossCtrl.text)),
                lessWeight: Value(_parseSafeNumber(item.lessCtrl.text)),
                lessWeightPerPiece: Value(item.isLessPerPiece),
                netWeight: Value(item.netWt),
                fineWeight: Value(item.fineWt),
                rate: Value(item.rate),
                makingChargeType: Value(
                  _dbMakingChargeType(item.makingChargeType),
                ),
                makingChargeInput: Value(
                  _parseSafeNumber(item.makingCtrl.text),
                ),
                makingCharge: Value(item.makingAmt),
                itemTotal: Value(item.totalValue),
                linkedStockItemId: Value(item.linkedStockItemId),
                linkedStockSku: Value(item.linkedStockSku),
              ),
            );
      }

      await _persistOldGoldItems(
        billId: billId,
        oldGoldItems: invoice.oldGoldItems,
      );
      await _consumeLinkedStock(invoice.saleItems);
      await _postSalePaymentLedgerEntries(
        invoice: invoice,
        billNumber: resolved.billNumber,
      );

      return PosCheckoutCommitResult(
        billId: billId,
        invoiceNumber: resolved.billNumber,
        invoiceSequence: resolved.sequence,
      );
    });
  }

  Future<void> _postSalePaymentLedgerEntries({
    required PosInvoiceModel invoice,
    required String billNumber,
  }) async {
    final customerName = invoice.customerName.trim().isEmpty
        ? 'Walk-in Customer'
        : invoice.customerName.trim();

    if (invoice.cashPaid > 0) {
      await _insertCashIncome(
        amount: invoice.cashPaid,
        paymentMode: cash_book.PaymentMode.cash,
        billNumber: billNumber,
        partyName: customerName,
        txnDate: invoice.invoiceDate,
      );
    }

    final preferredBankAccountId = await _findPreferredBankAccountId();

    if (invoice.upiPaid > 0) {
      if (preferredBankAccountId != null) {
        await _insertBankIncome(
          accountId: preferredBankAccountId,
          amount: invoice.upiPaid,
          paymentMode: bank_book.BankPaymentMode.upi,
          billNumber: billNumber,
          partyName: customerName,
          txnDate: invoice.invoiceDate,
        );
      } else {
        await _insertCashIncome(
          amount: invoice.upiPaid,
          paymentMode: cash_book.PaymentMode.upi,
          billNumber: billNumber,
          partyName: customerName,
          txnDate: invoice.invoiceDate,
        );
      }
    }

    if (invoice.cardPaid > 0) {
      if (preferredBankAccountId != null) {
        await _insertBankIncome(
          accountId: preferredBankAccountId,
          amount: invoice.cardPaid,
          paymentMode: bank_book.BankPaymentMode.card,
          billNumber: billNumber,
          partyName: customerName,
          txnDate: invoice.invoiceDate,
        );
      } else {
        await _insertCashIncome(
          amount: invoice.cardPaid,
          paymentMode: cash_book.PaymentMode.card,
          billNumber: billNumber,
          partyName: customerName,
          txnDate: invoice.invoiceDate,
        );
      }
    }
  }

  Future<void> _consumeLinkedStock(List<SaleItemModel> saleItems) async {
    final stockUsage = <int, int>{};

    for (final item in saleItems) {
      final stockItemId = item.linkedStockItemId;
      if (stockItemId == null) {
        continue;
      }

      stockUsage.update(
        stockItemId,
        (current) => current + _unitsForItem(item),
        ifAbsent: () => _unitsForItem(item),
      );
    }

    for (final entry in stockUsage.entries) {
      await _deductStock(
        stockItemId: entry.key,
        quantityToSell: entry.value,
      );
    }
  }

  Future<void> _persistOldGoldItems({
    required int billId,
    required List<OldGoldItemModel> oldGoldItems,
  }) async {
    for (var index = 0; index < oldGoldItems.length; index++) {
      final item = oldGoldItems[index];
      await _db.into(_db.billOldGoldItems).insert(
            BillOldGoldItemsCompanion(
              billId: Value(billId),
              lineNo: Value(index + 1),
              metalType: Value(item.metal.displayName),
              itemDescription: Value(item.descCtrl.text.trim()),
              grossWeight: Value(_parseSafeNumber(item.grossCtrl.text)),
              lessWeight: Value(_parseSafeNumber(item.lessCtrl.text)),
              netWeight: Value(item.netWt),
              purity: Value(_parseSafeNumber(item.purityCtrl.text)),
              fineWeight: Value(item.fineWt),
              rate: Value(item.rate),
              lineAmount: Value(item.totalValue),
            ),
          );
    }
  }

  int _unitsForItem(SaleItemModel item) {
    return item.pcs < 1 ? 1 : item.pcs;
  }

  Future<void> _deductStock({
    required int stockItemId,
    required int quantityToSell,
  }) async {
    final stockRow = await (_db.select(_db.stockItems)
          ..where((tbl) => tbl.id.equals(stockItemId)))
        .getSingleOrNull();

    if (stockRow == null) {
      throw StateError(
        'Selected stock item #$stockItemId no longer exists.',
      );
    }

    final isAvailable = stockRow.isActive &&
        stockRow.status == stock.StockStatus.available.label;
    if (!isAvailable) {
      throw StateError(
        'Stock item ${stockRow.sku} is no longer available for sale.',
      );
    }

    if (stockRow.quantity < quantityToSell) {
      throw StateError(
        'Only ${stockRow.quantity} unit(s) left for ${stockRow.sku}.',
      );
    }

    final remainingQty = stockRow.quantity - quantityToSell;
    await (_db.update(_db.stockItems)
          ..where((tbl) => tbl.id.equals(stockItemId)))
        .write(
      StockItemsCompanion(
        quantity: Value(remainingQty),
        isActive: Value(remainingQty > 0),
        status: Value(
          remainingQty > 0
              ? stock.StockStatus.available.label
              : stock.StockStatus.sold.label,
        ),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<_ResolvedInvoiceNumber> _resolveInvoiceNumber({
    required String invoicePrefix,
    required String shopInitials,
    required String financialYear,
    String? preferredInvoiceNumber,
  }) async {
    final pattern = _invoicePattern(
      invoicePrefix: invoicePrefix,
      shopInitials: shopInitials,
      financialYear: financialYear,
    );
    final bills = await _db.select(_db.bills).get();

    if (preferredInvoiceNumber != null &&
        !_billNumberExists(bills, preferredInvoiceNumber)) {
      final preferredSequence = _parseSequence(preferredInvoiceNumber, pattern);
      if (preferredSequence != null) {
        return _ResolvedInvoiceNumber(
          billNumber: preferredInvoiceNumber,
          sequence: preferredSequence,
        );
      }
    }

    var maxSequence = 0;
    for (final bill in bills) {
      final parsedSequence = _parseSequence(bill.billNo, pattern);
      if (parsedSequence != null && parsedSequence > maxSequence) {
        maxSequence = parsedSequence;
      }
    }

    final nextSequence = maxSequence + 1;
    return _ResolvedInvoiceNumber(
      billNumber: _buildBillNumber(
        invoicePrefix: invoicePrefix,
        shopInitials: shopInitials,
        financialYear: financialYear,
        sequence: nextSequence,
      ),
      sequence: nextSequence,
    );
  }

  bool _billNumberExists(List<Bill> bills, String billNumber) {
    return bills.any((bill) => bill.billNo == billNumber);
  }

  RegExp _invoicePattern({
    required String invoicePrefix,
    required String shopInitials,
    required String financialYear,
  }) {
    return RegExp(
      '^${RegExp.escape(invoicePrefix)}-${RegExp.escape(shopInitials)}-${RegExp.escape(financialYear)}-(\\d+)\$',
    );
  }

  int? _parseSequence(String billNumber, RegExp pattern) {
    final match = pattern.firstMatch(billNumber);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1) ?? '');
  }

  String _buildBillNumber({
    required String invoicePrefix,
    required String shopInitials,
    required String financialYear,
    required int sequence,
  }) {
    return '$invoicePrefix-$shopInitials-$financialYear-${sequence.toString().padLeft(4, '0')}';
  }

  String _invoicePrefixFromBillNo(String billNumber) {
    final parts = billNumber.split('-');
    return parts.isNotEmpty ? parts.first : 'INV';
  }

  String _shopInitialsFromBillNo(String billNumber) {
    final parts = billNumber.split('-');
    return parts.length > 1 ? parts[1] : 'SH';
  }

  String _financialYearFromBillNo(String billNumber) {
    final parts = billNumber.split('-');
    return parts.length > 2 ? parts[2] : DateTime.now().year.toString();
  }

  double _parseSafeNumber(String text) {
    if (text.trim().isEmpty) {
      return 0.0;
    }
    final cleanText = text.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanText) ?? 0.0;
  }

  double _dueAmount(PosInvoiceModel invoice) {
    return invoice.balanceDue > 0.5 ? invoice.balanceDue : 0.0;
  }

  String _resolvePaymentStatus(PosInvoiceModel invoice) {
    if (invoice.netPayable < 0 || invoice.balanceDue < -0.5) {
      return 'CREDIT';
    }
    if (invoice.totalPaid <= 0.005) {
      return 'UNPAID';
    }
    if (invoice.balanceDue > 0.5) {
      return 'PARTIAL';
    }
    return 'PAID';
  }

  String _dbBillingMode(BillingMode mode) {
    return mode == BillingMode.retail ? 'RETAIL' : 'WHOLESALE';
  }

  String _dbBillType(BillType type) {
    return type == BillType.gst ? 'GST' : 'NORMAL';
  }

  String _dbOldGoldMode(OldGoldAdjustMode mode) {
    return mode == OldGoldAdjustMode.cashAdjust
        ? 'CASH_ADJUST'
        : 'METAL_ADJUST';
  }

  String _dbMakingChargeType(MakingChargeType type) {
    switch (type) {
      case MakingChargeType.percentage:
        return 'PERCENTAGE';
      case MakingChargeType.perGram:
        return 'PER_GRAM';
      case MakingChargeType.perKg:
        return 'PER_KG';
      case MakingChargeType.perPiece:
        return 'PER_PIECE';
    }
  }

  Future<void> _insertCashIncome({
    required double amount,
    required cash_book.PaymentMode paymentMode,
    required String billNumber,
    required String partyName,
    required DateTime txnDate,
  }) async {
    final txnId = await _generateCashTxnId();
    await _db.into(_db.cashTransactions).insert(
          CashTransactionsCompanion.insert(
            txnId: txnId,
            txnDate: txnDate,
            type: cash_book.CashTransactionType.income.dbValue,
            category: cash_book.IncomeCategory.sale.dbValue,
            amount: Value(amount),
            paymentMode: Value(paymentMode.dbValue),
            description: Value('Sale receipt against $billNumber'),
            referenceId:
                Value(_buildLedgerReferenceId(billNumber, paymentMode.dbValue)),
            referenceType: const Value('BILL'),
            partyName: Value(partyName),
            isAutoGenerated: const Value(true),
            isVoided: const Value(false),
          ),
        );
  }

  Future<void> _insertBankIncome({
    required int accountId,
    required double amount,
    required bank_book.BankPaymentMode paymentMode,
    required String billNumber,
    required String partyName,
    required DateTime txnDate,
  }) async {
    final txnId = await _generateBankTxnId();
    await _db.into(_db.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: txnId,
            accountId: accountId,
            txnDate: txnDate,
            type: bank_book.BankTransactionType.credit.dbValue,
            category: bank_book.BankCreditCategory.salePayment.dbValue,
            amount: Value(amount),
            paymentMode: Value(paymentMode.dbValue),
            description: Value('Sale receipt against $billNumber'),
            referenceId:
                Value(_buildLedgerReferenceId(billNumber, paymentMode.dbValue)),
            referenceType: const Value('BILL'),
            partyName: Value(partyName),
            isAutoGenerated: const Value(true),
            isVoided: const Value(false),
          ),
        );
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

  String _buildLedgerReferenceId(String billNumber, String paymentMode) {
    return '$billNumber#$paymentMode';
  }
}

class _ResolvedInvoiceNumber {
  final String billNumber;
  final int sequence;

  const _ResolvedInvoiceNumber({
    required this.billNumber,
    required this.sequence,
  });
}

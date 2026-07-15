import 'package:drift/drift.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import '../../../features/sales_pos/domain/services/pos_number_formatter.dart';
import '../../../features/sales_pos/domain/services/pos_number_parser.dart';
import '../../../models/finance/bank_book/bank_book_enums.dart' as bank_book;
import '../../../models/finance/cash_book/cash_book_enums.dart' as cash_book;
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../models/sales_orders/sales_pos_models/sales_pos_models.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart'
    as stock;

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

class PosEditableBill {
  const PosEditableBill({
    required this.bill,
    required this.items,
    required this.oldGoldItems,
  });

  final Bill bill;
  final List<BillItem> items;
  final List<BillOldGoldItem> oldGoldItems;
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
    int? sourceAdvanceOrderId,
    String? sourceAdvanceOrderNo,
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
              sourceAdvanceOrderId: Value(sourceAdvanceOrderId),
              sourceAdvanceOrderNo: Value(_nullable(sourceAdvanceOrderNo)),
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
                linkedStockUnitId: Value(item.linkedStockUnitId),
                linkedStockSku: Value(item.linkedStockSku),
                stockUnitCost: Value(item.linkedStockUnitCost),
                stockProfitAmount: Value(item.stockProfitAmount),
              ),
            );
      }

      await _persistOldGoldItems(
        billId: billId,
        oldGoldItems: invoice.oldGoldItems,
      );
      await _consumeLinkedStock(
        invoice.saleItems,
        sourceId: billId.toString(),
        sourceNumber: resolved.billNumber,
      );
      await _postSalePaymentLedgerEntries(
        invoice: invoice,
        billNumber: resolved.billNumber,
      );
      await _postCustomerAccountCreditEntry(
        invoice: invoice,
        billNumber: resolved.billNumber,
        customerId: customerId,
      );
      await _postCustomerChangeReturnFinanceEntries(
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

  Future<PosEditableBill?> fetchEditableBill(int billId) async {
    final bill = await (_db.select(_db.bills)
          ..where((tbl) => tbl.id.equals(billId)))
        .getSingleOrNull();
    if (bill == null) return null;

    final items = await (_db.select(_db.billItems)
          ..where((tbl) => tbl.billId.equals(billId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.lineNo)]))
        .get();
    final oldGoldItems = await (_db.select(_db.billOldGoldItems)
          ..where((tbl) => tbl.billId.equals(billId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.lineNo)]))
        .get();

    return PosEditableBill(
      bill: bill,
      items: items,
      oldGoldItems: oldGoldItems,
    );
  }

  Future<List<SaleItemModel>> fetchPrintableSaleItems(int billId) async {
    final rows = await (_db.select(_db.billItems)
          ..where((tbl) => tbl.billId.equals(billId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.lineNo)]))
        .get();

    return rows.map(_saleItemFromBillItem).toList(growable: false);
  }

  Future<void> updateSale({
    required int billId,
    required PosInvoiceModel invoice,
    required int? customerId,
  }) async {
    await _db.transaction(() async {
      final existingBill = await (_db.select(_db.bills)
            ..where((tbl) => tbl.id.equals(billId)))
          .getSingleOrNull();
      if (existingBill == null) {
        throw StateError('Sales bill #$billId no longer exists.');
      }

      final existingItems = await (_db.select(_db.billItems)
            ..where((tbl) => tbl.billId.equals(billId)))
          .get();

      await _restoreLinkedStock(
        existingItems,
        sourceId: billId.toString(),
        sourceNumber: existingBill.billNo,
      );
      await _voidAutoGeneratedSalePaymentEntries(existingBill.billNo);
      await _voidAutoGeneratedCustomerAccountEntries(existingBill.billNo);
      await _voidAutoGeneratedCustomerChangeEntries(existingBill.billNo);
      if (existingBill.billNo != invoice.invoiceNumber) {
        await _voidAutoGeneratedSalePaymentEntries(invoice.invoiceNumber);
        await _voidAutoGeneratedCustomerAccountEntries(invoice.invoiceNumber);
        await _voidAutoGeneratedCustomerChangeEntries(invoice.invoiceNumber);
      }

      await (_db.update(_db.bills)..where((tbl) => tbl.id.equals(billId)))
          .write(
        BillsCompanion(
          billNo: Value(invoice.invoiceNumber),
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
          updatedAt: Value(DateTime.now()),
        ),
      );

      await (_db.delete(_db.billItems)
            ..where((tbl) => tbl.billId.equals(billId)))
          .go();
      await (_db.delete(_db.billOldGoldItems)
            ..where((tbl) => tbl.billId.equals(billId)))
          .go();

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
                linkedStockUnitId: Value(item.linkedStockUnitId),
                linkedStockSku: Value(item.linkedStockSku),
                stockUnitCost: Value(item.linkedStockUnitCost),
                stockProfitAmount: Value(item.stockProfitAmount),
              ),
            );
      }

      await _persistOldGoldItems(
        billId: billId,
        oldGoldItems: invoice.oldGoldItems,
      );
      await _consumeLinkedStock(
        invoice.saleItems,
        sourceId: billId.toString(),
        sourceNumber: invoice.invoiceNumber,
      );
      await _postSalePaymentLedgerEntries(
        invoice: invoice,
        billNumber: invoice.invoiceNumber,
      );
      await _postCustomerAccountCreditEntry(
        invoice: invoice,
        billNumber: invoice.invoiceNumber,
        customerId: customerId,
      );
      await _postCustomerChangeReturnFinanceEntries(
        invoice: invoice,
        billNumber: invoice.invoiceNumber,
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

  Future<void> _postCustomerAccountCreditEntry({
    required PosInvoiceModel invoice,
    required String billNumber,
    required int? customerId,
  }) async {
    final amount = invoice.changeSettlementAmount;
    if (invoice.changeSettlementMethod != RefundMethod.accountCredit ||
        amount <= 0.005) {
      return;
    }
    if (customerId == null) {
      throw StateError(
        'Select a customer before adding excess payment to customer account.',
      );
    }

    final customerName = invoice.customerName.trim().isEmpty
        ? 'Walk-in Customer'
        : invoice.customerName.trim();
    final sourceReference = _buildCustomerAccountReferenceId(billNumber);
    final paymentMode = invoice.changeSettlementPaymentMode ?? PaymentMode.cash;

    await _db.into(_db.customerAccountLedger).insert(
          CustomerAccountLedgerCompanion.insert(
            customerId: customerId,
            entryType: 'CREDIT',
            sourceType: 'POS_CHANGE_CREDIT',
            sourceReference: Value(sourceReference),
            amount: Value(amount),
            paymentMode: Value(paymentMode.displayName),
            notes: Value(
              'Excess payment kept as customer account credit against $billNumber',
            ),
            entryDate: Value(invoice.invoiceDate),
            isVoided: const Value(false),
          ),
        );

    await _postCustomerCreditFinanceEntry(
      amount: amount,
      paymentMode: paymentMode,
      billNumber: billNumber,
      sourceReference: sourceReference,
      partyName: customerName,
      txnDate: invoice.invoiceDate,
    );
  }

  Future<void> _postCustomerCreditFinanceEntry({
    required double amount,
    required PaymentMode paymentMode,
    required String billNumber,
    required String sourceReference,
    required String partyName,
    required DateTime txnDate,
  }) async {
    final preferredBankAccountId = await _findPreferredBankAccountId();
    switch (paymentMode) {
      case PaymentMode.cash:
        await _insertCashIncome(
          amount: amount,
          paymentMode: cash_book.PaymentMode.cash,
          billNumber: billNumber,
          partyName: partyName,
          txnDate: txnDate,
          category: cash_book.IncomeCategory.advanceBooking,
          description: 'Customer account credit against $billNumber',
          referenceId: '$sourceReference#CASH',
          referenceType: 'CUSTOMER_ACCOUNT',
        );
        break;
      case PaymentMode.upi:
        if (preferredBankAccountId != null) {
          await _insertBankIncome(
            accountId: preferredBankAccountId,
            amount: amount,
            paymentMode: bank_book.BankPaymentMode.upi,
            billNumber: billNumber,
            partyName: partyName,
            txnDate: txnDate,
            category: bank_book.BankCreditCategory.advanceReceived,
            description: 'Customer account credit against $billNumber',
            referenceId: '$sourceReference#UPI',
            referenceType: 'CUSTOMER_ACCOUNT',
          );
        } else {
          await _insertCashIncome(
            amount: amount,
            paymentMode: cash_book.PaymentMode.upi,
            billNumber: billNumber,
            partyName: partyName,
            txnDate: txnDate,
            category: cash_book.IncomeCategory.advanceBooking,
            description: 'Customer account credit against $billNumber',
            referenceId: '$sourceReference#UPI',
            referenceType: 'CUSTOMER_ACCOUNT',
          );
        }
        break;
      case PaymentMode.card:
        if (preferredBankAccountId != null) {
          await _insertBankIncome(
            accountId: preferredBankAccountId,
            amount: amount,
            paymentMode: bank_book.BankPaymentMode.card,
            billNumber: billNumber,
            partyName: partyName,
            txnDate: txnDate,
            category: bank_book.BankCreditCategory.advanceReceived,
            description: 'Customer account credit against $billNumber',
            referenceId: '$sourceReference#CARD',
            referenceType: 'CUSTOMER_ACCOUNT',
          );
        } else {
          await _insertCashIncome(
            amount: amount,
            paymentMode: cash_book.PaymentMode.card,
            billNumber: billNumber,
            partyName: partyName,
            txnDate: txnDate,
            category: cash_book.IncomeCategory.advanceBooking,
            description: 'Customer account credit against $billNumber',
            referenceId: '$sourceReference#CARD',
            referenceType: 'CUSTOMER_ACCOUNT',
          );
        }
        break;
      case PaymentMode.advance:
        break;
    }
  }

  Future<void> _postCustomerChangeReturnFinanceEntries({
    required PosInvoiceModel invoice,
    required String billNumber,
  }) async {
    final amount = invoice.changeSettlementAmount;
    final returnMethod = invoice.changeSettlementMethod;
    if (returnMethod == null ||
        returnMethod == RefundMethod.accountCredit ||
        amount <= 0.005) {
      return;
    }

    final returnPaymentMode = switch (returnMethod) {
      RefundMethod.cash => PaymentMode.cash,
      RefundMethod.upi => PaymentMode.upi,
      RefundMethod.accountCredit => PaymentMode.cash,
    };
    final sourcePaymentMode =
        invoice.changeSettlementPaymentMode ?? returnPaymentMode;

    if (sourcePaymentMode == returnPaymentMode) {
      return;
    }

    final customerName = invoice.customerName.trim().isEmpty
        ? 'Walk-in Customer'
        : invoice.customerName.trim();
    final sourceReference = _buildCustomerChangeReferenceId(billNumber);

    await _postChangeSourceInflow(
      amount: amount,
      paymentMode: sourcePaymentMode,
      billNumber: billNumber,
      sourceReference: sourceReference,
      partyName: customerName,
      txnDate: invoice.invoiceDate,
    );
    await _postChangeReturnOutflow(
      amount: amount,
      paymentMode: returnPaymentMode,
      billNumber: billNumber,
      sourceReference: sourceReference,
      partyName: customerName,
      txnDate: invoice.invoiceDate,
    );
  }

  Future<void> _postChangeSourceInflow({
    required double amount,
    required PaymentMode paymentMode,
    required String billNumber,
    required String sourceReference,
    required String partyName,
    required DateTime txnDate,
  }) async {
    final preferredBankAccountId = await _findPreferredBankAccountId();
    switch (paymentMode) {
      case PaymentMode.cash:
        await _insertCashIncome(
          amount: amount,
          paymentMode: cash_book.PaymentMode.cash,
          billNumber: billNumber,
          partyName: partyName,
          txnDate: txnDate,
          category: cash_book.IncomeCategory.miscIncome,
          description: 'Excess cash received before change return',
          referenceId: '$sourceReference#SOURCE_CASH',
          referenceType: 'CUSTOMER_CHANGE',
        );
        break;
      case PaymentMode.upi:
        if (preferredBankAccountId != null) {
          await _insertBankIncome(
            accountId: preferredBankAccountId,
            amount: amount,
            paymentMode: bank_book.BankPaymentMode.upi,
            billNumber: billNumber,
            partyName: partyName,
            txnDate: txnDate,
            category: bank_book.BankCreditCategory.miscCredit,
            description: 'Excess UPI received before change return',
            referenceId: '$sourceReference#SOURCE_UPI',
            referenceType: 'CUSTOMER_CHANGE',
          );
        } else {
          await _insertCashIncome(
            amount: amount,
            paymentMode: cash_book.PaymentMode.upi,
            billNumber: billNumber,
            partyName: partyName,
            txnDate: txnDate,
            category: cash_book.IncomeCategory.miscIncome,
            description: 'Excess UPI received before change return',
            referenceId: '$sourceReference#SOURCE_UPI',
            referenceType: 'CUSTOMER_CHANGE',
          );
        }
        break;
      case PaymentMode.card:
        if (preferredBankAccountId != null) {
          await _insertBankIncome(
            accountId: preferredBankAccountId,
            amount: amount,
            paymentMode: bank_book.BankPaymentMode.card,
            billNumber: billNumber,
            partyName: partyName,
            txnDate: txnDate,
            category: bank_book.BankCreditCategory.miscCredit,
            description: 'Excess card payment received before change return',
            referenceId: '$sourceReference#SOURCE_CARD',
            referenceType: 'CUSTOMER_CHANGE',
          );
        } else {
          await _insertCashIncome(
            amount: amount,
            paymentMode: cash_book.PaymentMode.card,
            billNumber: billNumber,
            partyName: partyName,
            txnDate: txnDate,
            category: cash_book.IncomeCategory.miscIncome,
            description: 'Excess card payment received before change return',
            referenceId: '$sourceReference#SOURCE_CARD',
            referenceType: 'CUSTOMER_CHANGE',
          );
        }
        break;
      case PaymentMode.advance:
        break;
    }
  }

  Future<void> _postChangeReturnOutflow({
    required double amount,
    required PaymentMode paymentMode,
    required String billNumber,
    required String sourceReference,
    required String partyName,
    required DateTime txnDate,
  }) async {
    final preferredBankAccountId = await _findPreferredBankAccountId();
    switch (paymentMode) {
      case PaymentMode.cash:
        await _insertCashExpense(
          amount: amount,
          paymentMode: cash_book.PaymentMode.cash,
          billNumber: billNumber,
          partyName: partyName,
          txnDate: txnDate,
          category: cash_book.ExpenseCategory.miscExpense,
          description: 'Change returned to customer in cash',
          referenceId: '$sourceReference#RETURN_CASH',
          referenceType: 'CUSTOMER_CHANGE',
        );
        break;
      case PaymentMode.upi:
        if (preferredBankAccountId != null) {
          await _insertBankDebit(
            accountId: preferredBankAccountId,
            amount: amount,
            paymentMode: bank_book.BankPaymentMode.upi,
            billNumber: billNumber,
            partyName: partyName,
            txnDate: txnDate,
            category: bank_book.BankDebitCategory.miscDebit,
            description: 'Change returned to customer through UPI',
            referenceId: '$sourceReference#RETURN_UPI',
            referenceType: 'CUSTOMER_CHANGE',
          );
        } else {
          await _insertCashExpense(
            amount: amount,
            paymentMode: cash_book.PaymentMode.upi,
            billNumber: billNumber,
            partyName: partyName,
            txnDate: txnDate,
            category: cash_book.ExpenseCategory.miscExpense,
            description: 'Change returned to customer through UPI',
            referenceId: '$sourceReference#RETURN_UPI',
            referenceType: 'CUSTOMER_CHANGE',
          );
        }
        break;
      case PaymentMode.card:
      case PaymentMode.advance:
        break;
    }
  }

  Future<void> _consumeLinkedStock(
    List<SaleItemModel> saleItems, {
    required String sourceId,
    required String sourceNumber,
  }) async {
    for (var index = 0; index < saleItems.length; index++) {
      final item = saleItems[index];
      final stockItemId = item.linkedStockItemId;
      if (stockItemId == null) {
        continue;
      }

      await _deductStock(
        stockItemId: stockItemId,
        stockUnitId: item.linkedStockUnitId,
        stockUnitCode: item.linkedStockSku,
        quantityToSell: _unitsForItem(item),
        sourceId: sourceId,
        sourceNumber: sourceNumber,
        sourceLineNo: index + 1,
      );
    }
  }

  Future<void> _restoreLinkedStock(
    List<BillItem> billItems, {
    required String sourceId,
    required String sourceNumber,
  }) async {
    for (final item in billItems) {
      final stockItemId = item.linkedStockItemId;
      if (stockItemId == null) {
        continue;
      }

      await _restoreStock(
        stockItemId: stockItemId,
        stockUnitId: item.linkedStockUnitId,
        stockUnitCode: item.linkedStockSku,
        quantityToRestore: _unitsForQuantity(item.quantity),
        sourceId: sourceId,
        sourceNumber: sourceNumber,
        sourceLineNo: item.lineNo,
      );
    }
  }

  Future<void> _voidAutoGeneratedSalePaymentEntries(String billNumber) async {
    final normalizedBillNumber = billNumber.trim();
    if (normalizedBillNumber.isEmpty) {
      return;
    }

    final now = DateTime.now();
    const voidReason = 'Reversed by sales bill edit';
    final billPrefixPattern = '$normalizedBillNumber#%';
    final dueCollectionPattern = '$normalizedBillNumber#DUE#%';

    await (_db.update(_db.cashTransactions)
          ..where(
            (tbl) =>
                tbl.referenceType.equals('BILL') &
                tbl.isAutoGenerated.equals(true) &
                tbl.isVoided.equals(false) &
                (tbl.referenceId.equals(normalizedBillNumber) |
                    (tbl.referenceId.like(billPrefixPattern) &
                        tbl.referenceId.like(dueCollectionPattern).not())),
          ))
        .write(
      CashTransactionsCompanion(
        isVoided: const Value(true),
        voidReason: const Value(voidReason),
        updatedAt: Value(now),
      ),
    );

    await (_db.update(_db.bankTransactions)
          ..where(
            (tbl) =>
                tbl.referenceType.equals('BILL') &
                tbl.isAutoGenerated.equals(true) &
                tbl.isVoided.equals(false) &
                (tbl.referenceId.equals(normalizedBillNumber) |
                    (tbl.referenceId.like(billPrefixPattern) &
                        tbl.referenceId.like(dueCollectionPattern).not())),
          ))
        .write(
      BankTransactionsCompanion(
        isVoided: const Value(true),
        voidReason: const Value(voidReason),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> _voidAutoGeneratedCustomerAccountEntries(
    String billNumber,
  ) async {
    final normalizedBillNumber = billNumber.trim();
    if (normalizedBillNumber.isEmpty) {
      return;
    }

    final now = DateTime.now();
    const voidReason = 'Reversed by sales bill edit';
    final sourceReference = _buildCustomerAccountReferenceId(
      normalizedBillNumber,
    );
    final sourceReferencePattern = '$sourceReference#%';

    await (_db.update(_db.customerAccountLedger)
          ..where(
            (tbl) =>
                tbl.sourceReference.equals(sourceReference) &
                tbl.sourceType.equals('POS_CHANGE_CREDIT') &
                tbl.isVoided.equals(false),
          ))
        .write(
      CustomerAccountLedgerCompanion(
        isVoided: const Value(true),
        voidReason: const Value(voidReason),
        updatedAt: Value(now),
      ),
    );

    await (_db.update(_db.cashTransactions)
          ..where(
            (tbl) =>
                tbl.referenceType.equals('CUSTOMER_ACCOUNT') &
                tbl.isAutoGenerated.equals(true) &
                tbl.isVoided.equals(false) &
                (tbl.referenceId.equals(sourceReference) |
                    tbl.referenceId.like(sourceReferencePattern)),
          ))
        .write(
      CashTransactionsCompanion(
        isVoided: const Value(true),
        voidReason: const Value(voidReason),
        updatedAt: Value(now),
      ),
    );

    await (_db.update(_db.bankTransactions)
          ..where(
            (tbl) =>
                tbl.referenceType.equals('CUSTOMER_ACCOUNT') &
                tbl.isAutoGenerated.equals(true) &
                tbl.isVoided.equals(false) &
                (tbl.referenceId.equals(sourceReference) |
                    tbl.referenceId.like(sourceReferencePattern)),
          ))
        .write(
      BankTransactionsCompanion(
        isVoided: const Value(true),
        voidReason: const Value(voidReason),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> _voidAutoGeneratedCustomerChangeEntries(
    String billNumber,
  ) async {
    final normalizedBillNumber = billNumber.trim();
    if (normalizedBillNumber.isEmpty) {
      return;
    }

    final now = DateTime.now();
    const voidReason = 'Reversed by sales bill edit';
    final sourceReference = _buildCustomerChangeReferenceId(
      normalizedBillNumber,
    );
    final sourceReferencePattern = '$sourceReference#%';

    await (_db.update(_db.cashTransactions)
          ..where(
            (tbl) =>
                tbl.referenceType.equals('CUSTOMER_CHANGE') &
                tbl.isAutoGenerated.equals(true) &
                tbl.isVoided.equals(false) &
                (tbl.referenceId.equals(sourceReference) |
                    tbl.referenceId.like(sourceReferencePattern)),
          ))
        .write(
      CashTransactionsCompanion(
        isVoided: const Value(true),
        voidReason: const Value(voidReason),
        updatedAt: Value(now),
      ),
    );

    await (_db.update(_db.bankTransactions)
          ..where(
            (tbl) =>
                tbl.referenceType.equals('CUSTOMER_CHANGE') &
                tbl.isAutoGenerated.equals(true) &
                tbl.isVoided.equals(false) &
                (tbl.referenceId.equals(sourceReference) |
                    tbl.referenceId.like(sourceReferencePattern)),
          ))
        .write(
      BankTransactionsCompanion(
        isVoided: const Value(true),
        voidReason: const Value(voidReason),
        updatedAt: Value(now),
      ),
    );
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
    return _unitsForQuantity(item.pcs);
  }

  int _unitsForQuantity(int quantity) {
    return quantity < 1 ? 1 : quantity;
  }

  Future<void> _restoreStock({
    required int stockItemId,
    required int? stockUnitId,
    required String? stockUnitCode,
    required int quantityToRestore,
    required String sourceId,
    required String sourceNumber,
    required int sourceLineNo,
  }) async {
    final stockRow = await (_db.select(_db.stockItems)
          ..where((tbl) => tbl.id.equals(stockItemId)))
        .getSingleOrNull();

    if (stockRow == null) {
      throw StateError(
        'Linked stock item #$stockItemId no longer exists; sale edit cannot safely restore inventory.',
      );
    }

    final restoredQty = stockRow.quantity + quantityToRestore;
    await (_db.update(_db.stockItems)
          ..where((tbl) => tbl.id.equals(stockItemId)))
        .write(
      StockItemsCompanion(
        quantity: Value(restoredQty),
        isActive: const Value(true),
        status: Value(stock.StockStatus.available.label),
        updatedAt: Value(DateTime.now()),
      ),
    );
    final now = DateTime.now();
    await _markStockUnitsAvailable(
      stockItemId: stockItemId,
      stockUnitId: stockUnitId,
      stockUnitCode: stockUnitCode,
      quantityToRestore: quantityToRestore,
      restoredAt: now,
    );
    await _insertStockMovement(
      stockRow: stockRow,
      movementType: 'SALE_RESTORE',
      sourceType: 'SALE',
      sourceId: sourceId,
      sourceNumber: sourceNumber,
      sourceLineNo: sourceLineNo,
      quantityDelta: quantityToRestore,
      reason: 'Sale edit stock restore',
      occurredAt: now,
    );
  }

  Future<void> _deductStock({
    required int stockItemId,
    required int? stockUnitId,
    required String? stockUnitCode,
    required int quantityToSell,
    required String sourceId,
    required String sourceNumber,
    required int sourceLineNo,
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

    final soldUnitCount = await _markStockUnitsSold(
      stockItemId: stockItemId,
      stockUnitId: stockUnitId,
      stockUnitCode: stockUnitCode,
      quantityToSell: quantityToSell,
      soldAt: DateTime.now(),
    );
    if (soldUnitCount < quantityToSell) {
      throw StateError(
        'Only $soldUnitCount stock unit(s) could be reserved for ${stockRow.sku}.',
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
    final now = DateTime.now();
    await _insertStockMovement(
      stockRow: stockRow,
      movementType: 'SALE',
      sourceType: 'SALE',
      sourceId: sourceId,
      sourceNumber: sourceNumber,
      sourceLineNo: sourceLineNo,
      quantityDelta: -quantityToSell,
      reason: 'POS sale stock deduction',
      occurredAt: now,
    );
  }

  Future<int> _markStockUnitsSold({
    required int stockItemId,
    required int? stockUnitId,
    required String? stockUnitCode,
    required int quantityToSell,
    required DateTime soldAt,
  }) async {
    final unitsToSell = await _stockUnitsForSale(
      stockItemId: stockItemId,
      stockUnitId: stockUnitId,
      stockUnitCode: stockUnitCode,
      quantityToSell: quantityToSell,
    );
    if (unitsToSell.length < quantityToSell) {
      return unitsToSell.length;
    }

    for (final unit in unitsToSell) {
      final status = unit.read<String>('status');
      if (status != stock.StockStatus.available.label) {
        throw StateError('Selected stock unit is no longer available for sale.');
      }
    }

    final ids = unitsToSell.map((row) => row.read<int>('id')).toList();
    final placeholders = List.filled(ids.length, '?').join(', ');
    await _db.customStatement(
      '''
      UPDATE stock_item_units
      SET status = ?, sold_at = ?, updated_at = ?
      WHERE id IN ($placeholders)
      ''',
      [
        stock.StockStatus.sold.label,
        soldAt.millisecondsSinceEpoch,
        soldAt.millisecondsSinceEpoch,
        ...ids,
      ],
    );
    return ids.length;
  }

  Future<List<QueryRow>> _stockUnitsForSale({
    required int stockItemId,
    required int? stockUnitId,
    required String? stockUnitCode,
    required int quantityToSell,
  }) async {
    final selected = await _selectedStockUnit(
      stockUnitId: stockUnitId,
      stockUnitCode: stockUnitCode,
    );
    final selectedId = selected?.read<int>('id');
    final units = <QueryRow>[
      if (selected != null) selected,
    ];

    final remaining = quantityToSell - units.length;
    if (remaining > 0) {
      final rows = selectedId == null
          ? await _db.customSelect(
              '''
              SELECT id, status
              FROM stock_item_units
              WHERE stock_item_id = ?
                AND status = ?
              ORDER BY piece_no ASC, id ASC
              LIMIT ?
              ''',
              variables: [
                Variable<int>(stockItemId),
                Variable<String>(stock.StockStatus.available.label),
                Variable<int>(remaining),
              ],
            ).get()
          : await _db.customSelect(
              '''
              SELECT id, status
              FROM stock_item_units
              WHERE stock_item_id = ?
                AND status = ?
                AND id <> ?
              ORDER BY piece_no ASC, id ASC
              LIMIT ?
              ''',
              variables: [
                Variable<int>(stockItemId),
                Variable<String>(stock.StockStatus.available.label),
                Variable<int>(selectedId),
                Variable<int>(remaining),
              ],
            ).get();
      units.addAll(rows);
    }

    return units;
  }

  Future<QueryRow?> _selectedStockUnit({
    required int? stockUnitId,
    required String? stockUnitCode,
  }) async {
    final whereClause = _stockUnitWhereClause(
      stockUnitId: stockUnitId,
      stockUnitCode: stockUnitCode,
    );
    if (whereClause == null) {
      return null;
    }
    final variables = _stockUnitWhereVariables(
      stockUnitId: stockUnitId,
      stockUnitCode: stockUnitCode,
    );
    return _db.customSelect(
      '''
      SELECT id, status
      FROM stock_item_units
      WHERE $whereClause
      LIMIT 1
      ''',
      variables: variables,
    ).getSingleOrNull();
  }

  Future<void> _markStockUnitsAvailable({
    required int stockItemId,
    required int? stockUnitId,
    required String? stockUnitCode,
    required int quantityToRestore,
    required DateTime restoredAt,
  }) async {
    final selected = await _selectedStockUnit(
      stockUnitId: stockUnitId,
      stockUnitCode: stockUnitCode,
    );
    final selectedId = selected?.read<int>('id');
    final units = <QueryRow>[
      if (selected != null) selected,
    ];

    final remaining = quantityToRestore - units.length;
    if (remaining > 0) {
      final rows = selectedId == null
          ? await _db.customSelect(
              '''
              SELECT id, status
              FROM stock_item_units
              WHERE stock_item_id = ?
                AND status = ?
              ORDER BY sold_at DESC, id DESC
              LIMIT ?
              ''',
              variables: [
                Variable<int>(stockItemId),
                Variable<String>(stock.StockStatus.sold.label),
                Variable<int>(remaining),
              ],
            ).get()
          : await _db.customSelect(
              '''
              SELECT id, status
              FROM stock_item_units
              WHERE stock_item_id = ?
                AND status = ?
                AND id <> ?
              ORDER BY sold_at DESC, id DESC
              LIMIT ?
              ''',
              variables: [
                Variable<int>(stockItemId),
                Variable<String>(stock.StockStatus.sold.label),
                Variable<int>(selectedId),
                Variable<int>(remaining),
              ],
            ).get();
      units.addAll(rows);
    }

    if (units.isEmpty) {
      return;
    }

    final ids = units.map((row) => row.read<int>('id')).toList();
    final placeholders = List.filled(ids.length, '?').join(', ');
    await _db.customStatement(
      '''
      UPDATE stock_item_units
      SET status = ?, sold_at = NULL, updated_at = ?
      WHERE id IN ($placeholders)
      ''',
      [
        stock.StockStatus.available.label,
        restoredAt.millisecondsSinceEpoch,
        ...ids,
      ],
    );
  }

  String? _stockUnitWhereClause({
    required int? stockUnitId,
    required String? stockUnitCode,
  }) {
    if (stockUnitId != null) {
      return 'id = ?';
    }
    final normalized = stockUnitCode?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return 'unit_code = ?';
    }
    return null;
  }

  List<Variable<Object>> _stockUnitWhereVariables({
    required int? stockUnitId,
    required String? stockUnitCode,
  }) {
    if (stockUnitId != null) {
      return [Variable<int>(stockUnitId)];
    }
    return [Variable<String>(stockUnitCode!.trim())];
  }

  Future<void> _insertStockMovement({
    required StockItem stockRow,
    required String movementType,
    required String sourceType,
    required String sourceId,
    required String sourceNumber,
    required int sourceLineNo,
    required int quantityDelta,
    required String reason,
    required DateTime occurredAt,
  }) {
    final multiplier = quantityDelta.abs();
    final sign = quantityDelta < 0 ? -1.0 : 1.0;
    return _db.customStatement(
      '''
      INSERT INTO stock_movements (
        stock_item_id,
        movement_type,
        source_type,
        source_id,
        source_line_no,
        source_number,
        sku_snapshot,
        metal_type_snapshot,
        item_name_snapshot,
        quantity_delta,
        gross_weight_delta,
        net_weight_delta,
        fine_weight_delta,
        reason,
        occurred_at,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        stockRow.id,
        movementType,
        sourceType,
        sourceId,
        sourceLineNo,
        sourceNumber,
        stockRow.sku,
        stockRow.metalType,
        stockRow.itemName,
        quantityDelta,
        stockRow.grossWeight * multiplier * sign,
        stockRow.netWeight * multiplier * sign,
        0.0,
        reason,
        occurredAt.millisecondsSinceEpoch,
        occurredAt.millisecondsSinceEpoch,
        occurredAt.millisecondsSinceEpoch,
      ],
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
    return PosNumberParser.parseNonNegative(text);
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

  SaleItemModel _saleItemFromBillItem(BillItem row) {
    final item = SaleItemModel(
      metal: _metalFromDb(row.metalType),
      makingChargeType: _makingChargeTypeFromDb(row.makingChargeType),
      isLessPerPiece: row.lessWeightPerPiece,
    );
    item.descCtrl.text = row.itemName;
    item.pcsCtrl.text = row.quantity.toString();
    item.huidCtrl.text = row.huid ?? '';
    item.purityCtrl.text = row.purity;
    item.grossCtrl.text = _formatPersistedNumber(row.grossWeight);
    item.lessCtrl.text = _formatPersistedNumber(row.lessWeight);
    item.rateCtrl.text = _formatPersistedNumber(row.rate);
    item.makingCtrl.text = _formatPersistedNumber(row.makingChargeInput);
    if (row.linkedStockItemId != null && row.linkedStockSku != null) {
      item.attachStockReference(
        stockItemId: row.linkedStockItemId!,
        stockUnitId: row.linkedStockUnitId,
        stockUnitCost: row.stockUnitCost,
        sku: row.linkedStockSku!,
      );
    }
    return item;
  }

  MetalType _metalFromDb(String value) {
    return switch (value.trim().toUpperCase()) {
      'SILVER' => MetalType.silver,
      'PLATINUM' => MetalType.platinum,
      'DIAMOND' => MetalType.diamond,
      _ => MetalType.gold,
    };
  }

  MakingChargeType _makingChargeTypeFromDb(String value) {
    return switch (value.trim().toUpperCase()) {
      'PERCENTAGE' => MakingChargeType.percentage,
      'PER_KG' => MakingChargeType.perKg,
      'PER_PIECE' => MakingChargeType.perPiece,
      _ => MakingChargeType.perGram,
    };
  }

  String _formatPersistedNumber(double value) {
    return PosNumberFormatter.compact(value);
  }

  Future<void> _insertCashIncome({
    required double amount,
    required cash_book.PaymentMode paymentMode,
    required String billNumber,
    required String partyName,
    required DateTime txnDate,
    cash_book.IncomeCategory category = cash_book.IncomeCategory.sale,
    String? description,
    String? referenceId,
    String referenceType = 'BILL',
  }) async {
    final txnId = await _generateCashTxnId();
    await _db.into(_db.cashTransactions).insert(
          CashTransactionsCompanion.insert(
            txnId: txnId,
            txnDate: txnDate,
            type: cash_book.CashTransactionType.income.dbValue,
            category: category.dbValue,
            amount: Value(amount),
            paymentMode: Value(paymentMode.dbValue),
            description:
                Value(description ?? 'Sale receipt against $billNumber'),
            referenceId: Value(
              referenceId ??
                  _buildLedgerReferenceId(billNumber, paymentMode.dbValue),
            ),
            referenceType: Value(referenceType),
            partyName: Value(partyName),
            isAutoGenerated: const Value(true),
            isVoided: const Value(false),
          ),
        );
  }

  Future<void> _insertCashExpense({
    required double amount,
    required cash_book.PaymentMode paymentMode,
    required String billNumber,
    required String partyName,
    required DateTime txnDate,
    cash_book.ExpenseCategory category = cash_book.ExpenseCategory.miscExpense,
    String? description,
    String? referenceId,
    String referenceType = 'BILL',
  }) async {
    final txnId = await _generateCashTxnId();
    await _db.into(_db.cashTransactions).insert(
          CashTransactionsCompanion.insert(
            txnId: txnId,
            txnDate: txnDate,
            type: cash_book.CashTransactionType.expense.dbValue,
            category: category.dbValue,
            amount: Value(amount),
            paymentMode: Value(paymentMode.dbValue),
            description:
                Value(description ?? 'Cash expense against $billNumber'),
            referenceId: Value(
              referenceId ??
                  _buildLedgerReferenceId(billNumber, paymentMode.dbValue),
            ),
            referenceType: Value(referenceType),
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
    bank_book.BankCreditCategory category =
        bank_book.BankCreditCategory.salePayment,
    String? description,
    String? referenceId,
    String referenceType = 'BILL',
  }) async {
    final txnId = await _generateBankTxnId();
    await _db.into(_db.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: txnId,
            accountId: accountId,
            txnDate: txnDate,
            type: bank_book.BankTransactionType.credit.dbValue,
            category: category.dbValue,
            amount: Value(amount),
            paymentMode: Value(paymentMode.dbValue),
            description:
                Value(description ?? 'Sale receipt against $billNumber'),
            referenceId: Value(
              referenceId ??
                  _buildLedgerReferenceId(billNumber, paymentMode.dbValue),
            ),
            referenceType: Value(referenceType),
            partyName: Value(partyName),
            isAutoGenerated: const Value(true),
            isVoided: const Value(false),
          ),
        );
  }

  Future<void> _insertBankDebit({
    required int accountId,
    required double amount,
    required bank_book.BankPaymentMode paymentMode,
    required String billNumber,
    required String partyName,
    required DateTime txnDate,
    bank_book.BankDebitCategory category =
        bank_book.BankDebitCategory.miscDebit,
    String? description,
    String? referenceId,
    String referenceType = 'BILL',
  }) async {
    final txnId = await _generateBankTxnId();
    await _db.into(_db.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: txnId,
            accountId: accountId,
            txnDate: txnDate,
            type: bank_book.BankTransactionType.debit.dbValue,
            category: category.dbValue,
            amount: Value(amount),
            paymentMode: Value(paymentMode.dbValue),
            description: Value(description ?? 'Bank debit against $billNumber'),
            referenceId: Value(
              referenceId ??
                  _buildLedgerReferenceId(billNumber, paymentMode.dbValue),
            ),
            referenceType: Value(referenceType),
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

  String _buildCustomerAccountReferenceId(String billNumber) {
    return '$billNumber#ACCOUNT_CREDIT';
  }

  String _buildCustomerChangeReferenceId(String billNumber) {
    return '$billNumber#CHANGE_RETURN';
  }

  String? _nullable(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
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

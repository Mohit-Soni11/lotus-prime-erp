import 'package:drift/drift.dart';

import 'package:lotus_erp/core/tax/gst_jurisdiction.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import '../../../features/sales_pos/domain/services/pos_invoice_series_formatter.dart';
import '../../../features/sales_pos/domain/services/pos_money_math.dart';
import '../../../features/sales_pos/domain/services/pos_number_formatter.dart';
import '../../../features/sales_pos/domain/services/pos_number_parser.dart';
import '../../../models/finance/bank_book/bank_book_enums.dart' as bank_book;
import '../../../models/finance/cash_book/cash_book_enums.dart' as cash_book;
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../models/sales_orders/sales_pos_models/sales_pos_models.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart'
    as stock;

const String _stockUnitSaleColumns = '''
id,
stock_item_id,
purchase_voucher_item_id,
status,
gross_weight,
less_weight,
net_weight,
actual_fine_weight,
wastage_fine_weight,
valuation_fine_weight,
rate_per_gram,
unit_cost,
making_amount
''';

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
    required this.tradeInItems,
  });

  final Bill bill;
  final List<BillItem> items;
  final List<BillTradeInItem> tradeInItems;
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
    await _db.ensureSalesCustomerMetalSettlementSchema();
    return _db.transaction(() async {
      final resolved = await _resolveInvoiceNumber(
        invoicePrefix: _invoicePrefixFromBillNo(invoice.invoiceNumber),
        shopInitials: _shopInitialsFromBillNo(invoice.invoiceNumber),
        financialYear: _financialYearFromBillNo(
          invoice.invoiceNumber,
          invoice.invoiceDate,
        ),
        preferredInvoiceNumber: invoice.invoiceNumber,
      );
      final money = _moneySnapshot(invoice);

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
              customerGstinSnapshot: Value(_nullable(invoice.customerGstin)),
              placeOfSupplySnapshot: Value(_nullable(
                invoice.placeOfSupply.trim().isNotEmpty
                    ? invoice.placeOfSupply
                    : invoice.customerCity,
              )),
              customerStateCodeSnapshot: Value(
                _nullable(invoice.customerStateCode),
              ),
              shopGstinSnapshot: Value(_nullable(invoice.shopGstin)),
              shopStateCodeSnapshot: Value(_nullable(invoice.shopStateCode)),
              billingMode: Value(_dbBillingMode(invoice.billingMode)),
              billType: const Value('GST'),
              documentType: Value(invoice.documentType.storageValue),
              gstPricingMode: Value(invoice.gstPricingMode.storageValue),
              taxTreatment: const Value('TAXABLE_SUPPLY'),
              paymentStatus: Value(_resolvePaymentStatus(money)),
              totalAmount: Value(money.grossAmount),
              discount: Value(money.discountAmount),
              taxableAmount: Value(money.taxableAmount),
              cgstAmount: Value(money.cgst),
              sgstAmount: Value(money.sgst),
              igstAmount: Value(money.igst),
              gstAmount: Value(money.totalGst),
              gstExclusiveSalesAmount: Value(
                invoice.gstPricingMode == GstPricingMode.exclusive
                    ? money.taxableAmount
                    : 0.0,
              ),
              gstInclusiveSalesAmount: Value(
                invoice.gstPricingMode == GstPricingMode.inclusive
                    ? money.taxableAmount
                    : 0.0,
              ),
              outputGstLiabilitySnapshot: Value(money.totalGst),
              makingTotal: Value(money.totalMakingCharge),
              roundOffAmount: Value(money.roundOffAmount),
              finalAmount: Value(money.netPayable),
              paidAmount: Value(money.totalPaid),
              cashPaid: Value(money.cashPaid),
              upiPaid: Value(money.upiPaid),
              cardPaid: Value(money.cardPaid),
              advancePaid: Value(money.advancePaid),
              dueAmount: Value(money.dueAmount),
              tradeInDeduction: Value(money.tradeInDeduction),
              tradeInMode: Value(_dbTradeInMode(invoice.tradeInMode)),
              billDate: Value(invoice.invoiceDate),
              promiseDate: Value(invoice.promiseDate),
              sourceAdvanceOrderId: Value(sourceAdvanceOrderId),
              sourceAdvanceOrderNo: Value(_nullable(sourceAdvanceOrderNo)),
              status: const Value('ACTIVE'),
            ),
          );

      for (var index = 0; index < invoice.saleItems.length; index++) {
        final item = invoice.saleItems[index];
        final lineTax = _lineTaxSnapshot(item, invoice, money);
        final itemName = item.descCtrl.text.trim().isNotEmpty
            ? item.descCtrl.text.trim()
            : item.metal.displayName;
        final stockUnitCost = await _stockUnitCostForSaleItem(item);
        final stockProfitAmount =
            stockUnitCost > 0 ? item.totalValue - stockUnitCost : 0.0;

        await _db.into(_db.billItems).insert(
              BillItemsCompanion(
                billId: Value(billId),
                lineNo: Value(index + 1),
                metalType: Value(item.metal.displayName),
                itemName: Value(itemName),
                hsnCode: Value(_nullable(item.invoiceHsnCode)),
                huid: Value(
                  item.huidText.trim().isNotEmpty ? item.huidText.trim() : null,
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
                gstPricingModeSnapshot:
                    Value(invoice.gstPricingMode.storageValue),
                taxTreatmentSnapshot: const Value('TAXABLE_SUPPLY'),
                taxableAmountSnapshot: Value(lineTax.taxableAmount),
                gstRateSnapshot: Value(lineTax.gstRate),
                cgstAmountSnapshot: Value(lineTax.cgst),
                sgstAmountSnapshot: Value(lineTax.sgst),
                igstAmountSnapshot: Value(lineTax.igst),
                gstAmountSnapshot: Value(lineTax.totalGst),
                invoiceValueSnapshot: Value(lineTax.invoiceValue),
                linkedStockItemId: Value(item.linkedStockItemId),
                linkedStockUnitId: Value(item.linkedStockUnitId),
                linkedStockSku: Value(item.linkedStockSku),
                stockUnitCost: Value(stockUnitCost),
                stockProfitAmount: Value(stockProfitAmount),
              ),
            );
      }

      await _persistTradeInItems(
        billId: billId,
        tradeInItems: invoice.tradeInItems,
        settlementType: invoice.customerMetalSettlementType,
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
    final tradeInItems = await (_db.select(_db.billTradeInItems)
          ..where((tbl) => tbl.billId.equals(billId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.lineNo)]))
        .get();

    return PosEditableBill(
      bill: bill,
      items: items,
      tradeInItems: tradeInItems,
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
    await _db.ensureSalesCustomerMetalSettlementSchema();
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
      final money = _moneySnapshot(invoice);

      await (_db.update(_db.bills)..where((tbl) => tbl.id.equals(billId)))
          .write(
        BillsCompanion(
          billNo: Value(existingBill.billNo),
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
          customerGstinSnapshot: Value(_nullable(invoice.customerGstin)),
          placeOfSupplySnapshot: Value(_nullable(
            invoice.placeOfSupply.trim().isNotEmpty
                ? invoice.placeOfSupply
                : invoice.customerCity,
          )),
          customerStateCodeSnapshot:
              Value(_nullable(invoice.customerStateCode)),
          shopGstinSnapshot: Value(_nullable(invoice.shopGstin)),
          shopStateCodeSnapshot: Value(_nullable(invoice.shopStateCode)),
          billingMode: Value(_dbBillingMode(invoice.billingMode)),
          billType: const Value('GST'),
          documentType: Value(invoice.documentType.storageValue),
          gstPricingMode: Value(invoice.gstPricingMode.storageValue),
          taxTreatment: const Value('TAXABLE_SUPPLY'),
          paymentStatus: Value(_resolvePaymentStatus(money)),
          totalAmount: Value(money.grossAmount),
          discount: Value(money.discountAmount),
          taxableAmount: Value(money.taxableAmount),
          cgstAmount: Value(money.cgst),
          sgstAmount: Value(money.sgst),
          igstAmount: Value(money.igst),
          gstAmount: Value(money.totalGst),
          gstExclusiveSalesAmount: Value(
            invoice.gstPricingMode == GstPricingMode.exclusive
                ? money.taxableAmount
                : 0.0,
          ),
          gstInclusiveSalesAmount: Value(
            invoice.gstPricingMode == GstPricingMode.inclusive
                ? money.taxableAmount
                : 0.0,
          ),
          outputGstLiabilitySnapshot: Value(money.totalGst),
          makingTotal: Value(money.totalMakingCharge),
          roundOffAmount: Value(money.roundOffAmount),
          finalAmount: Value(money.netPayable),
          paidAmount: Value(money.totalPaid),
          cashPaid: Value(money.cashPaid),
          upiPaid: Value(money.upiPaid),
          cardPaid: Value(money.cardPaid),
          advancePaid: Value(money.advancePaid),
          dueAmount: Value(money.dueAmount),
          tradeInDeduction: Value(money.tradeInDeduction),
          tradeInMode: Value(_dbTradeInMode(invoice.tradeInMode)),
          billDate: Value(invoice.invoiceDate),
          promiseDate: Value(invoice.promiseDate),
          status: const Value('ACTIVE'),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await (_db.delete(_db.billItems)
            ..where((tbl) => tbl.billId.equals(billId)))
          .go();
      await (_db.delete(_db.billTradeInItems)
            ..where((tbl) => tbl.billId.equals(billId)))
          .go();

      for (var index = 0; index < invoice.saleItems.length; index++) {
        final item = invoice.saleItems[index];
        final lineTax = _lineTaxSnapshot(item, invoice, money);
        final itemName = item.descCtrl.text.trim().isNotEmpty
            ? item.descCtrl.text.trim()
            : item.metal.displayName;
        final stockUnitCost = await _stockUnitCostForSaleItem(item);
        final stockProfitAmount =
            stockUnitCost > 0 ? item.totalValue - stockUnitCost : 0.0;

        await _db.into(_db.billItems).insert(
              BillItemsCompanion(
                billId: Value(billId),
                lineNo: Value(index + 1),
                metalType: Value(item.metal.displayName),
                itemName: Value(itemName),
                hsnCode: Value(_nullable(item.invoiceHsnCode)),
                huid: Value(
                  item.huidText.trim().isNotEmpty ? item.huidText.trim() : null,
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
                gstPricingModeSnapshot:
                    Value(invoice.gstPricingMode.storageValue),
                taxTreatmentSnapshot: const Value('TAXABLE_SUPPLY'),
                taxableAmountSnapshot: Value(lineTax.taxableAmount),
                gstRateSnapshot: Value(lineTax.gstRate),
                cgstAmountSnapshot: Value(lineTax.cgst),
                sgstAmountSnapshot: Value(lineTax.sgst),
                igstAmountSnapshot: Value(lineTax.igst),
                gstAmountSnapshot: Value(lineTax.totalGst),
                invoiceValueSnapshot: Value(lineTax.invoiceValue),
                linkedStockItemId: Value(item.linkedStockItemId),
                linkedStockUnitId: Value(item.linkedStockUnitId),
                linkedStockSku: Value(item.linkedStockSku),
                stockUnitCost: Value(stockUnitCost),
                stockProfitAmount: Value(stockProfitAmount),
              ),
            );
      }

      await _persistTradeInItems(
        billId: billId,
        tradeInItems: invoice.tradeInItems,
        settlementType: invoice.customerMetalSettlementType,
      );
      await _consumeLinkedStock(
        invoice.saleItems,
        sourceId: billId.toString(),
        sourceNumber: existingBill.billNo,
      );
      await _postSalePaymentLedgerEntries(
        invoice: invoice,
        billNumber: existingBill.billNo,
      );
      await _postCustomerAccountCreditEntry(
        invoice: invoice,
        billNumber: existingBill.billNo,
        customerId: customerId,
      );
      await _postCustomerChangeReturnFinanceEntries(
        invoice: invoice,
        billNumber: existingBill.billNo,
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
    final amount = _roundMoney(invoice.changeSettlementAmount);
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
    final amount = _roundMoney(invoice.changeSettlementAmount);
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
        quantityToSell: await _unitsForItem(item),
        saleGrossWeight: _parseSafeNumber(item.grossCtrl.text),
        saleLessWeight: _parseSafeNumber(item.lessCtrl.text),
        saleNetWeight: item.netWt,
        saleFineWeight: item.fineWt,
        saleLineAmount: item.totalValue,
        saleMakingAmount: item.makingAmt,
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
        quantityToRestore: await _unitsForBillItem(item),
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

  Future<void> _persistTradeInItems({
    required int billId,
    required List<TradeInItemModel> tradeInItems,
    required CustomerMetalSettlementType settlementType,
  }) async {
    for (var index = 0; index < tradeInItems.length; index++) {
      final item = tradeInItems[index];
      await _db.into(_db.billTradeInItems).insert(
            BillTradeInItemsCompanion(
              billId: Value(billId),
              lineNo: Value(index + 1),
              metalType: Value(item.metal.displayName),
              settlementType: Value(settlementType.storageValue),
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

  Future<int> _unitsForItem(SaleItemModel item) async {
    final stockItemId = item.linkedStockItemId;
    if (stockItemId != null && await _isLotStockItem(stockItemId)) {
      return _unitsForQuantity(item.pcs);
    }
    return _unitsForQuantity(item.pcs);
  }

  Future<double> _stockUnitCostForSaleItem(SaleItemModel item) async {
    final stockItemId = item.linkedStockItemId;
    if (stockItemId == null) {
      return 0.0;
    }
    if (!await _isLotStockItem(stockItemId)) {
      return item.linkedStockUnitCost;
    }

    final lotUnit = await _lotStockUnit(stockItemId);
    if (lotUnit == null) {
      return item.linkedStockUnitCost;
    }

    final allocatedOriginalCost = await _originalLotCostForSaleItem(
      item: item,
      lotUnit: lotUnit,
    );
    if (allocatedOriginalCost > 0) {
      return allocatedOriginalCost;
    }

    final currentNet = lotUnit.read<double>('net_weight');
    final currentCost = lotUnit.read<double>('unit_cost');
    if (currentNet <= 0 || currentCost <= 0 || item.netWt <= 0) {
      return 0.0;
    }
    final factor = (item.netWt / currentNet).clamp(0.0, 1.0);
    return currentCost * factor;
  }

  Future<double> _originalLotCostForSaleItem({
    required SaleItemModel item,
    required QueryRow lotUnit,
  }) async {
    final purchaseItemId =
        lotUnit.readNullable<int>('purchase_voucher_item_id');
    if (purchaseItemId == null) return 0.0;

    final row = await _db.customSelect(
      '''
      SELECT
        net_weight,
        valuation_fine_weight,
        fine_weight,
        wastage_fine_weight,
        rate,
        quantity,
        line_amount
      FROM purchase_voucher_items
      WHERE id = ?
      LIMIT 1
      ''',
      variables: [Variable<int>(purchaseItemId)],
    ).getSingleOrNull();
    if (row == null) return 0.0;

    final originalNetWeight = row.readNullable<double>('net_weight') ?? 0.0;
    final originalValuationFine =
        (row.readNullable<double>('valuation_fine_weight') ?? 0.0) > 0
            ? row.read<double>('valuation_fine_weight')
            : (row.readNullable<double>('fine_weight') ?? 0.0) +
                (row.readNullable<double>('wastage_fine_weight') ?? 0.0);
    final rate = (row.readNullable<double>('rate') ?? 0.0) > 0
        ? row.read<double>('rate')
        : lotUnit.read<double>('rate_per_gram');
    final originalQuantity = row.readNullable<int>('quantity') ?? 0;
    final lineAmount = row.readNullable<double>('line_amount') ?? 0.0;

    if (originalNetWeight <= 0 || originalValuationFine <= 0 || rate <= 0) {
      return 0.0;
    }

    final soldValuationFine =
        item.netWt * (originalValuationFine / originalNetWeight);
    final metalCost = soldValuationFine * rate;
    final originalMaking = _nonNegative(
      lineAmount - (originalValuationFine * rate),
    );
    final soldQuantity = item.pcs < 1 ? 1 : item.pcs;
    final makingCost = originalQuantity <= 0
        ? 0.0
        : originalMaking * soldQuantity / originalQuantity;

    return metalCost + makingCost;
  }

  Future<int> _unitsForBillItem(BillItem item) async {
    final stockItemId = item.linkedStockItemId;
    if (stockItemId != null && await _isLotStockItem(stockItemId)) {
      return _unitsForQuantity(item.quantity);
    }
    return _unitsForQuantity(item.quantity);
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
    final isLotStock = await _isLotStockItem(stockItemId);
    if (isLotStock) {
      await _restoreLotStock(
        stockRow: stockRow,
        quantityToRestore: quantityToRestore,
        sourceId: sourceId,
        sourceNumber: sourceNumber,
        sourceLineNo: sourceLineNo,
      );
      return;
    }

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
    final restoredUnits = await _markStockUnitsAvailable(
      stockItemId: stockItemId,
      stockUnitId: stockUnitId,
      stockUnitCode: stockUnitCode,
      quantityToRestore: quantityToRestore,
      restoredAt: now,
    );
    final delta = _deltaFromRows(restoredUnits, quantityToRestore, 1);
    await _insertStockMovement(
      stockRow: stockRow,
      movementType: 'SALE_RESTORE',
      sourceType: 'SALE',
      sourceId: sourceId,
      sourceNumber: sourceNumber,
      sourceLineNo: sourceLineNo,
      quantityDelta: quantityToRestore,
      grossWeightDelta: delta.grossWeight,
      netWeightDelta: delta.netWeight,
      fineWeightDelta: delta.fineWeight,
      reason: 'Sale edit stock restore',
      occurredAt: now,
    );
  }

  Future<void> _deductStock({
    required int stockItemId,
    required int? stockUnitId,
    required String? stockUnitCode,
    required int quantityToSell,
    required double saleGrossWeight,
    required double saleLessWeight,
    required double saleNetWeight,
    required double saleFineWeight,
    required double saleLineAmount,
    required double saleMakingAmount,
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

    final normalizedStockRow = await _normalizeUntrackedLotStock(
      stockRow,
      currentSourceId: sourceId,
    );
    final isLotStock = await _isLotStockItem(stockItemId);
    if (isLotStock) {
      await _deductLotStock(
        stockRow: normalizedStockRow,
        quantityToSell: quantityToSell,
        saleGrossWeight: saleGrossWeight,
        saleLessWeight: saleLessWeight,
        saleNetWeight: saleNetWeight,
        saleFineWeight: saleFineWeight,
        saleLineAmount: saleLineAmount,
        saleMakingAmount: saleMakingAmount,
        sourceId: sourceId,
        sourceNumber: sourceNumber,
        sourceLineNo: sourceLineNo,
      );
      return;
    }

    final soldUnits = await _markStockUnitsSold(
      stockItemId: stockItemId,
      stockUnitId: stockUnitId,
      stockUnitCode: stockUnitCode,
      quantityToSell: quantityToSell,
      soldAt: DateTime.now(),
    );
    if (soldUnits.length < quantityToSell) {
      throw StateError(
        'Only ${soldUnits.length} stock unit(s) could be reserved for ${stockRow.sku}.',
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
    final delta = _deltaFromRows(soldUnits, quantityToSell, -1);
    await _insertStockMovement(
      stockRow: stockRow,
      movementType: 'SALE',
      sourceType: 'SALE',
      sourceId: sourceId,
      sourceNumber: sourceNumber,
      sourceLineNo: sourceLineNo,
      quantityDelta: -quantityToSell,
      grossWeightDelta: delta.grossWeight,
      netWeightDelta: delta.netWeight,
      fineWeightDelta: delta.fineWeight,
      reason: 'POS sale stock deduction',
      occurredAt: now,
    );
  }

  Future<List<QueryRow>> _markStockUnitsSold({
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
      return unitsToSell;
    }

    for (final unit in unitsToSell) {
      final status = unit.read<String>('status');
      if (status != stock.StockStatus.available.label) {
        throw StateError(
            'Selected stock unit is no longer available for sale.');
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
    return unitsToSell;
  }

  Future<List<QueryRow>> _stockUnitsForSale({
    required int stockItemId,
    required int? stockUnitId,
    required String? stockUnitCode,
    required int quantityToSell,
  }) async {
    final selected = await _selectedStockUnit(
      stockItemId: stockItemId,
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
              SELECT $_stockUnitSaleColumns
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
              SELECT $_stockUnitSaleColumns
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
    required int stockItemId,
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
      stockItemId: stockItemId,
      stockUnitId: stockUnitId,
      stockUnitCode: stockUnitCode,
    );
    return _db.customSelect(
      '''
      SELECT $_stockUnitSaleColumns
      FROM stock_item_units
      WHERE $whereClause
      LIMIT 1
      ''',
      variables: variables,
    ).getSingleOrNull();
  }

  Future<List<QueryRow>> _markStockUnitsAvailable({
    required int stockItemId,
    required int? stockUnitId,
    required String? stockUnitCode,
    required int quantityToRestore,
    required DateTime restoredAt,
  }) async {
    final selected = await _selectedStockUnit(
      stockItemId: stockItemId,
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
              SELECT $_stockUnitSaleColumns
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
              SELECT $_stockUnitSaleColumns
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
      return const [];
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
    return units;
  }

  Future<bool> _isLotStockItem(int stockItemId) async {
    final row = await _db.customSelect(
      '''
      SELECT
        COUNT(*) AS unit_count,
        COALESCE(SUM(CASE WHEN huid IS NOT NULL AND TRIM(huid) <> '' THEN 1 ELSE 0 END), 0) AS huid_count
      FROM stock_item_units
      WHERE stock_item_id = ?
      ''',
      variables: [Variable<int>(stockItemId)],
    ).getSingleOrNull();
    if (row == null) {
      return false;
    }
    return row.read<int>('unit_count') > 0 && row.read<int>('huid_count') == 0;
  }

  Future<QueryRow?> _lotStockUnit(int stockItemId) {
    return _db.customSelect(
      '''
      SELECT $_stockUnitSaleColumns
      FROM stock_item_units
      WHERE stock_item_id = ?
      ORDER BY
        CASE WHEN status = ? THEN 0 ELSE 1 END,
        CASE WHEN LOWER(COALESCE(unit_code, '')) LIKE '%lot%' THEN 0 ELSE 1 END,
        id ASC
      LIMIT 1
      ''',
      variables: [
        Variable<int>(stockItemId),
        Variable<String>(stock.StockStatus.available.label),
      ],
    ).getSingleOrNull();
  }

  Future<StockItem> _normalizeUntrackedLotStock(
    StockItem stockRow, {
    required String currentSourceId,
  }) async {
    final summary = await _db.customSelect(
      '''
      SELECT
        COUNT(*) AS unit_count,
        COALESCE(SUM(CASE WHEN TRIM(COALESCE(huid, '')) <> '' THEN 1 ELSE 0 END), 0) AS huid_count,
        COALESCE(SUM(CASE WHEN status = ? THEN 1 ELSE 0 END), 0) AS available_count,
        COALESCE(SUM(CASE WHEN status = ? AND LOWER(COALESCE(unit_code, '')) LIKE '%lot%' THEN 1 ELSE 0 END), 0) AS available_lot_count
      FROM stock_item_units
      WHERE stock_item_id = ?
      ''',
      variables: [
        Variable<String>(stock.StockStatus.available.label),
        Variable<String>(stock.StockStatus.available.label),
        Variable<int>(stockRow.id),
      ],
    ).getSingleOrNull();

    if (summary == null ||
        summary.read<int>('unit_count') == 0 ||
        summary.read<int>('huid_count') > 0 ||
        summary.read<int>('available_count') == 0) {
      return stockRow;
    }

    final availableCount = summary.read<int>('available_count');
    final availableLotCount = summary.read<int>('available_lot_count');
    if (availableCount == 1 && availableLotCount == 1) {
      return stockRow;
    }

    final availableRows = await _db.customSelect(
      '''
      SELECT id,
             purchase_voucher_item_id,
             gross_weight,
             less_weight,
             net_weight,
             actual_fine_weight,
             wastage_fine_weight,
             valuation_fine_weight,
             unit_cost,
             making_amount
      FROM stock_item_units
      WHERE stock_item_id = ?
        AND status = ?
        AND TRIM(COALESCE(huid, '')) = ''
      ORDER BY
        CASE WHEN LOWER(COALESCE(unit_code, '')) LIKE '%lot%' THEN 0 ELSE 1 END,
        id ASC
      ''',
      variables: [
        Variable<int>(stockRow.id),
        Variable<String>(stock.StockStatus.available.label),
      ],
    ).get();

    if (availableRows.isEmpty) {
      return stockRow;
    }

    final unitBalance = _unitBalanceFromRows(availableRows);
    final sourceBalance = await _sourceBalanceForUntrackedLot(
      stockItemId: stockRow.id,
      currentSourceId: currentSourceId,
      availableRows: availableRows,
    );
    final balance = sourceBalance ?? unitBalance;
    final keeper = availableRows.first;
    final keeperId = keeper.read<int>('id');

    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customStatement(
      '''
      UPDATE stock_item_units
      SET unit_code = ?,
          piece_no = 1,
          gross_weight = ?,
          less_weight = ?,
          net_weight = ?,
          actual_fine_weight = ?,
          wastage_fine_weight = ?,
          valuation_fine_weight = ?,
          unit_cost = ?,
          making_amount = ?,
          status = ?,
          sold_at = NULL,
          updated_at = ?
      WHERE id = ?
      ''',
      [
        '${stockRow.sku}-LOT',
        balance.grossWeight,
        balance.lessWeight,
        balance.netWeight,
        balance.fineWeight,
        balance.wastageFineWeight,
        balance.valuationFineWeight,
        balance.unitCost,
        unitBalance.makingAmount,
        stock.StockStatus.available.label,
        now,
        keeperId,
      ],
    );

    final idsToDelete = availableRows
        .skip(1)
        .map((row) => row.read<int>('id'))
        .toList(growable: false);
    if (idsToDelete.isNotEmpty) {
      final placeholders = List.filled(idsToDelete.length, '?').join(', ');
      await _db.customStatement(
        '''
        DELETE FROM stock_item_units
        WHERE id IN ($placeholders)
        ''',
        idsToDelete,
      );
    }

    final remainingQuantity = stockRow.quantity > 0 ? stockRow.quantity : 1;
    await (_db.update(_db.stockItems)
          ..where((tbl) => tbl.id.equals(stockRow.id)))
        .write(
      StockItemsCompanion(
        quantity: Value(remainingQuantity),
        grossWeight: Value(balance.grossWeight),
        stoneWeight: Value(balance.lessWeight),
        netWeight: Value(balance.netWeight),
        isActive: const Value(true),
        status: Value(stock.StockStatus.available.label),
        updatedAt: Value(DateTime.fromMillisecondsSinceEpoch(now)),
      ),
    );

    return (_db.select(_db.stockItems)
          ..where((tbl) => tbl.id.equals(stockRow.id)))
        .getSingle();
  }

  _StockLotBalance _unitBalanceFromRows(List<QueryRow> rows) {
    double sum(String column) => rows.fold(
          0,
          (total, row) => total + (row.readNullable<double>(column) ?? 0),
        );
    return _StockLotBalance(
      grossWeight: sum('gross_weight'),
      lessWeight: sum('less_weight'),
      netWeight: sum('net_weight'),
      fineWeight: sum('actual_fine_weight'),
      wastageFineWeight: sum('wastage_fine_weight'),
      valuationFineWeight: sum('valuation_fine_weight'),
      unitCost: sum('unit_cost'),
      makingAmount: sum('making_amount'),
    );
  }

  Future<_StockLotBalance?> _sourceBalanceForUntrackedLot({
    required int stockItemId,
    required String currentSourceId,
    required List<QueryRow> availableRows,
  }) async {
    final purchaseItemIds = availableRows
        .map((row) => row.readNullable<int>('purchase_voucher_item_id'))
        .whereType<int>()
        .toSet();
    if (purchaseItemIds.length != 1) {
      return null;
    }

    final row = await _db.customSelect(
      '''
      SELECT
        pvi.gross_weight AS original_gross_weight,
        pvi.less_weight AS original_less_weight,
        pvi.net_weight AS original_net_weight,
        pvi.fine_weight AS original_fine_weight,
        pvi.wastage_fine_weight AS original_wastage_fine_weight,
        pvi.valuation_fine_weight AS original_valuation_fine_weight,
        pvi.line_amount AS original_line_amount,
        COALESCE(sales.sold_gross_weight, 0.0) AS sold_gross_weight,
        COALESCE(sales.sold_less_weight, 0.0) AS sold_less_weight,
        COALESCE(sales.sold_net_weight, 0.0) AS sold_net_weight,
        COALESCE(sales.sold_fine_weight, 0.0) AS sold_fine_weight,
        COALESCE(sales.sold_amount, 0.0) AS sold_amount
      FROM purchase_voucher_items pvi
      LEFT JOIN (
        SELECT
          linked_stock_item_id AS stock_item_id,
          SUM(COALESCE(gross_weight, 0.0)) AS sold_gross_weight,
          SUM(COALESCE(less_weight, 0.0)) AS sold_less_weight,
          SUM(COALESCE(net_weight, 0.0)) AS sold_net_weight,
          SUM(COALESCE(fine_weight, 0.0)) AS sold_fine_weight,
          SUM(COALESCE(item_total, 0.0)) AS sold_amount
        FROM bill_items
        WHERE linked_stock_item_id = ?
          AND CAST(bill_id AS TEXT) <> ?
        GROUP BY linked_stock_item_id
      ) sales ON sales.stock_item_id = ?
      WHERE pvi.id = ?
      ''',
      variables: [
        Variable<int>(stockItemId),
        Variable<String>(currentSourceId),
        Variable<int>(stockItemId),
        Variable<int>(purchaseItemIds.single),
      ],
    ).getSingleOrNull();
    if (row == null) {
      return null;
    }

    return _StockLotBalance(
      grossWeight: _nonNegative(
        (row.readNullable<double>('original_gross_weight') ?? 0) -
            (row.readNullable<double>('sold_gross_weight') ?? 0),
      ),
      lessWeight: _nonNegative(
        (row.readNullable<double>('original_less_weight') ?? 0) -
            (row.readNullable<double>('sold_less_weight') ?? 0),
      ),
      netWeight: _nonNegative(
        (row.readNullable<double>('original_net_weight') ?? 0) -
            (row.readNullable<double>('sold_net_weight') ?? 0),
      ),
      fineWeight: _nonNegative(
        (row.readNullable<double>('original_fine_weight') ?? 0) -
            (row.readNullable<double>('sold_fine_weight') ?? 0),
      ),
      wastageFineWeight:
          row.readNullable<double>('original_wastage_fine_weight') ?? 0,
      valuationFineWeight:
          row.readNullable<double>('original_valuation_fine_weight') ?? 0,
      unitCost: _nonNegative(
        (row.readNullable<double>('original_line_amount') ?? 0) -
            (row.readNullable<double>('sold_amount') ?? 0),
      ),
      makingAmount: 0,
    );
  }

  Future<void> _deductLotStock({
    required StockItem stockRow,
    required int quantityToSell,
    required double saleGrossWeight,
    required double saleLessWeight,
    required double saleNetWeight,
    required double saleFineWeight,
    required double saleLineAmount,
    required double saleMakingAmount,
    required String sourceId,
    required String sourceNumber,
    required int sourceLineNo,
  }) async {
    final lotUnit = await _lotStockUnit(stockRow.id);
    if (lotUnit == null) {
      throw StateError('Stock lot ${stockRow.sku} is not available.');
    }
    final status = lotUnit.read<String>('status');
    if (status != stock.StockStatus.available.label) {
      throw StateError('Selected stock lot is no longer available for sale.');
    }

    final remainingQty = stockRow.quantity - quantityToSell;
    final now = DateTime.now();
    final isFullLotSale = quantityToSell >= stockRow.quantity;
    final delta = isFullLotSale
        ? _lotDelta(
            stockRow: stockRow,
            unitRow: lotUnit,
            quantity: quantityToSell,
            sign: -1,
          )
        : _lotSaleDelta(
            stockRow: stockRow,
            unitRow: lotUnit,
            quantity: quantityToSell,
            saleGrossWeight: saleGrossWeight,
            saleLessWeight: saleLessWeight,
            saleNetWeight: saleNetWeight,
            saleFineWeight: saleFineWeight,
            saleLineAmount: saleLineAmount,
            saleMakingAmount: saleMakingAmount,
          );

    await _writeLotBalance(
      stockRow: stockRow,
      lotUnit: lotUnit,
      quantity: remainingQty,
      delta: delta,
      status: remainingQty > 0
          ? stock.StockStatus.available.label
          : stock.StockStatus.sold.label,
      soldAt: remainingQty > 0 ? null : now,
      updatedAt: now,
    );

    await _insertStockMovement(
      stockRow: stockRow,
      movementType: 'SALE',
      sourceType: 'SALE',
      sourceId: sourceId,
      sourceNumber: sourceNumber,
      sourceLineNo: sourceLineNo,
      quantityDelta: -quantityToSell,
      grossWeightDelta: delta.grossWeight,
      netWeightDelta: delta.netWeight,
      fineWeightDelta: delta.fineWeight,
      reason: 'POS sale stock deduction',
      occurredAt: now,
    );
  }

  Future<void> _restoreLotStock({
    required StockItem stockRow,
    required int quantityToRestore,
    required String sourceId,
    required String sourceNumber,
    required int sourceLineNo,
  }) async {
    final lotUnit = await _lotStockUnit(stockRow.id);
    if (lotUnit == null) {
      throw StateError('Linked stock lot ${stockRow.sku} no longer exists.');
    }

    final now = DateTime.now();
    final restoredQty = stockRow.quantity + quantityToRestore;
    final delta = await _saleRestoreDelta(
          stockItemId: stockRow.id,
          stockRow: stockRow,
          sourceId: sourceId,
          sourceLineNo: sourceLineNo,
        ) ??
        _lotDelta(
          stockRow: stockRow,
          unitRow: lotUnit,
          quantity: quantityToRestore,
          sign: 1,
        );

    await _writeLotBalance(
      stockRow: stockRow,
      lotUnit: lotUnit,
      quantity: restoredQty,
      delta: delta,
      status: stock.StockStatus.available.label,
      soldAt: null,
      updatedAt: now,
    );

    await _insertStockMovement(
      stockRow: stockRow,
      movementType: 'SALE_RESTORE',
      sourceType: 'SALE',
      sourceId: sourceId,
      sourceNumber: sourceNumber,
      sourceLineNo: sourceLineNo,
      quantityDelta: quantityToRestore,
      grossWeightDelta: delta.grossWeight,
      netWeightDelta: delta.netWeight,
      fineWeightDelta: delta.fineWeight,
      reason: 'Sale edit stock restore',
      occurredAt: now,
    );
  }

  Future<_StockLotDelta?> _saleRestoreDelta({
    required int stockItemId,
    required StockItem stockRow,
    required String sourceId,
    required int sourceLineNo,
  }) async {
    final row = await _db.customSelect(
      '''
      SELECT
        m.quantity_delta,
        m.gross_weight_delta,
        m.net_weight_delta,
        m.fine_weight_delta,
        COALESCE(i.stock_unit_cost, 0.0) AS bill_stock_unit_cost,
        COALESCE(i.making_charge, 0.0) AS bill_making_charge,
        COALESCE(i.net_weight, 0.0) AS bill_net_weight,
        u.purchase_voucher_item_id AS purchase_voucher_item_id
      FROM stock_movements m
      LEFT JOIN bill_items i ON CAST(i.bill_id AS TEXT) = m.source_id
          AND i.line_no = m.source_line_no
          AND i.linked_stock_item_id = m.stock_item_id
      LEFT JOIN stock_item_units u ON u.stock_item_id = m.stock_item_id
      WHERE m.stock_item_id = ?
        AND m.source_type = 'SALE'
        AND m.source_id = ?
        AND m.source_line_no = ?
        AND m.movement_type = 'SALE'
      ORDER BY m.id DESC
      LIMIT 1
      ''',
      variables: [
        Variable<int>(stockItemId),
        Variable<String>(sourceId),
        Variable<int>(sourceLineNo),
      ],
    ).getSingleOrNull();
    if (row == null) {
      return null;
    }
    final gross = -row.read<double>('gross_weight_delta');
    final net = -row.read<double>('net_weight_delta');
    final fine = -row.read<double>('fine_weight_delta');
    final quantity = row.read<int>('quantity_delta').abs();
    final billStockUnitCost =
        row.readNullable<double>('bill_stock_unit_cost') ?? 0.0;
    final billMakingCharge =
        row.readNullable<double>('bill_making_charge') ?? 0.0;
    final purchaseSnapshot = await _purchaseRatioRestoreSnapshot(
      purchaseVoucherItemId: row.readNullable<int>('purchase_voucher_item_id'),
      soldNetWeight: row.readNullable<double>('bill_net_weight') ?? net,
    );
    return _StockLotDelta(
      grossWeight: gross,
      lessWeight: gross - net,
      netWeight: net,
      fineWeight: fine,
      wastageFineWeight: purchaseSnapshot.wastageFineWeight,
      valuationFineWeight: purchaseSnapshot.valuationFineWeight > 0
          ? purchaseSnapshot.valuationFineWeight
          : fine,
      unitCost: billStockUnitCost > 0
          ? billStockUnitCost
          : stockRow.purchasePrice * quantity,
      makingAmount: billMakingCharge,
    );
  }

  Future<_LotPurchaseRestoreSnapshot> _purchaseRatioRestoreSnapshot({
    required int? purchaseVoucherItemId,
    required double soldNetWeight,
  }) async {
    if (purchaseVoucherItemId == null || soldNetWeight <= 0) {
      return const _LotPurchaseRestoreSnapshot.zero();
    }
    final row = await _db.customSelect(
      '''
      SELECT
        net_weight,
        wastage_fine_weight,
        valuation_fine_weight,
        fine_weight
      FROM purchase_voucher_items
      WHERE id = ?
      LIMIT 1
      ''',
      variables: [Variable<int>(purchaseVoucherItemId)],
    ).getSingleOrNull();
    if (row == null) {
      return const _LotPurchaseRestoreSnapshot.zero();
    }

    final originalNetWeight = row.readNullable<double>('net_weight') ?? 0.0;
    if (originalNetWeight <= 0) {
      return const _LotPurchaseRestoreSnapshot.zero();
    }
    final factor = (soldNetWeight / originalNetWeight).clamp(0.0, 1.0);
    final originalWastage =
        row.readNullable<double>('wastage_fine_weight') ?? 0.0;
    final originalValuation =
        (row.readNullable<double>('valuation_fine_weight') ?? 0.0) > 0
            ? row.read<double>('valuation_fine_weight')
            : (row.readNullable<double>('fine_weight') ?? 0.0) +
                originalWastage;
    return _LotPurchaseRestoreSnapshot(
      wastageFineWeight: originalWastage * factor,
      valuationFineWeight: originalValuation * factor,
    );
  }

  Future<void> _writeLotBalance({
    required StockItem stockRow,
    required QueryRow lotUnit,
    required int quantity,
    required _StockLotDelta delta,
    required String status,
    required DateTime? soldAt,
    required DateTime updatedAt,
  }) async {
    final nextGross = _nonNegative(stockRow.grossWeight + delta.grossWeight);
    final nextLess = _nonNegative(stockRow.stoneWeight + delta.lessWeight);
    final nextNet = _nonNegative(stockRow.netWeight + delta.netWeight);
    await (_db.update(_db.stockItems)
          ..where((tbl) => tbl.id.equals(stockRow.id)))
        .write(
      StockItemsCompanion(
        quantity: Value(quantity),
        grossWeight: Value(nextGross),
        stoneWeight: Value(nextLess),
        netWeight: Value(nextNet),
        isActive: Value(quantity > 0),
        status: Value(status),
        updatedAt: Value(updatedAt),
      ),
    );

    await _db.customStatement(
      '''
      UPDATE stock_item_units
      SET gross_weight = ?,
          less_weight = ?,
          net_weight = ?,
          actual_fine_weight = ?,
          wastage_fine_weight = ?,
          valuation_fine_weight = ?,
          unit_cost = ?,
          making_amount = ?,
          status = ?,
          sold_at = ?,
          updated_at = ?
      WHERE id = ?
      ''',
      [
        _nonNegative(lotUnit.read<double>('gross_weight') + delta.grossWeight),
        _nonNegative(lotUnit.read<double>('less_weight') + delta.lessWeight),
        _nonNegative(lotUnit.read<double>('net_weight') + delta.netWeight),
        _nonNegative(
          lotUnit.read<double>('actual_fine_weight') + delta.fineWeight,
        ),
        _nonNegative(
          lotUnit.read<double>('wastage_fine_weight') + delta.wastageFineWeight,
        ),
        _nonNegative(
          lotUnit.read<double>('valuation_fine_weight') +
              delta.valuationFineWeight,
        ),
        _nonNegative(lotUnit.read<double>('unit_cost') + delta.unitCost),
        _nonNegative(
            lotUnit.read<double>('making_amount') + delta.makingAmount),
        status,
        soldAt?.millisecondsSinceEpoch,
        updatedAt.millisecondsSinceEpoch,
        lotUnit.read<int>('id'),
      ],
    );
  }

  _StockLotDelta _lotDelta({
    required StockItem stockRow,
    required QueryRow unitRow,
    required int quantity,
    required int sign,
  }) {
    final safeQuantity = stockRow.quantity < 1 ? quantity : stockRow.quantity;
    final factor = safeQuantity <= 0 ? 1.0 : quantity / safeQuantity;
    return _StockLotDelta(
      grossWeight: unitRow.read<double>('gross_weight') * factor * sign,
      lessWeight: unitRow.read<double>('less_weight') * factor * sign,
      netWeight: unitRow.read<double>('net_weight') * factor * sign,
      fineWeight: unitRow.read<double>('actual_fine_weight') * factor * sign,
      wastageFineWeight:
          unitRow.read<double>('wastage_fine_weight') * factor * sign,
      valuationFineWeight:
          unitRow.read<double>('valuation_fine_weight') * factor * sign,
      unitCost: unitRow.read<double>('unit_cost') * factor * sign,
      makingAmount: unitRow.read<double>('making_amount') * factor * sign,
    );
  }

  _StockLotDelta _lotSaleDelta({
    required StockItem stockRow,
    required QueryRow unitRow,
    required int quantity,
    required double saleGrossWeight,
    required double saleLessWeight,
    required double saleNetWeight,
    required double saleFineWeight,
    required double saleLineAmount,
    required double saleMakingAmount,
  }) {
    final currentGross = unitRow.read<double>('gross_weight');
    final currentLess = unitRow.read<double>('less_weight');
    final currentNet = unitRow.read<double>('net_weight');
    final currentFine = unitRow.read<double>('actual_fine_weight');
    if (saleGrossWeight <= 0 && saleNetWeight <= 0) {
      return _lotDelta(
        stockRow: stockRow,
        unitRow: unitRow,
        quantity: quantity,
        sign: -1,
      );
    }

    final gross = saleGrossWeight > 0 ? saleGrossWeight : saleNetWeight;
    final less = saleLessWeight > 0 ? saleLessWeight : (gross - saleNetWeight);
    final net = saleNetWeight > 0 ? saleNetWeight : gross - less;
    final safeGross = gross.clamp(0.0, currentGross).toDouble();
    final safeLess = less.clamp(0.0, currentLess).toDouble();
    final safeNet = net.clamp(0.0, currentNet).toDouble();
    final netFactor = currentNet <= 0 ? 0.0 : safeNet / currentNet;
    final fine = saleFineWeight > 0 ? saleFineWeight : currentFine * netFactor;
    final safeFine = fine.clamp(0.0, currentFine).toDouble();

    return _StockLotDelta(
      grossWeight: -safeGross,
      lessWeight: -safeLess,
      netWeight: -safeNet,
      fineWeight: -safeFine,
      wastageFineWeight:
          -(unitRow.read<double>('wastage_fine_weight') * netFactor),
      valuationFineWeight:
          -(unitRow.read<double>('valuation_fine_weight') * netFactor),
      unitCost: -(unitRow.read<double>('unit_cost') * netFactor),
      makingAmount: -(saleMakingAmount > 0
          ? saleMakingAmount
          : unitRow.read<double>('making_amount') * netFactor),
    );
  }

  _StockLotDelta _deltaFromRows(
    List<QueryRow> rows,
    int quantity,
    int sign,
  ) {
    if (rows.isEmpty) {
      return const _StockLotDelta.zero();
    }
    final selectedRows = rows.take(quantity).toList(growable: false);
    return _StockLotDelta(
      grossWeight: selectedRows.fold(
            0.0,
            (sum, row) => sum + row.read<double>('gross_weight'),
          ) *
          sign,
      lessWeight: selectedRows.fold(
            0.0,
            (sum, row) => sum + row.read<double>('less_weight'),
          ) *
          sign,
      netWeight: selectedRows.fold(
            0.0,
            (sum, row) => sum + row.read<double>('net_weight'),
          ) *
          sign,
      fineWeight: selectedRows.fold(
            0.0,
            (sum, row) => sum + row.read<double>('actual_fine_weight'),
          ) *
          sign,
      wastageFineWeight: selectedRows.fold(
            0.0,
            (sum, row) => sum + row.read<double>('wastage_fine_weight'),
          ) *
          sign,
      valuationFineWeight: selectedRows.fold(
            0.0,
            (sum, row) => sum + row.read<double>('valuation_fine_weight'),
          ) *
          sign,
      unitCost: selectedRows.fold(
            0.0,
            (sum, row) => sum + row.read<double>('unit_cost'),
          ) *
          sign,
      makingAmount: selectedRows.fold(
            0.0,
            (sum, row) => sum + row.read<double>('making_amount'),
          ) *
          sign,
    );
  }

  double _nonNegative(double value) {
    if (value.abs() < 0.000001) {
      return 0;
    }
    return value < 0 ? 0 : value;
  }

  String? _stockUnitWhereClause({
    required int? stockUnitId,
    required String? stockUnitCode,
  }) {
    if (stockUnitId != null) {
      return 'stock_item_id = ? AND id = ?';
    }
    final normalized = stockUnitCode?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return 'stock_item_id = ? AND unit_code = ?';
    }
    return null;
  }

  List<Variable<Object>> _stockUnitWhereVariables({
    required int stockItemId,
    required int? stockUnitId,
    required String? stockUnitCode,
  }) {
    if (stockUnitId != null) {
      return [Variable<int>(stockItemId), Variable<int>(stockUnitId)];
    }
    return [
      Variable<int>(stockItemId),
      Variable<String>(stockUnitCode!.trim())
    ];
  }

  Future<void> _insertStockMovement({
    required StockItem stockRow,
    required String movementType,
    required String sourceType,
    required String sourceId,
    required String sourceNumber,
    required int sourceLineNo,
    required int quantityDelta,
    required double grossWeightDelta,
    required double netWeightDelta,
    required double fineWeightDelta,
    required String reason,
    required DateTime occurredAt,
  }) {
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
        grossWeightDelta,
        netWeightDelta,
        fineWeightDelta,
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
    final normalizedCode =
        PosInvoiceSeriesFormatter.normalizeBusinessCode(shopInitials);
    final normalizedYear =
        PosInvoiceSeriesFormatter.normalizeFinancialYearToken(financialYear);
    final bills = await _db.select(_db.bills).get();

    if (preferredInvoiceNumber != null &&
        !_billNumberExists(bills, preferredInvoiceNumber)) {
      final parsed = PosInvoiceSeriesFormatter.parse(preferredInvoiceNumber);
      if (parsed != null &&
          !parsed.isLegacy &&
          parsed.businessCode == normalizedCode &&
          parsed.financialYearToken == normalizedYear &&
          parsed.sequence > 0) {
        return _ResolvedInvoiceNumber(
          billNumber: preferredInvoiceNumber,
          sequence: parsed.sequence,
        );
      }
    }

    var maxSequence = 0;
    for (final bill in bills) {
      final parsed = PosInvoiceSeriesFormatter.parse(bill.billNo);
      if (parsed != null &&
          parsed.businessCode == normalizedCode &&
          parsed.financialYearToken == normalizedYear &&
          parsed.sequence > maxSequence) {
        maxSequence = parsed.sequence;
      }
    }

    final nextSequence = maxSequence + 1;
    return _ResolvedInvoiceNumber(
      billNumber: _buildBillNumber(
        invoicePrefix: invoicePrefix,
        shopInitials: normalizedCode,
        financialYear: normalizedYear,
        sequence: nextSequence,
      ),
      sequence: nextSequence,
    );
  }

  bool _billNumberExists(List<Bill> bills, String billNumber) {
    return bills.any((bill) => bill.billNo == billNumber);
  }

  String _buildBillNumber({
    required String invoicePrefix,
    required String shopInitials,
    required String financialYear,
    required int sequence,
  }) {
    return PosInvoiceSeriesFormatter.build(
      businessCode: shopInitials,
      financialYearToken: financialYear,
      sequence: sequence,
    );
  }

  String _invoicePrefixFromBillNo(String billNumber) {
    return '';
  }

  String _shopInitialsFromBillNo(String billNumber) {
    return PosInvoiceSeriesFormatter.parse(billNumber)?.businessCode ?? 'SH';
  }

  String _financialYearFromBillNo(String billNumber, DateTime invoiceDate) {
    return PosInvoiceSeriesFormatter.parse(billNumber)?.financialYearToken ??
        PosInvoiceSeriesFormatter.financialYearToken(invoiceDate);
  }

  double _parseSafeNumber(String text) {
    return PosNumberParser.parseNonNegative(text);
  }

  _PosInvoiceMoneySnapshot _moneySnapshot(PosInvoiceModel invoice) {
    final totalGst = _roundMoney(invoice.totalGst);
    final interState = _isInterStateSupply(invoice);
    final cgst = interState ? 0.0 : _roundMoney(totalGst / 2);
    final sgst = interState ? 0.0 : _roundMoney(totalGst - cgst);
    final igst = interState ? totalGst : 0.0;
    final cashPaid = _roundMoney(invoice.cashPaid);
    final upiPaid = _roundMoney(invoice.upiPaid);
    final cardPaid = _roundMoney(invoice.cardPaid);
    final advancePaid = _roundMoney(invoice.advancePaid);
    final totalPaid = _roundMoney(cashPaid + upiPaid + cardPaid + advancePaid);
    final netPayable = _roundMoney(invoice.netPayable);
    final balanceAmount = _settleMoney(netPayable - totalPaid);
    final dueAmount = balanceAmount > 0.005 ? balanceAmount : 0.0;

    return _PosInvoiceMoneySnapshot(
      grossAmount: _roundMoney(invoice.grossAmount),
      discountAmount: _roundMoney(invoice.discountAmount),
      taxableAmount: _roundMoney(invoice.taxableAmount),
      cgst: cgst,
      sgst: sgst,
      igst: igst,
      totalGst: totalGst,
      totalMakingCharge: _roundMoney(invoice.totalMakingCharge),
      roundOffAmount: _roundMoney(invoice.roundOffAmount),
      netPayable: netPayable,
      cashPaid: cashPaid,
      upiPaid: upiPaid,
      cardPaid: cardPaid,
      advancePaid: advancePaid,
      totalPaid: totalPaid,
      balanceAmount: balanceAmount,
      dueAmount: dueAmount,
      tradeInDeduction: _roundMoney(invoice.totalTradeInDeduction),
    );
  }

  _PosLineTaxSnapshot _lineTaxSnapshot(
    SaleItemModel item,
    PosInvoiceModel invoice,
    _PosInvoiceMoneySnapshot money,
  ) {
    final ratio = _allocationRatio(
      scopedGross: item.totalValue,
      invoiceGross: money.grossAmount,
    );
    final taxable = _roundMoney(money.taxableAmount * ratio);
    final cgst = _roundMoney(money.cgst * ratio);
    final sgst = _roundMoney(money.sgst * ratio);
    final igst = _roundMoney(money.igst * ratio);
    final totalGst = _roundMoney(cgst + sgst + igst);
    final gstRate = taxable.abs() <= 0.005 ? 0.0 : (totalGst / taxable) * 100;

    return _PosLineTaxSnapshot(
      taxableAmount: taxable,
      gstRate: _roundMoney(gstRate),
      cgst: cgst,
      sgst: sgst,
      igst: igst,
      totalGst: totalGst,
      invoiceValue: _roundMoney(taxable + totalGst),
    );
  }

  double _allocationRatio({
    required double scopedGross,
    required double invoiceGross,
  }) {
    if (scopedGross <= 0.005) return 0;
    if (invoiceGross.abs() <= 0.005) return 1;
    return scopedGross / invoiceGross;
  }

  bool _isInterStateSupply(PosInvoiceModel invoice) {
    final jurisdiction = GstJurisdictionResolver.resolve(
      shopGstin: invoice.shopGstin,
      shopStateCode: invoice.shopStateCode,
      shopStateName: invoice.shopAddress,
      customerGstin: invoice.customerGstin,
      customerStateCode: invoice.customerStateCode,
      customerStateName: invoice.customerCity,
      placeOfSupply: invoice.placeOfSupply,
    );
    return jurisdiction.isResolved && jurisdiction.isInterState;
  }

  String _resolvePaymentStatus(_PosInvoiceMoneySnapshot money) {
    if (money.netPayable < 0 || money.balanceAmount < -0.50) {
      return 'CREDIT';
    }
    if (money.totalPaid <= 0.005) {
      return 'UNPAID';
    }
    if (money.dueAmount > 0.005) {
      return 'PARTIAL';
    }
    return 'PAID';
  }

  String _dbBillingMode(BillingMode mode) {
    return mode == BillingMode.retail ? 'RETAIL' : 'WHOLESALE';
  }

  String _dbTradeInMode(TradeInAdjustMode mode) {
    return mode == TradeInAdjustMode.cashAdjust
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
    item.setInvoiceHsnCode(row.hsnCode);
    item.pcsCtrl.text = row.quantity.toString();
    item.setHuidText(row.huid ?? '');
    item.purityCtrl.text = row.purity;
    item.grossCtrl.text = _formatPersistedWeight(row.grossWeight);
    item.lessCtrl.text = _formatPersistedWeight(row.lessWeight);
    item.rateCtrl.text = _formatPersistedNumber(row.rate);
    item.makingCtrl.text = _formatPersistedNumber(row.makingChargeInput);
    if (row.linkedStockItemId != null && row.linkedStockSku != null) {
      item.attachStockReference(
        stockItemId: row.linkedStockItemId!,
        stockUnitId: row.linkedStockUnitId,
        stockUnitCost: row.stockUnitCost,
        stockSnapshotNetWeight: row.netWeight,
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

  String _formatPersistedWeight(double value) {
    return PosNumberFormatter.weight(value);
  }

  double _roundMoney(double amount) {
    return PosMoneyMath.roundToPaisa(amount);
  }

  double _settleMoney(double amount) {
    return PosMoneyMath.settlePaisa(amount);
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
    final normalizedAmount = _roundMoney(amount);
    if (normalizedAmount <= 0) return;
    final txnId = await _generateCashTxnId();
    await _db.into(_db.cashTransactions).insert(
          CashTransactionsCompanion.insert(
            txnId: txnId,
            txnDate: txnDate,
            type: cash_book.CashTransactionType.income.dbValue,
            category: category.dbValue,
            amount: Value(normalizedAmount),
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
    final normalizedAmount = _roundMoney(amount);
    if (normalizedAmount <= 0) return;
    final txnId = await _generateCashTxnId();
    await _db.into(_db.cashTransactions).insert(
          CashTransactionsCompanion.insert(
            txnId: txnId,
            txnDate: txnDate,
            type: cash_book.CashTransactionType.expense.dbValue,
            category: category.dbValue,
            amount: Value(normalizedAmount),
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
    final normalizedAmount = _roundMoney(amount);
    if (normalizedAmount <= 0) return;
    final txnId = await _generateBankTxnId();
    await _db.into(_db.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: txnId,
            accountId: accountId,
            txnDate: txnDate,
            type: bank_book.BankTransactionType.credit.dbValue,
            category: category.dbValue,
            amount: Value(normalizedAmount),
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
    final normalizedAmount = _roundMoney(amount);
    if (normalizedAmount <= 0) return;
    final txnId = await _generateBankTxnId();
    await _db.into(_db.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: txnId,
            accountId: accountId,
            txnDate: txnDate,
            type: bank_book.BankTransactionType.debit.dbValue,
            category: category.dbValue,
            amount: Value(normalizedAmount),
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

class _StockLotDelta {
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double fineWeight;
  final double wastageFineWeight;
  final double valuationFineWeight;
  final double unitCost;
  final double makingAmount;

  const _StockLotDelta({
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.fineWeight,
    required this.wastageFineWeight,
    required this.valuationFineWeight,
    required this.unitCost,
    required this.makingAmount,
  });

  const _StockLotDelta.zero()
      : grossWeight = 0,
        lessWeight = 0,
        netWeight = 0,
        fineWeight = 0,
        wastageFineWeight = 0,
        valuationFineWeight = 0,
        unitCost = 0,
        makingAmount = 0;
}

class _LotPurchaseRestoreSnapshot {
  final double wastageFineWeight;
  final double valuationFineWeight;

  const _LotPurchaseRestoreSnapshot({
    required this.wastageFineWeight,
    required this.valuationFineWeight,
  });

  const _LotPurchaseRestoreSnapshot.zero()
      : wastageFineWeight = 0,
        valuationFineWeight = 0;
}

class _PosInvoiceMoneySnapshot {
  const _PosInvoiceMoneySnapshot({
    required this.grossAmount,
    required this.discountAmount,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.totalGst,
    required this.totalMakingCharge,
    required this.roundOffAmount,
    required this.netPayable,
    required this.cashPaid,
    required this.upiPaid,
    required this.cardPaid,
    required this.advancePaid,
    required this.totalPaid,
    required this.balanceAmount,
    required this.dueAmount,
    required this.tradeInDeduction,
  });

  final double grossAmount;
  final double discountAmount;
  final double taxableAmount;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalGst;
  final double totalMakingCharge;
  final double roundOffAmount;
  final double netPayable;
  final double cashPaid;
  final double upiPaid;
  final double cardPaid;
  final double advancePaid;
  final double totalPaid;
  final double balanceAmount;
  final double dueAmount;
  final double tradeInDeduction;
}

class _PosLineTaxSnapshot {
  const _PosLineTaxSnapshot({
    required this.taxableAmount,
    required this.gstRate,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.totalGst,
    required this.invoiceValue,
  });

  final double taxableAmount;
  final double gstRate;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalGst;
  final double invoiceValue;
}

class _StockLotBalance {
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double fineWeight;
  final double wastageFineWeight;
  final double valuationFineWeight;
  final double unitCost;
  final double makingAmount;

  const _StockLotBalance({
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.fineWeight,
    required this.wastageFineWeight,
    required this.valuationFineWeight,
    required this.unitCost,
    required this.makingAmount,
  });
}

class _ResolvedInvoiceNumber {
  final String billNumber;
  final int sequence;

  const _ResolvedInvoiceNumber({
    required this.billNumber,
    required this.sequence,
  });
}

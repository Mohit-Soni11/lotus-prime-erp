import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/pdf/return_reversal_sales_invoice_pdf_service.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/pdf/return_reversal_voucher_pdf_service.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_line_inspection.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_state.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_workflow_step.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_process.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_transaction_summary.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart'
    as pos;
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';
import 'package:lotus_erp/models/setting/billing_setup/sales_billing_model.dart';
import 'package:lotus_erp/repositories/sales_orders/pos/pos_checkout_repository.dart';
import 'package:lotus_erp/repositories/setting/billing_setup/sales_billing_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'lotus_erp_permanent_tenant_id': 'tenant_return_voucher_pdf_test',
    });
  });

  test('builds PDF bytes for sales return voucher', () async {
    final state = _stateFor(
      operationType: ReturnReversalOperationType.salesReturn,
      sourceType: ReturnReversalSourceDocumentType.salesInvoice,
      documentNo: 'AJ-26-003',
    );

    final bytes = await ReturnReversalVoucherPdfService.buildVoucherBytes(
      state: state,
      options: _options,
    );

    expect(_pdfHeader(bytes), '%PDF');
    expect(
      ReturnReversalVoucherPdfService.documentKindFor(state),
      ReturnReversalVoucherDocumentKind.salesReturn,
    );
  });

  test('builds A4 PDF bytes through every Lotus voucher template', () async {
    final state = _stateFor(
      operationType: ReturnReversalOperationType.salesReturn,
      sourceType: ReturnReversalSourceDocumentType.salesInvoice,
      documentNo: 'AJ-26-003',
    );

    for (final template in PrintTemplateRegistry.forDocument(
      ReturnReversalVoucherDocumentKind.salesReturn.printTemplateDocumentType,
    )) {
      final bytes = await ReturnReversalVoucherPdfService.buildVoucherBytes(
        state: state,
        options: _options.copyWith(templateId: template.id),
      );

      expect(_pdfHeader(bytes), '%PDF', reason: template.id);
      expect(bytes.length, greaterThan(1000), reason: template.id);
    }
  });

  test('builds PDF bytes for booking cancellation voucher', () async {
    final state = _stateFor(
      operationType: ReturnReversalOperationType.bookingCancellation,
      sourceType: ReturnReversalSourceDocumentType.advanceBooking,
      documentNo: 'BK-LJ-2627-0002',
    );

    final bytes = await ReturnReversalVoucherPdfService.buildVoucherBytes(
      state: state,
      options: _options.copyWith(includeStockRouting: false),
    );

    expect(_pdfHeader(bytes), '%PDF');
    expect(
      ReturnReversalVoucherPdfService.documentKindFor(state),
      ReturnReversalVoucherDocumentKind.bookingCancellation,
    );
  });

  test('builds booking cancellation voucher through every Lotus template',
      () async {
    final state = _stateFor(
      operationType: ReturnReversalOperationType.bookingCancellation,
      sourceType: ReturnReversalSourceDocumentType.advanceBooking,
      documentNo: 'BK-LJ-2627-0002',
    );

    final templates = PrintTemplateRegistry.forDocument(
      ReturnReversalVoucherDocumentKind
          .bookingCancellation.printTemplateDocumentType,
    );
    expect(templates, hasLength(3));

    for (final template in templates) {
      final bytes = await ReturnReversalVoucherPdfService.buildVoucherBytes(
        state: state,
        options: _options.copyWith(
          templateId: template.id,
          includeStockRouting: false,
        ),
      );

      expect(_pdfHeader(bytes), '%PDF', reason: template.id);
      expect(bytes.length, greaterThan(1000), reason: template.id);
    }
  });

  test('builds PDF bytes for customer purchase reversal voucher', () async {
    final state = _stateFor(
      operationType: ReturnReversalOperationType.salesReturn,
      sourceType: ReturnReversalSourceDocumentType.customerPurchase,
      documentNo: 'CP-26-019',
    );

    final bytes = await ReturnReversalVoucherPdfService.buildVoucherBytes(
      state: state,
      options: _options,
    );

    expect(_pdfHeader(bytes), '%PDF');
    expect(
      ReturnReversalVoucherPdfService.documentKindFor(state),
      ReturnReversalVoucherDocumentKind.customerPurchaseReversal,
    );
  });

  test('builds original and updated sales invoice PDFs through every template',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = PosCheckoutRepository(db: db);
    final salesBillingRepo = SalesBillingRepo(db: db);
    await salesBillingRepo.saveForMetal(
      SalesBillingModel.defaultFor('gold').copyWith(
        selectedTemplate: PrintTemplateRegistry.lotusSignature.id,
        termsAndConditions: 'Gold policy locked from sales setup.',
        printTermsAndConditions: true,
      ),
    );
    await salesBillingRepo.saveForMetal(
      SalesBillingModel.defaultFor('silver').copyWith(
        selectedTemplate: PrintTemplateRegistry.lotusEconomy.id,
        termsAndConditions: 'Silver policy locked from sales setup.',
        printTermsAndConditions: true,
      ),
    );
    final result = await repository.finalizeSale(
      invoice: _posInvoiceForOriginalCopy(),
      customerId: null,
    );
    final state = _salesInvoiceStateWithReturnedAndSelectedLines(
      sourceId: result.billId,
      documentNo: result.invoiceNumber,
    );

    for (final mode in ReturnReversalSalesInvoiceCopyMode.values) {
      for (final template in PrintTemplateRegistry.forDocument(
        PrintTemplateDocumentType.salesInvoice,
      )) {
        final bytes =
            await ReturnReversalSalesInvoicePdfService.buildInvoiceBytes(
          state: state,
          mode: mode,
          options: _options.copyWith(templateId: template.id),
          checkoutRepository: repository,
          salesBillingRepo: salesBillingRepo,
          shopProfileOverride: ShopPrintDocumentProfile.empty,
        );

        expect(_pdfHeader(bytes), '%PDF',
            reason: '${mode.name}:${template.id}');
        expect(bytes.length, greaterThan(1000),
            reason: '${mode.name}:${template.id}');
      }
    }
  });

  test('original sales invoice PDF supports locked metal-specific scopes',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = PosCheckoutRepository(db: db);
    final salesBillingRepo = SalesBillingRepo(db: db);
    final result = await repository.finalizeSale(
      invoice: _posInvoiceForOriginalCopy(),
      customerId: null,
    );
    final state = _salesInvoiceStateWithReturnedAndSelectedLines(
      sourceId: result.billId,
      documentNo: result.invoiceNumber,
    );

    final goldBytes =
        await ReturnReversalSalesInvoicePdfService.buildInvoiceBytes(
      state: state,
      mode: ReturnReversalSalesInvoiceCopyMode.original,
      options:
          _options.copyWith(templateId: PrintTemplateRegistry.lotusEconomy.id),
      checkoutRepository: repository,
      salesBillingRepo: salesBillingRepo,
      shopProfileOverride: ShopPrintDocumentProfile.empty,
      activeMetal: pos.MetalType.gold,
      includeAllMetals: false,
    );
    final silverBytes =
        await ReturnReversalSalesInvoicePdfService.buildInvoiceBytes(
      state: state,
      mode: ReturnReversalSalesInvoiceCopyMode.original,
      options:
          _options.copyWith(templateId: PrintTemplateRegistry.lotusEconomy.id),
      checkoutRepository: repository,
      salesBillingRepo: salesBillingRepo,
      shopProfileOverride: ShopPrintDocumentProfile.empty,
      activeMetal: pos.MetalType.silver,
      includeAllMetals: false,
    );

    expect(_pdfHeader(goldBytes), '%PDF');
    expect(_pdfHeader(silverBytes), '%PDF');
    expect(goldBytes.length, greaterThan(1000));
    expect(silverBytes.length, greaterThan(1000));
  });

  test('updated sales invoice copy keeps only available source lines', () {
    final state = _salesInvoiceStateWithReturnedAndSelectedLines();

    final original =
        ReturnReversalSalesInvoicePdfService.buildPrintableDocumentForTesting(
      state: state,
      mode: ReturnReversalSalesInvoiceCopyMode.original,
    );
    final updated =
        ReturnReversalSalesInvoicePdfService.buildPrintableDocumentForTesting(
      state: state,
      mode: ReturnReversalSalesInvoiceCopyMode.updatedAfterReturn,
    );

    expect(original.itemTable.rows.map((row) => row.first), ['1', '2', '3']);
    expect(updated.itemTable.rows.map((row) => row.first), ['3']);
    expect(updated.settlementPanels.last.details[1].label, 'Return Deducted');
  });
}

const _options = ReturnReversalVoucherPrintOptions(
  format: PrintFormat.a4,
  templateId: 'default',
);

String _pdfHeader(List<int> bytes) => ascii.decode(bytes.take(4).toList());

ReturnReversalState _stateFor({
  required ReturnReversalOperationType operationType,
  required ReturnReversalSourceDocumentType sourceType,
  required String documentNo,
}) {
  final line = ReturnReversalSourceLineItem(
    sourceLineId: 11,
    lineNo: 1,
    metalType: 'GOLD',
    description: sourceType == ReturnReversalSourceDocumentType.advanceBooking
        ? 'ADVANCE BOOKING'
        : 'NOSE PIN',
    hsnCode: '71131910',
    purity: '18KT',
    quantity: 1,
    quantityUnitCode: 'PCS',
    grossWeight: 0.800,
    netWeight: 0.759,
    fineWeight: 0.759,
    rate: 11400,
    makingChargeType: 'PERCENTAGE',
    makingChargeInput: 12,
    makingAmount: 1038,
    discountAmount: 1,
    taxableAmount: 9690,
    gstAmount: 0,
    invoiceValue: 9691,
    value: 9691,
    huidNumber: 'HUID123',
    status: 'PENDING',
  );
  final document = ReturnReversalSourceDocument(
    id: 91,
    type: sourceType,
    documentNo: documentNo,
    customerId: 7,
    customerName: 'REYANSH SONI',
    mobile: '9304479436',
    address: 'EAST LAKSHMI NAGAR KHEMNICHAK, PATNA',
    documentDate: DateTime(2026, 9, 3),
    grossValue: 9691,
    discountAmount: 1,
    taxableAmount: 9690,
    gstAmount: 0,
    makingTotal: 1038,
    finalAmount: 9981,
    paidAmount: sourceType == ReturnReversalSourceDocumentType.advanceBooking
        ? 5000
        : 9981,
    cashPaid: sourceType == ReturnReversalSourceDocumentType.advanceBooking
        ? 5000
        : 9981,
    dueAmount: 0,
    netWeight: 0.759,
    lineItems: [line],
  );
  final draft = ReturnReversalLineInspectionDraft.fromLine(line).copyWith(
    includeMakingCharge:
        sourceType != ReturnReversalSourceDocumentType.advanceBooking,
    stockRoute: ReturnReversalStockRoute.melting,
  );
  return ReturnReversalState(
    operationType: operationType,
    summary: const ReturnReversalTransactionSummary.empty(),
    lookupResult: const ReturnReversalLookupResult.empty(),
    selectedSourceDocument: document,
    returnCartLineNumbers: const {1},
    activeWorkflowStep: ReturnReversalWorkflowStep.invoiceItems,
    activeInspectionLineNo: 1,
    lineInspectionDrafts: {1: draft},
    isProcessing: false,
    lastProcessResult: const ReturnReversalProcessResult(
      voucherId: 100,
      voucherNo: 'RV-26-0001',
      processedLineCount: 1,
      returnValue: 8653,
      dueAdjustedAmount: 0,
      customerCreditAmount: 8653,
      status: 'POSTED',
    ),
    isLoading: false,
    isSearching: false,
    errorMessage: null,
    lookupMessage: null,
    processMessage: null,
  );
}

ReturnReversalState _salesInvoiceStateWithReturnedAndSelectedLines({
  int sourceId = 108,
  String documentNo = 'AJ-26-008',
}) {
  final lines = [
    _sourceLine(lineNo: 1, value: 3826),
    _sourceLine(
      lineNo: 2,
      value: 5178,
      reversalStatus: 'POSTED',
      reversalLineReturnValue: 4500,
    ),
    _sourceLine(
        lineNo: 3, description: 'PAYAL', metalType: 'SILVER', value: 24000),
  ];
  final document = ReturnReversalSourceDocument(
    id: sourceId,
    type: ReturnReversalSourceDocumentType.salesInvoice,
    documentNo: documentNo,
    customerId: 7,
    customerName: 'REYANSH SONI',
    mobile: '9304479436',
    address: 'EAST LAKSHMI NAGAR KHEMNICHAK, PATNA',
    documentDate: DateTime(2026, 8, 22),
    grossValue: 33004,
    discountAmount: 0,
    taxableAmount: 33004,
    gstAmount: 990,
    makingTotal: 1810,
    finalAmount: 33994,
    paidAmount: 33994,
    cashPaid: 33994,
    dueAmount: 0,
    netWeight: 101.538,
    lineItems: lines,
    reversedLineCount: 1,
  );
  return ReturnReversalState(
    operationType: ReturnReversalOperationType.salesReturn,
    summary: const ReturnReversalTransactionSummary.empty(),
    lookupResult: const ReturnReversalLookupResult.empty(),
    selectedSourceDocument: document,
    returnCartLineNumbers: const {1},
    activeWorkflowStep: ReturnReversalWorkflowStep.invoiceItems,
    activeInspectionLineNo: 1,
    lineInspectionDrafts: {
      1: ReturnReversalLineInspectionDraft.fromLine(lines.first),
    },
    isProcessing: false,
    lastProcessResult: null,
    isLoading: false,
    isSearching: false,
    errorMessage: null,
    lookupMessage: null,
    processMessage: null,
  );
}

PosInvoiceModel _posInvoiceForOriginalCopy() {
  return PosInvoiceModel(
    invoiceNumber: 'AJ-26-008',
    invoiceDate: DateTime(2026, 8, 22),
    billType: pos.BillType.gst,
    gstPricingMode: pos.GstPricingMode.exclusive,
    documentType: pos.SalesDocumentType.taxInvoice,
    billingMode: pos.BillingMode.retail,
    shopName: 'Lotus ERP',
    shopAddress: 'Patna',
    shopPhone: '9300000000',
    shopGstin: '',
    customerName: 'REYANSH SONI',
    customerMobile: '9304479436',
    customerCity: 'EAST LAKSHMI NAGAR KHEMNICHAK, PATNA',
    customerPan: '',
    customerGstin: '',
    tradeInMode: pos.TradeInAdjustMode.cashAdjust,
    saleItems: [
      _posSaleItem(lineNo: 1, value: 3826),
      _posSaleItem(lineNo: 2, value: 5178),
      _posSaleItem(
        lineNo: 3,
        value: 24000,
        description: 'PAYAL',
        metal: pos.MetalType.silver,
      ),
    ],
    tradeInItems: const [],
    grossAmount: 33004,
    discountAmount: 0,
    taxableAmount: 33004,
    cgst: 495,
    sgst: 495,
    totalGst: 990,
    totalTradeInDeduction: 0,
    grandTotal: 33994,
    cashPaid: 33994,
    upiPaid: 0,
    cardPaid: 0,
    advancePaid: 0,
    balanceDue: 0,
    totalMakingCharge: 1810,
  );
}

SaleItemModel _posSaleItem({
  required int lineNo,
  required double value,
  String description = 'NOSE PIN',
  pos.MetalType metal = pos.MetalType.gold,
}) {
  final item = SaleItemModel(
    metal: metal,
    makingChargeType: pos.MakingChargeType.perGram,
  );
  final netWeight = metal == pos.MetalType.silver ? 100.0 : 0.269;
  final rate = value / netWeight;
  item.descCtrl.text = description;
  item.pcsCtrl.text = '1';
  item.setInvoiceHsnCode(
      metal == pos.MetalType.silver ? '71131110' : '71131910');
  item.purityCtrl.text = metal == pos.MetalType.silver ? '925' : '18KT';
  item.grossCtrl.text = netWeight.toStringAsFixed(3);
  item.lessCtrl.text = '0';
  item.rateCtrl.text = rate.toStringAsFixed(3);
  item.makingCtrl.text = '0';
  item.setHuidText('HUID$lineNo');
  return item;
}

ReturnReversalSourceLineItem _sourceLine({
  required int lineNo,
  required double value,
  String description = 'NOSE PIN',
  String metalType = 'GOLD',
  String reversalStatus = '',
  double? reversalLineReturnValue,
}) {
  return ReturnReversalSourceLineItem(
    sourceLineId: lineNo,
    lineNo: lineNo,
    metalType: metalType,
    description: description,
    hsnCode: '71131910',
    purity: metalType == 'SILVER' ? '92.5' : '18KT',
    quantity: 1,
    quantityUnitCode: metalType == 'SILVER' ? 'PAIR' : 'PCS',
    grossWeight: metalType == 'SILVER' ? 100 : 0.300,
    netWeight: metalType == 'SILVER' ? 100 : 0.269,
    fineWeight: metalType == 'SILVER' ? 92.5 : 0.269,
    rate: metalType == 'SILVER' ? 240 : 12700,
    makingChargeType: 'PERCENTAGE',
    makingChargeInput: 12,
    makingAmount: 410,
    discountAmount: 0,
    taxableAmount: value,
    gstAmount: 0,
    invoiceValue: value,
    value: value,
    huidNumber: 'HUID$lineNo',
    status: 'PENDING',
    reversalStatus: reversalStatus,
    reversalLineReturnValue: reversalLineReturnValue,
  );
}

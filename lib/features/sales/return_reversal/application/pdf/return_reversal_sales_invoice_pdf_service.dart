import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/print_templates/application/global/lotus_printable_document.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_pdf_profile.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/pdf/return_reversal_voucher_pdf_service.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_state.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_item_unit_profile.dart';
import 'package:lotus_erp/features/sales_pos/application/pdf/pos_invoice_pdf_builder.dart';
import 'package:lotus_erp/features/sales_pos/application/pdf/pos_invoice_print_config.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/data/shop_print_information_repository.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';
import 'package:lotus_erp/repositories/sales_orders/pos/pos_checkout_repository.dart';
import 'package:lotus_erp/repositories/setting/billing_setup/sales_billing_repo.dart';

part 'return_reversal_sales_invoice_source.dart';
part 'return_reversal_sales_invoice_layout.dart';

final ShopPrintInformationRepository _shopProfileRepository =
    ShopPrintInformationRepository();

enum ReturnReversalSalesInvoiceCopyMode {
  original,
  updatedAfterReturn,
}

extension ReturnReversalSalesInvoiceCopyModeX
    on ReturnReversalSalesInvoiceCopyMode {
  String get title {
    return switch (this) {
      ReturnReversalSalesInvoiceCopyMode.original => 'Sales Invoice',
      ReturnReversalSalesInvoiceCopyMode.updatedAfterReturn =>
        'Updated Sales Invoice',
    };
  }

  String get badgeLabel {
    return switch (this) {
      ReturnReversalSalesInvoiceCopyMode.original => 'ORIGINAL COPY',
      ReturnReversalSalesInvoiceCopyMode.updatedAfterReturn => 'AFTER RETURN',
    };
  }

  String get tableTitle {
    return switch (this) {
      ReturnReversalSalesInvoiceCopyMode.original => 'SALES ITEMS',
      ReturnReversalSalesInvoiceCopyMode.updatedAfterReturn =>
        'AVAILABLE ITEMS AFTER RETURN',
    };
  }
}

class ReturnReversalSalesInvoicePdfService {
  ReturnReversalSalesInvoicePdfService._();

  static Future<Uint8List> buildInvoiceBytes({
    required ReturnReversalState state,
    required ReturnReversalVoucherPrintOptions options,
    required ReturnReversalSalesInvoiceCopyMode mode,
    PdfPageFormat? pageFormat,
    PosCheckoutRepository? checkoutRepository,
    SalesBillingRepo? salesBillingRepo,
    ShopPrintDocumentProfile? shopProfileOverride,
    MetalType? activeMetal,
    bool includeAllMetals = true,
  }) async {
    final sourceDocument = state.selectedSourceDocument;
    if (sourceDocument == null) {
      throw StateError('Select a sales invoice before generating PDF.');
    }
    if (sourceDocument.type != ReturnReversalSourceDocumentType.salesInvoice) {
      throw StateError(
          'Sales invoice PDFs are available only for sales return.');
    }

    final shopProfile = shopProfileOverride ?? await _loadShopProfile();
    if (mode == ReturnReversalSalesInvoiceCopyMode.original) {
      return _buildOriginalPosInvoiceBytes(
        state: state,
        sourceDocument: sourceDocument,
        shopProfile: shopProfile,
        options: options,
        checkoutRepository: checkoutRepository ?? PosCheckoutRepository(),
        salesBillingRepo: salesBillingRepo ?? SalesBillingRepo(),
        activeMetal: activeMetal,
        includeAllMetals: includeAllMetals,
      );
    }

    return _buildUpdatedPosInvoiceBytes(
      state: state,
      sourceDocument: sourceDocument,
      shopProfile: shopProfile,
      options: options,
      checkoutRepository: checkoutRepository ?? PosCheckoutRepository(),
      salesBillingRepo: salesBillingRepo ?? SalesBillingRepo(),
      activeMetal: activeMetal,
      includeAllMetals: includeAllMetals,
    );
  }

  @visibleForTesting
  static LotusPrintableDocument buildPrintableDocumentForTesting({
    required ReturnReversalState state,
    required ReturnReversalSalesInvoiceCopyMode mode,
    ShopPrintDocumentProfile shopProfile = ShopPrintDocumentProfile.empty,
    String templateId = PrintTemplateRegistry.defaultTemplateId,
  }) {
    final sourceDocument = state.selectedSourceDocument;
    if (sourceDocument == null) {
      throw StateError('Select a sales invoice before generating PDF.');
    }
    return _printableDocument(
      shopProfile: shopProfile,
      sourceDocument: sourceDocument,
      invoiceData: _InvoiceCopyData.fromState(state, mode),
      mode: mode,
      templateId: PrintTemplateRegistry.byId(templateId).id,
    );
  }
}

class _InvoiceCopyData {
  final List<ReturnReversalSourceLineItem> lines;
  final double originalFinalAmount;
  final double finalAmount;
  final double deductedAmount;
  final int removedLineCount;

  const _InvoiceCopyData({
    required this.lines,
    required this.originalFinalAmount,
    required this.finalAmount,
    required this.deductedAmount,
    required this.removedLineCount,
  });

  factory _InvoiceCopyData.fromState(
    ReturnReversalState state,
    ReturnReversalSalesInvoiceCopyMode mode,
  ) {
    final sourceDocument = state.selectedSourceDocument!;
    final removedLineNumbers = <int>{
      for (final line in sourceDocument.lineItems)
        if (line.isReversed) line.lineNo,
      ...state.returnCartLineNumbers,
    };
    final lines = mode == ReturnReversalSalesInvoiceCopyMode.original
        ? sourceDocument.lineItems
        : sourceDocument.lineItems
            .where((line) => !removedLineNumbers.contains(line.lineNo))
            .toList(growable: false);
    final originalLineTotal = sourceDocument.lineItems.fold<double>(
      0,
      (sum, line) => sum + line.displayLineTotal,
    );
    final availableLineTotal = lines.fold<double>(
      0,
      (sum, line) => sum + line.displayLineTotal,
    );
    final ratio = originalLineTotal.abs() <= 0.005
        ? (mode == ReturnReversalSalesInvoiceCopyMode.original ? 1.0 : 0.0)
        : availableLineTotal / originalLineTotal;
    final finalAmount = mode == ReturnReversalSalesInvoiceCopyMode.original
        ? sourceDocument.finalAmount
        : math.max(0.0, sourceDocument.finalAmount * ratio);

    return _InvoiceCopyData(
      lines: lines,
      originalFinalAmount: sourceDocument.finalAmount,
      finalAmount: finalAmount,
      deductedAmount: math.max(0.0, sourceDocument.finalAmount - finalAmount),
      removedLineCount: mode == ReturnReversalSalesInvoiceCopyMode.original
          ? 0
          : removedLineNumbers.length,
    );
  }
}

const List<String> _monthShort = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

extension _ReturnReversalSalesInvoiceStringX on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}

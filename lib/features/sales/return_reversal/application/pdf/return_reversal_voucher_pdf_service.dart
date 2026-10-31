import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:lotus_erp/core/pdf/lotus_pdf_theme.dart';
import 'package:lotus_erp/core/pdf/lotus_pdf_text_renderer.dart';
import 'package:lotus_erp/features/print_templates/application/global/lotus_print_template_renderer_registry.dart';
import 'package:lotus_erp/features/print_templates/application/global/lotus_printable_document.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_pdf_profile.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_line_inspection.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_state.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/data/shop_print_information_repository.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';

part 'return_reversal_voucher_document_data.dart';
part 'return_reversal_voucher_document_layout.dart';

final ShopPrintInformationRepository _shopProfileRepository =
    ShopPrintInformationRepository();

enum ReturnReversalVoucherDocumentKind {
  salesReturn,
  bookingCancellation,
  customerPurchaseReversal,
}

extension ReturnReversalVoucherDocumentKindX
    on ReturnReversalVoucherDocumentKind {
  String get title {
    return switch (this) {
      ReturnReversalVoucherDocumentKind.salesReturn => 'Sales Return Voucher',
      ReturnReversalVoucherDocumentKind.bookingCancellation =>
        'Booking Cancellation Voucher',
      ReturnReversalVoucherDocumentKind.customerPurchaseReversal =>
        'Customer Purchase Reversal Voucher',
    };
  }

  String get shortTitle {
    return switch (this) {
      ReturnReversalVoucherDocumentKind.salesReturn => 'Sales Return',
      ReturnReversalVoucherDocumentKind.bookingCancellation => 'Cancellation',
      ReturnReversalVoucherDocumentKind.customerPurchaseReversal =>
        'Purchase Reversal',
    };
  }

  String get settlementTitle {
    return switch (this) {
      ReturnReversalVoucherDocumentKind.salesReturn => 'Return Settlement',
      ReturnReversalVoucherDocumentKind.bookingCancellation =>
        'Cancellation Settlement',
      ReturnReversalVoucherDocumentKind.customerPurchaseReversal =>
        'Purchase Reversal Settlement',
    };
  }

  PrintTemplateDocumentType get printTemplateDocumentType {
    return switch (this) {
      ReturnReversalVoucherDocumentKind.salesReturn =>
        PrintTemplateDocumentType.salesReturn,
      ReturnReversalVoucherDocumentKind.bookingCancellation =>
        PrintTemplateDocumentType.bookingAdvance,
      ReturnReversalVoucherDocumentKind.customerPurchaseReversal =>
        PrintTemplateDocumentType.purchaseReturn,
    };
  }
}

class ReturnReversalVoucherPrintOptions {
  final PrintFormat format;
  final String templateId;
  final int copies;
  final bool includeDuplicateStamp;
  final bool includeOriginalPricing;
  final bool includeVerificationAudit;
  final bool includeStockRouting;
  final bool includeSettlement;

  const ReturnReversalVoucherPrintOptions({
    required this.format,
    required this.templateId,
    this.copies = 1,
    this.includeDuplicateStamp = false,
    this.includeOriginalPricing = true,
    this.includeVerificationAudit = true,
    this.includeStockRouting = true,
    this.includeSettlement = true,
  });

  ReturnReversalVoucherPrintOptions copyWith({
    PrintFormat? format,
    String? templateId,
    int? copies,
    bool? includeDuplicateStamp,
    bool? includeOriginalPricing,
    bool? includeVerificationAudit,
    bool? includeStockRouting,
    bool? includeSettlement,
  }) {
    return ReturnReversalVoucherPrintOptions(
      format: format ?? this.format,
      templateId: templateId ?? this.templateId,
      copies: copies ?? this.copies,
      includeDuplicateStamp:
          includeDuplicateStamp ?? this.includeDuplicateStamp,
      includeOriginalPricing:
          includeOriginalPricing ?? this.includeOriginalPricing,
      includeVerificationAudit:
          includeVerificationAudit ?? this.includeVerificationAudit,
      includeStockRouting: includeStockRouting ?? this.includeStockRouting,
      includeSettlement: includeSettlement ?? this.includeSettlement,
    );
  }

  String get revisionKey {
    return [
      format.name,
      templateId,
      copies,
      includeDuplicateStamp,
      includeOriginalPricing,
      includeVerificationAudit,
      includeStockRouting,
      includeSettlement,
    ].join('|');
  }
}

class ReturnReversalVoucherPdfService {
  ReturnReversalVoucherPdfService._();

  static ReturnReversalVoucherDocumentKind documentKindFor(
    ReturnReversalState state,
  ) {
    final sourceType = state.selectedSourceDocument?.type;
    if (state.operationType.isBookingCancellation ||
        sourceType == ReturnReversalSourceDocumentType.advanceBooking) {
      return ReturnReversalVoucherDocumentKind.bookingCancellation;
    }
    if (sourceType == ReturnReversalSourceDocumentType.customerPurchase) {
      return ReturnReversalVoucherDocumentKind.customerPurchaseReversal;
    }
    return ReturnReversalVoucherDocumentKind.salesReturn;
  }

  static PdfPageFormat pageFormatFor(PrintFormat format) {
    return switch (format) {
      PrintFormat.a4 => PdfPageFormat.a4,
      PrintFormat.thermal3inch => const PdfPageFormat(
          80 * PdfPageFormat.mm,
          900 * PdfPageFormat.mm,
          marginAll: 4 * PdfPageFormat.mm,
        ),
      PrintFormat.thermal2inch => const PdfPageFormat(
          57 * PdfPageFormat.mm,
          900 * PdfPageFormat.mm,
          marginAll: 3 * PdfPageFormat.mm,
        ),
    };
  }

  static Future<Uint8List> buildVoucherBytes({
    required ReturnReversalState state,
    required ReturnReversalVoucherPrintOptions options,
    PdfPageFormat? pageFormat,
  }) async {
    final sourceDocument = state.selectedSourceDocument;
    if (sourceDocument == null) {
      throw StateError('Select a source document before previewing voucher.');
    }

    final kind = documentKindFor(state);
    final template = PrintTemplateRegistry.byId(options.templateId);
    final rows = _voucherRowsFor(state);
    if (rows.isEmpty) {
      throw StateError('Add at least one line before generating voucher.');
    }
    final settlement = _settlementFor(state, rows, kind);
    final shopProfile = await _loadShopProfile();
    final printableDocument = options.format == PrintFormat.a4
        ? _printableDocument(
            shopProfile: shopProfile,
            state: state,
            sourceDocument: sourceDocument,
            kind: kind,
            rows: rows,
            settlement: settlement,
            options: options,
            templateId: template.id,
          )
        : null;
    final textRenderer =
        printableDocument == null ? null : await LotusPdfTextRenderer.create();
    if (printableDocument != null && textRenderer != null) {
      await LotusPrintTemplateRendererRegistry.warmPolicyText(
        printableDocument,
        textRenderer,
      );
    }

    final effectivePageFormat = pageFormat ?? pageFormatFor(options.format);
    final pdf = pw.Document(
      title: kind.title,
      author: _shopName(shopProfile),
      creator: 'Lotus ERP Return & Reversal Desk',
      subject:
          '${kind.title} (${PrintTemplateRegistry.labelFor(template.id)}) - ${sourceDocument.documentNo}',
      theme: await _documentTheme(),
    );
    final bool thermal = options.format != PrintFormat.a4;
    final normalizedCopies = options.copies.clamp(1, 5).toInt();

    for (var copyIndex = 0; copyIndex < normalizedCopies; copyIndex++) {
      final copy = copyIndex + 1;
      final duplicate = options.includeDuplicateStamp && copyIndex > 0;
      pdf.addPage(
        pw.MultiPage(
          pageFormat: effectivePageFormat,
          margin: _pageMarginFor(options.format),
          build: (context) {
            if (options.format == PrintFormat.a4 &&
                printableDocument != null &&
                textRenderer != null) {
              return LotusPrintTemplateRendererRegistry.buildA4(
                templateId: template.id,
                context: LotusPrintTemplateRenderContext(
                  document: printableDocument,
                  textRenderer: textRenderer,
                ),
                isDuplicateCopy: duplicate,
              );
            }
            if (thermal) {
              return _buildThermalContent(
                state: state,
                kind: kind,
                sourceDocument: sourceDocument,
                rows: rows,
                settlement: settlement,
                options: options,
                template: template,
                copy: copy,
              );
            }
            return _buildA4Content(
              state: state,
              kind: kind,
              sourceDocument: sourceDocument,
              rows: rows,
              settlement: settlement,
              options: options,
              template: template,
              copy: copy,
            );
          },
        ),
      );
    }

    return pdf.save();
  }
}

class _VoucherRow {
  final ReturnReversalSourceLineItem line;
  final ReturnReversalLineInspectionDraft draft;
  final double receivedRatio;
  final double adjustedLineAmount;
  final double adjustedMakingAmount;
  final double metalAmount;
  final double makingReturnedAmount;
  final double returnValue;

  const _VoucherRow({
    required this.line,
    required this.draft,
    required this.receivedRatio,
    required this.adjustedLineAmount,
    required this.adjustedMakingAmount,
    required this.metalAmount,
    required this.makingReturnedAmount,
    required this.returnValue,
  });
}

class _VoucherSettlement {
  final double returnValue;
  final double dueAdjustedAmount;
  final double refundPayableAmount;

  const _VoucherSettlement({
    required this.returnValue,
    required this.dueAdjustedAmount,
    required this.refundPayableAmount,
  });
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

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}

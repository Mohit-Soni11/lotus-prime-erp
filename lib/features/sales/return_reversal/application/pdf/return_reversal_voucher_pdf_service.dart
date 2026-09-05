import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

  static final ShopPrintInformationRepository _shopProfileRepository =
      ShopPrintInformationRepository();

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

  static List<_VoucherRow> _voucherRowsFor(ReturnReversalState state) {
    final sourceDocument = state.selectedSourceDocument;
    if (sourceDocument == null) return const [];

    final selectedRows = state.returnCartLineItems;
    final candidateRows = selectedRows.isNotEmpty
        ? selectedRows
        : sourceDocument.lineItems
            .where((line) => line.isReversed)
            .toList(growable: false);

    final sourceRows =
        candidateRows.isNotEmpty ? candidateRows : sourceDocument.lineItems;

    return sourceRows.map((line) {
      final draft = state.lineInspectionDrafts[line.lineNo] ??
          ReturnReversalLineInspectionDraft.fromLine(line);
      final valuation = _valuationFor(line, draft);
      return _VoucherRow(
        line: line,
        draft: draft,
        receivedRatio: valuation.receivedRatio,
        adjustedLineAmount: valuation.adjustedLineAmount,
        adjustedMakingAmount: valuation.adjustedMakingAmount,
        metalAmount: valuation.metalAmount,
        makingReturnedAmount: valuation.makingReturnedAmount,
        returnValue: valuation.returnValue,
      );
    }).toList(growable: false);
  }

  static Future<ShopPrintDocumentProfile> _loadShopProfile() async {
    try {
      return await _shopProfileRepository.loadDocumentProfile();
    } catch (_) {
      return ShopPrintDocumentProfile.empty;
    }
  }

  static _VoucherRow _valuationFor(
    ReturnReversalSourceLineItem line,
    ReturnReversalLineInspectionDraft draft,
  ) {
    final ratio =
        line.netWeight <= 0 ? 1.0 : (draft.receivedNetWeight / line.netWeight);
    final safeRatio = ratio.clamp(0.0, 1.0);
    final adjustedLineAmount = line.displayLineTotal * safeRatio;
    final adjustedMakingAmount = line.makingAmount * safeRatio;
    final fallbackMetalAmount =
        math.max(0.0, adjustedLineAmount - adjustedMakingAmount);
    final metalAmount = line.reversalMetalReturnAmount ?? fallbackMetalAmount;
    final makingReturnedAmount = line.reversalMakingReturnedAmount ??
        (draft.includeMakingCharge ? adjustedMakingAmount : 0.0);
    final returnValue = line.reversalLineReturnValue ??
        math.max(0.0, metalAmount + makingReturnedAmount);
    return _VoucherRow(
      line: line,
      draft: draft,
      receivedRatio: safeRatio,
      adjustedLineAmount: adjustedLineAmount,
      adjustedMakingAmount: adjustedMakingAmount,
      metalAmount: metalAmount,
      makingReturnedAmount: makingReturnedAmount,
      returnValue: returnValue,
    );
  }

  static _VoucherSettlement _settlementFor(
    ReturnReversalState state,
    List<_VoucherRow> rows,
    ReturnReversalVoucherDocumentKind kind,
  ) {
    final document = state.selectedSourceDocument;
    final result = state.lastProcessResult;
    final returnValue = result?.returnValue ??
        rows.fold<double>(0, (sum, row) => sum + row.returnValue);
    final dueAdjusted = result?.dueAdjustedAmount ??
        (kind == ReturnReversalVoucherDocumentKind.salesReturn
            ? math.min(document?.dueAmount ?? 0, returnValue)
            : 0);
    final customerCredit = result?.customerCreditAmount ??
        math.max(0.0, returnValue - dueAdjusted);
    return _VoucherSettlement(
      returnValue: returnValue,
      dueAdjustedAmount: dueAdjusted,
      customerCreditAmount: customerCredit,
    );
  }

  static String _voucherStatusLabel(
    ReturnReversalState state,
    ReturnReversalSourceDocument? document,
    List<_VoucherRow> rows,
  ) {
    final resultStatus = state.lastProcessResult?.status.trim();
    if (resultStatus != null && resultStatus.isNotEmpty) {
      return resultStatus;
    }
    if ((document?.reversalVoucherNo.trim().isNotEmpty ?? false) ||
        rows.any((row) => row.line.isReversed)) {
      return 'POSTED';
    }
    return 'DRAFT';
  }

  static LotusPrintableDocument _printableDocument({
    required ShopPrintDocumentProfile shopProfile,
    required ReturnReversalState state,
    required ReturnReversalSourceDocument sourceDocument,
    required ReturnReversalVoucherDocumentKind kind,
    required List<_VoucherRow> rows,
    required _VoucherSettlement settlement,
    required ReturnReversalVoucherPrintOptions options,
    required String templateId,
  }) {
    final template = PrintTemplateRegistry.byId(templateId);
    return LotusPrintableDocument(
      shopProfile: shopProfile,
      template: template,
      profile: PrintTemplatePdfProfile.forTemplate(template.id),
      title: kind.title,
      subtitle: sourceDocument.type.label,
      documentNumberLabel: 'Voucher No',
      documentNumber: _voucherNo(state, sourceDocument),
      documentDateLabel: 'Voucher Date',
      documentDate: _formatDate(DateTime.now()),
      badgeLabel: _voucherStatusLabel(state, sourceDocument, rows),
      primaryPanel: _printableCustomerPanel(sourceDocument),
      secondaryPanel: _printableSourcePanel(state, sourceDocument),
      itemTable: _printableItemTable(kind, rows, options),
      settlementPanels: _printableSettlementPanels(
        kind,
        sourceDocument,
        rows,
        settlement,
        options,
      ),
      policySections: const [],
      footerMessage: '',
      showHeaderDocumentMeta: true,
      showHeaderBadge: true,
      useFallbackShopName: true,
      renderPolicySectionsAsPages: false,
      startPolicySectionsOnNewPage: false,
      showLegalSignatureFooter: false,
    );
  }

  static LotusPrintablePanel _printableCustomerPanel(
    ReturnReversalSourceDocument sourceDocument,
  ) {
    return LotusPrintablePanel(
      title: 'CUSTOMER DETAILS',
      details: [
        LotusPrintableDetail(
          iconKey: 'customer',
          label: 'Customer',
          value: _fallback(sourceDocument.customerName, 'Walk-in Customer'),
          highlight: true,
        ),
        if (sourceDocument.mobile.trim().isNotEmpty)
          LotusPrintableDetail(
            iconKey: 'phone',
            label: 'Mobile',
            value: sourceDocument.mobile.trim(),
          ),
        if (sourceDocument.address.trim().isNotEmpty)
          LotusPrintableDetail(
            iconKey: 'location',
            label: 'Address',
            value: sourceDocument.address.trim(),
            multiline: true,
          ),
      ],
    );
  }

  static LotusPrintablePanel _printableSourcePanel(
    ReturnReversalState state,
    ReturnReversalSourceDocument sourceDocument,
  ) {
    return LotusPrintablePanel(
      title: 'SOURCE DOCUMENT',
      details: [
        LotusPrintableDetail(
          iconKey: 'invoice',
          label: 'Source No',
          value: sourceDocument.documentNo,
          highlight: true,
        ),
        LotusPrintableDetail(
          iconKey: 'calendar',
          label: 'Source Date',
          value: _formatDate(sourceDocument.documentDate),
        ),
        LotusPrintableDetail(
          iconKey: 'items',
          label: 'Source Type',
          value: sourceDocument.type.label,
        ),
        LotusPrintableDetail(
          iconKey: 'status',
          label: 'Desk Mode',
          value: state.operationType.ledgerLabel,
          highlight: true,
        ),
        LotusPrintableDetail(
          iconKey: 'amount',
          label: 'Original Total',
          value: _formatMoney(sourceDocument.finalAmount),
        ),
        LotusPrintableDetail(
          iconKey: 'payment',
          label: 'Amount Received',
          value: _formatMoney(sourceDocument.paidAmount),
        ),
      ],
    );
  }

  static LotusPrintableTable _printableItemTable(
    ReturnReversalVoucherDocumentKind kind,
    List<_VoucherRow> rows,
    ReturnReversalVoucherPrintOptions options,
  ) {
    final headers = <String>[
      'S. No.',
      'Item',
      'Metal',
      'Sold Wt',
      'Received Wt',
    ];
    if (options.includeOriginalPricing) headers.add('Invoice Value');
    headers.add('Return');
    if (options.includeStockRouting &&
        kind != ReturnReversalVoucherDocumentKind.bookingCancellation) {
      headers.add('Route');
    }

    return LotusPrintableTable(
      title: 'RETURN LINES',
      headers: headers,
      rows: [
        for (final row in rows)
          [
            row.line.lineNo.toString(),
            row.line.description,
            row.line.metalType,
            '${_formatWeight(row.line.netWeight)} g',
            '${_formatWeight(row.draft.receivedNetWeight)} g',
            if (options.includeOriginalPricing)
              _formatMoney(row.adjustedLineAmount),
            _formatMoney(row.returnValue),
            if (options.includeStockRouting &&
                kind != ReturnReversalVoucherDocumentKind.bookingCancellation)
              row.draft.stockRoute.label,
          ],
      ],
    );
  }

  static List<LotusPrintablePanel> _printableSettlementPanels(
    ReturnReversalVoucherDocumentKind kind,
    ReturnReversalSourceDocument sourceDocument,
    List<_VoucherRow> rows,
    _VoucherSettlement settlement,
    ReturnReversalVoucherPrintOptions options,
  ) {
    return [
      if (options.includeSettlement)
        LotusPrintablePanel(
          title: kind.settlementTitle.toUpperCase(),
          details: [
            LotusPrintableDetail(
              iconKey: 'amount',
              label:
                  kind == ReturnReversalVoucherDocumentKind.bookingCancellation
                      ? 'Refund Value'
                      : 'Return Value',
              value: _formatMoney(settlement.returnValue),
              highlight: true,
            ),
            if (settlement.dueAdjustedAmount > 0.005)
              LotusPrintableDetail(
                iconKey: 'amount',
                label: 'Due Adjusted',
                value: _formatMoney(settlement.dueAdjustedAmount),
              ),
            LotusPrintableDetail(
              iconKey: 'amount',
              label:
                  kind == ReturnReversalVoucherDocumentKind.bookingCancellation
                      ? 'Refund Payable'
                      : 'Customer Credit',
              value: _formatMoney(settlement.customerCreditAmount),
              highlight: true,
            ),
          ],
        ),
      if (options.includeVerificationAudit)
        LotusPrintablePanel(
          title: 'VERIFICATION AUDIT',
          details: [
            LotusPrintableDetail(
              iconKey: 'verified',
              label: 'Matched Lines',
              value: _matchedLineSummary(rows),
              highlight: true,
            ),
            LotusPrintableDetail(
              iconKey: 'items',
              label: 'Line Count',
              value: '${rows.length}',
            ),
            LotusPrintableDetail(
              iconKey: 'invoice',
              label: 'Source No',
              value: sourceDocument.documentNo,
            ),
          ],
        ),
    ];
  }

  static List<pw.Widget> _buildA4Content({
    required ReturnReversalState state,
    required ReturnReversalVoucherDocumentKind kind,
    required ReturnReversalSourceDocument sourceDocument,
    required List<_VoucherRow> rows,
    required _VoucherSettlement settlement,
    required ReturnReversalVoucherPrintOptions options,
    required PrintTemplateDefinition template,
    required int copy,
  }) {
    return [
      _brandHeader(
        kind,
        state,
        sourceDocument,
        template,
        options,
        copy,
        false,
      ),
      pw.SizedBox(height: 16),
      _partyAndSourceBlock(sourceDocument, state, false),
      pw.SizedBox(height: 14),
      _itemsTable(kind, rows, options, false),
      if (options.includeSettlement) ...[
        pw.SizedBox(height: 14),
        _settlementBlock(kind, sourceDocument, settlement, false),
      ],
      pw.Spacer(),
      _voucherFooter(false),
    ];
  }

  static List<pw.Widget> _buildThermalContent({
    required ReturnReversalState state,
    required ReturnReversalVoucherDocumentKind kind,
    required ReturnReversalSourceDocument sourceDocument,
    required List<_VoucherRow> rows,
    required _VoucherSettlement settlement,
    required ReturnReversalVoucherPrintOptions options,
    required PrintTemplateDefinition template,
    required int copy,
  }) {
    return [
      _brandHeader(
        kind,
        state,
        sourceDocument,
        template,
        options,
        copy,
        true,
      ),
      _thermalDivider(),
      _partyAndSourceBlock(sourceDocument, state, true),
      _thermalDivider(),
      _thermalItems(kind, rows, options),
      if (options.includeSettlement) ...[
        _thermalDivider(),
        _settlementBlock(kind, sourceDocument, settlement, true),
      ],
      _thermalDivider(),
      _voucherFooter(true),
    ];
  }

  static pw.Widget _brandHeader(
    ReturnReversalVoucherDocumentKind kind,
    ReturnReversalState state,
    ReturnReversalSourceDocument sourceDocument,
    PrintTemplateDefinition template,
    ReturnReversalVoucherPrintOptions options,
    int copy,
    bool thermal,
  ) {
    final result = state.lastProcessResult;
    final voucherNo = result?.voucherNo ??
        sourceDocument.reversalVoucherNo.ifBlank('DRAFT-${sourceDocument.id}');
    final textColor = thermal ? PdfColors.black : PdfColors.blueGrey900;
    return pw.Container(
      padding: thermal ? pw.EdgeInsets.zero : const pw.EdgeInsets.all(14),
      decoration: thermal
          ? null
          : pw.BoxDecoration(
              color: PdfColors.blueGrey900,
              borderRadius: pw.BorderRadius.circular(10),
            ),
      child: pw.Column(
        crossAxisAlignment: thermal
            ? pw.CrossAxisAlignment.center
            : pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'LOTUS ERP',
            style: pw.TextStyle(
              fontSize: thermal ? 14 : 22,
              fontWeight: pw.FontWeight.bold,
              color: thermal ? PdfColors.black : PdfColors.amber100,
            ),
          ),
          pw.SizedBox(height: thermal ? 3 : 6),
          pw.Text(
            kind.title,
            style: pw.TextStyle(
              fontSize: thermal ? 10 : 13,
              fontWeight: pw.FontWeight.bold,
              color: thermal ? PdfColors.black : PdfColors.white,
            ),
          ),
          pw.SizedBox(height: thermal ? 3 : 8),
          pw.Text(
            'Voucher: $voucherNo  |  Source: ${sourceDocument.documentNo}'
            '  |  ${_formatDate(DateTime.now())}  |  ${_copyLabel(copy, state, options)}',
            textAlign: thermal ? pw.TextAlign.center : pw.TextAlign.left,
            style: pw.TextStyle(
              fontSize: thermal ? 7 : 9,
              color: textColor,
            ).copyWith(color: thermal ? PdfColors.black : PdfColors.grey200),
          ),
          if (!thermal) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Template: ${template.shortName}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey300),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _partyAndSourceBlock(
    ReturnReversalSourceDocument sourceDocument,
    ReturnReversalState state,
    bool thermal,
  ) {
    final labelWidth = thermal ? 56.0 : 92.0;
    return pw.Container(
      padding: thermal
          ? const pw.EdgeInsets.symmetric(vertical: 4)
          : const pw.EdgeInsets.all(12),
      decoration: thermal
          ? null
          : pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
      child: pw.Column(
        children: [
          _infoRow(
              'Customer', sourceDocument.customerName, labelWidth, thermal),
          _infoRow('Mobile', sourceDocument.mobile, labelWidth, thermal),
          _infoRow('Address', sourceDocument.address, labelWidth, thermal),
          _infoRow(
            'Source Type',
            sourceDocument.type.label,
            labelWidth,
            thermal,
          ),
          _infoRow(
            'Source Date',
            _formatDate(sourceDocument.documentDate),
            labelWidth,
            thermal,
          ),
          _infoRow(
            'Desk Mode',
            state.operationType.ledgerLabel,
            labelWidth,
            thermal,
          ),
        ],
      ),
    );
  }

  static pw.Widget _itemsTable(
    ReturnReversalVoucherDocumentKind kind,
    List<_VoucherRow> rows,
    ReturnReversalVoucherPrintOptions options,
    bool thermal,
  ) {
    final headers = <String>[
      'S. No.',
      'Item',
      'Metal',
      'Sold Wt',
      'Received Wt',
      'Return',
    ];
    if (options.includeOriginalPricing) {
      headers.insert(5, 'Invoice Value');
    }
    if (options.includeStockRouting &&
        kind != ReturnReversalVoucherDocumentKind.bookingCancellation) {
      headers.add('Route');
    }

    final data = rows.map((row) {
      final line = row.line;
      final values = <String>[
        line.lineNo.toString(),
        line.description,
        line.metalType,
        '${_formatWeight(line.netWeight)} g',
        '${_formatWeight(row.draft.receivedNetWeight)} g',
        _formatMoney(row.returnValue),
      ];
      if (options.includeOriginalPricing) {
        values.insert(5, _formatMoney(row.adjustedLineAmount));
      }
      if (options.includeStockRouting &&
          kind != ReturnReversalVoucherDocumentKind.bookingCancellation) {
        values.add(row.draft.stockRoute.label);
      }
      return values;
    }).toList(growable: false);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Return Lines', false),
        pw.SizedBox(height: 7),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: data,
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.amber100),
          headerStyle: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 6,
          ),
        ),
        if (options.includeVerificationAudit) ...[
          pw.SizedBox(height: 8),
          _auditStrip(rows),
        ],
      ],
    );
  }

  static pw.Widget _thermalItems(
    ReturnReversalVoucherDocumentKind kind,
    List<_VoucherRow> rows,
    ReturnReversalVoucherPrintOptions options,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: rows.map((row) {
        final route =
            kind == ReturnReversalVoucherDocumentKind.bookingCancellation
                ? 'N/A'
                : row.draft.stockRoute.label;
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${row.line.lineNo}. ${row.line.description}',
                style:
                    pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '${row.line.metalType} | ${_formatWeight(row.draft.receivedNetWeight)} g'
                ' | Route: $route',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Return Value',
                      style: const pw.TextStyle(fontSize: 7)),
                  pw.Text(
                    _formatMoney(row.returnValue),
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }

  static pw.Widget _settlementBlock(
    ReturnReversalVoucherDocumentKind kind,
    ReturnReversalSourceDocument sourceDocument,
    _VoucherSettlement settlement,
    bool thermal,
  ) {
    return pw.Container(
      padding: thermal ? pw.EdgeInsets.zero : const pw.EdgeInsets.all(12),
      decoration: thermal
          ? null
          : pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle(kind.settlementTitle, thermal),
          pw.SizedBox(height: thermal ? 5 : 8),
          _amountRow('Original Total', sourceDocument.finalAmount, thermal),
          _amountRow('Amount Received', sourceDocument.paidAmount, thermal),
          _amountRow('Return / Refund Value', settlement.returnValue, thermal),
          _amountRow('Due Adjusted', settlement.dueAdjustedAmount, thermal),
          _amountRow(
              'Customer Credit', settlement.customerCreditAmount, thermal),
        ],
      ),
    );
  }

  static pw.Widget _auditStrip(List<_VoucherRow> rows) {
    final matched = rows
        .where((row) => row.draft.huidMatched && row.draft.unitMatched)
        .length;
    final total = rows.length;
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green200),
        borderRadius: pw.BorderRadius.circular(7),
      ),
      child: pw.Text(
        'Verification audit: $matched of $total line(s) matched HUID and unit checks.',
        style: pw.TextStyle(
          fontSize: 8,
          color: PdfColors.green900,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _voucherFooter(bool thermal) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (!thermal) pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: thermal ? 4 : 8),
        pw.Text(
          'This document is generated from Lotus ERP Return & Reversal Desk.',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: thermal ? 6.5 : 8,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title, bool thermal) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: thermal ? 8 : 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.amber900,
      ),
    );
  }

  static pw.Widget _infoRow(
    String label,
    String value,
    double labelWidth,
    bool thermal,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: labelWidth,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: thermal ? 7 : 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.ifBlank('-'),
              style: pw.TextStyle(fontSize: thermal ? 7 : 8),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _amountRow(
    String label,
    double? value,
    bool thermal, {
    String? valueText,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: thermal ? 7 : 8)),
          pw.Text(
            valueText ?? _formatMoney(value ?? 0),
            style: pw.TextStyle(
              fontSize: thermal ? 7.5 : 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _thermalDivider() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Container(height: 0.6, color: PdfColors.grey500),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _monthShort[date.month - 1];
    return '$day $month ${date.year}';
  }

  static String _formatMoney(double value) {
    final rounded = value.round();
    final negative = rounded < 0;
    final digits = negative ? (-rounded).toString() : rounded.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return '${negative ? '-' : ''}Rs ${buffer.toString()}';
  }

  static String _formatWeight(double value) => value.toStringAsFixed(3);

  static pw.EdgeInsets _pageMarginFor(PrintFormat format) {
    return switch (format) {
      PrintFormat.a4 => const pw.EdgeInsets.all(24),
      PrintFormat.thermal3inch => const pw.EdgeInsets.all(4 * PdfPageFormat.mm),
      PrintFormat.thermal2inch => const pw.EdgeInsets.all(3 * PdfPageFormat.mm),
    };
  }

  static Future<pw.ThemeData> _documentTheme() async {
    final devanagariFont = await _loadFont(
      'assets/fonts/lohit_devanagari/Lohit-Devanagari.ttf',
    );
    final windowsDirectory = Platform.environment['WINDIR'];
    if (windowsDirectory != null) {
      final regularFile = File('$windowsDirectory\\Fonts\\segoeui.ttf');
      final boldFile = File('$windowsDirectory\\Fonts\\segoeuib.ttf');
      if (regularFile.existsSync() && boldFile.existsSync()) {
        try {
          return pw.ThemeData.withFont(
            base: pw.Font.ttf(_asByteData(await regularFile.readAsBytes())),
            bold: pw.Font.ttf(_asByteData(await boldFile.readAsBytes())),
            fontFallback:
                devanagariFont == null ? null : <pw.Font>[devanagariFont],
          );
        } catch (_) {}
      }
    }

    return pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      fontFallback: devanagariFont == null ? null : <pw.Font>[devanagariFont],
    );
  }

  static Future<pw.Font?> _loadFont(String assetPath) async {
    try {
      return pw.Font.ttf(await rootBundle.load(assetPath));
    } catch (_) {
      try {
        final file = File(assetPath);
        if (!file.existsSync()) return null;
        return pw.Font.ttf(_asByteData(await file.readAsBytes()));
      } catch (_) {
        return null;
      }
    }
  }

  static ByteData _asByteData(Uint8List bytes) {
    return bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
  }

  static String _shopName(ShopPrintDocumentProfile profile) {
    return profile.invoiceHeaderName.trim().ifBlank('Lotus ERP');
  }

  static String _voucherNo(
    ReturnReversalState state,
    ReturnReversalSourceDocument sourceDocument,
  ) {
    final postedVoucherNo = state.lastProcessResult?.voucherNo ??
        sourceDocument.reversalVoucherNo.ifBlank('');
    if (postedVoucherNo.trim().isNotEmpty) {
      return postedVoucherNo.trim();
    }
    return 'DRAFT-${sourceDocument.documentNo}';
  }

  static String _fallback(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static String _matchedLineSummary(List<_VoucherRow> rows) {
    final matched = rows
        .where((row) => row.draft.huidMatched && row.draft.unitMatched)
        .length;
    return '$matched of ${rows.length} line(s)';
  }

  static String _copyLabel(
    int copy,
    ReturnReversalState state,
    ReturnReversalVoucherPrintOptions options,
  ) {
    final statusLabel = state.lastProcessResult == null ? 'Draft' : 'Posted';
    final duplicate = options.includeDuplicateStamp && copy > 1;
    return '${duplicate ? 'Duplicate' : statusLabel} Copy $copy';
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
  final double customerCreditAmount;

  const _VoucherSettlement({
    required this.returnValue,
    required this.dueAdjustedAmount,
    required this.customerCreditAmount,
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

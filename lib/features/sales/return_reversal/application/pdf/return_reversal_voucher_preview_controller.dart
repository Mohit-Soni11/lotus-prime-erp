import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:lotus_erp/core/logging/app_logger.dart';
import 'package:lotus_erp/core/printing/lotus_pdf_print_dispatcher.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/pdf/return_reversal_sales_invoice_pdf_service.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/pdf/return_reversal_voucher_pdf_service.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';

enum ReturnReversalVoucherGenState {
  idle,
  generating,
  ready,
  error,
}

enum ReturnReversalOutputDocumentKind {
  returnVoucher,
  originalSalesInvoice,
  updatedSalesInvoice,
}

extension ReturnReversalOutputDocumentKindX
    on ReturnReversalOutputDocumentKind {
  String get label {
    return switch (this) {
      ReturnReversalOutputDocumentKind.returnVoucher => 'Return Voucher',
      ReturnReversalOutputDocumentKind.originalSalesInvoice =>
        'Original Sales Invoice',
      ReturnReversalOutputDocumentKind.updatedSalesInvoice =>
        'Updated Sales Invoice',
    };
  }

  String get shortLabel {
    return switch (this) {
      ReturnReversalOutputDocumentKind.returnVoucher => 'Return Voucher',
      ReturnReversalOutputDocumentKind.originalSalesInvoice =>
        'Original Invoice',
      ReturnReversalOutputDocumentKind.updatedSalesInvoice => 'Updated Invoice',
    };
  }

  String get subtitle {
    return switch (this) {
      ReturnReversalOutputDocumentKind.returnVoucher =>
        'Return/refund audit voucher',
      ReturnReversalOutputDocumentKind.originalSalesInvoice =>
        'Original bill copy before return',
      ReturnReversalOutputDocumentKind.updatedSalesInvoice =>
        'Available items after return deduction',
    };
  }

  bool get requiresSalesInvoice {
    return this != ReturnReversalOutputDocumentKind.returnVoucher;
  }
}

class ReturnReversalVoucherPreviewController extends ChangeNotifier {
  final ReturnReversalController deskController;
  final LotusPdfPrintDispatcher _printDispatcher;

  ReturnReversalVoucherGenState genState = ReturnReversalVoucherGenState.idle;
  Uint8List? pdfBytes;
  String? errorMessage;
  PrintFormat selectedFormat = PrintFormat.a4;
  late String selectedTemplateId;
  int printCopies = 1;
  bool includeDuplicateStamp = false;
  bool usePrinterDriverSettings = true;
  bool includeOriginalPricing = true;
  bool includeVerificationAudit = true;
  bool includeStockRouting = true;
  bool includeSettlement = true;
  ReturnReversalOutputDocumentKind selectedOutputDocument =
      ReturnReversalOutputDocumentKind.returnVoucher;
  MetalType? selectedInvoiceMetal;

  ReturnReversalVoucherPreviewController({
    required this.deskController,
    LotusPdfPrintDispatcher printDispatcher = const LotusPdfPrintDispatcher(),
  }) : _printDispatcher = printDispatcher {
    selectedTemplateId = supportedTemplates.first.id;
    deskController.addListener(_handleDeskStateChanged);
  }

  ReturnReversalVoucherDocumentKind get documentKind {
    return ReturnReversalVoucherPdfService.documentKindFor(
      deskController.state,
    );
  }

  PrintTemplateDocumentType get documentType {
    if (selectedOutputDocument.requiresSalesInvoice) {
      return PrintTemplateDocumentType.salesInvoice;
    }
    return documentKind.printTemplateDocumentType;
  }

  List<PrintTemplateDefinition> get supportedTemplates {
    final templates = PrintTemplateRegistry.forDocument(documentType);
    return templates.isEmpty
        ? const [PrintTemplateRegistry.lotusClassic]
        : templates;
  }

  ReturnReversalVoucherPrintOptions get options {
    return ReturnReversalVoucherPrintOptions(
      format: selectedFormat,
      templateId: selectedTemplateId,
      copies: printCopies,
      includeDuplicateStamp: includeDuplicateStamp,
      includeOriginalPricing: includeOriginalPricing,
      includeVerificationAudit: includeVerificationAudit,
      includeStockRouting: includeStockRouting,
      includeSettlement: includeSettlement,
    );
  }

  bool get isReady => genState == ReturnReversalVoucherGenState.ready;

  bool get canUseSalesInvoiceDocuments {
    return deskController.state.selectedSourceDocument?.type ==
        ReturnReversalSourceDocumentType.salesInvoice;
  }

  bool isOutputDocumentEnabled(ReturnReversalOutputDocumentKind kind) {
    return !kind.requiresSalesInvoice || canUseSalesInvoiceDocuments;
  }

  String get selectedOutputDocumentLabel => selectedOutputDocument.label;

  bool get showsInvoiceMetalScope {
    return selectedOutputDocument.requiresSalesInvoice &&
        canUseSalesInvoiceDocuments;
  }

  List<MetalType> get availableInvoiceMetals {
    final sourceDocument = deskController.state.selectedSourceDocument;
    if (sourceDocument == null) return const [];
    final metals = <MetalType>{};
    final lines = selectedOutputDocument ==
            ReturnReversalOutputDocumentKind.updatedSalesInvoice
        ? sourceDocument.lineItems.where((line) {
            return !line.isReversed &&
                !deskController.state.returnCartLineNumbers
                    .contains(line.lineNo);
          })
        : sourceDocument.lineItems;
    for (final line in lines) {
      metals.add(_metalFromSource(line.metalType));
    }
    return metals.toList(growable: false);
  }

  String get selectedInvoiceScopeLabel {
    return selectedInvoiceMetal == null
        ? 'All Metals'
        : selectedInvoiceMetal!.displayName;
  }

  Future<void> generateVoucher() async {
    genState = ReturnReversalVoucherGenState.generating;
    errorMessage = null;
    notifyListeners();

    try {
      _normalizeSelectedTemplate();
      _normalizeSelectedOutputDocument();
      pdfBytes = await _buildSelectedDocumentBytes();
      genState = ReturnReversalVoucherGenState.ready;
    } catch (error, stackTrace) {
      pdfBytes = null;
      errorMessage = error.toString();
      genState = ReturnReversalVoucherGenState.error;
      AppLogger.error(
        'Return reversal voucher preview generation failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    notifyListeners();
  }

  Future<void> switchFormat(PrintFormat format) async {
    if (selectedFormat == format) return;
    selectedFormat = format;
    await generateVoucher();
  }

  Future<void> selectPrintTemplate(String templateId) async {
    if (selectedTemplateId == templateId) return;
    selectedTemplateId = templateId;
    await generateVoucher();
  }

  Future<void> selectOutputDocument(
    ReturnReversalOutputDocumentKind kind,
  ) async {
    if (!isOutputDocumentEnabled(kind) || selectedOutputDocument == kind) {
      return;
    }
    selectedOutputDocument = kind;
    _normalizeSelectedInvoiceMetal();
    await generateVoucher();
  }

  Future<void> selectInvoiceMetalScope(MetalType? metal) async {
    if (!showsInvoiceMetalScope) return;
    final metals = availableInvoiceMetals;
    if (metal != null && !metals.contains(metal)) return;
    if (selectedInvoiceMetal == metal) return;
    selectedInvoiceMetal = metal;
    await generateVoucher();
  }

  Future<void> updateVoucherSections({
    bool? originalPricing,
    bool? verificationAudit,
    bool? stockRouting,
    bool? settlement,
  }) async {
    includeOriginalPricing = originalPricing ?? includeOriginalPricing;
    includeVerificationAudit = verificationAudit ?? includeVerificationAudit;
    includeStockRouting = stockRouting ?? includeStockRouting;
    includeSettlement = settlement ?? includeSettlement;
    await generateVoucher();
  }

  Future<void> updatePrintOptions({
    int? copies,
    bool? duplicate,
    bool? useDriverSettings,
  }) async {
    printCopies = (copies ?? printCopies).clamp(1, 5).toInt();
    includeDuplicateStamp = duplicate ?? includeDuplicateStamp;
    usePrinterDriverSettings = useDriverSettings ?? usePrinterDriverSettings;
    if (printCopies <= 1) {
      includeDuplicateStamp = false;
    }
    await generateVoucher();
  }

  Future<bool> printVoucher(BuildContext context) async {
    final bytes = await _latestBytes();
    if (bytes == null || !context.mounted) return false;

    final result = await _printDispatcher.dispatch(
      context: context,
      bytes: bytes,
      documentName: _pdfBaseName,
      outputFileName: _pdfFileName,
      printerPickerTitle: 'Select Document Printer',
      virtualSaveDialogTitle: 'Save Document Print Output As',
      usePrinterSettings: usePrinterDriverSettings,
    );
    return result.completed;
  }

  Future<bool> shareVoucherPdf() async {
    final bytes = await _latestBytes();
    if (bytes == null) return false;

    final tempDirectory = await Directory.systemTemp.createTemp(
      'lotus_erp_return_voucher_share_',
    );
    final file =
        File('${tempDirectory.path}${Platform.pathSeparator}$_pdfFileName');
    await file.writeAsBytes(bytes, flush: true);

    final result = await SharePlus.instance.share(
      ShareParams(
        title: 'Share ${selectedOutputDocument.label} PDF',
        subject: _pdfBaseName,
        files: [
          XFile(
            file.path,
            mimeType: 'application/pdf',
            name: _pdfFileName,
          ),
        ],
        fileNameOverrides: [_pdfFileName],
      ),
    );

    if (result.status != ShareResultStatus.dismissed) return true;
    return Printing.sharePdf(
      bytes: bytes,
      filename: _pdfFileName,
      subject: _pdfBaseName,
    );
  }

  Future<String?> exportVoucherPdf() async {
    final bytes = await _latestBytes();
    if (bytes == null) return null;

    final selectedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export ${selectedOutputDocument.label} PDF',
      fileName: _pdfFileName,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      lockParentWindow: true,
    );
    if (selectedPath == null) return null;

    final path = selectedPath.toLowerCase().endsWith('.pdf')
        ? selectedPath
        : '$selectedPath.pdf';
    final file = File(path);
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<Uint8List?> _latestBytes() async {
    if (pdfBytes == null || genState != ReturnReversalVoucherGenState.ready) {
      await generateVoucher();
    }
    return pdfBytes;
  }

  void _handleDeskStateChanged() {
    _normalizeSelectedOutputDocument();
    _normalizeSelectedInvoiceMetal();
    final currentIds =
        supportedTemplates.map((template) => template.id).toSet();
    if (!currentIds.contains(selectedTemplateId)) {
      selectedTemplateId = supportedTemplates.first.id;
    }
    generateVoucher();
  }

  void _normalizeSelectedTemplate() {
    final currentIds =
        supportedTemplates.map((template) => template.id).toSet();
    if (!currentIds.contains(selectedTemplateId)) {
      selectedTemplateId = supportedTemplates.first.id;
    }
  }

  void _normalizeSelectedOutputDocument() {
    if (!isOutputDocumentEnabled(selectedOutputDocument)) {
      selectedOutputDocument = ReturnReversalOutputDocumentKind.returnVoucher;
    }
  }

  void _normalizeSelectedInvoiceMetal() {
    if (!showsInvoiceMetalScope) {
      selectedInvoiceMetal = null;
      return;
    }
    final metals = availableInvoiceMetals;
    if (selectedInvoiceMetal != null &&
        !metals.contains(selectedInvoiceMetal)) {
      selectedInvoiceMetal = null;
    }
    if (metals.length <= 1) {
      selectedInvoiceMetal = metals.isEmpty ? null : metals.first;
    }
  }

  Future<Uint8List> _buildSelectedDocumentBytes() {
    return switch (selectedOutputDocument) {
      ReturnReversalOutputDocumentKind.returnVoucher =>
        ReturnReversalVoucherPdfService.buildVoucherBytes(
          state: deskController.state,
          options: options,
        ),
      ReturnReversalOutputDocumentKind.originalSalesInvoice =>
        ReturnReversalSalesInvoicePdfService.buildInvoiceBytes(
          state: deskController.state,
          options: options,
          mode: ReturnReversalSalesInvoiceCopyMode.original,
          activeMetal: selectedInvoiceMetal,
          includeAllMetals: selectedInvoiceMetal == null,
        ),
      ReturnReversalOutputDocumentKind.updatedSalesInvoice =>
        ReturnReversalSalesInvoicePdfService.buildInvoiceBytes(
          state: deskController.state,
          options: options,
          mode: ReturnReversalSalesInvoiceCopyMode.updatedAfterReturn,
          activeMetal: selectedInvoiceMetal,
          includeAllMetals: selectedInvoiceMetal == null,
        ),
    };
  }

  String get _pdfBaseName {
    final sourceNo =
        deskController.state.selectedSourceDocument?.documentNo ?? 'DRAFT';
    final voucherNo = deskController.state.lastProcessResult?.voucherNo ??
        deskController.state.selectedSourceDocument?.reversalVoucherNo;
    final documentNo =
        (voucherNo?.trim().isNotEmpty ?? false) ? voucherNo!.trim() : sourceNo;
    final title =
        selectedOutputDocument == ReturnReversalOutputDocumentKind.returnVoucher
            ? documentKind.shortTitle
            : selectedOutputDocument.shortLabel;
    return '${title}_$documentNo'.replaceAll(' ', '_');
  }

  MetalType _metalFromSource(String value) {
    return switch (value.trim().toUpperCase()) {
      'SILVER' => MetalType.silver,
      'PLATINUM' => MetalType.platinum,
      'DIAMOND' => MetalType.diamond,
      _ => MetalType.gold,
    };
  }

  String get _pdfFileName {
    final sanitized = _pdfBaseName.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '-');
    return sanitized.toLowerCase().endsWith('.pdf')
        ? sanitized
        : '$sanitized.pdf';
  }

  @override
  void dispose() {
    deskController.removeListener(_handleDeskStateChanged);
    super.dispose();
  }
}

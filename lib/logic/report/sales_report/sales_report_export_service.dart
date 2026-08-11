import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../models/reports/sales_report/sales_report_models.dart';
import '../../../features/settings/billing_setup/shop_info/data/shop_print_information_repository.dart';
import '../../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import 'export/sales_report_csv_builder.dart';
import 'export/sales_report_excel_builder.dart';
import 'export/sales_report_export_formatters.dart';
import 'export/sales_report_pdf_builder.dart';

enum SalesReportExportAction {
  completePdf,
  gstLiabilityPdf,
  gradeWisePdf,
  invoiceLedgerPdf,
  itemLedgerPdf,
  invoiceLedgerCsv,
  itemLedgerCsv,
  completeExcel,
}

class SalesReportExportService {
  SalesReportExportService._();

  static Future<String?> exportCsv(SalesReportSnapshot snapshot) {
    return exportCompleteCsv(snapshot);
  }

  static Future<String?> exportCompleteCsv(
    SalesReportSnapshot snapshot, {
    String? filePrefix,
  }) {
    return _saveCsv(
      dialogTitle: 'Download Complete Sales Report',
      fileName: _fileName(
        snapshot.filter,
        filePrefix ?? 'sales-report',
        'csv',
      ),
      contents: SalesReportCsvBuilder.buildComplete(snapshot),
    );
  }

  static Future<String?> exportCompleteExcel(
    SalesReportSnapshot snapshot, {
    String reportTitle = 'Sales Report',
    String? filePrefix,
  }) async {
    final identity = await _loadIdentity();
    final bytes = SalesReportExcelBuilder.buildComplete(
      snapshot,
      identity: identity,
      reportTitle: reportTitle,
    );
    return _saveBytes(
      dialogTitle: 'Download $reportTitle Excel',
      fileName: _fileName(
        snapshot.filter,
        filePrefix ?? 'sales-report',
        'xlsx',
      ),
      bytes: bytes,
      extension: 'xlsx',
    );
  }

  static Future<String?> exportInvoiceLedgerCsv(
    SalesReportSnapshot snapshot, {
    List<SalesReportInvoiceRow>? invoices,
    List<SalesReportItemRow>? items,
    String? filePrefix,
  }) {
    return _saveCsv(
      dialogTitle: 'Download Invoice Ledger',
      fileName: _fileName(
        snapshot.filter,
        filePrefix ?? 'sales-invoice-ledger',
        'csv',
      ),
      contents: SalesReportCsvBuilder.buildInvoiceLedger(
        invoices ?? snapshot.invoices,
        items ?? snapshot.items,
      ),
    );
  }

  static Future<String?> exportInvoiceLedgerPdf(
    SalesReportSnapshot snapshot, {
    List<SalesReportInvoiceRow>? invoices,
    List<SalesReportItemRow>? items,
    String reportTitle = 'Invoice Ledger',
    String? filePrefix,
  }) async {
    final identity = await _loadIdentity();
    final scopedSnapshot = _copySnapshot(
      snapshot,
      invoices: invoices,
      items: items,
    );
    final bytes = await buildInvoiceLedgerPdfBytes(
      scopedSnapshot,
      identity: identity,
      reportTitle: reportTitle,
    );
    return _savePdf(
      dialogTitle: 'Download $reportTitle PDF',
      fileName: _fileName(
        snapshot.filter,
        filePrefix ?? 'sales-invoice-ledger',
        'pdf',
      ),
      bytes: bytes,
    );
  }

  static Future<String?> exportItemLedgerCsv(
    SalesReportSnapshot snapshot, {
    List<SalesReportItemRow>? items,
    String? filePrefix,
  }) {
    return _saveCsv(
      dialogTitle: 'Download Item Ledger',
      fileName: _fileName(
        snapshot.filter,
        filePrefix ?? 'sales-item-ledger',
        'csv',
      ),
      contents: SalesReportCsvBuilder.buildItemLedger(items ?? snapshot.items),
    );
  }

  static Future<String?> exportItemLedgerPdf(
    SalesReportSnapshot snapshot, {
    List<SalesReportItemRow>? items,
    String reportTitle = 'Item Ledger',
    String? filePrefix,
  }) async {
    final identity = await _loadIdentity();
    final scopedSnapshot = _copySnapshot(
      snapshot,
      items: items,
    );
    final bytes = await buildItemLedgerPdfBytes(
      scopedSnapshot,
      identity: identity,
      reportTitle: reportTitle,
    );
    return _savePdf(
      dialogTitle: 'Download $reportTitle PDF',
      fileName: _fileName(
        snapshot.filter,
        filePrefix ?? 'sales-item-ledger',
        'pdf',
      ),
      bytes: bytes,
    );
  }

  static Future<String?> exportCompletePdf(
    SalesReportSnapshot snapshot, {
    String reportTitle = 'Sales Report',
    String? filePrefix,
  }) async {
    final identity = await _loadIdentity();
    final bytes = await buildCompletePdfBytes(
      snapshot,
      reportTitle: reportTitle,
      identity: identity,
    );
    return _savePdf(
      dialogTitle: 'Download $reportTitle PDF',
      fileName: _fileName(
        snapshot.filter,
        filePrefix ?? 'sales-report',
        'pdf',
      ),
      bytes: bytes,
    );
  }

  static Future<String?> exportGstLiabilityPdf(
    SalesReportSnapshot snapshot,
  ) async {
    final identity = await _loadIdentity();
    final bytes = await buildGstLiabilityPdfBytes(
      snapshot,
      identity: identity,
    );
    return _savePdf(
      dialogTitle: 'Download GST Liability Report',
      fileName: _fileName(snapshot.filter, 'gst-liability-report', 'pdf'),
      bytes: bytes,
    );
  }

  static Future<String?> exportGradeWisePdf(
    SalesReportSnapshot snapshot, {
    required String metalTitle,
  }) async {
    final identity = await _loadIdentity();
    final bytes = await buildGradeWisePdfBytes(
      snapshot,
      metalTitle: metalTitle,
      identity: identity,
    );
    return _savePdf(
      dialogTitle: 'Download $metalTitle Grade-wise Sales Report',
      fileName: _fileName(
        snapshot.filter,
        '${SalesReportExportFormatters.filePart(metalTitle)}-grade-sales-report',
        'pdf',
      ),
      bytes: bytes,
    );
  }

  @visibleForTesting
  static String buildCompleteCsvForTest(SalesReportSnapshot snapshot) {
    return SalesReportCsvBuilder.buildComplete(snapshot);
  }

  @visibleForTesting
  static Future<Uint8List> buildCompletePdfBytes(
    SalesReportSnapshot snapshot, {
    String reportTitle = 'Sales Report',
    SalesReportExportIdentity identity = SalesReportExportIdentity.fallback,
  }) {
    return SalesReportPdfBuilder.buildComplete(
      snapshot,
      reportTitle: reportTitle,
      identity: identity,
    );
  }

  @visibleForTesting
  static Future<Uint8List> buildGstLiabilityPdfBytes(
    SalesReportSnapshot snapshot, {
    SalesReportExportIdentity identity = SalesReportExportIdentity.fallback,
  }) {
    return SalesReportPdfBuilder.buildGstLiability(
      snapshot,
      identity: identity,
    );
  }

  @visibleForTesting
  static Future<Uint8List> buildGradeWisePdfBytes(
    SalesReportSnapshot snapshot, {
    required String metalTitle,
    SalesReportExportIdentity identity = SalesReportExportIdentity.fallback,
  }) {
    return SalesReportPdfBuilder.buildGradeWise(
      snapshot,
      metalTitle: metalTitle,
      identity: identity,
    );
  }

  @visibleForTesting
  static Future<Uint8List> buildInvoiceLedgerPdfBytes(
    SalesReportSnapshot snapshot, {
    String reportTitle = 'Invoice Ledger',
    SalesReportExportIdentity identity = SalesReportExportIdentity.fallback,
  }) {
    return SalesReportPdfBuilder.buildInvoiceLedger(
      snapshot,
      identity: identity,
      reportTitle: reportTitle,
    );
  }

  @visibleForTesting
  static Future<Uint8List> buildItemLedgerPdfBytes(
    SalesReportSnapshot snapshot, {
    String reportTitle = 'Item Ledger',
    SalesReportExportIdentity identity = SalesReportExportIdentity.fallback,
  }) {
    return SalesReportPdfBuilder.buildItemLedger(
      snapshot,
      identity: identity,
      reportTitle: reportTitle,
    );
  }

  @visibleForTesting
  static Uint8List buildCompleteExcelBytes(
    SalesReportSnapshot snapshot, {
    String reportTitle = 'Sales Report',
    SalesReportExportIdentity identity = SalesReportExportIdentity.fallback,
  }) {
    return SalesReportExcelBuilder.buildComplete(
      snapshot,
      identity: identity,
      reportTitle: reportTitle,
    );
  }

  static Future<String?> _saveCsv({
    required String dialogTitle,
    required String fileName,
    required String contents,
  }) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      lockParentWindow: true,
    );
    if (path == null) return null;

    final exportPath = path.toLowerCase().endsWith('.csv') ? path : '$path.csv';
    await File(exportPath).writeAsString(contents);
    return exportPath;
  }

  static Future<String?> _saveBytes({
    required String dialogTitle,
    required String fileName,
    required Uint8List bytes,
    required String extension,
  }) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [extension],
      lockParentWindow: true,
    );
    if (path == null) return null;

    final normalizedExtension = '.$extension';
    final exportPath = path.toLowerCase().endsWith(normalizedExtension)
        ? path
        : '$path$normalizedExtension';
    await File(exportPath).writeAsBytes(bytes, flush: true);
    return exportPath;
  }

  static Future<String?> _savePdf({
    required String dialogTitle,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      lockParentWindow: true,
    );
    if (path == null) return null;

    final exportPath = path.toLowerCase().endsWith('.pdf') ? path : '$path.pdf';
    await File(exportPath).writeAsBytes(bytes, flush: true);
    return exportPath;
  }

  static Future<SalesReportExportIdentity> _loadIdentity() async {
    try {
      final profile =
          await ShopPrintInformationRepository().loadDocumentProfile();
      final shopName = profile.primaryName.trim();
      if (shopName.isEmpty) return SalesReportExportIdentity.fallback;
      return SalesReportExportIdentity(
        shopName: shopName,
        headerLines: _reportHeaderLines(profile),
      );
    } catch (_) {
      return SalesReportExportIdentity.fallback;
    }
  }

  static List<String> _reportHeaderLines(ShopPrintDocumentProfile profile) {
    final lines = <String>[
      if (profile.primaryAddress.trim().isNotEmpty) profile.primaryAddress,
      if (profile.primaryPhone.trim().isNotEmpty)
        'Phone: ${profile.primaryPhone}',
      if (profile.gstin.trim().isNotEmpty) 'GSTIN: ${profile.gstin}',
    ];
    return lines;
  }

  static SalesReportSnapshot _copySnapshot(
    SalesReportSnapshot snapshot, {
    List<SalesReportInvoiceRow>? invoices,
    List<SalesReportItemRow>? items,
  }) {
    return SalesReportSnapshot(
      filter: snapshot.filter,
      summary: snapshot.summary,
      gstLiability: snapshot.gstLiability,
      metals: snapshot.metals,
      invoices: invoices ?? snapshot.invoices,
      items: items ?? snapshot.items,
      availableMetals: snapshot.availableMetals,
    );
  }

  static String _fileName(
    SalesReportFilter filter,
    String prefix,
    String extension,
  ) {
    return '${SalesReportExportFormatters.filePart(prefix)}.$extension';
  }
}

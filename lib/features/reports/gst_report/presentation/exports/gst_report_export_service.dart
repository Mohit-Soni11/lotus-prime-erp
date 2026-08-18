import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';

import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';
import 'gst_report_csv_builder.dart';
import 'gst_report_pdf_builder.dart';
import 'gst_report_portal_pack_builder.dart';

enum GstReportExportAction {
  portalUtilityPackZip,
  b2bPortalUtilityPackZip,
  b2cPortalUtilityPackZip,
  gstr1B2bCsv,
  gstr1B2clCsv,
  gstr1B2csCsv,
  gstr1HsnB2bCsv,
  gstr1HsnB2cCsv,
  gstr1DocumentsCsv,
  filingGuidePdf,
  summaryPdf,
  gstr1Csv,
  gstr3bCsv,
  hsnCsv,
  hsnPdf,
  invoiceLedgerCsv,
  invoiceLedgerPdf,
}

class GstReportExportService {
  GstReportExportService._();

  static Future<String?> export(
    GstReportSnapshot snapshot,
    GstReportExportAction action,
  ) {
    switch (action) {
      case GstReportExportAction.portalUtilityPackZip:
        return _saveZip(
          dialogTitle: 'Download GSTR-1 Offline Utility Pack',
          fileName: _fileName(snapshot, 'gstr-1-offline-utility-pack', 'zip'),
          buildBytes: () => _buildPortalPack(snapshot),
        );
      case GstReportExportAction.b2bPortalUtilityPackZip:
        return _saveZip(
          dialogTitle: 'Download B2B GSTR-1 Offline Utility Pack',
          fileName:
              _fileName(snapshot, 'gstr-1-b2b-offline-utility-pack', 'zip'),
          buildBytes: () => _buildPortalPack(
            snapshot,
            segment: GstFilingSegment.b2b,
          ),
        );
      case GstReportExportAction.b2cPortalUtilityPackZip:
        return _saveZip(
          dialogTitle: 'Download B2C GSTR-1 Offline Utility Pack',
          fileName:
              _fileName(snapshot, 'gstr-1-b2c-offline-utility-pack', 'zip'),
          buildBytes: () => _buildPortalPack(
            snapshot,
            segment: GstFilingSegment.b2c,
          ),
        );
      case GstReportExportAction.gstr1B2bCsv:
        return _savePortalCsv(
          dialogTitle: 'Download GSTR-1 B2B CSV',
          fileName: _fileName(snapshot, 'gstr-1-b2b-invoices', 'csv'),
          rows: GstReportPortalPackBuilder.b2bRows(snapshot),
        );
      case GstReportExportAction.gstr1B2clCsv:
        return _savePortalCsv(
          dialogTitle: 'Download GSTR-1 B2CL CSV',
          fileName: _fileName(snapshot, 'gstr-1-b2cl-invoices', 'csv'),
          rows: GstReportPortalPackBuilder.b2cLargeRows(snapshot),
        );
      case GstReportExportAction.gstr1B2csCsv:
        return _savePortalCsv(
          dialogTitle: 'Download GSTR-1 B2CS CSV',
          fileName: _fileName(snapshot, 'gstr-1-b2cs-summary', 'csv'),
          rows: GstReportPortalPackBuilder.b2cSmallRows(snapshot),
        );
      case GstReportExportAction.gstr1HsnB2bCsv:
        return _savePortalCsv(
          dialogTitle: 'Download GSTR-1 HSN B2B CSV',
          fileName: _fileName(snapshot, 'gstr-1-hsn-b2b-table12', 'csv'),
          rows: GstReportPortalPackBuilder.hsnB2bRows(snapshot),
        );
      case GstReportExportAction.gstr1HsnB2cCsv:
        return _savePortalCsv(
          dialogTitle: 'Download GSTR-1 HSN B2C CSV',
          fileName: _fileName(snapshot, 'gstr-1-hsn-b2c-table12', 'csv'),
          rows: GstReportPortalPackBuilder.hsnB2cRows(snapshot),
        );
      case GstReportExportAction.gstr1DocumentsCsv:
        return _savePortalCsv(
          dialogTitle: 'Download GSTR-1 Document Summary CSV',
          fileName: _fileName(snapshot, 'gstr-1-documents-issued', 'csv'),
          rows: GstReportPortalPackBuilder.documentIssuedRows(snapshot),
        );
      case GstReportExportAction.filingGuidePdf:
        return _savePdf(
          dialogTitle: 'Download GST Portal Filing Guide',
          fileName: _fileName(snapshot, 'gst-portal-filing-guide', 'pdf'),
          buildBytes: () => GstReportPdfBuilder.buildFilingGuide(snapshot),
        );
      case GstReportExportAction.summaryPdf:
        return _savePdf(
          dialogTitle: 'Download GST Summary PDF',
          fileName: _fileName(snapshot, 'gst-summary', 'pdf'),
          buildBytes: () => GstReportPdfBuilder.buildSummary(snapshot),
        );
      case GstReportExportAction.gstr1Csv:
        return _saveCsv(
          dialogTitle: 'Download GSTR-1 CSV',
          fileName: _fileName(snapshot, 'gstr-1-filing-workspace', 'csv'),
          contents: GstReportCsvBuilder.gstr1PortalRows(snapshot)
              .map(_csvRow)
              .join('\r\n'),
        );
      case GstReportExportAction.gstr3bCsv:
        return _saveCsv(
          dialogTitle: 'Download GSTR-3B Summary CSV',
          fileName: _fileName(snapshot, 'gstr-3b-filing-workspace', 'csv'),
          contents: GstReportCsvBuilder.gstr3bPortalRows(snapshot)
              .map(_csvRow)
              .join('\r\n'),
        );
      case GstReportExportAction.hsnCsv:
        return _saveCsv(
          dialogTitle: 'Download HSN Register CSV',
          fileName: _fileName(snapshot, 'hsn-gst-register', 'csv'),
          contents: GstReportCsvBuilder.hsnRows(snapshot.hsnSummary)
              .map(_csvRow)
              .join('\r\n'),
        );
      case GstReportExportAction.hsnPdf:
        return _savePdf(
          dialogTitle: 'Download HSN Register PDF',
          fileName: _fileName(snapshot, 'hsn-gst-register', 'pdf'),
          buildBytes: () => GstReportPdfBuilder.buildHsnRegister(snapshot),
        );
      case GstReportExportAction.invoiceLedgerCsv:
        return _saveCsv(
          dialogTitle: 'Download GST Invoice Ledger CSV',
          fileName: _fileName(snapshot, 'gst-invoice-ledger', 'csv'),
          contents: GstReportCsvBuilder.buildComplete(snapshot),
        );
      case GstReportExportAction.invoiceLedgerPdf:
        return _savePdf(
          dialogTitle: 'Download GST Invoice Ledger PDF',
          fileName: _fileName(snapshot, 'gst-invoice-ledger', 'pdf'),
          buildBytes: () => GstReportPdfBuilder.buildInvoiceLedger(snapshot),
        );
    }
  }

  static Uint8List _buildPortalPack(
    GstReportSnapshot snapshot, {
    GstFilingSegment? segment,
  }) {
    final documents = GstReportPortalPackBuilder.documents(
      snapshot,
      segment: segment,
    );
    if (documents.isEmpty) {
      throw StateError('No GST portal upload data is available.');
    }
    final archive = Archive();
    for (final document in documents) {
      final bytes = utf8.encode(document.contents);
      archive.addFile(ArchiveFile(document.fileName, bytes.length, bytes));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static Future<String?> _savePortalCsv({
    required String dialogTitle,
    required String fileName,
    required List<List<String>> rows,
  }) {
    if (!_hasPortalRows(rows)) {
      throw StateError('No GST portal upload data is available.');
    }
    return _saveCsv(
      dialogTitle: dialogTitle,
      fileName: fileName,
      contents: rows.map(GstReportPortalPackBuilder.csvRow).join('\r\n'),
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
    await File(exportPath).writeAsString(contents, flush: true);
    return exportPath;
  }

  static Future<String?> _savePdf({
    required String dialogTitle,
    required String fileName,
    required Future<Uint8List> Function() buildBytes,
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
    await File(exportPath).writeAsBytes(await buildBytes(), flush: true);
    return exportPath;
  }

  static Future<String?> _saveZip({
    required String dialogTitle,
    required String fileName,
    required Uint8List Function() buildBytes,
  }) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      lockParentWindow: true,
    );
    if (path == null) return null;
    final exportPath = path.toLowerCase().endsWith('.zip') ? path : '$path.zip';
    await File(exportPath).writeAsBytes(buildBytes(), flush: true);
    return exportPath;
  }

  static String _fileName(
    GstReportSnapshot snapshot,
    String name,
    String extension,
  ) {
    return '$name-${GstReportFormatters.filePart(snapshot.period)}.$extension';
  }

  static String _csvRow(List<String> row) {
    return row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(',');
  }

  static bool _hasPortalRows(List<List<String>> rows) {
    return rows.skip(1).any((row) => row.any((cell) => cell.trim().isNotEmpty));
  }
}

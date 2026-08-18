import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';
import 'gst_report_csv_builder.dart';
import 'gst_report_pdf_builder.dart';

enum GstReportExportAction {
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
}

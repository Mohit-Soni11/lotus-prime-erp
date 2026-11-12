import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../models/reports/day_book/day_book_models.dart';
import 'export/day_book_csv_export.dart';
import 'export/day_book_export_data.dart';
import 'export/day_book_export_loader.dart';
import 'export/day_book_pdf_export.dart';
import 'export/day_book_report_builder.dart';

class DayBookExportService {
  DayBookExportService._();

  static Future<void> previewPdf(DayBookSummary summary) async {
    final data = await DayBookExportLoader().load(summary);
    final bytes = await buildPdf(summary, data: data);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<bool> sharePdf(DayBookSummary summary) async {
    final data = await DayBookExportLoader().load(summary);
    final bytes = await buildPdf(summary, data: data);
    return Printing.sharePdf(
      bytes: bytes,
      filename: _fileName(summary.date, 'pdf'),
      subject: 'Day Book - ${DateFormat('d MMM yyyy').format(summary.date)}',
      body:
          'Detailed Day Book for ${DateFormat('d MMM yyyy').format(summary.date)}.',
    );
  }

  static Future<String?> exportCsv(DayBookSummary summary) async {
    final data = await DayBookExportLoader().load(summary);
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Day Book Detail',
      fileName: _fileName(summary.date, 'csv'),
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      lockParentWindow: true,
    );
    if (path == null) return null;
    final exportPath = path.toLowerCase().endsWith('.csv') ? path : '$path.csv';
    await File(exportPath).writeAsString(buildCsv(summary, data: data));
    return exportPath;
  }

  @visibleForTesting
  static Future<Uint8List> buildPdf(DayBookSummary summary,
          {DayBookExportData? data}) =>
      DayBookPdfExport.build(
          summary.date,
          DayBookReportBuilder.build(
              data ?? DayBookExportData(summary: summary)));

  @visibleForTesting
  static String buildCsv(DayBookSummary summary, {DayBookExportData? data}) =>
      DayBookCsvExport.build(
          summary.date,
          DayBookReportBuilder.build(
              data ?? DayBookExportData(summary: summary)));

  static String _fileName(DateTime date, String extension) =>
      'day_book_${DateFormat('yyyyMMdd').format(date)}.$extension';
}

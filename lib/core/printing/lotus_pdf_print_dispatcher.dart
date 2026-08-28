import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:printing/printing.dart';

import '../logging/app_logger.dart';

enum LotusPdfPrintResult {
  printed,
  savedVirtualOutput,
  cancelled,
  failed,
}

extension LotusPdfPrintResultX on LotusPdfPrintResult {
  bool get completed =>
      this == LotusPdfPrintResult.printed ||
      this == LotusPdfPrintResult.savedVirtualOutput;
}

class LotusPdfPrintDispatcher {
  const LotusPdfPrintDispatcher();

  Future<LotusPdfPrintResult> dispatch({
    required BuildContext context,
    required Uint8List bytes,
    required String documentName,
    required String outputFileName,
    required String printerPickerTitle,
    required String virtualSaveDialogTitle,
    bool usePrinterSettings = true,
  }) async {
    if (bytes.isEmpty) return LotusPdfPrintResult.failed;

    try {
      final printer = await Printing.pickPrinter(
        context: context,
        title: printerPickerTitle,
      );
      if (printer == null) return LotusPdfPrintResult.cancelled;

      if (isVirtualPdfPrinter(printer)) {
        final saved = await _saveVirtualPrintOutput(
          bytes: bytes,
          fileName: outputFileName,
          dialogTitle: virtualSaveDialogTitle,
        );
        return saved
            ? LotusPdfPrintResult.savedVirtualOutput
            : LotusPdfPrintResult.cancelled;
      }

      final printed = await Printing.directPrintPdf(
        printer: printer,
        name: documentName,
        usePrinterSettings: usePrinterSettings,
        onLayout: (_) async => bytes,
      );

      return printed ? LotusPdfPrintResult.printed : LotusPdfPrintResult.failed;
    } catch (error, stackTrace) {
      AppLogger.error(
        'LotusPdfPrintDispatcher.dispatch failed',
        error: error,
        stackTrace: stackTrace,
      );
      return LotusPdfPrintResult.failed;
    }
  }

  bool isVirtualPdfPrinter(Printer printer) {
    final signature = [
      printer.name,
      printer.model,
      printer.url,
      printer.comment,
    ].whereType<String>().join(' ').toLowerCase();

    return signature.contains('pdf') ||
        signature.contains('xps') ||
        signature.contains('onenote');
  }

  Future<bool> _saveVirtualPrintOutput({
    required Uint8List bytes,
    required String fileName,
    required String dialogTitle,
  }) async {
    final selectedPath = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: _ensurePdfExtension(fileName),
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      lockParentWindow: true,
    );
    if (selectedPath == null) return false;

    final exportPath = _ensurePdfExtension(selectedPath);
    final file = File(exportPath);
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    await file.writeAsBytes(bytes, flush: true);
    AppLogger.info('PDF print output saved at: ${file.path}');
    return true;
  }

  String _ensurePdfExtension(String path) {
    return path.toLowerCase().endsWith('.pdf') ? path : '$path.pdf';
  }
}

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

import '../../models/girvi/girvi_invoice_draft.dart';
import 'girvi_invoice_pdf_service.dart';

enum GirviInvoiceHubState { idle, generating, ready, error }

class GirviInvoiceHubController extends ChangeNotifier {
  GirviInvoiceHubController({
    required this.draft,
    required Future<bool> Function() onFinalize,
    GirviInvoicePdfService? pdfService,
  })  : _onFinalize = onFinalize,
        _pdfService = pdfService ?? GirviInvoicePdfService();

  final GirviInvoiceDraft draft;
  final Future<bool> Function() _onFinalize;
  final GirviInvoicePdfService _pdfService;

  GirviInvoiceHubState state = GirviInvoiceHubState.idle;
  GirviInvoiceFormat selectedFormat = GirviInvoiceFormat.a4;
  Uint8List? pdfBytes;
  String? errorMessage;
  int printCopies = 1;
  bool includeDuplicateStamp = false;
  bool isFinalized = false;
  bool isFinalizing = false;
  bool isExporting = false;

  bool get isReady => state == GirviInvoiceHubState.ready && pdfBytes != null;

  Future<void> generatePreview() async {
    state = GirviInvoiceHubState.generating;
    errorMessage = null;
    notifyListeners();
    try {
      pdfBytes = await _pdfService.build(
        draft: draft,
        format: selectedFormat,
        copies: printCopies,
        duplicateStamp: includeDuplicateStamp,
      );
      state = GirviInvoiceHubState.ready;
    } catch (error) {
      state = GirviInvoiceHubState.error;
      errorMessage = 'Invoice preview could not be generated.';
      debugPrint('GirviInvoiceHubController.generatePreview error: $error');
    }
    notifyListeners();
  }

  Future<void> switchFormat(GirviInvoiceFormat format) async {
    if (selectedFormat == format) return;
    selectedFormat = format;
    await generatePreview();
  }

  Future<void> updatePrintOptions({
    required int copies,
    required bool duplicate,
  }) async {
    printCopies = copies.clamp(1, 5);
    includeDuplicateStamp = duplicate;
    await generatePreview();
  }

  Future<bool> finalizeIfNeeded() async {
    if (isFinalized) return true;
    if (isFinalizing) return false;

    isFinalizing = true;
    errorMessage = null;
    notifyListeners();
    try {
      isFinalized = await _onFinalize();
      if (!isFinalized) {
        errorMessage = 'Girvi ticket could not be saved.';
      }
      return isFinalized;
    } catch (error) {
      errorMessage = 'Girvi ticket could not be saved.';
      debugPrint('GirviInvoiceHubController.finalizeIfNeeded error: $error');
      return false;
    } finally {
      isFinalizing = false;
      notifyListeners();
    }
  }

  Future<bool> printInvoice() async {
    if (!await finalizeIfNeeded()) return false;
    final bytes = await _pdfService.build(
      draft: draft,
      format: selectedFormat,
      copies: printCopies,
      duplicateStamp: includeDuplicateStamp,
    );
    await Printing.layoutPdf(
      name: _fileName,
      onLayout: (_) async => bytes,
    );
    return true;
  }

  Future<String?> exportPdf() async {
    if (!await finalizeIfNeeded()) return null;
    isExporting = true;
    notifyListeners();
    try {
      final selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Girvi Invoice PDF',
        fileName: _fileName,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        lockParentWindow: true,
      );
      if (selectedPath == null) return null;

      final outputPath = selectedPath.toLowerCase().endsWith('.pdf')
          ? selectedPath
          : '$selectedPath.pdf';
      final bytes = await _pdfService.build(
        draft: draft,
        format: selectedFormat,
        copies: printCopies,
        duplicateStamp: includeDuplicateStamp,
      );
      await File(outputPath).writeAsBytes(bytes, flush: true);
      return outputPath;
    } catch (error) {
      errorMessage = 'Invoice PDF could not be exported.';
      debugPrint('GirviInvoiceHubController.exportPdf error: $error');
      return null;
    } finally {
      isExporting = false;
      notifyListeners();
    }
  }

  String get _fileName {
    final safeTicket = draft.ticketNo.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '_');
    return 'girvi_invoice_$safeTicket.pdf';
  }
}

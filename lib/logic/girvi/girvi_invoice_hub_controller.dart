import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

import '../../models/girvi/girvi_invoice_draft.dart';
import '../../models/setting/billing_setup/girvi_billing_model.dart';
import '../../repositories/setting/billing_setup/girvi_billing_repo.dart';
import 'girvi_invoice_pdf_service.dart';

enum GirviInvoiceHubState { idle, generating, ready, error }

class GirviInvoiceHubController extends ChangeNotifier {
  GirviInvoiceHubController({
    required this.draft,
    required Future<bool> Function() onFinalize,
    GirviInvoicePdfService? pdfService,
    Future<GirviBillingModel> Function()? settingsLoader,
  })  : _onFinalize = onFinalize,
        _pdfService = pdfService ?? GirviInvoicePdfService(),
        _settingsLoader = settingsLoader ?? GirviBillingRepo().fetch;

  final GirviInvoiceDraft draft;
  final Future<bool> Function() _onFinalize;
  final GirviInvoicePdfService _pdfService;
  final Future<GirviBillingModel> Function() _settingsLoader;

  GirviInvoiceHubState state = GirviInvoiceHubState.idle;
  GirviBillingModel invoiceSettings = GirviBillingModel.defaults;
  GirviInvoiceFormat selectedFormat = GirviInvoiceFormat.a4;
  Uint8List? pdfBytes;
  String? errorMessage;
  int printCopies = 1;
  bool includeDuplicateStamp = false;
  bool isFinalized = false;
  bool isFinalizing = false;
  bool isExporting = false;
  bool _settingsLoaded = false;

  bool get isReady => state == GirviInvoiceHubState.ready && pdfBytes != null;

  Future<void> generatePreview() async {
    state = GirviInvoiceHubState.generating;
    errorMessage = null;
    notifyListeners();
    try {
      if (!_settingsLoaded) {
        await _loadSavedSettings();
      }
      pdfBytes = await _pdfService.build(
        draft: draft,
        format: selectedFormat,
        settings: invoiceSettings,
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

  bool getCustomizationValue(String key) {
    switch (key) {
      case 'metal':
        return invoiceSettings.showMetal;
      case 'pieces':
        return invoiceSettings.showPieces;
      case 'gross':
        return invoiceSettings.showGrossWeight;
      case 'less':
        return invoiceSettings.showLessWeight;
      case 'net':
        return invoiceSettings.showNetWeight;
      case 'purity':
        return invoiceSettings.showPurity;
      case 'valuationPurity':
        return invoiceSettings.showValuationPurity;
      case 'fine':
        return invoiceSettings.showFineWeight;
      case 'rate':
        return invoiceSettings.showRate;
      case 'huid':
        return invoiceSettings.showHuid;
      case 'value':
        return invoiceSettings.showTotalValue;
      case 'photos':
        return invoiceSettings.showItemPhotos;
      case 'kyc':
        return invoiceSettings.showKycDetails;
      case 'payment':
        return invoiceSettings.showDisbursementDetails;
      case 'printTerms':
        return invoiceSettings.printTermsAndConditions;
      case 'printFooter':
        return invoiceSettings.printFooterMessage;
      default:
        return false;
    }
  }

  Future<void> setCustomization(String key, bool value) async {
    switch (key) {
      case 'metal':
        invoiceSettings = invoiceSettings.copyWith(showMetal: value);
        break;
      case 'pieces':
        invoiceSettings = invoiceSettings.copyWith(showPieces: value);
        break;
      case 'gross':
        invoiceSettings = invoiceSettings.copyWith(showGrossWeight: value);
        break;
      case 'less':
        invoiceSettings = invoiceSettings.copyWith(showLessWeight: value);
        break;
      case 'net':
        invoiceSettings = invoiceSettings.copyWith(showNetWeight: value);
        break;
      case 'purity':
        invoiceSettings = invoiceSettings.copyWith(showPurity: value);
        break;
      case 'valuationPurity':
        invoiceSettings = invoiceSettings.copyWith(showValuationPurity: value);
        break;
      case 'fine':
        invoiceSettings = invoiceSettings.copyWith(showFineWeight: value);
        break;
      case 'rate':
        invoiceSettings = invoiceSettings.copyWith(showRate: value);
        break;
      case 'huid':
        invoiceSettings = invoiceSettings.copyWith(showHuid: value);
        break;
      case 'value':
        invoiceSettings = invoiceSettings.copyWith(showTotalValue: value);
        break;
      case 'photos':
        invoiceSettings = invoiceSettings.copyWith(showItemPhotos: value);
        break;
      case 'kyc':
        invoiceSettings = invoiceSettings.copyWith(showKycDetails: value);
        break;
      case 'payment':
        invoiceSettings =
            invoiceSettings.copyWith(showDisbursementDetails: value);
        break;
      case 'printTerms':
        invoiceSettings =
            invoiceSettings.copyWith(printTermsAndConditions: value);
        break;
      case 'printFooter':
        invoiceSettings = invoiceSettings.copyWith(printFooterMessage: value);
        break;
      default:
        return;
    }
    await generatePreview();
  }

  Future<void> setSavedCopyEnabled(bool value) async {
    invoiceSettings = invoiceSettings.copyWith(
      printTermsAndConditions: value,
      printFooterMessage: value,
    );
    await generatePreview();
  }

  Future<void> restoreSavedSetup() async {
    state = GirviInvoiceHubState.generating;
    notifyListeners();
    try {
      await _loadSavedSettings();
      await generatePreview();
    } catch (error) {
      state = GirviInvoiceHubState.error;
      errorMessage = 'Saved Girvi billing setup could not be loaded.';
      debugPrint('GirviInvoiceHubController.restoreSavedSetup error: $error');
      notifyListeners();
    }
  }

  Future<void> _loadSavedSettings() async {
    try {
      invoiceSettings = await _settingsLoader();
    } catch (error) {
      invoiceSettings = GirviBillingModel.defaults;
      debugPrint('Girvi invoice setup fallback: $error');
    }
    _settingsLoaded = true;
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
      settings: invoiceSettings,
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
        settings: invoiceSettings,
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

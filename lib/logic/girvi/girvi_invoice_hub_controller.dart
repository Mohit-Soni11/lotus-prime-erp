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
  String? activePrintMetal;

  bool get isReady => state == GirviInvoiceHubState.ready && pdfBytes != null;

  List<String> get presentMetals {
    final detected = draft.items
        .map((item) => GirviBillingMetal.normalize(item.metal))
        .toSet();
    const ordered = [
      GirviBillingMetal.gold,
      GirviBillingMetal.silver,
      GirviBillingMetal.platinum,
      GirviBillingMetal.diamond,
      GirviBillingMetal.other,
    ];
    return ordered.where(detected.contains).toList();
  }

  String? get effectiveActiveMetal {
    final metals = presentMetals;
    if (metals.isEmpty) return null;
    if (activePrintMetal != null && metals.contains(activePrintMetal)) {
      return activePrintMetal;
    }
    return metals.first;
  }

  GirviInvoiceFieldSettings getMetalSettings(String metal) {
    return invoiceSettings.settingsForMetal(metal);
  }

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

  Future<void> _loadSavedSettings() async {
    try {
      invoiceSettings = await _settingsLoader();
    } catch (error) {
      invoiceSettings = GirviBillingModel.defaults;
      debugPrint('Girvi invoice setup fallback: $error');
    }
    activePrintMetal = effectiveActiveMetal;
    _settingsLoaded = true;
  }

  void setActivePrintMetal(String metal) {
    final normalized = GirviBillingMetal.normalize(metal);
    if (!presentMetals.contains(normalized) || activePrintMetal == normalized) {
      return;
    }
    activePrintMetal = normalized;
    notifyListeners();
  }

  bool getMetalCustomizationValue(String metal, String key) {
    final settings = getMetalSettings(metal);
    switch (key) {
      case 'serial':
        return settings.showSerialNumber;
      case 'metal':
        return settings.showMetal;
      case 'item':
        return settings.showItemName;
      case 'pieces':
        return settings.showPieces;
      case 'huid':
        return settings.showHuid;
      case 'purity':
        return settings.showPurity;
      case 'gross':
        return settings.showGrossWeight;
      case 'less':
        return settings.showLessWeight;
      case 'net':
        return settings.showNetWeight;
      case 'valuationPurity':
        return settings.showValuationPurity;
      case 'fineWeight':
        return settings.showFineWeight;
      case 'ratePerGram':
        return settings.showRatePerGram;
      case 'valuationAmount':
        return settings.showValuationAmount;
      case 'photos':
        return settings.showItemPhotos;
      default:
        return false;
    }
  }

  bool getCombinedCustomizationValue(String key) {
    final metals = presentMetals;
    if (metals.isEmpty) return false;
    return metals.every((metal) => getMetalCustomizationValue(metal, key));
  }

  Future<void> setMetalCustomization(
    String metal,
    String key,
    bool value,
  ) async {
    final current = getMetalSettings(metal);
    final updated = _updateMetalSetting(current, key, value);
    if (updated == null) return;
    invoiceSettings = invoiceSettings.withMetalSettings(metal, updated);
    await generatePreview();
  }

  Future<void> setCombinedCustomization(String key, bool value) async {
    final metals = presentMetals;
    if (metals.isEmpty) return;
    var updatedModel = invoiceSettings;
    for (final metal in metals) {
      final updated = _updateMetalSetting(
        updatedModel.settingsForMetal(metal),
        key,
        value,
      );
      if (updated != null) {
        updatedModel = updatedModel.withMetalSettings(metal, updated);
      }
    }
    invoiceSettings = updatedModel;
    await generatePreview();
  }

  GirviInvoiceFieldSettings? _updateMetalSetting(
    GirviInvoiceFieldSettings current,
    String key,
    bool value,
  ) {
    switch (key) {
      case 'serial':
        return current.copyWith(showSerialNumber: value);
      case 'metal':
        return current.copyWith(showMetal: value);
      case 'item':
        return current.copyWith(showItemName: value);
      case 'pieces':
        return current.copyWith(showPieces: value);
      case 'huid':
        return current.copyWith(showHuid: value);
      case 'purity':
        return current.copyWith(showPurity: value);
      case 'gross':
        return current.copyWith(showGrossWeight: value);
      case 'less':
        return current.copyWith(showLessWeight: value);
      case 'net':
        return current.copyWith(showNetWeight: value);
      case 'valuationPurity':
        return current.copyWith(showValuationPurity: value);
      case 'fineWeight':
        return current.copyWith(showFineWeight: value);
      case 'ratePerGram':
        return current.copyWith(showRatePerGram: value);
      case 'valuationAmount':
        return current.copyWith(showValuationAmount: value);
      case 'photos':
        return current.copyWith(showItemPhotos: value);
      default:
        return null;
    }
  }

  bool getDocumentCustomizationValue(String key) {
    switch (key) {
      case 'customerMobile':
        return invoiceSettings.showCustomerMobile;
      case 'customerCity':
        return invoiceSettings.showCustomerCity;
      case 'loanAmount':
        return invoiceSettings.showLoanAmount;
      case 'interestRate':
        return invoiceSettings.showInterestRate;
      case 'duration':
        return invoiceSettings.showDuration;
      case 'startDate':
        return invoiceSettings.showStartDate;
      case 'maturityDate':
        return invoiceSettings.showMaturityDate;
      case 'monthlyInterest':
        return invoiceSettings.showMonthlyInterest;
      case 'totalInterest':
        return invoiceSettings.showTotalInterest;
      case 'totalDue':
        return invoiceSettings.showTotalDue;
      case 'totalValuation':
        return invoiceSettings.showTotalValue;
      case 'disbursement':
        return invoiceSettings.showDisbursementDetails;
      case 'kycDetails':
        return invoiceSettings.showKycDetails;
      case 'kycPhoto':
        return invoiceSettings.showKycPhoto;
      case 'notes':
        return invoiceSettings.showNotes;
      case 'terms':
        return invoiceSettings.printTermsAndConditions;
      case 'declaration':
        return invoiceSettings.printCustomerDeclaration;
      case 'footer':
        return invoiceSettings.printFooterMessage;
      default:
        return false;
    }
  }

  Future<void> setDocumentCustomization(String key, bool value) async {
    switch (key) {
      case 'customerMobile':
        invoiceSettings = invoiceSettings.copyWith(showCustomerMobile: value);
        break;
      case 'customerCity':
        invoiceSettings = invoiceSettings.copyWith(showCustomerCity: value);
        break;
      case 'loanAmount':
        invoiceSettings = invoiceSettings.copyWith(showLoanAmount: value);
        break;
      case 'interestRate':
        invoiceSettings = invoiceSettings.copyWith(showInterestRate: value);
        break;
      case 'duration':
        invoiceSettings = invoiceSettings.copyWith(showDuration: value);
        break;
      case 'startDate':
        invoiceSettings = invoiceSettings.copyWith(showStartDate: value);
        break;
      case 'maturityDate':
        invoiceSettings = invoiceSettings.copyWith(showMaturityDate: value);
        break;
      case 'monthlyInterest':
        invoiceSettings = invoiceSettings.copyWith(showMonthlyInterest: value);
        break;
      case 'totalInterest':
        invoiceSettings = invoiceSettings.copyWith(showTotalInterest: value);
        break;
      case 'totalDue':
        invoiceSettings = invoiceSettings.copyWith(showTotalDue: value);
        break;
      case 'totalValuation':
        invoiceSettings = invoiceSettings.copyWith(showTotalValue: value);
        break;
      case 'disbursement':
        invoiceSettings =
            invoiceSettings.copyWith(showDisbursementDetails: value);
        break;
      case 'kycDetails':
        invoiceSettings = invoiceSettings.copyWith(showKycDetails: value);
        break;
      case 'kycPhoto':
        invoiceSettings = invoiceSettings.copyWith(showKycPhoto: value);
        break;
      case 'notes':
        invoiceSettings = invoiceSettings.copyWith(showNotes: value);
        break;
      case 'terms':
        invoiceSettings =
            invoiceSettings.copyWith(printTermsAndConditions: value);
        break;
      case 'declaration':
        invoiceSettings =
            invoiceSettings.copyWith(printCustomerDeclaration: value);
        break;
      case 'footer':
        invoiceSettings = invoiceSettings.copyWith(printFooterMessage: value);
        break;
      default:
        return;
    }
    await generatePreview();
  }

  Future<void> restoreMetalSavedSetup(String metal) async {
    try {
      final saved = await _settingsLoader();
      invoiceSettings = invoiceSettings.withMetalSettings(
        metal,
        saved.settingsForMetal(metal),
      );
      await generatePreview();
    } catch (error) {
      errorMessage = 'Saved Girvi billing setup could not be loaded.';
      debugPrint(
        'GirviInvoiceHubController.restoreMetalSavedSetup error: $error',
      );
      notifyListeners();
    }
  }

  Future<void> restoreCombinedSavedSetup() async {
    try {
      final saved = await _settingsLoader();
      var updated = invoiceSettings;
      for (final metal in presentMetals) {
        updated = updated.withMetalSettings(
          metal,
          saved.settingsForMetal(metal),
        );
      }
      invoiceSettings = updated;
      await generatePreview();
    } catch (error) {
      errorMessage = 'Saved Girvi billing setup could not be loaded.';
      debugPrint(
        'GirviInvoiceHubController.restoreCombinedSavedSetup error: $error',
      );
      notifyListeners();
    }
  }

  Future<void> restoreDocumentSavedSetup() async {
    try {
      final saved = await _settingsLoader();
      invoiceSettings = invoiceSettings.copyWith(
        showCustomerMobile: saved.showCustomerMobile,
        showCustomerCity: saved.showCustomerCity,
        showLoanAmount: saved.showLoanAmount,
        showInterestRate: saved.showInterestRate,
        showDuration: saved.showDuration,
        showStartDate: saved.showStartDate,
        showMaturityDate: saved.showMaturityDate,
        showMonthlyInterest: saved.showMonthlyInterest,
        showTotalInterest: saved.showTotalInterest,
        showTotalDue: saved.showTotalDue,
        showTotalValue: saved.showTotalValue,
        showDisbursementDetails: saved.showDisbursementDetails,
        showKycDetails: saved.showKycDetails,
        showKycPhoto: saved.showKycPhoto,
        showNotes: saved.showNotes,
        printTermsAndConditions: saved.printTermsAndConditions,
        printFooterMessage: saved.printFooterMessage,
        termsAndConditions: saved.termsAndConditions,
        footerMessage: saved.footerMessage,
      );
      await generatePreview();
    } catch (error) {
      errorMessage = 'Saved Girvi receipt setup could not be loaded.';
      debugPrint(
        'GirviInvoiceHubController.restoreDocumentSavedSetup error: $error',
      );
      notifyListeners();
    }
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

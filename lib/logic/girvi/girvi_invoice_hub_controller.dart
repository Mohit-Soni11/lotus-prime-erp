import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/printing/lotus_pdf_print_dispatcher.dart';
import '../../features/print_templates/domain/print_template_registry.dart';
import '../../features/settings/billing_setup/shop_info/data/shop_print_information_repository.dart';
import '../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import '../../models/girvi/girvi_invoice_draft.dart';
import '../../models/girvi/girvi_invoice_branding.dart';
import '../../models/setting/billing_setup/girvi_billing_model.dart';
import '../../repositories/girvi/girvi_invoice_branding_repository.dart';
import '../../repositories/setting/billing_setup/girvi_billing_repo.dart';
import 'girvi_invoice_pdf_service.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

enum GirviInvoiceHubState { idle, generating, ready, error }

class GirviInvoiceHubController extends ChangeNotifier {
  GirviInvoiceHubController({
    required this.draft,
    required Future<bool> Function() onFinalize,
    GirviInvoicePdfService? pdfService,
    GirviBillingRepo? billingRepo,
    Future<GirviBillingModel> Function()? settingsLoader,
    Future<bool> Function(GirviBillingModel model)? settingsSaver,
    Future<GirviInvoiceBranding> Function()? brandingLoader,
    ShopPrintInformationRepository? shopPrintRepository,
  })  : _onFinalize = onFinalize,
        _pdfService = pdfService ?? GirviInvoicePdfService(),
        _brandingLoader =
            brandingLoader ?? GirviInvoiceBrandingRepository().fetch,
        _shopPrintRepository =
            shopPrintRepository ?? ShopPrintInformationRepository() {
    final resolvedBillingRepo = billingRepo ?? GirviBillingRepo();
    _settingsLoader = settingsLoader ?? resolvedBillingRepo.fetch;
    _settingsSaver = settingsSaver ?? resolvedBillingRepo.save;
  }

  final GirviInvoiceDraft draft;
  final Future<bool> Function() _onFinalize;
  final GirviInvoicePdfService _pdfService;
  late final Future<GirviBillingModel> Function() _settingsLoader;
  late final Future<bool> Function(GirviBillingModel model) _settingsSaver;
  final Future<GirviInvoiceBranding> Function() _brandingLoader;
  final ShopPrintInformationRepository _shopPrintRepository;

  GirviInvoiceHubState state = GirviInvoiceHubState.idle;
  GirviBillingModel invoiceSettings = GirviBillingModel.defaults;
  GirviInvoiceBranding invoiceBranding = GirviInvoiceBranding.fallback;
  GirviInvoiceFormat selectedFormat = GirviInvoiceFormat.a4;
  GirviReceiptMode selectedReceiptMode = GirviReceiptMode.pledge;
  String selectedTemplateId = PrintTemplateRegistry.defaultTemplateId;
  Uint8List? pdfBytes;
  String? errorMessage;
  int printCopies = 1;
  bool includeDuplicateStamp = false;
  bool usePrinterDriverSettings = true;
  LotusPrintColorMode printColorMode = LotusPrintColorMode.color;
  bool isFinalized = false;
  bool isFinalizing = false;
  bool isExporting = false;
  bool isSharing = false;
  bool _settingsLoaded = false;
  bool _brandingLoaded = false;
  ShopPrintInformationState? _shopPrintState;
  String? activePrintMetal;

  bool get isReady => state == GirviInvoiceHubState.ready && pdfBytes != null;

  ShopPrintInformationState? get shopPrintInformationState => _shopPrintState;

  GirviInvoiceDraft get printableDraft =>
      draft.copyWith(mode: selectedReceiptMode);

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
      _shopPrintState ??= await _loadShopPrintState();
      if (!_brandingLoaded) {
        await _loadShopBranding();
      }
      pdfBytes = await _pdfService.build(
        draft: printableDraft,
        format: selectedFormat,
        settings: invoiceSettings,
        branding: invoiceBranding,
        templateId: selectedTemplateId,
        copies: printCopies,
        duplicateStamp: includeDuplicateStamp,
      );
      state = GirviInvoiceHubState.ready;
    } catch (error) {
      state = GirviInvoiceHubState.error;
      errorMessage = 'Invoice preview could not be generated.';
      AppLogger.debug(
          'GirviInvoiceHubController.generatePreview error: $error');
    }
    notifyListeners();
  }

  Future<void> _loadShopBranding() async {
    try {
      invoiceBranding = await _brandingLoader();
      final shopPrintState = _shopPrintState;
      if (shopPrintState != null) {
        await _applyShopPrintProfile(shopPrintState);
      }
    } catch (error) {
      invoiceBranding = GirviInvoiceBranding.fallback;
      AppLogger.debug('Girvi shop profile fallback: $error');
    }
    _brandingLoaded = true;
  }

  Future<ShopPrintInformationState> _loadShopPrintState() async {
    try {
      return await _shopPrintRepository.load();
    } catch (error) {
      AppLogger.debug('Girvi shop print setup fallback: $error');
      return const ShopPrintInformationState(
        tenantId: '',
        fields: <ShopPrintField>[],
        enabledFieldIds: <String>{},
      );
    }
  }

  Future<void> _applyShopPrintProfile(
    ShopPrintInformationState state,
  ) async {
    if (state.tenantId.isEmpty) return;
    final profile = await _shopPrintRepository.buildDocumentProfile(state);
    invoiceBranding = invoiceBranding.withPrintProfile(profile);
  }

  Future<void> setShopPrintFieldEnabled(
    ShopPrintField field,
    bool enabled,
  ) async {
    final state = _shopPrintState;
    if (state == null || !field.isConfigured) return;

    final enabledIds = {...state.enabledFieldIds};
    if (enabled) {
      enabledIds.add(field.id);
    } else {
      enabledIds.remove(field.id);
    }

    _shopPrintState = state.copyWith(enabledFieldIds: enabledIds);
    await _applyShopPrintProfile(_shopPrintState!);
    await generatePreview();
  }

  Future<void> restoreShopPrintInformationSetup() async {
    _shopPrintState = await _loadShopPrintState();
    await _applyShopPrintProfile(_shopPrintState!);
    await generatePreview();
  }

  Future<void> saveShopPrintInformationSetup() async {
    final state = _shopPrintState;
    if (state == null || state.tenantId.isEmpty) return;
    await _shopPrintRepository.save(state);
  }

  Future<void> _loadSavedSettings() async {
    try {
      invoiceSettings = await _settingsLoader();
      selectedTemplateId = _resolveTemplateId(invoiceSettings.selectedTemplate);
    } catch (error) {
      invoiceSettings = GirviBillingModel.defaults;
      selectedTemplateId = PrintTemplateRegistry.defaultTemplateId;
      AppLogger.debug('Girvi invoice setup fallback: $error');
    }
    activePrintMetal = effectiveActiveMetal;
    selectedReceiptMode = draft.mode;
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
      AppLogger.debug(
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
      AppLogger.debug(
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
        printCustomerDeclaration: saved.printCustomerDeclaration,
        printFooterMessage: saved.printFooterMessage,
        termsAndConditions: saved.termsAndConditions,
        termsAndConditionsHindi: saved.termsAndConditionsHindi,
        customerDeclaration: saved.customerDeclaration,
        customerDeclarationHindi: saved.customerDeclarationHindi,
        footerMessage: saved.footerMessage,
      );
      await generatePreview();
    } catch (error) {
      errorMessage = 'Saved Girvi receipt setup could not be loaded.';
      AppLogger.debug(
        'GirviInvoiceHubController.restoreDocumentSavedSetup error: $error',
      );
      notifyListeners();
    }
  }

  Future<bool> saveInvoiceDisplaySetup() async {
    try {
      final modelToSave = invoiceSettings.copyWith(
        selectedTemplate: selectedTemplateId,
      );
      final saved = await _settingsSaver(modelToSave);
      if (!saved) {
        errorMessage = 'Girvi invoice display setup could not be saved.';
        notifyListeners();
        return false;
      }
      invoiceSettings = modelToSave;
      _settingsLoaded = true;
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      errorMessage = 'Girvi invoice display setup could not be saved.';
      AppLogger.debug(
        'GirviInvoiceHubController.saveInvoiceDisplaySetup error: $error',
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> switchFormat(GirviInvoiceFormat format) async {
    if (selectedFormat == format) return;
    selectedFormat = format;
    await generatePreview();
  }

  Future<void> switchTemplate(String templateId) async {
    final resolvedTemplateId = _resolveTemplateId(templateId);
    if (selectedTemplateId == resolvedTemplateId) return;
    selectedTemplateId = resolvedTemplateId;
    invoiceSettings = invoiceSettings.copyWith(
      selectedTemplate: resolvedTemplateId,
    );
    await generatePreview();
  }

  Future<void> updatePrintOptions({
    required int copies,
    required bool duplicate,
    bool? useDriverSettings,
    LotusPrintColorMode? colorMode,
  }) async {
    final normalizedCopies = copies.clamp(1, 5).toInt();
    printCopies = normalizedCopies;
    includeDuplicateStamp = normalizedCopies > 1 && duplicate;
    usePrinterDriverSettings = useDriverSettings ?? usePrinterDriverSettings;
    printColorMode = colorMode ?? printColorMode;
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
      AppLogger.debug(
          'GirviInvoiceHubController.finalizeIfNeeded error: $error');
      return false;
    } finally {
      isFinalizing = false;
      notifyListeners();
    }
  }

  Future<bool> printInvoice([BuildContext? context]) async {
    if (!await finalizeIfNeeded()) return false;
    if (!_brandingLoaded) await _loadShopBranding();
    final bytes = await buildPrintPdfBytes();
    if (bytes == null) return false;
    if (context == null) {
      return Printing.layoutPdf(
        name: _fileName,
        onLayout: (_) async => bytes,
      );
    }
    if (!context.mounted) return false;

    final result = await const LotusPdfPrintDispatcher().dispatch(
      context: context,
      bytes: bytes,
      documentName: _documentName,
      outputFileName: _fileName,
      printerPickerTitle: 'Select Girvi Invoice Printer',
      virtualSaveDialogTitle: 'Save Girvi Print Output As',
      usePrinterSettings: usePrinterDriverSettings,
      colorMode: printColorMode,
    );
    return result.completed;
  }

  Future<Uint8List?> buildPrintPdfBytes() async {
    if (!await finalizeIfNeeded()) return null;
    if (!_brandingLoaded) await _loadShopBranding();
    return _buildPdfBytes();
  }

  Future<bool> shareInvoicePdf() async {
    if (!await finalizeIfNeeded()) return false;
    if (!_brandingLoaded) await _loadShopBranding();

    isSharing = true;
    errorMessage = null;
    notifyListeners();
    try {
      final bytes = await _buildPdfBytes();
      final shareFile = await _writeTemporaryShareFile(_fileName, bytes);
      final result = await SharePlus.instance.share(
        ShareParams(
          title: 'Share Girvi Invoice PDF',
          subject: 'Girvi Invoice ${draft.ticketNo}',
          text: _shareMessage,
          files: [
            XFile(
              shareFile.path,
              mimeType: 'application/pdf',
              name: _fileName,
            ),
          ],
          fileNameOverrides: [_fileName],
        ),
      );
      if (result.status != ShareResultStatus.dismissed) return true;

      return Printing.sharePdf(
        bytes: bytes,
        filename: _fileName,
        subject: 'Girvi Invoice ${draft.ticketNo}',
      );
    } catch (error) {
      errorMessage = 'Invoice PDF could not be shared.';
      AppLogger.debug(
          'GirviInvoiceHubController.shareInvoicePdf error: $error');
      return false;
    } finally {
      isSharing = false;
      notifyListeners();
    }
  }

  Future<String?> exportPdf() async {
    if (!await finalizeIfNeeded()) return null;
    if (!_brandingLoaded) await _loadShopBranding();
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
      final bytes = await _buildPdfBytes();
      await File(outputPath).writeAsBytes(bytes, flush: true);
      return outputPath;
    } catch (error) {
      errorMessage = 'Invoice PDF could not be exported.';
      AppLogger.debug('GirviInvoiceHubController.exportPdf error: $error');
      return null;
    } finally {
      isExporting = false;
      notifyListeners();
    }
  }

  Future<Uint8List> _buildPdfBytes() {
    return _pdfService.build(
      draft: printableDraft,
      format: selectedFormat,
      settings: invoiceSettings,
      branding: invoiceBranding,
      templateId: selectedTemplateId,
      copies: printCopies,
      duplicateStamp: includeDuplicateStamp,
    );
  }

  Future<File> _writeTemporaryShareFile(
      String fileName, Uint8List bytes) async {
    final directory = await Directory.systemTemp.createTemp(
      'lotus_erp_girvi_invoice_share_',
    );
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String get _documentName => 'Girvi Invoice ${draft.ticketNo}';

  String get _fileName {
    final safeTicket = draft.ticketNo.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '_');
    return 'girvi_invoice_$safeTicket.pdf';
  }

  String get _shareMessage {
    final customer = draft.customerName.trim().isEmpty
        ? 'Customer'
        : draft.customerName.trim();
    return [
      'Dear $customer,',
      '',
      'Your Girvi invoice is attached.',
      'Invoice No: ${draft.ticketNo}',
      'Loan Amount: Rs ${draft.loanAmount.toStringAsFixed(2)}',
    ].join('\n');
  }

  String _resolveTemplateId(String templateId) {
    final template = PrintTemplateRegistry.byId(templateId);
    if (template.supports(PrintTemplateDocumentType.girviReceipt)) {
      return template.id;
    }
    return PrintTemplateRegistry.defaultTemplateId;
  }
}

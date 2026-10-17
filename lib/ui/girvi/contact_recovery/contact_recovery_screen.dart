import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../constants/app_routes.dart';
import '../../../logic/girvi/girvi_invoice_document_store.dart';
import '../../../logic/girvi/girvi_invoice_hub_controller.dart';
import '../../../logic/girvi/girvi_notice_generation_service.dart';
import '../../../logic/girvi/girvi_notice_pdf_service.dart';
import '../../../logic/girvi/contact_recovery_controller.dart';
import '../../../models/girvi/girvi_notice_action_model.dart';
import '../../../models/girvi/girvi_customer_response_model.dart';
import '../../../models/girvi/girvi_notice_document_record_model.dart';
import '../../../models/girvi/contact_recovery_model.dart';
import '../../../repositories/customer/customer_profile_repository.dart';
import '../../../theme/girvi/girvi_theme.dart';
import 'contact_recovery_app_bar.dart';
import 'widgets/notice_pdf_language_preview.dart';

part 'parts/contact_recovery_body.dart';
part 'parts/contact_recovery_case_card.dart';
part 'parts/contact_recovery_controls.dart';
part 'parts/contact_recovery_dialogs.dart';
part 'parts/contact_recovery_document_components.dart';
part 'parts/contact_recovery_empty_state.dart';
part 'parts/contact_recovery_overview.dart';
part 'parts/contact_recovery_settlement_dialog.dart';
part 'parts/notice_language_selector.dart';

class ContactRecoveryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String? initialTicketNo;
  final ContactRecoveryController? controller;

  const ContactRecoveryScreen({
    super.key,
    this.onBack,
    this.initialTicketNo,
    this.controller,
  });

  @override
  State<ContactRecoveryScreen> createState() => _ContactRecoveryScreenState();
}

class _ContactRecoveryScreenState extends State<ContactRecoveryScreen> {
  late final ContactRecoveryController _controller;
  final _noticePdfService = GirviNoticePdfService();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ContactRecoveryController();
    _controller.addListener(_syncState);
    final initialTicket = widget.initialTicketNo?.trim();
    if (initialTicket != null && initialTicket.isNotEmpty) {
      _searchController.text = initialTicket;
      _controller.setSearchQuery(initialTicket);
    }
    _searchController.addListener(
      () => _controller.setSearchQuery(_searchController.text),
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_syncState);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  void _syncState() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return Scaffold(
      backgroundColor: GirviColors.bodyBg,
      appBar: ContactRecoveryAppBar(
        onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ContactRecoveryOverview(state: state),
          _ContactRecoveryControls(
            state: state,
            searchController: _searchController,
            onFilterChanged: _controller.setFilter,
          ),
          if (state.inlineMessage != null)
            _InlineMessage(
              message: state.inlineMessage!,
              onClose: _controller.dismissInlineMessage,
            ),
          Expanded(
            child: _ContactRecoveryBody(
              state: state,
              onOpenAccount: _openAccount,
              onPrepareNotice: _prepareNotice,
              onViewNotice: _viewSavedNotice,
              onDownloadNotice: _downloadSavedNotice,
              onPrintNotice: _printSavedNotice,
              onRecordCustomerResponse: _recordCustomerResponse,
              onViewCustomerResponses: _viewCustomerResponses,
              onViewInvoice: _viewInvoice,
              onDownloadInvoice: _downloadInvoice,
              onViewItemImage: _viewItemImage,
              onDownloadItemImage: _downloadItemImage,
              onInitiateRecovery: _initiateCollateralRecovery,
              onCloseDisposal: _closeDisposalSettlement,
            ),
          ),
        ],
      ),
    );
  }

  void _openAccount(ContactRecoveryCase item) {
    final uri = Uri(
      path: RoutePaths.girviAccountFor(item.loan.id),
      queryParameters: {'returnTo': 'girviNotice'},
    );
    context.push(uri.toString());
  }

  Future<void> _prepareNotice(ContactRecoveryCase item) async {
    final noticeType = item.nextNoticeType;
    if (noticeType == null) {
      _controller.showInlineMessage(
        'The formal notice is already prepared for ticket ${item.loan.ticketNo}.',
      );
      return;
    }

    final noticeService = GirviNoticeGenerationService();
    final validationIssues = noticeService.validate(item);
    if (validationIssues.isNotEmpty) {
      _controller.showInlineMessage(
        'Notice cannot be prepared for ticket ${item.loan.ticketNo}: ${validationIssues.first}',
      );
      return;
    }

    final initialTexts = {
      ...noticeService.buildAll(
        item: item,
        noticeType: noticeType,
      ),
    };
    await showDialog<void>(
      context: context,
      builder: (context) => _NoticeEditorDialog(
        item: item,
        noticeType: noticeType,
        initialTexts: initialTexts,
        initialLanguage: GirviNoticeLanguage.hindi,
        onCopy: (language, text) =>
            _copyNoticeText(item, noticeType, language, text),
        onPreview: (language, text) =>
            _previewPreparedNotice(item, noticeType, language, text),
        onSave: (language, text, allTexts) => _controller.recordNoticePrepared(
          item,
          noticeType,
          text,
          autoGeneratedText: initialTexts[language],
          noticeDocuments: allTexts,
          autoGeneratedDocuments: initialTexts,
          primaryLanguage: language,
        ),
      ),
    );
  }

  Future<void> _copyNoticeText(
    ContactRecoveryCase item,
    GirviNoticeType noticeType,
    GirviNoticeLanguage language,
    String noticeText,
  ) async {
    await Clipboard.setData(ClipboardData(text: noticeText));
    await _controller.recordNoticeDraft(item, noticeText);
  }

  Future<void> _previewPreparedNotice(
    ContactRecoveryCase item,
    GirviNoticeType noticeType,
    GirviNoticeLanguage language,
    String noticeText,
  ) async {
    try {
      final bytes = await _noticePdfService.build(
        item: item,
        noticeType: noticeType,
        noticeLanguage: language,
        noticeText: noticeText,
      );
      if (!mounted) return;
      await _showNoticePreview(
        title: '${noticeType.label} PDF',
        subtitle: '${item.loan.ticketNo} · ${language.label} preview',
        bytes: bytes,
      );
    } catch (_) {
      _controller.showInlineMessage(
        '${noticeType.label} PDF preview could not be generated.',
      );
    }
  }

  Future<void> _viewSavedNotice(
    ContactRecoveryCase item,
    GirviNoticeAction action,
  ) async {
    final drafts = _savedNoticeDrafts(item, action);
    if (drafts.isEmpty) {
      _controller.showInlineMessage(
        'No approved notice text is available for ticket ${item.loan.ticketNo}.',
      );
      return;
    }
    final primaryLanguage = _noticeLanguageForText(action.noticeText ?? '');
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      useSafeArea: false,
      builder: (_) => NoticePdfLanguagePreview(
        title: '${action.noticeLabel} PDF',
        ticketNo: item.loan.ticketNo,
        availableLanguages: drafts.keys.toSet(),
        initialLanguage: drafts.containsKey(primaryLanguage)
            ? primaryLanguage
            : drafts.keys.first,
        buildPdf: (language) => _buildSavedNoticePdf(drafts[language]!),
      ),
    );
  }

  Map<GirviNoticeLanguage, _SavedNoticeDraft> _savedNoticeDrafts(
    ContactRecoveryCase item,
    GirviNoticeAction action,
  ) {
    final drafts = <GirviNoticeLanguage, _SavedNoticeDraft>{};
    for (final document in item.documentsForNoticeAction(action.id)) {
      if (document.noticeText.trim().isEmpty) continue;
      drafts[document.language] =
          _savedNoticeDraft(item, action, document: document);
    }
    // Legacy notices contain only the language that was actually approved.
    final legacyText = action.noticeText?.trim() ?? '';
    if (drafts.isEmpty && legacyText.isNotEmpty) {
      final draft = _savedNoticeDraft(item, action);
      drafts[draft.language] = draft;
    }
    return drafts;
  }

  Future<_SavedNoticeDraft?> _chooseSavedNoticeDraft(
    ContactRecoveryCase item,
    GirviNoticeAction action,
  ) async {
    final drafts = _savedNoticeDrafts(item, action);
    if (drafts.isEmpty) {
      _controller.showInlineMessage(
        'No approved notice text is available for ticket ${item.loan.ticketNo}.',
      );
      return null;
    }
    final selectedLanguage = await showDialog<GirviNoticeLanguage>(
      context: context,
      builder: (context) => _NoticeLanguageSelectorDialog(
        noticeType: GirviNoticeType.formal,
        availableLanguages: drafts.keys.toSet(),
      ),
    );
    if (!mounted || selectedLanguage == null) return null;
    return drafts[selectedLanguage];
  }

  Future<Uint8List> _buildSavedNoticePdf(
    _SavedNoticeDraft draft,
  ) {
    return _noticePdfService.buildStoredNotice(
      ticketNo: draft.item.loan.ticketNo,
      noticeType: draft.noticeType,
      noticeLanguage: draft.language,
      noticeText: draft.noticeText,
      savedAt: draft.action.actionAt,
      legacyNoticeStage: draft.action.isLegacyNoticePreparation
          ? draft.action.resolvedNoticeStage
          : null,
    );
  }

  Future<void> _downloadSavedNotice(
    ContactRecoveryCase item,
    GirviNoticeAction action,
  ) async {
    final draft = await _chooseSavedNoticeDraft(item, action);
    if (draft == null) return;
    try {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save ${draft.action.noticeLabel}',
        fileName: draft.fileName,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (outputPath == null) return;

      final normalizedPath = outputPath.toLowerCase().endsWith('.pdf')
          ? outputPath
          : '$outputPath.pdf';
      final bytes = await _buildSavedNoticePdf(draft);
      await File(normalizedPath).writeAsBytes(bytes, flush: true);
      final proofRecorded = await _controller.recordNoticeDeliveryProof(
        item: item,
        noticeType: draft.noticeType,
        noticeText: draft.noticeText,
        noticeLanguage: draft.language,
        noticeActionId: draft.action.id,
        actionType: GirviNoticeActionTypes.noticePdfSaved,
        deliveryChannel: 'PDF File',
        deliveryStatus: 'Saved',
        deliveryReference: normalizedPath,
      );
      _controller.showInlineMessage(
        '${draft.action.noticeLabel} (${draft.language.label}) PDF saved for ticket ${item.loan.ticketNo}.${proofRecorded ? '' : ' Saving the audit record failed; the PDF file was saved.'}',
      );
    } catch (_) {
      _controller.showInlineMessage(
        '${draft.action.noticeLabel} PDF could not be saved.',
      );
    }
  }

  Future<void> _printSavedNotice(
    ContactRecoveryCase item,
    GirviNoticeAction action,
  ) async {
    final draft = await _chooseSavedNoticeDraft(item, action);
    if (draft == null) return;
    try {
      final bytes = await _buildSavedNoticePdf(draft);
      final printed = await Printing.layoutPdf(
        name: draft.fileName,
        onLayout: (_) async => bytes,
      );
      if (printed) {
        final proofRecorded = await _controller.recordNoticeDeliveryProof(
          item: item,
          noticeType: draft.noticeType,
          noticeText: draft.noticeText,
          noticeLanguage: draft.language,
          noticeActionId: draft.action.id,
          actionType: GirviNoticeActionTypes.noticePdfPrinted,
          deliveryChannel: 'Printer',
          deliveryStatus: 'Printed',
        );
        _controller.showInlineMessage(
          '${draft.action.noticeLabel} (${draft.language.label}) PDF sent to printer for ticket ${item.loan.ticketNo}.${proofRecorded ? '' : ' Saving the audit record failed.'}',
        );
      }
    } catch (_) {
      _controller.showInlineMessage(
        '${draft.action.noticeLabel} PDF could not be printed.',
      );
    }
  }

  Future<void> _recordCustomerResponse(
    ContactRecoveryCase item,
    GirviNoticeAction notice,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _CustomerResponseDialog(
        item: item,
        notice: notice,
        onSave: ({
          required kind,
          required channel,
          required responseText,
          promisedAmount,
          promiseDueAt,
          proofReference,
        }) =>
            _controller.recordCustomerResponse(
          item: item,
          notice: notice,
          kind: kind,
          channel: channel,
          responseText: responseText,
          promisedAmount: promisedAmount,
          promiseDueAt: promiseDueAt,
          proofReference: proofReference,
        ),
      ),
    );
  }

  Future<void> _viewCustomerResponses(ContactRecoveryCase item) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _CustomerResponseTimelineDialog(
        item: item,
        onResolvePromise: ({
          required response,
          required status,
          String? resolutionNote,
        }) =>
            _controller.resolveCustomerPromise(
          item: item,
          responseId: response.id,
          status: status,
          resolutionNote: resolutionNote,
        ),
      ),
    );
  }

  Future<void> _closeDisposalSettlement(ContactRecoveryCase item) async {
    final bankAccounts = await _controller.loadActiveRecoveryBankAccounts();
    if (!mounted) return;
    final result = await showDialog<_DisposalSettlementResult>(
      context: context,
      builder: (context) => _DisposalSettlementDialog(
        item: item,
        bankAccounts: bankAccounts,
      ),
    );

    if (result == null) return;
    await _controller.closeDisposalSettlement(
      item: item,
      pledgedValuation: result.pledgedValuation,
      recoveredAmount: result.recoveredAmount,
      penaltyAmount: result.penaltyAmount,
      note: result.note,
      paymentMode: result.paymentMethod.dbValue,
      bankAccountId: result.bankAccountId,
    );
  }

  Future<void> _initiateCollateralRecovery(ContactRecoveryCase item) async {
    await _controller.initiateCollateralRecovery(item);
  }

  Future<void> _viewInvoice(ContactRecoveryCase item) async {
    try {
      final bytes = await _buildInvoicePdfBytes(item);
      if (!mounted) return;
      await _showInvoicePreview(item: item, bytes: bytes);
    } catch (_) {
      _controller.showInlineMessage(
        'Invoice PDF could not be opened for ticket ${item.loan.ticketNo}.',
      );
    }
  }

  Future<void> _downloadInvoice(ContactRecoveryCase item) async {
    try {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Invoice PDF',
        fileName: 'girvi_invoice_${_safeFileToken(item.loan.ticketNo)}.pdf',
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        lockParentWindow: true,
      );
      if (outputPath == null) return;

      final normalizedPath = outputPath.toLowerCase().endsWith('.pdf')
          ? outputPath
          : '$outputPath.pdf';
      final bytes = await _buildInvoicePdfBytes(item);
      await File(normalizedPath).writeAsBytes(bytes, flush: true);
      _controller.showInlineMessage(
        'Invoice PDF saved for ticket ${item.loan.ticketNo}.',
      );
    } catch (_) {
      _controller.showInlineMessage(
        'Invoice PDF could not be saved for ticket ${item.loan.ticketNo}.',
      );
    }
  }

  Future<Uint8List> _buildInvoicePdfBytes(ContactRecoveryCase item) async {
    if (item.loan.invoiceGenerated) {
      final savedBytes = await const GirviInvoiceDocumentStore().readInvoice(
        loanId: item.loan.id,
        ticketNo: item.loan.ticketNo,
      );
      if (savedBytes != null) return savedBytes;
    }

    final draft = await CustomerProfileRepository(db: _controller.database)
        .fetchGirviInvoiceDraft(
      customerId: item.loan.customerId,
      loanId: item.loan.id,
    );
    if (draft == null) {
      throw StateError('Invoice draft could not be loaded.');
    }

    final invoiceController = GirviInvoiceHubController(
      draft: draft,
      onFinalize: () async => true,
    );
    try {
      await invoiceController.generatePreview();
      final bytes = invoiceController.pdfBytes;
      if (bytes == null) {
        throw StateError('Invoice PDF could not be generated.');
      }
      return bytes;
    } finally {
      invoiceController.dispose();
    }
  }

  Future<void> _showInvoicePreview({
    required ContactRecoveryCase item,
    required Uint8List bytes,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      useSafeArea: false,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF111827),
        child: Stack(
          children: [
            Positioned.fill(
              child: PdfPreview(
                build: (_) async => bytes,
                initialPageFormat: PdfPageFormat.a4,
                allowPrinting: false,
                allowSharing: false,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                useActions: false,
                maxPageWidth: 920,
                scrollViewDecoration: const BoxDecoration(
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 18,
              child: _PreviewTitleBadge(
                title: 'Invoice PDF',
                subtitle: item.loan.ticketNo,
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: Material(
                color: Colors.black.withValues(alpha: 0.62),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Close preview',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNoticePreview({
    required String title,
    required String subtitle,
    required Uint8List bytes,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      useSafeArea: false,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF111827),
        child: Stack(
          children: [
            Positioned.fill(
              child: PdfPreview(
                build: (_) async => bytes,
                initialPageFormat: PdfPageFormat.a4,
                allowPrinting: false,
                allowSharing: false,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                useActions: false,
                maxPageWidth: 920,
                scrollViewDecoration: const BoxDecoration(
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 18,
              child: _PreviewTitleBadge(
                title: title,
                subtitle: subtitle,
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: Material(
                color: Colors.black.withValues(alpha: 0.62),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Close preview',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewItemImage(ContactRecoveryCase item) async {
    final path = _firstExistingItemPhotoPath(item);
    if (path == null) {
      _controller.showInlineMessage(
        'No item image is available for ticket ${item.loan.ticketNo}.',
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      useSafeArea: false,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF111827),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.6,
                maxScale: 5,
                boundaryMargin: const EdgeInsets.all(260),
                child: Center(
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported_rounded,
                          color: Colors.white.withValues(alpha: 0.72),
                          size: 52,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Item image could not be opened',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 18,
              child: _PreviewTitleBadge(
                title: 'Item Image',
                subtitle: item.loan.ticketNo,
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: Material(
                color: Colors.black.withValues(alpha: 0.62),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Close image',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadItemImage(ContactRecoveryCase item) async {
    final path = _firstExistingItemPhotoPath(item);
    if (path == null) {
      _controller.showInlineMessage(
        'No item image is available for ticket ${item.loan.ticketNo}.',
      );
      return;
    }

    try {
      final extension = _fileExtension(path);
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Item Image',
        fileName:
            'pledged_item_${_safeFileToken(item.loan.ticketNo)}.$extension',
        type: FileType.custom,
        allowedExtensions: [extension],
        lockParentWindow: true,
      );
      if (outputPath == null) return;

      final normalizedPath = outputPath.toLowerCase().endsWith('.$extension')
          ? outputPath
          : '$outputPath.$extension';
      await File(path).copy(normalizedPath);
      _controller.showInlineMessage(
        'Item image saved for ticket ${item.loan.ticketNo}.',
      );
    } catch (_) {
      _controller.showInlineMessage(
        'Item image could not be saved for ticket ${item.loan.ticketNo}.',
      );
    }
  }

  String? _firstExistingItemPhotoPath(ContactRecoveryCase item) {
    for (final rawPath in item.itemPhotoPaths) {
      final path = rawPath.trim();
      if (path.isNotEmpty && File(path).existsSync()) return path;
    }
    return null;
  }

  String _fileExtension(String path) {
    final name = path.split(RegExp(r'[\\/]')).last;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == name.length - 1) return 'jpg';
    final extension = name.substring(dotIndex + 1).toLowerCase();
    return RegExp(r'^[a-z0-9]{2,5}$').hasMatch(extension) ? extension : 'jpg';
  }

  String _safeFileToken(String value) {
    final token = value.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    return token.isEmpty ? 'document' : token;
  }

  String _noticePdfName(
    ContactRecoveryCase item,
    GirviNoticeType noticeType,
    GirviNoticeLanguage language,
  ) {
    final safeTicket =
        item.loan.ticketNo.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    return 'girvi_${safeTicket}_notice_${language.fileLabel}.pdf';
  }

  _SavedNoticeDraft _savedNoticeDraft(
    ContactRecoveryCase item,
    GirviNoticeAction action, {
    GirviNoticeDocumentRecord? document,
  }) {
    const noticeType = GirviNoticeType.formal;
    final storedText =
        document?.noticeText.trim() ?? action.noticeText?.trim() ?? '';
    final selectedLanguage =
        document?.language ?? _noticeLanguageForText(storedText);
    return _SavedNoticeDraft(
      item: item,
      action: action,
      noticeType: noticeType,
      language: selectedLanguage,
      noticeText: storedText,
      fileName: action.isLegacyNoticePreparation
          ? 'girvi_${item.loan.ticketNo.replaceAll(RegExp(r"[^A-Za-z0-9]+"), "_")}_legacy_notice_${action.resolvedNoticeStage}_${selectedLanguage.fileLabel}.pdf'
          : _noticePdfName(item, noticeType, selectedLanguage),
    );
  }

  GirviNoticeLanguage _noticeLanguageForText(String value) {
    if (RegExp(r'[\u0900-\u097F]').hasMatch(value)) {
      return GirviNoticeLanguage.hindi;
    }
    return GirviNoticeLanguage.english;
  }
}

class _SavedNoticeDraft {
  final ContactRecoveryCase item;
  final GirviNoticeAction action;
  final GirviNoticeType noticeType;
  final GirviNoticeLanguage language;
  final String noticeText;
  final String fileName;

  const _SavedNoticeDraft({
    required this.item,
    required this.action,
    required this.noticeType,
    required this.language,
    required this.noticeText,
    required this.fileName,
  });
}

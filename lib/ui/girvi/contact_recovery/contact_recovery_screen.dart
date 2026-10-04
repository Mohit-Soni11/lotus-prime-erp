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
import '../../../models/girvi/contact_recovery_model.dart';
import '../../../repositories/customer/customer_profile_repository.dart';
import '../../../theme/girvi/girvi_theme.dart';
import 'contact_recovery_app_bar.dart';

part 'parts/contact_recovery_body.dart';
part 'parts/contact_recovery_case_card.dart';
part 'parts/contact_recovery_controls.dart';
part 'parts/contact_recovery_dialogs.dart';
part 'parts/contact_recovery_document_components.dart';
part 'parts/contact_recovery_empty_state.dart';
part 'parts/contact_recovery_overview.dart';
part 'parts/contact_recovery_settlement_dialog.dart';

class ContactRecoveryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String? initialTicketNo;

  const ContactRecoveryScreen({
    super.key,
    this.onBack,
    this.initialTicketNo,
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
    _controller = ContactRecoveryController()..addListener(_syncState);
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
    _controller.dispose();
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
        'All required notices are already prepared for ticket ${item.loan.ticketNo}.',
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
        onPrint: (language, text) =>
            _printNotice(item, noticeType, language, text),
        onShare: (language, text) =>
            _shareNotice(item, noticeType, language, text),
        onSave: (language, text) => _controller.recordNoticePrepared(
          item,
          noticeType,
          text,
          autoGeneratedText: initialTexts[language],
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

  Future<void> _printNotice(
    ContactRecoveryCase item,
    GirviNoticeType noticeType,
    GirviNoticeLanguage language,
    String noticeText,
  ) async {
    final bytes = await _noticePdfService.build(
      item: item,
      noticeType: noticeType,
      noticeLanguage: language,
      noticeText: noticeText,
    );
    final printed = await Printing.layoutPdf(
      name: _noticePdfName(item, noticeType, language),
      onLayout: (_) async => bytes,
    );
    if (printed) {
      await _controller.recordNoticeDeliveryProof(
        item: item,
        noticeType: noticeType,
        noticeText: noticeText,
        actionType: GirviNoticeActionTypes.noticePdfPrinted,
        deliveryChannel: 'Printer',
        deliveryStatus: 'Printed',
      );
    }
  }

  Future<void> _shareNotice(
    ContactRecoveryCase item,
    GirviNoticeType noticeType,
    GirviNoticeLanguage language,
    String noticeText,
  ) async {
    final bytes = await _noticePdfService.build(
      item: item,
      noticeType: noticeType,
      noticeLanguage: language,
      noticeText: noticeText,
    );
    final shared = await Printing.sharePdf(
      bytes: bytes,
      filename: _noticePdfName(item, noticeType, language),
    );
    if (shared) {
      await _controller.recordNoticeDeliveryProof(
        item: item,
        noticeType: noticeType,
        noticeText: noticeText,
        actionType: GirviNoticeActionTypes.noticePdfShared,
        deliveryChannel: 'Share Sheet',
        deliveryStatus: 'Shared',
      );
    }
  }

  Future<void> _viewSavedNotice(
    ContactRecoveryCase item,
    GirviNoticeAction action,
  ) async {
    final draft = _savedNoticeDraft(item, action);
    await showDialog<void>(
      context: context,
      builder: (context) => _SavedNoticePreviewDialog(
        draft: draft,
        onDownload: () => _downloadSavedNotice(item, action),
        onPrint: () => _printSavedNotice(item, action),
      ),
    );
  }

  Future<void> _downloadSavedNotice(
    ContactRecoveryCase item,
    GirviNoticeAction action,
  ) async {
    final draft = _savedNoticeDraft(item, action);
    try {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save ${draft.noticeType.label}',
        fileName: draft.fileName,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (outputPath == null) return;

      final normalizedPath = outputPath.toLowerCase().endsWith('.pdf')
          ? outputPath
          : '$outputPath.pdf';
      final bytes = await _noticePdfService.buildStoredNotice(
        ticketNo: item.loan.ticketNo,
        noticeType: draft.noticeType,
        noticeLanguage: draft.language,
        noticeText: draft.noticeText,
        savedAt: action.actionAt,
      );
      await File(normalizedPath).writeAsBytes(bytes, flush: true);
      await _controller.recordNoticeDeliveryProof(
        item: item,
        noticeType: draft.noticeType,
        noticeText: draft.noticeText,
        actionType: GirviNoticeActionTypes.noticePdfSaved,
        deliveryChannel: 'PDF File',
        deliveryStatus: 'Saved',
        deliveryReference: normalizedPath,
      );
      _controller.showInlineMessage(
        '${draft.noticeType.label} PDF saved for ticket ${item.loan.ticketNo}.',
      );
    } catch (_) {
      _controller.showInlineMessage(
        '${draft.noticeType.label} PDF could not be saved.',
      );
    }
  }

  Future<void> _printSavedNotice(
    ContactRecoveryCase item,
    GirviNoticeAction action,
  ) async {
    final draft = _savedNoticeDraft(item, action);
    try {
      final bytes = await _noticePdfService.buildStoredNotice(
        ticketNo: item.loan.ticketNo,
        noticeType: draft.noticeType,
        noticeLanguage: draft.language,
        noticeText: draft.noticeText,
        savedAt: action.actionAt,
      );
      final printed = await Printing.layoutPdf(
        name: draft.fileName,
        onLayout: (_) async => bytes,
      );
      if (printed) {
        await _controller.recordNoticeDeliveryProof(
          item: item,
          noticeType: draft.noticeType,
          noticeText: draft.noticeText,
          actionType: GirviNoticeActionTypes.noticePdfPrinted,
          deliveryChannel: 'Printer',
          deliveryStatus: 'Printed',
        );
        _controller.showInlineMessage(
          '${draft.noticeType.label} PDF sent to printer for ticket ${item.loan.ticketNo}.',
        );
      }
    } catch (_) {
      _controller.showInlineMessage(
        '${draft.noticeType.label} PDF could not be printed.',
      );
    }
  }

  Future<void> _closeDisposalSettlement(ContactRecoveryCase item) async {
    final result = await showDialog<_DisposalSettlementResult>(
      context: context,
      builder: (context) => _DisposalSettlementDialog(item: item),
    );

    if (result == null) return;
    await _controller.closeDisposalSettlement(
      item: item,
      pledgedValuation: result.pledgedValuation,
      recoveredAmount: result.recoveredAmount,
      penaltyAmount: result.penaltyAmount,
      note: result.note,
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
    return 'girvi_${safeTicket}_notice_${noticeType.stage}_${language.fileLabel}.pdf';
  }

  _SavedNoticeDraft _savedNoticeDraft(
    ContactRecoveryCase item,
    GirviNoticeAction action,
  ) {
    final noticeType = _noticeTypeFromAction(action);
    final storedText = action.noticeText?.trim() ?? '';
    final language = _noticeLanguageForText(storedText);
    final noticeText = storedText.isEmpty
        ? GirviNoticeGenerationService().build(
            item: item,
            noticeType: noticeType,
            language: language,
          )
        : _noticeTextWithoutValuation(storedText);
    return _SavedNoticeDraft(
      item: item,
      action: action,
      noticeType: noticeType,
      language: language,
      noticeText: noticeText,
      fileName: _noticePdfName(item, noticeType, language),
    );
  }

  String _noticeTextWithoutValuation(String noticeText) {
    const hiddenPrefixes = <String>[
      'Pledged Valuation:',
      'Pledged Value:',
      'Valuation:',
      'गिरवी मूल्यांकन:',
      'गिरवी मूल्य:',
      'मूल्यांकन:',
    ];
    return noticeText
        .split('\n')
        .where((line) {
          final trimmed = line.trim();
          return !hiddenPrefixes.any(trimmed.startsWith);
        })
        .join('\n')
        .trim();
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

GirviNoticeType _noticeTypeFromAction(GirviNoticeAction action) {
  final stage = _noticeStageFromAction(action) ?? 1;
  return GirviNoticeType.fromStage(stage.clamp(1, 3).toInt());
}

int? _noticeStageFromAction(GirviNoticeAction action) {
  final stage = action.noticeStage;
  if (stage != null) return stage;
  switch (action.actionType) {
    case GirviNoticeActionTypes.firstNoticePrepared:
    case GirviNoticeActionTypes.noticeDraftCopied:
      return 1;
    case GirviNoticeActionTypes.secondNoticePrepared:
      return 2;
    case GirviNoticeActionTypes.finalNoticePrepared:
      return 3;
    default:
      return null;
  }
}

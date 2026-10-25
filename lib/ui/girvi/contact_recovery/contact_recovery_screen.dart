import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants/app_routes.dart';
import '../../../core/time/date_sensitive_refresh.dart';
import '../../../core/printing/lotus_pdf_print_dispatcher.dart';
import '../../../logic/girvi/girvi_invoice_document_store.dart';
import '../../../logic/girvi/girvi_recovery_pdf_stamp_service.dart';
import '../../../logic/girvi/girvi_invoice_hub_controller.dart';
import '../../../logic/girvi/girvi_notice_generation_service.dart';
import '../../../logic/girvi/girvi_notice_pdf_service.dart';
import '../../../logic/girvi/notice_pdf/notice_statement_data.dart';
import '../../../logic/girvi/notice_pdf/notice_item_photo_resolver.dart';
import '../../../logic/girvi/contact_recovery_controller.dart';
import '../../../logic/girvi/notice/girvi_notice_approval_validator.dart';
import '../../../models/girvi/girvi_notice_action_model.dart';
import '../../../models/girvi/girvi_notice_branding_snapshot.dart';
import '../../../models/girvi/girvi_invoice_branding.dart';
import '../../../models/girvi/girvi_notice_review_period.dart';
import '../../../models/girvi/girvi_customer_response_model.dart';
import '../../../models/girvi/girvi_notice_document_record_model.dart';
import '../../../models/girvi/girvi_loan_model.dart';
import '../../../models/girvi/contact_recovery_model.dart';
import '../../../repositories/customer/customer_profile_repository.dart';
import '../../../repositories/girvi/girvi_invoice_branding_repository.dart';
import '../../../theme/girvi/girvi_theme.dart';
import 'contact_recovery_app_bar.dart';
import 'item_recovery/item_recovery_dialog.dart';

part 'parts/contact_recovery_body.dart';
part 'parts/contact_recovery_case_card.dart';
part 'parts/contact_recovery_inline_message.dart';
part 'parts/contact_recovery_dialogs.dart';
part 'parts/contact_recovery_response_dialogs.dart';
part 'parts/contact_recovery_response_editor.dart';
part 'parts/contact_recovery_document_components.dart';
part 'parts/contact_recovery_empty_state.dart';
part 'parts/contact_recovery_notice_dispatch.dart';
part 'parts/contact_recovery_delivery.dart';
part 'parts/contact_recovery_account_documents.dart';
part 'parts/contact_recovery_notice_documents.dart';

class ContactRecoveryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String? initialTicketNo;
  final ContactRecoveryController? controller;
  final GirviInvoiceBrandingRepository? brandingRepository;
  final Future<String?> Function(
    String method,
    Uint8List bytes,
    String fileName,
    String customerMobile,
  )? noticeDispatcher;
  final Future<Uint8List> Function()? noticePdfBytesBuilder;

  const ContactRecoveryScreen({
    super.key,
    this.onBack,
    this.initialTicketNo,
    this.controller,
    this.brandingRepository,
    this.noticeDispatcher,
    this.noticePdfBytesBuilder,
  });

  @override
  State<ContactRecoveryScreen> createState() => _ContactRecoveryScreenState();
}

class _ContactRecoveryScreenState extends State<ContactRecoveryScreen> {
  late final ContactRecoveryController _controller;
  late final DateSensitiveRefresh _dateRefresh;
  final _noticePdfService = GirviNoticePdfService();
  late final _noticeItemPhotoResolver =
      NoticeItemPhotoResolver(_controller.database);
  late final _noticeBrandingRepository = widget.brandingRepository ??
      GirviInvoiceBrandingRepository(db: _controller.database);
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        ContactRecoveryController(ticketNo: widget.initialTicketNo ?? '');
    _controller.addListener(_syncState);
    if (widget.initialTicketNo?.trim().isNotEmpty ?? false) {
      _controller.load();
    }
    _dateRefresh = DateSensitiveRefresh(
      onRefresh: _controller.load,
      hasDueEvent: (now) => _controller.state.allCases.any((item) {
        final dueAt = item.recoveryAvailableAt;
        return item.stage == ContactRecoveryStage.noticePending &&
            dueAt != null &&
            !now.isBefore(dueAt);
      }),
    );
  }

  @override
  void dispose() {
    _dateRefresh.dispose();
    _controller.removeListener(_syncState);
    if (widget.controller == null) {
      _controller.dispose();
    }
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
          if (state.inlineMessage != null)
            _InlineMessage(
              message: state.inlineMessage!,
              onClose: _controller.dismissInlineMessage,
            ),
          Expanded(
            child: widget.initialTicketNo?.trim().isNotEmpty != true
                ? const _EmptyState(
                    title: 'Select an invoice',
                    subtitle:
                        'Open Notice & Recovery from the invoice in Risk & Collections.',
                  )
                : _ContactRecoveryBody(
                    state: state,
                    onOpenAccount: _openAccount,
                    onPrepareNotice: _prepareNotice,
                    onViewNotice: _viewSavedNotice,
                    onDownloadNotice: _downloadSavedNotice,
                    onPrintNotice: _printSavedNotice,
                    onConfirmDelivery: _confirmNoticeDelivery,
                    onSettlement: _openSettlement,
                    onRecordCustomerResponse: _recordCustomerResponse,
                    onViewCustomerResponses: _viewCustomerResponses,
                    onViewInvoice: _viewInvoice,
                    onDownloadInvoice: _downloadInvoice,
                    onViewItemImage: _viewItemImage,
                    onDownloadItemImage: _downloadItemImage,
                    onCompleteRecovery: _completeItemRecovery,
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

  Future<void> _openSettlement(ContactRecoveryCase item) async {
    await context.push(
      Uri(
        path: RoutePaths.girviInterest,
        queryParameters: {
          'ticketNo': item.loan.ticketNo,
          'returnTo': 'girviNotice',
        },
      ).toString(),
    );
    if (mounted) await _controller.load();
  }

  Future<void> _prepareNotice(ContactRecoveryCase item) async {
    await _controller.load();
    if (!mounted) return;
    if (_controller.state.errorMessage != null) return;
    final currentItem = _controller.state.allCases
        .where((entry) => entry.loan.id == item.loan.id)
        .firstOrNull;
    if (currentItem == null) {
      _controller.showInlineMessage(
        'Ticket ${item.loan.ticketNo} is no longer eligible for notice preparation.',
      );
      return;
    }
    final noticeType = currentItem.nextNoticeType;
    if (noticeType == null) {
      _controller.showInlineMessage(
        'The formal notice is already prepared for ticket ${currentItem.loan.ticketNo}.',
      );
      return;
    }

    final branding = await _noticeBrandingRepository.fetch();
    if (!mounted) return;
    final noticeService = GirviNoticeGenerationService(
      now: currentItem.now,
      shopName: branding.printShopName,
    );
    final validationIssues = noticeService.validate(currentItem);
    if (validationIssues.isNotEmpty) {
      _controller.showInlineMessage(
        'Notice cannot be prepared for ticket ${currentItem.loan.ticketNo}: ${validationIssues.first}',
      );
      return;
    }

    String generateTextForPeriod(int days) => noticeService.build(
          item: currentItem,
          noticeType: noticeType,
          language: GirviNoticeLanguage.english,
          noticePeriodDays: days,
        );
    final initialDays =
        currentItem.noticePeriodDays > 0 ? currentItem.noticePeriodDays : 7;
    final initialText = generateTextForPeriod(initialDays);
    await showDialog<void>(
      context: context,
      builder: (context) => _NoticeEditorDialog(
        item: currentItem,
        noticeType: noticeType,
        initialText: initialText,
        generateTextForPeriod: generateTextForPeriod,
        onPreview: (language, text, days) => _previewPreparedNotice(
          currentItem,
          noticeType,
          language,
          text,
          days,
          branding,
        ),
        onSend: (language, text, allTexts, days, method) => _sendPreparedNotice(
          currentItem,
          noticeType,
          language,
          text,
          allTexts,
          days,
          method,
          branding,
          generateTextForPeriod(days),
        ),
      ),
    );
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
          promiseDueAt,
        }) =>
            _controller.recordCustomerResponse(
          item: item,
          notice: notice,
          kind: kind,
          channel: channel,
          responseText: responseText,
          promiseDueAt: promiseDueAt,
        ),
      ),
    );
  }

  Future<void> _viewCustomerResponses(ContactRecoveryCase item) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _CustomerResponseTimelineDialog(
        item: item,
        onResolveFollowUp: ({
          required response,
          required status,
          String? resolutionNote,
        }) =>
            _controller.resolveCustomerFollowUp(
          item: item,
          responseId: response.id,
          status: status,
          resolutionNote: resolutionNote,
        ),
      ),
    );
  }

  Future<void> _completeItemRecovery(ContactRecoveryCase item) async {
    final bankAccounts = await _controller.loadActiveRecoveryBankAccounts();
    final pledgedItems =
        await _controller.loadRecoveryPledgedItems(item.loan.id);
    if (!mounted) return;
    final result = await showDialog<ItemRecoveryResult>(
      context: context,
      builder: (context) => ItemRecoveryDialog(
        item: item,
        bankAccounts: bankAccounts,
        pledgedItems: pledgedItems,
      ),
    );

    if (result == null) return;
    await _controller.completeItemRecovery(
      item: item,
      recoveredAmount: result.recoveredAmount,
      note: result.note,
      paymentMode: result.paymentMethod?.dbValue,
      dispositionMethod: result.dispositionMethod,
      bankAccountId: result.bankAccountId,
    );
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
      fileName: action.noticeActionId != null
          ? 'girvi_${item.loan.ticketNo.replaceAll(RegExp(r"[^A-Za-z0-9]+"), "_")}_corrected_notice_${selectedLanguage.fileLabel}.pdf'
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

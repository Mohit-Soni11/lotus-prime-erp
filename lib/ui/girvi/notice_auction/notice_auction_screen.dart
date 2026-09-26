import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../constants/app_routes.dart';
import '../../../logic/girvi/girvi_notice_pdf_service.dart';
import '../../../logic/girvi/notice_auction_controller.dart';
import '../../../models/girvi/girvi_notice_action_model.dart';
import '../../../models/girvi/notice_auction_model.dart';
import '../../../theme/girvi/girvi_theme.dart';
import 'notice_auction_app_bar.dart';

part 'parts/notice_auction_components.dart';
part 'parts/notice_auction_dialogs.dart';
part 'parts/notice_auction_document_components.dart';
part 'parts/notice_auction_settlement_dialog.dart';

class NoticeAuctionScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String? initialTicketNo;

  const NoticeAuctionScreen({
    super.key,
    this.onBack,
    this.initialTicketNo,
  });

  @override
  State<NoticeAuctionScreen> createState() => _NoticeAuctionScreenState();
}

class _NoticeAuctionScreenState extends State<NoticeAuctionScreen> {
  late final NoticeAuctionController _controller;
  final _noticePdfService = GirviNoticePdfService();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = NoticeAuctionController()..addListener(_syncState);
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
      appBar: NoticeAuctionAppBar(
        onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
        onRefreshTap: _controller.load,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NoticeAuctionOverview(state: state),
          _NoticeAuctionControls(
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
            child: _NoticeAuctionBody(
              state: state,
              onOpenAccount: _openAccount,
              onPrepareNotice: _prepareNotice,
              onViewNotice: _viewSavedNotice,
              onDownloadNotice: _downloadSavedNotice,
              onPrintNotice: _printSavedNotice,
              onCloseDisposal: _closeDisposalSettlement,
            ),
          ),
        ],
      ),
    );
  }

  void _openAccount(NoticeAuctionCase item) {
    final uri = Uri(
      path: RoutePaths.girviAccountFor(item.loan.id),
      queryParameters: {'returnTo': 'girviNotice'},
    );
    context.push(uri.toString());
  }

  Future<void> _prepareNotice(NoticeAuctionCase item) async {
    final noticeType = item.nextNoticeType;
    if (noticeType == null) {
      _controller.showInlineMessage(
        'All required notices are already prepared for ticket ${item.loan.ticketNo}.',
      );
      return;
    }

    final initialTexts = {
      GirviNoticeLanguage.hindi: _buildNoticeText(
        item,
        noticeType,
        GirviNoticeLanguage.hindi,
      ),
      GirviNoticeLanguage.english: _buildNoticeText(
        item,
        noticeType,
        GirviNoticeLanguage.english,
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
        ),
      ),
    );
  }

  Future<void> _copyNoticeText(
    NoticeAuctionCase item,
    GirviNoticeType noticeType,
    GirviNoticeLanguage language,
    String noticeText,
  ) async {
    await Clipboard.setData(ClipboardData(text: noticeText));
    await _controller.recordNoticePrepared(item, noticeType, noticeText);
  }

  Future<void> _printNotice(
    NoticeAuctionCase item,
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
      await _controller.recordNoticePrepared(item, noticeType, noticeText);
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
    NoticeAuctionCase item,
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
      await _controller.recordNoticePrepared(item, noticeType, noticeText);
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
    NoticeAuctionCase item,
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
    NoticeAuctionCase item,
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
      final bytes = await _noticePdfService.build(
        item: item,
        noticeType: draft.noticeType,
        noticeLanguage: draft.language,
        noticeText: draft.noticeText,
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
    NoticeAuctionCase item,
    GirviNoticeAction action,
  ) async {
    final draft = _savedNoticeDraft(item, action);
    try {
      final bytes = await _noticePdfService.build(
        item: item,
        noticeType: draft.noticeType,
        noticeLanguage: draft.language,
        noticeText: draft.noticeText,
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

  Future<void> _closeDisposalSettlement(NoticeAuctionCase item) async {
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

  String _buildNoticeText(
    NoticeAuctionCase item,
    GirviNoticeType noticeType,
    GirviNoticeLanguage language,
  ) {
    final account = item.account;
    final loan = item.loan;
    final dateFmt = DateFormat('dd MMMM yyyy');
    final noticeDate = dateFmt.format(DateTime.now());
    final startDate = dateFmt.format(loan.startDate);
    final maturity = loan.maturityDate == null
        ? 'Not set'
        : dateFmt.format(loan.maturityDate!);
    final settlementDeadline = DateTime.now().add(
      Duration(days: item.noticePeriodDays),
    );
    final itemSummary = loan.itemDescription.trim().isEmpty
        ? loan.itemSummary
        : loan.itemDescription.trim();
    final cleanItemSummary = _noticeItemSummary(itemSummary, language);
    final address = account.customerAddress.isEmpty
        ? language == GirviNoticeLanguage.hindi
            ? 'उपलब्ध नहीं'
            : 'Not available'
        : account.customerAddress;
    final deadline = dateFmt.format(settlementDeadline);
    final noticeProgress = '${noticeType.stage}/3';
    final overdueAge = item.overdueAgeMonthsDaysLabel;
    final loanAge = item.loanAgeMonthsDaysLabel;

    if (language == GirviNoticeLanguage.hindi) {
      final subject = switch (noticeType) {
        GirviNoticeType.first => 'पहली गिरवी निपटान सूचना',
        GirviNoticeType.second => 'दूसरी गिरवी भुगतान चेतावनी',
        GirviNoticeType.finalNotice => 'अंतिम भुगतान और वसूली सूचना',
      };
      final opening = switch (noticeType) {
        GirviNoticeType.first =>
          'यह सूचना है कि नीचे दिया गया गिरवी खाता देय तारीख के बाद भी लंबित है। कृपया सूचना अवधि में पूरी बकाया राशि जमा कर गिरवी वस्तु छुड़ाएं।',
        GirviNoticeType.second =>
          'पहली सूचना के बाद भी खाता लंबित है। यह दूसरी लिखित चेतावनी है। कृपया अंतिम कार्रवाई से बचने के लिए बकाया राशि तुरंत जमा करें।',
      GirviNoticeType.finalNotice =>
          'यह अंतिम सूचना है। यदि अंतिम तारीख तक पूरा भुगतान नहीं होता है, तो गिरवी वस्तु को न छुड़ाया गया मानकर लागू कानून, सहमत Girvi terms और business policy के अनुसार वैध वसूली प्रक्रिया शुरू की जा सकती है।',
      };
      final closing = switch (noticeType) {
        GirviNoticeType.first =>
          'कृपया इस सूचना के साथ दुकान पर आएं और अंतिम तारीख से पहले पूरा भुगतान करें।',
        GirviNoticeType.second =>
          'इस चेतावनी के बाद भी भुगतान नहीं होने पर अंतिम भुगतान और वसूली सूचना जारी की जा सकती है।',
        GirviNoticeType.finalNotice =>
          'अंतिम तारीख के बाद वसूली राशि को मूलधन, ब्याज, दंड, custody charges और legal recovery cost में adjust किया जा सकता है। कोई balance customer से payable रह सकता है; surplus amount policy और law के अनुसार handle होगा।',
      };

      return [
        'विषय: $subject',
        '',
        'प्रिय ${account.customerName},',
        '',
        opening,
        '',
        'सूचना दिनांक: $noticeDate',
        'टिकट नंबर: ${loan.ticketNo}',
        'ग्राहक मोबाइल: ${account.customerMobile}',
        'ग्राहक पता: $address',
        'गिरवी रखने की तारीख: $startDate',
        'देय तारीख: $maturity',
        'खाता अवधि: $loanAge',
        'बकाया अवधि: $overdueAge',
        'सूचना चरण: $noticeProgress',
        '',
        'गिरवी वस्तु: $cleanItemSummary',
        'गिरवी मूल्यांकन: ${_money(loan.totalValue)}',
        '',
        'मूलधन बकाया: ${_money(account.principalDue)}',
        'ब्याज बकाया: ${_money(account.netInterestDue)}',
        'कुल देय राशि: ${_money(account.totalPayable)}',
        '',
        'सूचना अवधि: ${item.noticePeriodDays} दिन',
        'अंतिम तारीख: $deadline',
        '',
        closing,
        '',
        'यह notice लागू कानून, सहमत Girvi terms और business policy के अनुसार जारी है। दुकान के सभी rights और remedies reserved रहेंगे।',
        '',
        'दुकान साइन',
      ].join('\n');
    }

    final subject = switch (noticeType) {
      GirviNoticeType.first => 'First Girvi Settlement Notice',
      GirviNoticeType.second => 'Second Girvi Settlement Warning',
      GirviNoticeType.finalNotice => 'Final Redemption and Recovery Notice',
    };
    final opening = switch (noticeType) {
      GirviNoticeType.first =>
        'This is a formal notice that the Girvi account listed below remains overdue after maturity. Please clear the outstanding dues and redeem the pledged article within the notice period.',
      GirviNoticeType.second =>
        'The account remains overdue after the first notice. This is the second formal warning to clear the dues immediately and avoid final recovery review.',
      GirviNoticeType.finalNotice =>
        'This is the final notice. If the account is not fully settled by the deadline, the pledged article may be treated as unredeemed and processed through lawful recovery in accordance with applicable law, agreed Girvi terms and business policy.',
    };
    final closing = switch (noticeType) {
      GirviNoticeType.first =>
        'Please visit the shop with this notice and complete the settlement before the deadline.',
      GirviNoticeType.second =>
        'Failure to settle after this warning may result in a final redemption and recovery notice.',
      GirviNoticeType.finalNotice =>
        'After the final deadline, recovery proceeds may be adjusted against principal, interest, penalty, custody charges and lawful recovery costs. Any remaining shortfall may continue to be payable by the customer, and any surplus may be handled as per applicable policy and law.',
    };

    return [
      'Subject: $subject',
      '',
      'Dear ${account.customerName},',
      '',
      opening,
      '',
      'Notice Date: $noticeDate',
      'Ticket Number: ${loan.ticketNo}',
      'Customer Mobile: ${account.customerMobile}',
      'Customer Address: $address',
      'Girvi Date: $startDate',
      'Maturity Date: $maturity',
      'Account Age: $loanAge',
      'Overdue Age: $overdueAge',
      'Notice Stage: $noticeProgress',
      '',
      'Pledged Item: $cleanItemSummary',
      'Pledged Valuation: ${_money(loan.totalValue)}',
      '',
      'Principal Outstanding: ${_money(account.principalDue)}',
      'Interest Outstanding: ${_money(account.netInterestDue)}',
      'Total Payable: ${_money(account.totalPayable)}',
      '',
      'Notice Period: ${item.noticePeriodDays} days',
      'Settlement Deadline: $deadline',
      '',
      closing,
      '',
      'This notice is issued without prejudice to all rights and remedies available to the shop under applicable law, agreed Girvi terms and business policy.',
      '',
      'Authorised Signatory',
    ].join('\n');
  }

  String _noticeItemSummary(String value, GirviNoticeLanguage language) {
    final serialLabel =
        language == GirviNoticeLanguage.hindi ? 'क्रमांक' : 'Serial Number';
    return value
        .replaceAllMapped(
          RegExp(r'#\s*(\d+)'),
          (match) => '$serialLabel ${match.group(1)}',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _noticePdfName(
    NoticeAuctionCase item,
    GirviNoticeType noticeType,
    GirviNoticeLanguage language,
  ) {
    final safeTicket =
        item.loan.ticketNo.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    return 'girvi_${safeTicket}_notice_${noticeType.stage}_${language.fileLabel}.pdf';
  }

  _SavedNoticeDraft _savedNoticeDraft(
    NoticeAuctionCase item,
    GirviNoticeAction action,
  ) {
    final noticeType = _noticeTypeFromAction(action);
    final storedText = action.noticeText?.trim() ?? '';
    final language = _noticeLanguageForText(storedText);
    final noticeText = storedText.isEmpty
        ? _buildNoticeText(item, noticeType, language)
        : storedText;
    return _SavedNoticeDraft(
      item: item,
      action: action,
      noticeType: noticeType,
      language: language,
      noticeText: noticeText,
      fileName: _noticePdfName(item, noticeType, language),
    );
  }

  GirviNoticeLanguage _noticeLanguageForText(String value) {
    if (RegExp(r'[\u0900-\u097F]').hasMatch(value)) {
      return GirviNoticeLanguage.hindi;
    }
    return GirviNoticeLanguage.english;
  }

  String _money(double value) =>
      'Rs ${NumberFormat('#,##,##0', 'en_IN').format(value)}';
}

class _SavedNoticeDraft {
  final NoticeAuctionCase item;
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

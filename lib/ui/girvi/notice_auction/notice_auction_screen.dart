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
          'यह अंतिम सूचना है। यदि अंतिम तारीख तक पूरा भुगतान नहीं होता है, तो गिरवी वस्तु को न छुड़ाया गया मानकर लागू कानून, सहमत Girvi terms और business policy के अनुसार वैध वसूली या disposal प्रक्रिया शुरू की जा सकती है।',
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
        'This is the final notice. If the account is not fully settled by the deadline, the pledged article may be treated as unredeemed and processed for lawful recovery or disposal in accordance with applicable law, agreed Girvi terms and business policy.',
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

class _NoticeAuctionOverview extends StatelessWidget {
  final NoticeAuctionState state;

  const _NoticeAuctionOverview({required this.state});

  @override
  Widget build(BuildContext context) {
    final stats = state.stats;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1200
              ? 4
              : constraints.maxWidth >= 780
                  ? 2
                  : 1;
          final spacing = columns == 1 ? 10.0 : 14.0;
          final width =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: 12,
            children: [
              SizedBox(
                width: width,
                child: _SummaryTile(
                  label: 'Notice Cases',
                  value: stats.totalCases.toString(),
                  footer: '${stats.noticeDueCount} active cases',
                  accent: GirviColors.warning,
                ),
              ),
              SizedBox(
                width: width,
                child: _SummaryTile(
                  label: 'Final Notice',
                  value: stats.finalNoticeCount.toString(),
                  footer: '${state.noticePeriodDays} day notice cycle',
                  accent: GirviColors.danger,
                ),
              ),
              SizedBox(
                width: width,
                child: _SummaryTile(
                  label: 'Total Exposure',
                  value: _money(stats.totalExposure),
                  footer: 'Principal ${_money(stats.principalExposure)}',
                  accent: GirviColors.brandGold,
                ),
              ),
              SizedBox(
                width: width,
                child: _SummaryTile(
                  label: 'Disposal Ready',
                  value: stats.disposalReadyCount.toString(),
                  footer: 'Updated at ${stats.lastUpdatedAt}',
                  accent: GirviColors.statusAuctioned,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _money(double value) =>
      'Rs ${NumberFormat('#,##,##0', 'en_IN').format(value)}';
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String footer;
  final Color accent;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.footer,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: const [
          BoxShadow(
            color: GirviColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GirviStyles.caption.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
              maxLines: 1,
            ),
          ),
          Text(
            footer,
            style: GirviStyles.caption.copyWith(fontSize: 12.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NoticeAuctionControls extends StatelessWidget {
  final NoticeAuctionState state;
  final TextEditingController searchController;
  final ValueChanged<NoticeAuctionFilter> onFilterChanged;

  const _NoticeAuctionControls({
    required this.state,
    required this.searchController,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            style: GirviStyles.caption,
            decoration: InputDecoration(
              hintText: 'Search customer, mobile, ticket, item or status',
              hintStyle:
                  GirviStyles.caption.copyWith(color: GirviColors.textHint),
              filled: true,
              fillColor: GirviColors.cardBg,
              prefixIcon: const Icon(GirviIcons.search, size: 19),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GirviColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GirviColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: GirviColors.brandGold, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: NoticeAuctionFilter.values
                  .map(
                    (filter) => _FilterChip(
                      label: _labelFor(filter),
                      count: state.countForFilter(filter),
                      active: state.filter == filter,
                      onTap: () => onFilterChanged(filter),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(NoticeAuctionFilter filter) {
    switch (filter) {
      case NoticeAuctionFilter.all:
        return 'Active Cases';
      case NoticeAuctionFilter.firstNotice:
        return 'First Notice';
      case NoticeAuctionFilter.secondNotice:
        return 'Second Notice';
      case NoticeAuctionFilter.finalNotice:
        return 'Final Notice';
      case NoticeAuctionFilter.disposalReady:
        return 'Disposal Ready';
      case NoticeAuctionFilter.settled:
        return 'Closed';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? GirviColors.shellBg : GirviColors.cardBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? GirviColors.shellBg : GirviColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GirviStyles.caption.copyWith(
                fontSize: 12.5,
                color: active ? Colors.white : GirviColors.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              constraints: const BoxConstraints(minWidth: 22),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withValues(alpha: 0.16)
                    : GirviColors.bodyBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active
                      ? Colors.white.withValues(alpha: 0.22)
                      : GirviColors.cardBorder,
                ),
              ),
              child: Text(
                count.toString(),
                style: GirviStyles.caption.copyWith(
                  fontSize: 12.5,
                  color: active ? Colors.white : GirviColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _InlineMessage({
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: GirviColors.infoBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: GirviColors.info.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            const Icon(GirviIcons.info, size: 18, color: GirviColors.info),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GirviStyles.caption.copyWith(fontSize: 12.5),
              ),
            ),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeAuctionBody extends StatelessWidget {
  final NoticeAuctionState state;
  final ValueChanged<NoticeAuctionCase> onOpenAccount;
  final ValueChanged<NoticeAuctionCase> onPrepareNotice;
  final void Function(NoticeAuctionCase item, GirviNoticeAction action)
      onViewNotice;
  final void Function(NoticeAuctionCase item, GirviNoticeAction action)
      onDownloadNotice;
  final void Function(NoticeAuctionCase item, GirviNoticeAction action)
      onPrintNotice;
  final ValueChanged<NoticeAuctionCase> onCloseDisposal;

  const _NoticeAuctionBody({
    required this.state,
    required this.onOpenAccount,
    required this.onPrepareNotice,
    required this.onViewNotice,
    required this.onDownloadNotice,
    required this.onPrintNotice,
    required this.onCloseDisposal,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: GirviColors.brandGold),
      );
    }
    if (state.errorMessage != null) {
      return _EmptyState(
        title: 'Unable to Load Notice Cases',
        subtitle: state.errorMessage!,
      );
    }
    if (state.visibleCases.isEmpty) {
      return const _EmptyState(
        title: 'No Notice Cases Found',
        subtitle:
            'There are no Girvi accounts requiring notice or auction review.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: state.visibleCases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = state.visibleCases[index];
        return _NoticeAuctionCard(
          item: item,
          onOpenAccount: () => onOpenAccount(item),
          onPrepareNotice:
              item.nextNoticeType == null ? null : () => onPrepareNotice(item),
          onViewNotice: (action) => onViewNotice(item, action),
          onDownloadNotice: (action) => onDownloadNotice(item, action),
          onPrintNotice: (action) => onPrintNotice(item, action),
          onCloseDisposal:
              item.canCloseDisposal ? () => onCloseDisposal(item) : null,
        );
      },
    );
  }
}

class _NoticeAuctionCard extends StatelessWidget {
  final NoticeAuctionCase item;
  final VoidCallback onOpenAccount;
  final VoidCallback? onPrepareNotice;
  final ValueChanged<GirviNoticeAction> onViewNotice;
  final ValueChanged<GirviNoticeAction> onDownloadNotice;
  final ValueChanged<GirviNoticeAction> onPrintNotice;
  final VoidCallback? onCloseDisposal;

  const _NoticeAuctionCard({
    required this.item,
    required this.onOpenAccount,
    required this.onPrepareNotice,
    required this.onViewNotice,
    required this.onDownloadNotice,
    required this.onPrintNotice,
    required this.onCloseDisposal,
  });

  @override
  Widget build(BuildContext context) {
    final loan = item.loan;
    final dateFmt = DateFormat('dd MMM yyyy');
    final maturity = loan.maturityDate == null
        ? 'Not set'
        : dateFmt.format(loan.maturityDate!);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.accentColor.withValues(alpha: 0.36)),
        boxShadow: const [
          BoxShadow(
            color: GirviColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          final identity = _CaseIdentity(item: item, maturityLabel: maturity);
          final amounts = _CaseAmounts(item: item);
          final notices = _NoticeDocumentStrip(
            item: item,
            onViewNotice: onViewNotice,
            onDownloadNotice: onDownloadNotice,
            onPrintNotice: onPrintNotice,
          );
          final actions = _CaseActions(
            item: item,
            onOpenAccount: onOpenAccount,
            onPrepareNotice: onPrepareNotice,
            onCloseDisposal: onCloseDisposal,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: 12),
                amounts,
                const SizedBox(height: 12),
                notices,
                const SizedBox(height: 12),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: identity),
              const SizedBox(width: 14),
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    amounts,
                    const SizedBox(height: 10),
                    notices,
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(width: 190, child: actions),
            ],
          );
        },
      ),
    );
  }
}

class _CaseIdentity extends StatelessWidget {
  final NoticeAuctionCase item;
  final String maturityLabel;

  const _CaseIdentity({
    required this.item,
    required this.maturityLabel,
  });

  @override
  Widget build(BuildContext context) {
    final account = item.account;
    final loan = item.loan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                account.customerName,
                style: GirviStyles.sectionTitle.copyWith(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _StageBadge(item: item),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _InfoPill(label: 'Ticket', value: loan.ticketNo),
            _InfoPill(label: 'Mobile', value: account.customerMobile),
            _InfoPill(label: 'Maturity', value: maturityLabel),
          ],
        ),
        const SizedBox(height: 10),
        _PledgedItemSummary(item: item),
        const SizedBox(height: 8),
        Text(
          account.customerAddress.isEmpty
              ? 'Address not available'
              : account.customerAddress,
          style: GirviStyles.caption.copyWith(fontSize: 12.5),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (item.latestAction != null) ...[
          const SizedBox(height: 8),
          _NoticeActivityLine(item: item),
        ],
      ],
    );
  }
}

class _NoticeActivityLine extends StatelessWidget {
  final NoticeAuctionCase item;

  const _NoticeActivityLine({required this.item});

  @override
  Widget build(BuildContext context) {
    final action = item.latestAction!;
    final timestamp = DateFormat('dd MMM yyyy, hh:mm a').format(
      action.actionAt,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: item.accentBg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: item.accentColor.withValues(alpha: 0.22)),
      ),
      child: Text(
        '${action.displayLabel} on $timestamp',
        style: GirviStyles.caption.copyWith(
          color: GirviColors.textDark,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _PledgedItemSummary extends StatelessWidget {
  final NoticeAuctionCase item;

  const _PledgedItemSummary({required this.item});

  @override
  Widget build(BuildContext context) {
    final loan = item.loan;
    final attributes = <_ItemAttribute>[
      _ItemAttribute('Metal Type', loan.metalTypeEnum.displayName),
      if (loan.metalPurity.trim().isNotEmpty)
        _ItemAttribute('Purity', loan.metalPurity.trim()),
      _ItemAttribute('Pieces', _pieces(loan.itemCount)),
      _ItemAttribute('Gross Weight', _weight(loan.grossWeight)),
      if (loan.stoneWeight > 0)
        _ItemAttribute('Less Weight', _weight(loan.stoneWeight)),
      _ItemAttribute('Net Weight', _weight(loan.netWeight)),
      _ItemAttribute('Valuation', _money(loan.totalValue)),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GirviColors.brandGold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: GirviColors.brandGold.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _itemTitle(),
            style: GirviStyles.caption.copyWith(
              color: GirviColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: attributes
                .map((attribute) => _ItemAttributeChip(attribute: attribute))
                .toList(),
          ),
        ],
      ),
    );
  }

  String _itemTitle() {
    final raw = item.loan.itemDescription.trim();
    if (raw.isEmpty) return _titleCase(item.loan.itemSummary);
    final firstPart = raw.split('|').first.trim();
    final serialMatch = RegExp(r'^#\s*(\d+)\s*(.*)$').firstMatch(firstPart);
    if (serialMatch != null) {
      final serial = serialMatch.group(1) ?? '';
      final name = _titleCase(serialMatch.group(2)?.trim() ?? '');
      if (name.isEmpty) return 'Serial Number $serial';
      return 'Serial Number $serial - $name';
    }
    return _titleCase(firstPart);
  }

  String _titleCase(String value) {
    final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return cleaned;
    return cleaned.split(' ').map((part) {
      if (part.isEmpty || RegExp(r'\d').hasMatch(part)) return part;
      if (part == part.toUpperCase()) return part;
      return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
    }).join(' ');
  }

  String _pieces(int count) => '$count piece${count == 1 ? '' : 's'}';

  String _weight(double value) => '${value.toStringAsFixed(3)} g';

  String _money(double value) =>
      'Rs ${NumberFormat('#,##,##0', 'en_IN').format(value)}';
}

class _ItemAttribute {
  final String label;
  final String value;

  const _ItemAttribute(this.label, this.value);
}

class _ItemAttributeChip extends StatelessWidget {
  final _ItemAttribute attribute;

  const _ItemAttributeChip({required this.attribute});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: '${attribute.label}: ',
              style: GirviStyles.caption.copyWith(
                color: GirviColors.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: attribute.value,
              style: GirviStyles.caption.copyWith(
                color: GirviColors.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseAmounts extends StatelessWidget {
  final NoticeAuctionCase item;

  const _CaseAmounts({required this.item});

  @override
  Widget build(BuildContext context) {
    final account = item.account;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _AmountTile(label: 'Principal', value: _money(account.principalDue)),
        _AmountTile(label: 'Interest', value: _money(account.netInterestDue)),
        _AmountTile(
          label: 'Total Payable',
          value: _money(account.totalPayable),
          accent: GirviColors.danger,
        ),
        _AmountTile(
          label: 'Overdue Age',
          value: item.overdueAgeMonthsDaysLabel,
          accent: item.accentColor,
        ),
      ],
    );
  }

  String _money(double value) =>
      'Rs ${NumberFormat('#,##,##0', 'en_IN').format(value)}';
}

class _NoticeDocumentStrip extends StatelessWidget {
  final NoticeAuctionCase item;
  final ValueChanged<GirviNoticeAction> onViewNotice;
  final ValueChanged<GirviNoticeAction> onDownloadNotice;
  final ValueChanged<GirviNoticeAction> onPrintNotice;

  const _NoticeDocumentStrip({
    required this.item,
    required this.onViewNotice,
    required this.onDownloadNotice,
    required this.onPrintNotice,
  });

  @override
  Widget build(BuildContext context) {
    final actions = item.preparedNoticeActions;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GirviColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Notice Documents',
                  style: GirviStyles.caption.copyWith(
                    color: GirviColors.textDark,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _NoticeCountBadge(label: item.noticesSentLabel),
            ],
          ),
          const SizedBox(height: 9),
          if (actions.isEmpty)
            const _NoNoticeDocuments()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions.map(
                (action) {
                  final stage = _noticeStageFromAction(action) ?? 1;
                  return _NoticeDocumentCard(
                    action: action,
                    latestProof: item.latestDeliveryProofForStage(stage),
                    onView: () => onViewNotice(action),
                    onDownload: () => onDownloadNotice(action),
                    onPrint: () => onPrintNotice(action),
                  );
                },
              ).toList(),
            ),
        ],
      ),
    );
  }
}

class _NoticeCountBadge extends StatelessWidget {
  final String label;

  const _NoticeCountBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: GirviColors.brandGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: GirviColors.brandGold.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: GirviStyles.caption.copyWith(
          color: GirviColors.brandGold,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NoNoticeDocuments extends StatelessWidget {
  const _NoNoticeDocuments();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Text(
        'No notice document has been prepared yet.',
        style: GirviStyles.caption.copyWith(
          color: GirviColors.textDark,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NoticeDocumentCard extends StatelessWidget {
  final GirviNoticeAction action;
  final GirviNoticeAction? latestProof;
  final VoidCallback onView;
  final VoidCallback onDownload;
  final VoidCallback onPrint;

  const _NoticeDocumentCard({
    required this.action,
    required this.latestProof,
    required this.onView,
    required this.onDownload,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final noticeType = _noticeTypeFromAction(action);
    final timestamp =
        DateFormat('dd MMM yyyy, hh:mm a').format(action.actionAt);
    final proof = latestProof;
    final proofTimestamp = proof == null
        ? null
        : DateFormat('dd MMM yyyy, hh:mm a')
            .format(proof.deliveredAt ?? proof.actionAt);
    final color = _noticeStageColor(noticeType);

    return InkWell(
      onTap: onView,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 196,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.28)),
          boxShadow: const [
            BoxShadow(
              color: GirviColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.24)),
                  ),
                  child: Text(
                    '0${noticeType.stage}',
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    noticeType.label,
                    style: GirviStyles.caption.copyWith(
                      color: GirviColors.textDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Prepared $timestamp',
              style: GirviStyles.caption.copyWith(
                color: GirviColors.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: proof == null
                    ? GirviColors.warningBg.withValues(alpha: 0.45)
                    : GirviColors.successBg.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: proof == null
                      ? GirviColors.warning.withValues(alpha: 0.24)
                      : GirviColors.success.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                proof == null
                    ? 'Proof pending'
                    : '${proof.deliveryProofLabel} - $proofTimestamp',
                style: GirviStyles.caption.copyWith(
                  color: GirviColors.textDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniNoticeAction(
                    label: 'View',
                    icon: Icons.visibility_outlined,
                    onTap: onView,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _MiniNoticeAction(
                    label: 'Save',
                    icon: Icons.download_rounded,
                    onTap: onDownload,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _MiniNoticeAction(
                    label: 'Print',
                    icon: Icons.print_rounded,
                    onTap: onPrint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _noticeStageColor(GirviNoticeType noticeType) {
    switch (noticeType) {
      case GirviNoticeType.first:
        return GirviColors.warning;
      case GirviNoticeType.second:
        return GirviColors.danger;
      case GirviNoticeType.finalNotice:
        return GirviColors.statusAuctioned;
    }
  }
}

class _MiniNoticeAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniNoticeAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label == 'Save' ? 'Download PDF' : '$label notice',
      waitDuration: const Duration(milliseconds: 450),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GirviColors.bodyBg,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: GirviColors.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: GirviColors.textDark),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  style: GirviStyles.caption.copyWith(
                    color: GirviColors.textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaseActions extends StatelessWidget {
  final NoticeAuctionCase item;
  final VoidCallback onOpenAccount;
  final VoidCallback? onPrepareNotice;
  final VoidCallback? onCloseDisposal;

  const _CaseActions({
    required this.item,
    required this.onOpenAccount,
    required this.onPrepareNotice,
    required this.onCloseDisposal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionButton(
          label: 'Open Account',
          color: GirviColors.shellBg,
          onTap: onOpenAccount,
        ),
        const SizedBox(height: 8),
        _ActionButton(
          label: item.stage == NoticeAuctionStage.settled
              ? 'Workflow Closed'
              : item.nextNoticeType?.label ?? '3 Notices Prepared',
          color: GirviColors.warning,
          onTap: onPrepareNotice,
        ),
        const SizedBox(height: 8),
        _ActionButton(
          label: item.stage == NoticeAuctionStage.settled
              ? 'Closed'
              : 'Close Disposal',
          color: item.stage == NoticeAuctionStage.settled
              ? GirviColors.success
              : GirviColors.danger,
          onTap: onCloseDisposal,
        ),
        const SizedBox(height: 8),
        Text(
          item.stageDescription,
          style: GirviStyles.caption.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StageBadge extends StatelessWidget {
  final NoticeAuctionCase item;

  const _StageBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: item.accentBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: item.accentColor.withValues(alpha: 0.38)),
      ),
      child: Text(
        item.stageLabel,
        style: GirviStyles.statusBadge.copyWith(color: item.accentColor),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: GirviColors.bodyBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: GirviStyles.caption.copyWith(
                fontSize: 12.5,
                color: GirviColors.textHint,
              ),
            ),
            TextSpan(
              text: value,
              style: GirviStyles.caption.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _AmountTile({
    required this.label,
    required this.value,
    this.accent = GirviColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      height: 74,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GirviColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GirviStyles.caption.copyWith(fontSize: 12.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? color : GirviColors.inputBgLocked,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? color : GirviColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: enabled ? Colors.white : GirviColors.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SavedNoticePreviewDialog extends StatefulWidget {
  final _SavedNoticeDraft draft;
  final Future<void> Function() onDownload;
  final Future<void> Function() onPrint;

  const _SavedNoticePreviewDialog({
    required this.draft,
    required this.onDownload,
    required this.onPrint,
  });

  @override
  State<_SavedNoticePreviewDialog> createState() =>
      _SavedNoticePreviewDialogState();
}

class _SavedNoticePreviewDialogState extends State<_SavedNoticePreviewDialog> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final actionDate = DateFormat('dd MMM yyyy, hh:mm a').format(
      draft.action.actionAt,
    );

    return AlertDialog(
      backgroundColor: GirviColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(24),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
      actionsPadding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GirviColors.brandGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: GirviColors.brandGold.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              '0${draft.noticeType.stage}',
              style: GoogleFonts.inter(
                color: GirviColors.brandGold,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.noticeType.label,
                  style: GirviStyles.sectionTitle.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 3),
                Text(
                  '${draft.item.loan.ticketNo} | ${draft.item.account.customerName} | ${draft.language.label} | $actionDate',
                  style: GirviStyles.caption.copyWith(
                    color: GirviColors.textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 780,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 560),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: GirviColors.bodyBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GirviColors.cardBorder),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              draft.noticeText,
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontSize: 13.6,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: GirviStyles.caption.copyWith(
              color: GirviColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _busy ? null : () => _run(widget.onDownload),
          icon: const Icon(Icons.download_rounded, size: 17),
          label: const Text('Save PDF'),
          style: TextButton.styleFrom(
            foregroundColor: GirviColors.textDark,
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w900),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _busy ? null : () => _run(widget.onPrint),
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.print_rounded, size: 17),
          label: Text(
            _busy ? 'Working' : 'Print PDF',
            style: GoogleFonts.inter(fontWeight: FontWeight.w900),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: GirviColors.shellBg,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoticeEditorDialog extends StatefulWidget {
  final NoticeAuctionCase item;
  final GirviNoticeType noticeType;
  final Map<GirviNoticeLanguage, String> initialTexts;
  final GirviNoticeLanguage initialLanguage;
  final Future<void> Function(GirviNoticeLanguage language, String text) onCopy;
  final Future<void> Function(GirviNoticeLanguage language, String text)
      onPrint;
  final Future<void> Function(GirviNoticeLanguage language, String text)
      onShare;
  final Future<bool> Function(GirviNoticeLanguage language, String text) onSave;

  const _NoticeEditorDialog({
    required this.item,
    required this.noticeType,
    required this.initialTexts,
    required this.initialLanguage,
    required this.onCopy,
    required this.onPrint,
    required this.onShare,
    required this.onSave,
  });

  @override
  State<_NoticeEditorDialog> createState() => _NoticeEditorDialogState();
}

class _NoticeEditorDialogState extends State<_NoticeEditorDialog> {
  late final TextEditingController _textController;
  late GirviNoticeLanguage _language;
  late final Map<GirviNoticeLanguage, String> _texts;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
    _texts = Map<GirviNoticeLanguage, String>.from(widget.initialTexts);
    _textController = TextEditingController(text: _texts[_language] ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<void> Function(GirviNoticeLanguage language, String text) action,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _syncCurrentLanguageText();
      await action(_language, _textController.text.trim());
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _syncCurrentLanguageText();
      final saved = await widget.onSave(_language, _textController.text.trim());
      if (saved && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setLanguage(GirviNoticeLanguage value) {
    if (_busy || value == _language) return;
    _syncCurrentLanguageText();
    setState(() {
      _language = value;
      _textController.text = _texts[value] ?? '';
    });
  }

  void _syncCurrentLanguageText() {
    _texts[_language] = _textController.text;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: GirviColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(24),
      title: Text(
        widget.noticeType.label,
        style: GirviStyles.sectionTitle.copyWith(fontSize: 17),
      ),
      content: SizedBox(
        width: 760,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.item.loan.ticketNo} | ${widget.item.account.customerName} | ${widget.noticeType.subtitle}',
              style: GirviStyles.caption.copyWith(
                fontSize: 12.8,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NoticeLanguageButton(
                    label: 'Hindi',
                    selected: _language == GirviNoticeLanguage.hindi,
                    onTap: () => _setLanguage(GirviNoticeLanguage.hindi),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NoticeLanguageButton(
                    label: 'English',
                    selected: _language == GirviNoticeLanguage.english,
                    onTap: () => _setLanguage(GirviNoticeLanguage.english),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              minLines: 16,
              maxLines: 22,
              style: GoogleFonts.inter(
                fontSize: 13.2,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: GirviColors.textDark,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: GirviColors.bodyBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: GirviColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: GirviColors.brandGold,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: GirviStyles.caption.copyWith(color: GirviColors.textMuted),
          ),
        ),
        TextButton(
          onPressed: _busy ? null : () => _run(widget.onCopy),
          child: Text('Copy Text', style: _actionTextStyle()),
        ),
        TextButton(
          onPressed: _busy ? null : () => _run(widget.onShare),
          child: Text('Share PDF', style: _actionTextStyle()),
        ),
        TextButton(
          onPressed: _busy ? null : () => _run(widget.onPrint),
          child: Text('Print PDF', style: _actionTextStyle()),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: GirviColors.shellBg,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Save Notice',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                ),
        ),
      ],
    );
  }

  TextStyle _actionTextStyle() {
    return GoogleFonts.inter(
      color: GirviColors.shellBg,
      fontWeight: FontWeight.w800,
    );
  }
}

class _NoticeLanguageButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NoticeLanguageButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? GirviColors.shellBg : GirviColors.bodyBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? GirviColors.shellBg : GirviColors.cardBorder,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: selected ? Colors.white : GirviColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _DisposalSettlementResult {
  final double pledgedValuation;
  final double recoveredAmount;
  final double penaltyAmount;
  final String note;

  const _DisposalSettlementResult({
    required this.pledgedValuation,
    required this.recoveredAmount,
    required this.penaltyAmount,
    required this.note,
  });
}

class _DisposalSettlementDialog extends StatefulWidget {
  final NoticeAuctionCase item;

  const _DisposalSettlementDialog({required this.item});

  @override
  State<_DisposalSettlementDialog> createState() =>
      _DisposalSettlementDialogState();
}

class _DisposalSettlementDialogState extends State<_DisposalSettlementDialog> {
  late final TextEditingController _valuationController;
  late final TextEditingController _recoveredController;
  late final TextEditingController _penaltyController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _valuationController = TextEditingController(
      text: widget.item.loan.totalValue.toStringAsFixed(0),
    );
    _recoveredController = TextEditingController(text: '0');
    _penaltyController = TextEditingController(text: '0');
    _noteController = TextEditingController(
      text:
          'Final disposal settlement after three notices. Recovery proceeds adjusted against outstanding dues subject to applicable law and business policy.',
    );
  }

  @override
  void dispose() {
    _valuationController.dispose();
    _recoveredController.dispose();
    _penaltyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payable = widget.item.account.totalPayable;
    final penalty = _number(_penaltyController.text);
    final recovered = _number(_recoveredController.text);
    final settlementTotal = payable + penalty;
    final balanceDue =
        recovered >= settlementTotal ? 0.0 : settlementTotal - recovered;
    final surplus =
        recovered > settlementTotal ? recovered - settlementTotal : 0.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: GirviColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GirviColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: GirviColors.shadowMedium,
                blurRadius: 26,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _dialogHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 720;
                        final casePanel = _caseSnapshot(payable);
                        final recoveryPanel = _recoveryPanel(
                          payable: payable,
                          penalty: penalty,
                          recovered: recovered,
                          settlementTotal: settlementTotal,
                          balanceDue: balanceDue,
                          surplus: surplus,
                        );

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              casePanel,
                              const SizedBox(height: 14),
                              recoveryPanel,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 284, child: casePanel),
                            const SizedBox(width: 16),
                            Expanded(child: recoveryPanel),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                _actionBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: const BoxDecoration(
        color: GirviColors.shellBg,
        border: Border(
          bottom: BorderSide(color: GirviColors.shellBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GirviColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: GirviColors.danger.withValues(alpha: 0.34),
              ),
            ),
            child: const Icon(
              GirviIcons.auctioned,
              color: GirviColors.danger,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Close Disposal Settlement',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Final recovery closure after all three notices are prepared.',
                  style: GirviStyles.caption.copyWith(
                    color: GirviColors.shellTextMuted,
                    fontSize: 12.8,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Text(
              widget.item.loan.ticketNo,
              style: GirviStyles.ticketNumber.copyWith(fontSize: 12.8),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _caseSnapshot(double payable) {
    final account = widget.item.account;
    final loan = widget.item.loan;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.bodyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Case Snapshot', GirviIcons.ticket),
          const SizedBox(height: 12),
          Text(
            account.customerName,
            style: GoogleFonts.manrope(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: GirviColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _snapshotChip('Notices ${widget.item.noticesSentLabel}'),
              _snapshotChip(widget.item.stageLabel),
            ],
          ),
          const SizedBox(height: 12),
          _snapshotLine('Mobile', account.customerMobile),
          _snapshotLine('Maturity', _date(loan.maturityDate)),
          _snapshotLine('Overdue Age', widget.item.overdueAgeMonthsDaysLabel),
          _snapshotLine('Pledged Value', _money(loan.totalValue)),
          _snapshotLine(
            'Total Payable',
            _money(payable),
            valueColor: GirviColors.danger,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GirviColors.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GirviColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pledged Item',
                  style: GirviStyles.caption.copyWith(
                    fontSize: 12.5,
                    color: GirviColors.textHint,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _itemSummary(),
                  style: GirviStyles.caption.copyWith(
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recoveryPanel({
    required double payable,
    required double penalty,
    required double recovered,
    required double settlementTotal,
    required double balanceDue,
    required double surplus,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Recovery Details', GirviIcons.calculator),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              _settlementField(
                controller: _valuationController,
                label: 'Pledged Valuation',
                helper: 'Current article value',
              ),
              _settlementField(
                controller: _recoveredController,
                label: 'Recovered Amount',
                helper: 'Cash or sale proceeds',
              ),
              _settlementField(
                controller: _penaltyController,
                label: 'Penalty / Handling',
                helper: 'Lawful extra charges',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _settlementOutcome(
            payable: payable,
            penalty: penalty,
            recovered: recovered,
            settlementTotal: settlementTotal,
            balanceDue: balanceDue,
            surplus: surplus,
          ),
          const SizedBox(height: 14),
          _legalNotice(),
          const SizedBox(height: 14),
          Text(
            'Settlement Note',
            style: GirviStyles.caption.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _noteController,
            minLines: 3,
            maxLines: 5,
            style: GirviStyles.caption.copyWith(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: 'Write the disposal recovery note for audit.',
              hintStyle: GirviStyles.caption.copyWith(
                color: GirviColors.textHint,
                fontSize: 12.5,
              ),
              filled: true,
              fillColor: GirviColors.bodyBg,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GirviColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GirviColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: GirviColors.brandGold,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settlementOutcome({
    required double payable,
    required double penalty,
    required double recovered,
    required double settlementTotal,
    required double balanceDue,
    required double surplus,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GirviColors.bodyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Settlement Outcome', GirviIcons.valuation),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _settlementMetric('Total Payable', _money(payable)),
              _settlementMetric('Penalty', _money(penalty)),
              _settlementMetric(
                'Settlement Total',
                _money(settlementTotal),
                accent: GirviColors.brandGold,
              ),
              _settlementMetric('Recovered', _money(recovered)),
              _settlementMetric(
                'Balance Due',
                _money(balanceDue),
                accent:
                    balanceDue > 0 ? GirviColors.danger : GirviColors.success,
              ),
              _settlementMetric(
                'Surplus',
                _money(surplus),
                accent:
                    surplus > 0 ? GirviColors.success : GirviColors.textDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legalNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GirviColors.dangerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GirviColors.dangerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            GirviIcons.warning,
            color: GirviColors.danger,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Close only after three notices are complete, supporting records are verified, and lawful disposal approval is available.',
              style: GirviStyles.caption.copyWith(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        color: GirviColors.cardBg,
        border: Border(top: BorderSide(color: GirviColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'This action closes the notice and disposal workflow for this ticket.',
              style: GirviStyles.caption.copyWith(
                color: GirviColors.textHint,
                fontSize: 12.5,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 14),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: GirviColors.textDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _closeSettlement,
            icon: const Icon(Icons.lock_rounded, size: 18),
            label: Text(
              'Close Settlement',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: GirviColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GirviColors.brandGoldLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GirviColors.warningBorder),
          ),
          child: Icon(icon, size: 17, color: GirviColors.brandDeep),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: GirviStyles.sectionTitle.copyWith(fontSize: 15.5),
          ),
        ),
      ],
    );
  }

  Widget _snapshotChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Text(
        label,
        style: GirviStyles.statusBadge.copyWith(
          color: GirviColors.textDark,
          fontSize: 12.5,
        ),
      ),
    );
  }

  Widget _snapshotLine(
    String label,
    String value, {
    Color valueColor = GirviColors.textDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GirviStyles.caption.copyWith(
                fontSize: 12.5,
                color: GirviColors.textHint,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GirviStyles.caption.copyWith(
                fontSize: 12.5,
                color: valueColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _closeSettlement() {
    Navigator.of(context).pop(
      _DisposalSettlementResult(
        pledgedValuation: _number(_valuationController.text),
        recoveredAmount: _number(_recoveredController.text),
        penaltyAmount: _number(_penaltyController.text),
        note: _noteController.text.trim(),
      ),
    );
  }

  Widget _settlementField({
    required TextEditingController controller,
    required String label,
    required String helper,
  }) {
    return SizedBox(
      width: 142,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GirviStyles.caption.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: GirviColors.textDark,
            ),
            decoration: InputDecoration(
              prefixText: 'Rs ',
              prefixStyle: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: GirviColors.textHint,
              ),
              filled: true,
              fillColor: GirviColors.bodyBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GirviColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GirviColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: GirviColors.brandGold,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            style: GirviStyles.caption.copyWith(
              fontSize: 12.5,
              color: GirviColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settlementMetric(
    String label,
    String value, {
    Color accent = GirviColors.textDark,
  }) {
    return Container(
      width: 142,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GirviStyles.caption.copyWith(fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  double _number(String value) {
    return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
  }

  String _date(DateTime? value) =>
      value == null ? 'Not set' : DateFormat('dd MMM yyyy').format(value);

  String _itemSummary() {
    final loan = widget.item.loan;
    final value = loan.itemDescription.trim().isEmpty
        ? loan.itemSummary
        : loan.itemDescription;
    return value
        .replaceAllMapped(
          RegExp(r'#\s*(\d+)'),
          (match) => 'Serial Number ${match.group(1)}',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _money(double value) =>
      'Rs ${NumberFormat('#,##,##0', 'en_IN').format(value)}';
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: GirviColors.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                GirviIcons.released,
                color: GirviColors.success,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GirviStyles.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GirviStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

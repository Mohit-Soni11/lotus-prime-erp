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

    final initialText = _buildNoticeText(item, noticeType);
    await showDialog<void>(
      context: context,
      builder: (context) => _NoticeEditorDialog(
        item: item,
        noticeType: noticeType,
        initialText: initialText,
        onCopy: (text) => _copyNoticeText(item, noticeType, text),
        onPrint: (text) => _printNotice(item, noticeType, text),
        onShare: (text) => _shareNotice(item, noticeType, text),
        onSave: (text) => _controller.recordNoticePrepared(
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
    String noticeText,
  ) async {
    await Clipboard.setData(ClipboardData(text: noticeText));
    await _controller.recordNoticePrepared(item, noticeType, noticeText);
  }

  Future<void> _printNotice(
    NoticeAuctionCase item,
    GirviNoticeType noticeType,
    String noticeText,
  ) async {
    final bytes = await _noticePdfService.build(
      item: item,
      noticeType: noticeType,
      noticeText: noticeText,
    );
    final printed = await Printing.layoutPdf(
      name: _noticePdfName(item, noticeType),
      onLayout: (_) async => bytes,
    );
    if (printed) {
      await _controller.recordNoticePrepared(item, noticeType, noticeText);
    }
  }

  Future<void> _shareNotice(
    NoticeAuctionCase item,
    GirviNoticeType noticeType,
    String noticeText,
  ) async {
    final bytes = await _noticePdfService.build(
      item: item,
      noticeType: noticeType,
      noticeText: noticeText,
    );
    final shared = await Printing.sharePdf(
      bytes: bytes,
      filename: _noticePdfName(item, noticeType),
    );
    if (shared) {
      await _controller.recordNoticePrepared(item, noticeType, noticeText);
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
  ) {
    final account = item.account;
    final loan = item.loan;
    final dateFmt = DateFormat('dd MMMM yyyy');
    final maturity = loan.maturityDate == null
        ? 'Not set'
        : dateFmt.format(loan.maturityDate!);
    final settlementDeadline = DateTime.now().add(
      Duration(days: item.noticePeriodDays),
    );
    final itemSummary = loan.itemDescription.trim().isEmpty
        ? loan.itemSummary
        : loan.itemDescription.trim();
    final subject = switch (noticeType) {
      GirviNoticeType.first => 'First Girvi Settlement Notice',
      GirviNoticeType.second => 'Second Girvi Settlement Warning',
      GirviNoticeType.finalNotice => 'Final Redemption and Disposal Notice',
    };
    final body = switch (noticeType) {
      GirviNoticeType.first =>
        'This is the first formal reminder to clear the overdue Girvi account and redeem the pledged article within the notice period.',
      GirviNoticeType.second =>
        'This is the second formal warning. Please clear the overdue amount immediately to avoid final forfeiture and disposal review.',
      GirviNoticeType.finalNotice =>
        'This is the final notice. If the account is not settled within the stated period, the pledged article may be treated as unredeemed and processed for lawful disposal to recover outstanding dues, subject to applicable law and business policy.',
    };
    final closing = switch (noticeType) {
      GirviNoticeType.first =>
        'Please visit the shop with this notice and complete the settlement before the deadline.',
      GirviNoticeType.second =>
        'Failure to settle after this warning may lead to a final disposal notice.',
      GirviNoticeType.finalNotice =>
        'After the final deadline, any recovery proceeds may be adjusted against principal, interest, penalty, handling and lawful recovery costs. Any balance due may remain payable by the customer, and any surplus may be handled as per applicable policy and law.',
    };

    return [
      'Subject: $subject',
      '',
      'Dear ${account.customerName},',
      '',
      body,
      '',
      'Ticket Number: ${loan.ticketNo}',
      'Customer Mobile: ${account.customerMobile}',
      'Customer Address: ${account.customerAddress.isEmpty ? 'Not available' : account.customerAddress}',
      'Pledged Item: $itemSummary',
      'Pledged Valuation: ${_money(loan.totalValue)}',
      'Maturity Date: $maturity',
      'Overdue Period: ${item.overdueDays} days',
      'Notice Stage: ${noticeType.stage} of 3',
      '',
      'Principal Outstanding: ${_money(account.principalDue)}',
      'Interest Outstanding: ${_money(account.netInterestDue)}',
      'Total Payable: ${_money(account.totalPayable)}',
      '',
      'Notice Period: ${item.noticePeriodDays} days',
      'Settlement Deadline: ${dateFmt.format(settlementDeadline)}',
      '',
      closing,
      '',
      'This notice is issued without prejudice to the rights and remedies available to the shop under applicable law, contract terms and business policy.',
      '',
      'Authorised Signatory',
    ].join('\n');
  }

  String _noticePdfName(NoticeAuctionCase item, GirviNoticeType noticeType) {
    final safeTicket =
        item.loan.ticketNo.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    return 'girvi_${safeTicket}_notice_${noticeType.stage}.pdf';
  }

  String _money(double value) =>
      'Rs ${NumberFormat('#,##,##0', 'en_IN').format(value)}';
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
            style: GirviStyles.caption.copyWith(fontSize: 12),
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
        return 'All Cases';
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
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
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
        child: Text(
          label,
          style: GirviStyles.caption.copyWith(
            fontSize: 12.5,
            color: active ? Colors.white : GirviColors.textDark,
            fontWeight: FontWeight.w800,
          ),
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
  final ValueChanged<NoticeAuctionCase> onCloseDisposal;

  const _NoticeAuctionBody({
    required this.state,
    required this.onOpenAccount,
    required this.onPrepareNotice,
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
  final VoidCallback? onCloseDisposal;

  const _NoticeAuctionCard({
    required this.item,
    required this.onOpenAccount,
    required this.onPrepareNotice,
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
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: identity),
              const SizedBox(width: 14),
              Expanded(flex: 5, child: amounts),
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
        Text(
          loan.itemDescription.trim().isEmpty
              ? loan.itemSummary
              : loan.itemDescription.trim(),
          style: GirviStyles.caption.copyWith(fontWeight: FontWeight.w800),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
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
          fontSize: 12.2,
          fontWeight: FontWeight.w800,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
          value: '${item.overdueDays} days',
          accent: item.accentColor,
        ),
        _AmountTile(
          label: 'Notice Stage',
          value: item.stage == NoticeAuctionStage.settled
              ? 'Closed'
              : '${item.preparedNoticeCount}/3',
          accent: GirviColors.brandGold,
        ),
      ],
    );
  }

  String _money(double value) =>
      'Rs ${NumberFormat('#,##,##0', 'en_IN').format(value)}';
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
            fontSize: 12.2,
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
                fontSize: 11.5,
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
            style: GirviStyles.caption.copyWith(fontSize: 11.8),
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

class _NoticeEditorDialog extends StatefulWidget {
  final NoticeAuctionCase item;
  final GirviNoticeType noticeType;
  final String initialText;
  final Future<void> Function(String text) onCopy;
  final Future<void> Function(String text) onPrint;
  final Future<void> Function(String text) onShare;
  final Future<bool> Function(String text) onSave;

  const _NoticeEditorDialog({
    required this.item,
    required this.noticeType,
    required this.initialText,
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
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(String text) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action(_textController.text.trim());
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final saved = await widget.onSave(_textController.text.trim());
      if (saved && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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

    return AlertDialog(
      backgroundColor: GirviColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Close Disposal Settlement',
        style: GirviStyles.sectionTitle.copyWith(fontSize: 17),
      ),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Close only after all three notices are prepared and the account is approved for lawful recovery/disposal.',
              style: GirviStyles.caption.copyWith(
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _settlementField(
                    controller: _valuationController,
                    label: 'Pledged Valuation',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _settlementField(
                    controller: _recoveredController,
                    label: 'Recovered Amount',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _settlementField(
                    controller: _penaltyController,
                    label: 'Penalty / Handling',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _settlementMetric('Total Payable', _money(payable)),
                _settlementMetric('Settlement Total', _money(settlementTotal)),
                _settlementMetric('Customer Balance Due', _money(balanceDue)),
                _settlementMetric('Customer Surplus', _money(surplus)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              minLines: 3,
              maxLines: 5,
              style: GirviStyles.caption.copyWith(fontSize: 12.8),
              decoration: InputDecoration(
                labelText: 'Settlement Note',
                filled: true,
                fillColor: GirviColors.bodyBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: GirviColors.cardBorder),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GirviStyles.caption.copyWith(color: GirviColors.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(
              _DisposalSettlementResult(
                pledgedValuation: _number(_valuationController.text),
                recoveredAmount: _number(_recoveredController.text),
                penaltyAmount: _number(_penaltyController.text),
                note: _noteController.text.trim(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: GirviColors.danger,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Close Settlement',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _settlementField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      style: GirviStyles.caption.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: GirviColors.bodyBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: GirviColors.cardBorder),
        ),
      ),
    );
  }

  Widget _settlementMetric(String label, String value) {
    return Container(
      width: 142,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GirviColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GirviStyles.caption.copyWith(fontSize: 11.5)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: GirviColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  double _number(String value) {
    return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
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

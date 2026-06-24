import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_routes.dart';
import '../../../logic/girvi/notice_auction_controller.dart';
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
              onCopyNotice: _copyNotice,
              onMarkAuctioned: _confirmAuction,
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

  Future<void> _copyNotice(NoticeAuctionCase item) async {
    final noticeText = _buildNoticeText(item);
    await Clipboard.setData(ClipboardData(text: noticeText));
    await _controller.recordNoticeDraft(item, noticeText);
  }

  Future<void> _confirmAuction(NoticeAuctionCase item) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => _AuctionConfirmationDialog(item: item),
        ) ??
        false;

    if (!confirmed) return;
    await _controller.markAuctioned(item);
  }

  String _buildNoticeText(NoticeAuctionCase item) {
    final account = item.account;
    final loan = item.loan;
    final dateFmt = DateFormat('dd MMMM yyyy');
    final maturity = loan.maturityDate == null
        ? 'Not set'
        : dateFmt.format(loan.maturityDate!);
    final settlementDeadline = DateTime.now().add(
      Duration(days: item.noticePeriodDays),
    );

    return [
      'Subject: Final Girvi Settlement Notice',
      '',
      'Dear ${account.customerName},',
      '',
      'This is a formal notice regarding your Girvi account. Please review the account details and settle the outstanding amount before the stated deadline.',
      '',
      'Ticket Number: ${loan.ticketNo}',
      'Customer Mobile: ${account.customerMobile}',
      'Customer Address: ${account.customerAddress.isEmpty ? 'Not available' : account.customerAddress}',
      'Pledged Item: ${loan.itemDescription.trim().isEmpty ? loan.itemSummary : loan.itemDescription.trim()}',
      'Maturity Date: $maturity',
      'Overdue Period: ${item.overdueDays} days',
      '',
      'Principal Outstanding: ${_money(account.principalDue)}',
      'Interest Outstanding: ${_money(account.netInterestDue)}',
      'Total Payable: ${_money(account.totalPayable)}',
      '',
      'Notice Period: ${item.noticePeriodDays} days',
      'Settlement Deadline: ${dateFmt.format(settlementDeadline)}',
      '',
      'If the outstanding amount is not settled within the notice period, the pledged article may be moved for auction review as per applicable business policy and legal requirements.',
      '',
      'Thank you.',
    ].join('\n');
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
                  footer: '${stats.noticeDueCount} notice due',
                  accent: GirviColors.warning,
                ),
              ),
              SizedBox(
                width: width,
                child: _SummaryTile(
                  label: 'Auction Review',
                  value: stats.auctionReviewCount.toString(),
                  footer: '${state.noticePeriodDays} day notice period',
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
                  label: 'Auctioned',
                  value: stats.auctionedCount.toString(),
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
      case NoticeAuctionFilter.noticeDue:
        return 'Notice Due';
      case NoticeAuctionFilter.auctionReview:
        return 'Auction Review';
      case NoticeAuctionFilter.auctioned:
        return 'Auctioned';
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
  final ValueChanged<NoticeAuctionCase> onCopyNotice;
  final ValueChanged<NoticeAuctionCase> onMarkAuctioned;

  const _NoticeAuctionBody({
    required this.state,
    required this.onOpenAccount,
    required this.onCopyNotice,
    required this.onMarkAuctioned,
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
          onCopyNotice: () => onCopyNotice(item),
          onMarkAuctioned: item.stage == NoticeAuctionStage.auctioned
              ? null
              : () => onMarkAuctioned(item),
        );
      },
    );
  }
}

class _NoticeAuctionCard extends StatelessWidget {
  final NoticeAuctionCase item;
  final VoidCallback onOpenAccount;
  final VoidCallback onCopyNotice;
  final VoidCallback? onMarkAuctioned;

  const _NoticeAuctionCard({
    required this.item,
    required this.onOpenAccount,
    required this.onCopyNotice,
    required this.onMarkAuctioned,
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
            onCopyNotice: onCopyNotice,
            onMarkAuctioned: onMarkAuctioned,
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
      ],
    );
  }

  String _money(double value) =>
      'Rs ${NumberFormat('#,##,##0', 'en_IN').format(value)}';
}

class _CaseActions extends StatelessWidget {
  final NoticeAuctionCase item;
  final VoidCallback onOpenAccount;
  final VoidCallback onCopyNotice;
  final VoidCallback? onMarkAuctioned;

  const _CaseActions({
    required this.item,
    required this.onOpenAccount,
    required this.onCopyNotice,
    required this.onMarkAuctioned,
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
          label: 'Copy Legal Notice',
          color: GirviColors.warning,
          onTap: onCopyNotice,
        ),
        const SizedBox(height: 8),
        _ActionButton(
          label: item.stage == NoticeAuctionStage.auctioned
              ? 'Auctioned'
              : 'Mark Auctioned',
          color: item.stage == NoticeAuctionStage.auctioned
              ? GirviColors.statusAuctioned
              : GirviColors.danger,
          onTap: onMarkAuctioned,
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

class _AuctionConfirmationDialog extends StatelessWidget {
  final NoticeAuctionCase item;

  const _AuctionConfirmationDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: GirviColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Confirm Auction Status',
        style: GirviStyles.sectionTitle.copyWith(fontSize: 17),
      ),
      content: Text(
        'Ticket ${item.loan.ticketNo} will be marked as auctioned. This account will move out of the active notice queue.',
        style: GirviStyles.caption.copyWith(height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: GirviStyles.caption.copyWith(color: GirviColors.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: GirviColors.danger,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Mark Auctioned',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
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

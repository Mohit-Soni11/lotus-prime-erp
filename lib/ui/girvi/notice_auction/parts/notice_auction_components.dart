part of '../notice_auction_screen.dart';

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
                  label: 'Recovery Review',
                  value: stats.disposalReadyCount.toString(),
                  footer: 'Updated at ${stats.lastUpdatedAt}',
                  accent: GirviColors.info,
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
        return 'Recovery Review';
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
            'There are no Girvi accounts requiring overdue notice review.',
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

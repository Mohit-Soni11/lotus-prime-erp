part of '../contact_recovery_screen.dart';

class _ContactRecoveryCard extends StatelessWidget {
  final ContactRecoveryCase item;
  final VoidCallback onOpenAccount;
  final VoidCallback? onPrepareNotice;
  final ValueChanged<GirviNoticeAction> onViewNotice;
  final ValueChanged<GirviNoticeAction> onDownloadNotice;
  final ValueChanged<GirviNoticeAction> onPrintNotice;
  final VoidCallback? onInitiateRecovery;
  final VoidCallback? onCloseDisposal;

  const _ContactRecoveryCard({
    required this.item,
    required this.onOpenAccount,
    required this.onPrepareNotice,
    required this.onViewNotice,
    required this.onDownloadNotice,
    required this.onPrintNotice,
    required this.onInitiateRecovery,
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
            onInitiateRecovery: onInitiateRecovery,
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
  final ContactRecoveryCase item;
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
            _InfoPill(label: 'Invoice', value: loan.ticketNo),
            _InfoPill(label: 'Mobile', value: account.customerMobile),
            _InfoPill(label: 'Maturity Date', value: maturityLabel),
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
  final ContactRecoveryCase item;

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
  final ContactRecoveryCase item;

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
  final ContactRecoveryCase item;

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

part of 'due_collection_entry_screen.dart';

class _BillSummaryBox extends StatelessWidget {
  final DueCollectionBillModel bill;

  const _BillSummaryBox({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DueCollectionEntryStyles.flatPanel(
          color: DueCollectionEntryColors.panelSoft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DueCollectionEntryColors.brandGoldLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: DueCollectionEntryColors.brandGold
                      .withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: DueCollectionEntryColors.bodyPanel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: DueCollectionEntryColors.brandGold
                            .withValues(alpha: 0.24)),
                  ),
                  child: const Icon(DueCollectionEntryIcons.bill,
                      color: DueCollectionEntryColors.brandGold, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(DueCollectionEntryStrings.selectedBill,
                          style: DueCollectionEntryStyles.label),
                      const SizedBox(height: 3),
                      Text(bill.billNo,
                          style: DueCollectionEntryStyles.sectionTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                _StatusBadge(bill: bill),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: DueCollectionEntryStyles.flatPanel(),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: DueCollectionEntryColors.infoBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: DueCollectionEntryColors.info
                            .withValues(alpha: 0.18)),
                  ),
                  child: const Icon(DueCollectionEntryIcons.customer,
                      color: DueCollectionEntryColors.info, size: 21),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill.customerName,
                          style: DueCollectionEntryStyles.rowTitle
                              .copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 5),
                      _TinyLine(
                          icon: DueCollectionEntryIcons.phone,
                          text:
                              '${bill.mobile}  |  ${DueCollectionEntryController.formatDate(bill.billDate)}'),
                      if (bill.address.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        _TinyLine(
                            icon: DueCollectionEntryIcons.location,
                            text: bill.address),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AmountChip(
                  label: 'Bill',
                  value: bill.finalAmount,
                  color: DueCollectionEntryColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AmountChip(
                  label: 'Paid',
                  value: bill.paidAmount,
                  color: DueCollectionEntryColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AmountChip(
                  label: 'Due',
                  value: bill.dueAmount,
                  color: DueCollectionEntryColors.warning,
                  emphasis: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool emphasis;

  const _AmountChip({
    required this.label,
    required this.value,
    required this.color,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: emphasis
            ? DueCollectionEntryColors.warningBg
            : DueCollectionEntryColors.bodyPanel,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: color.withValues(alpha: emphasis ? 0.24 : 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: DueCollectionEntryStyles.rowSub.copyWith(color: color)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              DueCollectionEntryController.formatAmount(value),
              style: DueCollectionEntryStyles.rowTitle
                  .copyWith(color: color, fontSize: emphasis ? 14 : 13),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptReadyBox extends StatelessWidget {
  final String receiptNo;
  final String billNo;
  final double amount;
  final double discount;
  final double balance;
  final String mode;

  const _ReceiptReadyBox({
    required this.receiptNo,
    required this.billNo,
    required this.amount,
    required this.discount,
    required this.balance,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DueCollectionEntryColors.successBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: DueCollectionEntryColors.success.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DueCollectionEntryColors.bodyPanel,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                      color: DueCollectionEntryColors.success
                          .withValues(alpha: 0.2)),
                ),
                child: const Icon(DueCollectionEntryIcons.verified,
                    color: DueCollectionEntryColors.success, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(DueCollectionEntryStrings.receiptReady,
                        style: DueCollectionEntryStyles.label),
                    const SizedBox(height: 3),
                    Text(receiptNo,
                        style: DueCollectionEntryStyles.rowTitle
                            .copyWith(color: DueCollectionEntryColors.success),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              _ReceiptHistoryButton(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DueReceiptHistoryScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ReceiptMetaLine(
                  label: 'Collected',
                  value: DueCollectionEntryController.formatAmount(amount),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReceiptMetaLine(
                  label: 'Balance',
                  value: DueCollectionEntryController.formatAmount(balance),
                ),
              ),
            ],
          ),
          if (discount > 0.5) ...[
            const SizedBox(height: 8),
            _ReceiptMetaLine(
              label: 'Discount Applied',
              value: DueCollectionEntryController.formatAmount(discount),
              compact: false,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ReceiptMetaLine(
                  label: 'Mode',
                  value: mode.toUpperCase(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReceiptMetaLine(
                  label: DueCollectionEntryStrings.savedInHistory,
                  value: billNo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptHistoryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ReceiptHistoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: DueCollectionEntryColors.bodyPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: DueCollectionEntryColors.success.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(DueCollectionEntryIcons.history,
                size: 15, color: DueCollectionEntryColors.success),
            SizedBox(width: 5),
            Text(DueCollectionEntryStrings.viewHistory,
                style: TextStyle(
                    color: DueCollectionEntryColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0)),
          ],
        ),
      ),
    );
  }
}

class _ReceiptMetaLine extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;

  const _ReceiptMetaLine({
    required this.label,
    required this.value,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: DueCollectionEntryColors.bodyPanel.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: DueCollectionEntryColors.success.withValues(alpha: 0.14)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: DueCollectionEntryStyles.rowSub),
                const SizedBox(height: 3),
                Text(value,
                    style: DueCollectionEntryStyles.rowTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            )
          : Row(
              children: [
                Expanded(
                    child: Text(label, style: DueCollectionEntryStyles.rowSub)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(value,
                      style: DueCollectionEntryStyles.rowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
    );
  }
}

class _QuickAmountButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmountButton({required this.label, required this.onTap});

  @override
  State<_QuickAmountButton> createState() => _QuickAmountButtonState();
}

class _QuickAmountButtonState extends State<_QuickAmountButton> {
  bool _hover = false;

  void _setHover(bool value) {
    if (!mounted || _hover == value) return;
    setState(() => _hover = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hover
                ? DueCollectionEntryColors.brandGoldLight
                : DueCollectionEntryColors.bodyPanel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: _hover
                    ? DueCollectionEntryColors.brandGold
                    : DueCollectionEntryColors.bodyBorder),
          ),
          child: Text(widget.label,
              style: DueCollectionEntryStyles.label
                  .copyWith(color: DueCollectionEntryColors.textPrimary)),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final DueCollectionPaymentMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip(
      {required this.mode, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? DueCollectionEntryColors.brandGoldLight
              : DueCollectionEntryColors.bodyPanel,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: selected
                  ? DueCollectionEntryColors.brandGold
                  : DueCollectionEntryColors.bodyBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_modeIcon(mode),
                size: 16,
                color: selected
                    ? DueCollectionEntryColors.brandGold
                    : DueCollectionEntryColors.textMuted),
            const SizedBox(width: 6),
            Text(mode.label,
                style: DueCollectionEntryStyles.label.copyWith(
                    color: selected
                        ? DueCollectionEntryColors.brandGold
                        : DueCollectionEntryColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  IconData _modeIcon(DueCollectionPaymentMode mode) {
    switch (mode) {
      case DueCollectionPaymentMode.cash:
        return DueCollectionEntryIcons.cash;
      case DueCollectionPaymentMode.upi:
        return DueCollectionEntryIcons.upi;
      case DueCollectionPaymentMode.card:
        return DueCollectionEntryIcons.card;
      case DueCollectionPaymentMode.bank:
        return DueCollectionEntryIcons.bank;
      case DueCollectionPaymentMode.cheque:
        return DueCollectionEntryIcons.cheque;
    }
  }
}

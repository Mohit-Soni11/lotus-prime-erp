part of 'due_collection_entry_screen.dart';

class _CustomerDueDetail extends StatelessWidget {
  final DueCollectionEntryController ctrl;

  const _CustomerDueDetail({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final customer = ctrl.selectedCustomer;
    if (customer == null) return const _NoCustomerSelected();
    return Column(
      children: [
        _CustomerProfileBanner(
            customer: customer, onBack: ctrl.clearCustomerSelection),
        const _CustomerDueBillHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: customer.bills.length,
            itemBuilder: (context, index) {
              final bill = customer.bills[index];
              return _CustomerDueBillRow(
                bill: bill,
                selected: ctrl.selectedBill?.id == bill.id,
                alternate: index.isOdd,
                onTap: () => ctrl.selectBill(bill),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CustomerProfileBanner extends StatelessWidget {
  final DueCollectionCustomerModel customer;
  final VoidCallback onBack;

  const _CustomerProfileBanner({required this.customer, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: DueCollectionEntryColors.bodyPanel,
        border: Border(
          bottom: BorderSide(color: DueCollectionEntryColors.bodyBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: DueCollectionEntryColors.panelSoft,
                    borderRadius: BorderRadius.circular(9),
                    border:
                        Border.all(color: DueCollectionEntryColors.bodyBorder),
                  ),
                  child: const Icon(DueCollectionEntryIcons.back,
                      size: 17, color: DueCollectionEntryColors.textPrimary),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DueCollectionEntryColors.infoBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: DueCollectionEntryColors.info
                          .withValues(alpha: 0.18)),
                ),
                child: const Icon(DueCollectionEntryIcons.customer,
                    color: DueCollectionEntryColors.info, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name,
                        style: DueCollectionEntryStyles.sectionTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Text(
                      '${customer.mobile}  |  ${customer.address}',
                      style: DueCollectionEntryStyles.rowSub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (customer.hasOverdue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: DueCollectionEntryColors.dangerBg,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: DueCollectionEntryColors.danger
                            .withValues(alpha: 0.22)),
                  ),
                  child: Text('${customer.overdueCount} overdue',
                      style: DueCollectionEntryStyles.label.copyWith(
                          color: DueCollectionEntryColors.danger,
                          fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _CustomerMetricPill(
                  label: 'Total Due',
                  value: DueCollectionEntryController.formatAmount(
                      customer.totalDue),
                  color: DueCollectionEntryColors.warning,
                  strong: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CustomerMetricPill(
                  label: 'Due Bills',
                  value: customer.billCount.toString(),
                  color: DueCollectionEntryColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CustomerMetricPill(
                  label: 'Overdue Due',
                  value: DueCollectionEntryController.formatCompact(
                      customer.overdueDue),
                  color: DueCollectionEntryColors.danger,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CustomerMetricPill(
                  label: 'Paid So Far',
                  value: DueCollectionEntryController.formatCompact(
                      customer.totalPaid),
                  color: DueCollectionEntryColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool strong;

  const _CustomerMetricPill({
    required this.label,
    required this.value,
    required this.color,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: strong ? 64 : 58,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: DueCollectionEntryStyles.rowSub.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(value,
              style: DueCollectionEntryStyles.rowTitle
                  .copyWith(color: color, fontSize: strong ? 16 : 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _CustomerDueBillHeader extends StatelessWidget {
  const _CustomerDueBillHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: DueCollectionEntryColors.tableHeader,
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderText('Invoice')),
          Expanded(flex: 2, child: _HeaderText('Bill Date', center: true)),
          Expanded(flex: 2, child: _HeaderText('Bill', center: true)),
          Expanded(flex: 2, child: _HeaderText('Paid', center: true)),
          Expanded(flex: 2, child: _HeaderText('Due', center: true)),
          Expanded(flex: 2, child: _HeaderText('Promise', center: true)),
          Expanded(flex: 2, child: _HeaderText('Status', center: true)),
          SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  final bool center;

  const _HeaderText(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: DueCollectionEntryStyles.label
          .copyWith(color: DueCollectionEntryColors.textPrimary, fontSize: 11),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _CustomerDueBillRow extends StatefulWidget {
  final DueCollectionBillModel bill;
  final bool selected;
  final bool alternate;
  final VoidCallback onTap;

  const _CustomerDueBillRow({
    required this.bill,
    required this.selected,
    required this.alternate,
    required this.onTap,
  });

  @override
  State<_CustomerDueBillRow> createState() => _CustomerDueBillRowState();
}

class _CustomerDueBillRowState extends State<_CustomerDueBillRow> {
  bool _hover = false;

  void _setHover(bool value) {
    if (!mounted || _hover == value) return;
    setState(() => _hover = value);
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    final bg = widget.selected
        ? DueCollectionEntryColors.rowSelected
        : _hover
            ? DueCollectionEntryColors.rowHover
            : widget.alternate
                ? DueCollectionEntryColors.rowAlt
                : DueCollectionEntryColors.bodyPanel;

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          height: 64,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(flex: 3, child: _InvoiceCell(bill: bill)),
              Expanded(
                  flex: 2,
                  child: _CenterText(
                      DueCollectionEntryController.formatShortDate(
                          bill.billDate))),
              Expanded(
                  flex: 2,
                  child: _CenterText(DueCollectionEntryController.formatCompact(
                      bill.finalAmount))),
              Expanded(
                  flex: 2,
                  child: _CenterText(DueCollectionEntryController.formatCompact(
                      bill.paidAmount))),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    DueCollectionEntryController.formatCompact(bill.dueAmount),
                    style: DueCollectionEntryStyles.rowTitle
                        .copyWith(color: DueCollectionEntryColors.warning),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(flex: 2, child: _PromiseCell(bill: bill)),
              Expanded(flex: 2, child: Center(child: _StatusBadge(bill: bill))),
              const SizedBox(
                  width: 28,
                  child: Icon(DueCollectionEntryIcons.arrow,
                      size: 18, color: DueCollectionEntryColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceCell extends StatelessWidget {
  final DueCollectionBillModel bill;

  const _InvoiceCell({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(bill.billNo,
            style: DueCollectionEntryStyles.rowTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 3),
        Text('${bill.billingMode} - ${bill.billType}',
            style: DueCollectionEntryStyles.rowSub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _CenterText extends StatelessWidget {
  final String text;

  const _CenterText(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(text,
            style: DueCollectionEntryStyles.rowSub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis));
  }
}

class _PromiseCell extends StatelessWidget {
  final DueCollectionBillModel bill;

  const _PromiseCell({required this.bill});

  @override
  Widget build(BuildContext context) {
    final color = bill.isOverdue
        ? DueCollectionEntryColors.danger
        : bill.isDueToday
            ? DueCollectionEntryColors.warning
            : DueCollectionEntryColors.textMuted;
    return Center(
      child: Text(
        DueCollectionEntryController.formatShortDate(bill.promiseDate),
        style: DueCollectionEntryStyles.rowSub
            .copyWith(color: color, fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DueCollectionBillModel bill;

  const _StatusBadge({required this.bill});

  @override
  Widget build(BuildContext context) {
    final color = bill.isOverdue
        ? DueCollectionEntryColors.danger
        : bill.isDueToday
            ? DueCollectionEntryColors.warning
            : DueCollectionEntryColors.info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        bill.isOverdue ? 'OVERDUE' : bill.statusLabel,
        style:
            DueCollectionEntryStyles.label.copyWith(color: color, fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _NoCustomerSelected extends StatelessWidget {
  const _NoCustomerSelected();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(DueCollectionEntryIcons.customer,
              size: 48, color: DueCollectionEntryColors.textMuted),
          SizedBox(height: 12),
          Text('Select customer', style: DueCollectionEntryStyles.sectionTitle),
          SizedBox(height: 5),
          Text('Customer due bills will appear here.',
              style: DueCollectionEntryStyles.muted),
        ],
      ),
    );
  }
}

class _EmptyBills extends StatelessWidget {
  const _EmptyBills();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(DueCollectionEntryIcons.empty,
              size: 48, color: DueCollectionEntryColors.textMuted),
          SizedBox(height: 12),
          Text(DueCollectionEntryStrings.noBillTitle,
              style: DueCollectionEntryStyles.sectionTitle),
          SizedBox(height: 5),
          Text(DueCollectionEntryStrings.noBillSub,
              style: DueCollectionEntryStyles.muted),
        ],
      ),
    );
  }
}

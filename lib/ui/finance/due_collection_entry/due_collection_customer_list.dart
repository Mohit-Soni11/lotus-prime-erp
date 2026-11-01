part of 'due_collection_entry_screen.dart';

class _SearchBox extends StatelessWidget {
  final DueCollectionEntryController ctrl;

  const _SearchBox({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: DueCollectionEntryStyles.flatPanel(
          color: DueCollectionEntryColors.bodyPanel),
      child: TextField(
        controller: ctrl.searchCtrl,
        style: DueCollectionEntryStyles.rowTitle,
        decoration: InputDecoration(
          prefixIcon: const Icon(DueCollectionEntryIcons.search,
              size: 18, color: DueCollectionEntryColors.textMuted),
          suffixIcon: ctrl.searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  onPressed: ctrl.clearSearch,
                  icon: const Icon(DueCollectionEntryIcons.clear, size: 17)),
          hintText: DueCollectionEntryStrings.searchHint,
          hintStyle: DueCollectionEntryStyles.muted,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _TinyLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TinyLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: DueCollectionEntryColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: DueCollectionEntryStyles.rowSub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String message;
  final bool isError;

  const _MessageBox({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? DueCollectionEntryColors.danger
        : DueCollectionEntryColors.brandGold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isError
            ? DueCollectionEntryColors.dangerBg
            : DueCollectionEntryColors.brandGoldLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(message,
          style: DueCollectionEntryStyles.label.copyWith(color: color)),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MoneyLine(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: DueCollectionEntryStyles.label)),
        Text(DueCollectionEntryController.formatAmount(value),
            style: DueCollectionEntryStyles.rowTitle
                .copyWith(color: color, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _BillList extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final bool inset;

  const _BillList({required this.ctrl, this.inset = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(inset ? 14 : 0),
      child: Container(
        decoration: DueCollectionEntryStyles.panel(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  const Icon(DueCollectionEntryIcons.customer,
                      color: DueCollectionEntryColors.brandGold, size: 17),
                  const SizedBox(width: 8),
                  const Expanded(
                      child: Text('Customer Due Desk',
                          style: DueCollectionEntryStyles.sectionTitle)),
                  _CountBadge(
                      count: ctrl.customers.length,
                      total: ctrl.stats.customerCount),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: _SearchBox(ctrl: ctrl),
            ),
            Expanded(
              child: ctrl.selectedCustomer != null
                  ? _CustomerDueDetail(ctrl: ctrl)
                  : ctrl.customers.isEmpty
                      ? const _EmptyBills()
                      : _CustomerResultsList(ctrl: ctrl),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final int total;

  const _CountBadge({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final label = count == total ? '$total customers' : '$count found';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DueCollectionEntryColors.brandGoldLight,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: DueCollectionEntryColors.brandGold.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: DueCollectionEntryStyles.label
              .copyWith(color: DueCollectionEntryColors.brandGold)),
    );
  }
}

class _CustomerResultsList extends StatelessWidget {
  final DueCollectionEntryController ctrl;

  const _CustomerResultsList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DueCollectionEntryColors.panelSoft,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        itemCount: ctrl.customers.length,
        itemBuilder: (context, index) {
          final customer = ctrl.customers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CustomerResultCard(
              customer: customer,
              selected: ctrl.selectedCustomer?.key == customer.key,
              onTap: () => ctrl.selectCustomer(customer),
            ),
          );
        },
      ),
    );
  }
}

class _CustomerResultCard extends StatelessWidget {
  final DueCollectionCustomerModel customer;
  final bool selected;
  final VoidCallback onTap;

  const _CustomerResultCard({
    required this.customer,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? DueCollectionEntryColors.brandGold
        : DueCollectionEntryColors.bodyBorder;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? DueCollectionEntryColors.rowSelected
              : DueCollectionEntryColors.bodyPanel,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DueCollectionEntryColors.infoBg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color:
                        DueCollectionEntryColors.info.withValues(alpha: 0.18)),
              ),
              child: const Icon(DueCollectionEntryIcons.customer,
                  color: DueCollectionEntryColors.info, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name,
                      style: DueCollectionEntryStyles.rowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(customer.mobile,
                      style: DueCollectionEntryStyles.rowSub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _MiniTag(customer.billCount == 1
                          ? '1 bill'
                          : '${customer.billCount} bills'),
                      if (customer.hasOverdue) ...[
                        const SizedBox(width: 6),
                        _MiniTag(
                          '${DueCollectionEntryController.formatCompact(customer.overdueDue)} overdue',
                          color: DueCollectionEntryColors.danger,
                        ),
                      ],
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          DueCollectionEntryController.formatCompact(
                              customer.totalDue),
                          textAlign: TextAlign.right,
                          style: DueCollectionEntryStyles.rowTitle.copyWith(
                              color: DueCollectionEntryColors.warning),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniTag(this.text, {this.color = DueCollectionEntryColors.brandGold});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(text,
          style: DueCollectionEntryStyles.rowSub.copyWith(color: color)),
    );
  }
}

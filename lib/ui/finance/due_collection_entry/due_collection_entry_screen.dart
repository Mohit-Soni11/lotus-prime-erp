import 'package:flutter/material.dart';

import '../../../logic/finance/due_collection_entry/due_collection_entry_controller.dart';
import '../../../models/finance/due_collection_entry/due_collection_entry_model.dart';
import '../../../theme/finance/due_collection_entry/due_collection_entry_theme.dart';

class DueCollectionEntryScreen extends StatefulWidget {
  const DueCollectionEntryScreen({super.key});

  @override
  State<DueCollectionEntryScreen> createState() =>
      _DueCollectionEntryScreenState();
}

class _DueCollectionEntryScreenState extends State<DueCollectionEntryScreen> {
  late final DueCollectionEntryController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = DueCollectionEntryController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  Future<void> _handleSave() async {
    final result = await _ctrl.saveCollection();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: result.success
            ? DueCollectionEntryColors.success
            : DueCollectionEntryColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: DueCollectionEntryColors.bodyBg,
            appBar: _DueCollectionAppBar(
              onBack: _handleBack,
              onRefresh: _ctrl.refresh,
              onReset: _ctrl.resetEntry,
              isLoading: _ctrl.isLoading,
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 1180;
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 330, child: _LeftPanel(ctrl: _ctrl)),
                        Container(
                            width: 1,
                            color: DueCollectionEntryColors.bodyBorder),
                        Expanded(child: _BillList(ctrl: _ctrl)),
                        Container(
                            width: 1,
                            color: DueCollectionEntryColors.bodyBorder),
                        SizedBox(
                            width: 430,
                            child: _CollectionPanel(
                                ctrl: _ctrl, onSave: _handleSave)),
                      ],
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LeftPanel(ctrl: _ctrl, embedded: true),
                        const SizedBox(height: 12),
                        SizedBox(height: 460, child: _BillList(ctrl: _ctrl)),
                        const SizedBox(height: 12),
                        _CollectionPanel(
                            ctrl: _ctrl, onSave: _handleSave, embedded: true),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DueCollectionAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onReset;
  final bool isLoading;

  const _DueCollectionAppBar(
      {required this.onBack,
      required this.onRefresh,
      required this.onReset,
      required this.isLoading});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<_DueCollectionAppBar> createState() => _DueCollectionAppBarState();
}

class _DueCollectionAppBarState extends State<_DueCollectionAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkCtrl;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: DueCollectionEntryColors.shellPanel,
        border: Border(
            bottom: BorderSide(
                color: DueCollectionEntryColors.shellBorder, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _ShellIconButton(
                icon: DueCollectionEntryIcons.back,
                tooltip: 'Back',
                onTap: widget.onBack),
            const SizedBox(width: 16),
            Container(
                width: 1,
                height: 30,
                color: DueCollectionEntryColors.shellBorder),
            const SizedBox(width: 16),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: DueCollectionEntryColors.brandGoldLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: DueCollectionEntryColors.brandGold
                        .withValues(alpha: 0.3)),
              ),
              child: const Icon(DueCollectionEntryIcons.module,
                  color: DueCollectionEntryColors.brandGold, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DueCollectionEntryStrings.title,
                      style: DueCollectionEntryStyles.appBarTitle),
                  SizedBox(height: 3),
                  Text(DueCollectionEntryStrings.subtitle,
                      style: DueCollectionEntryStyles.appBarSub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _blinkCtrl,
              builder: (_, __) => Opacity(
                opacity: 0.35 + (_blinkCtrl.value * 0.65),
                child: const Row(
                  children: [
                    _LiveDot(),
                    SizedBox(width: 6),
                    Text(DueCollectionEntryStrings.live,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: DueCollectionEntryColors.success,
                            letterSpacing: 1.2)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
            _ShellIconButton(
                icon: widget.isLoading
                    ? Icons.hourglass_top_rounded
                    : DueCollectionEntryIcons.refresh,
                tooltip: DueCollectionEntryStrings.refresh,
                onTap: widget.isLoading ? null : widget.onRefresh),
            const SizedBox(width: 8),
            _ShellIconButton(
                icon: DueCollectionEntryIcons.reset,
                tooltip: DueCollectionEntryStrings.reset,
                onTap: widget.onReset),
          ],
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
            color: DueCollectionEntryColors.success, shape: BoxShape.circle));
  }
}

class _ShellIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ShellIconButton(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_ShellIconButton> createState() => _ShellIconButtonState();
}

class _ShellIconButtonState extends State<_ShellIconButton> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted || _hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered && !disabled
                  ? DueCollectionEntryColors.brandGoldLight
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _hovered && !disabled
                      ? DueCollectionEntryColors.brandGold
                          .withValues(alpha: 0.4)
                      : DueCollectionEntryColors.shellBorder),
            ),
            child: Icon(widget.icon,
                size: 16,
                color: disabled
                    ? DueCollectionEntryColors.shellBorder
                    : _hovered
                        ? DueCollectionEntryColors.brandGold
                        : DueCollectionEntryColors.shellMuted),
          ),
        ),
      ),
    );
  }
}

class _LeftPanel extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final bool embedded;

  const _LeftPanel({required this.ctrl, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final child = SingleChildScrollView(
      padding: EdgeInsets.all(embedded ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchBox(ctrl: ctrl),
          const SizedBox(height: 12),
          _SummaryCard(
            icon: DueCollectionEntryIcons.amount,
            label: 'Total Due',
            value:
                DueCollectionEntryController.formatCompact(ctrl.stats.totalDue),
            color: DueCollectionEntryColors.warning,
            bg: DueCollectionEntryColors.warningBg,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _MiniSummary(
                      label: 'Bills',
                      value: ctrl.stats.billCount.toString(),
                      icon: DueCollectionEntryIcons.bill)),
              const SizedBox(width: 10),
              Expanded(
                  child: _MiniSummary(
                      label: 'Customers',
                      value: ctrl.stats.customerCount.toString(),
                      icon: DueCollectionEntryIcons.customer)),
            ],
          ),
          const SizedBox(height: 10),
          _SummaryCard(
            icon: DueCollectionEntryIcons.warning,
            label: 'Overdue Due',
            value: DueCollectionEntryController.formatCompact(
                ctrl.stats.overdueDue),
            color: DueCollectionEntryColors.danger,
            bg: DueCollectionEntryColors.dangerBg,
          ),
          const SizedBox(height: 12),
          _SelectedCustomerCard(bill: ctrl.selectedBill),
          if (ctrl.errorMessage != null) ...[
            const SizedBox(height: 12),
            _MessageBox(message: ctrl.errorMessage!, isError: true),
          ],
          if (ctrl.successMessage != null) ...[
            const SizedBox(height: 12),
            _MessageBox(message: ctrl.successMessage!, isError: false),
          ],
        ],
      ),
    );
    if (embedded) return child;
    return Container(color: DueCollectionEntryColors.bodyBg, child: child);
  }
}

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

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _SummaryCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DueCollectionEntryStyles.panel(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: color.withValues(alpha: 0.18))),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: DueCollectionEntryStyles.label, maxLines: 1),
                const SizedBox(height: 4),
                Text(value,
                    style: DueCollectionEntryStyles.amount
                        .copyWith(color: color, fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSummary extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniSummary(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: DueCollectionEntryStyles.flatPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: DueCollectionEntryColors.brandGold),
          const SizedBox(height: 8),
          Text(value,
              style: DueCollectionEntryStyles.amount.copyWith(fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: DueCollectionEntryStyles.rowSub),
        ],
      ),
    );
  }
}

class _SelectedCustomerCard extends StatelessWidget {
  final DueCollectionBillModel? bill;

  const _SelectedCustomerCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final item = bill;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DueCollectionEntryStyles.panel(
          color: DueCollectionEntryColors.panelSoft),
      child: item == null
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selected Bill', style: DueCollectionEntryStyles.label),
                SizedBox(height: 8),
                Text('Select a due bill to start collection.',
                    style: DueCollectionEntryStyles.muted),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selected Customer',
                    style: DueCollectionEntryStyles.label),
                const SizedBox(height: 10),
                Text(item.customerName,
                    style: DueCollectionEntryStyles.sectionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                _TinyLine(
                    icon: DueCollectionEntryIcons.phone, text: item.mobile),
                if (item.address.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  _TinyLine(
                      icon: DueCollectionEntryIcons.location,
                      text: item.address),
                ],
                const SizedBox(height: 12),
                _MoneyLine(
                    label: 'Selected Due',
                    value: item.dueAmount,
                    color: DueCollectionEntryColors.warning),
              ],
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
        : DueCollectionEntryColors.success;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isError
            ? DueCollectionEntryColors.dangerBg
            : DueCollectionEntryColors.successBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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

  const _BillList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Container(
        decoration: DueCollectionEntryStyles.panel(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  const Icon(DueCollectionEntryIcons.receipt,
                      color: DueCollectionEntryColors.brandGold, size: 19),
                  const SizedBox(width: 8),
                  const Expanded(
                      child: Text(DueCollectionEntryStrings.pendingBills,
                          style: DueCollectionEntryStyles.sectionTitle)),
                  _CountBadge(
                      count: ctrl.bills.length, total: ctrl.allBillCount),
                ],
              ),
            ),
            const _BillHeader(),
            Expanded(
              child: ctrl.bills.isEmpty
                  ? const _EmptyBills()
                  : ListView.builder(
                      itemCount: ctrl.bills.length,
                      itemBuilder: (context, index) {
                        final bill = ctrl.bills[index];
                        return _BillRow(
                          bill: bill,
                          selected: ctrl.selectedBill?.id == bill.id,
                          alternate: index.isOdd,
                          onTap: () => ctrl.selectBill(bill),
                        );
                      },
                    ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DueCollectionEntryColors.brandGoldLight,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: DueCollectionEntryColors.brandGold.withValues(alpha: 0.3)),
      ),
      child: Text('$count of $total',
          style: DueCollectionEntryStyles.label
              .copyWith(color: DueCollectionEntryColors.brandGold)),
    );
  }
}

class _BillHeader extends StatelessWidget {
  const _BillHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: DueCollectionEntryColors.tableHeader,
      child: const Row(
        children: [
          Expanded(flex: 4, child: _HeaderText('Customer')),
          Expanded(flex: 3, child: _HeaderText('Bill')),
          Expanded(flex: 2, child: _HeaderText('Bill Date', center: true)),
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

class _BillRow extends StatefulWidget {
  final DueCollectionBillModel bill;
  final bool selected;
  final bool alternate;
  final VoidCallback onTap;

  const _BillRow(
      {required this.bill,
      required this.selected,
      required this.alternate,
      required this.onTap});

  @override
  State<_BillRow> createState() => _BillRowState();
}

class _BillRowState extends State<_BillRow> {
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
          height: 68,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(flex: 4, child: _CustomerCell(bill: bill)),
              Expanded(flex: 3, child: _BillCell(bill: bill)),
              Expanded(
                  flex: 2,
                  child: _CenterText(
                      DueCollectionEntryController.formatShortDate(
                          bill.billDate))),
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

class _CustomerCell extends StatelessWidget {
  final DueCollectionBillModel bill;

  const _CustomerCell({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DueCollectionEntryColors.infoBg,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
                color: DueCollectionEntryColors.info.withValues(alpha: 0.18)),
          ),
          child: const Icon(DueCollectionEntryIcons.customer,
              size: 18, color: DueCollectionEntryColors.info),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(bill.customerName,
                  style: DueCollectionEntryStyles.rowTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(bill.mobile,
                  style: DueCollectionEntryStyles.rowSub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _BillCell extends StatelessWidget {
  final DueCollectionBillModel bill;

  const _BillCell({required this.bill});

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

class _CollectionPanel extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final VoidCallback onSave;
  final bool embedded;

  const _CollectionPanel(
      {required this.ctrl, required this.onSave, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final bill = ctrl.selectedBill;
    final content = Container(
      margin: EdgeInsets.all(embedded ? 0 : 14),
      decoration: DueCollectionEntryStyles.panel(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: DueCollectionEntryColors.tableHeader,
            child: const Row(
              children: [
                Icon(DueCollectionEntryIcons.amount,
                    size: 19, color: DueCollectionEntryColors.brandGold),
                SizedBox(width: 8),
                Text(DueCollectionEntryStrings.collectionForm,
                    style: DueCollectionEntryStyles.sectionTitle),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: bill == null
                  ? const _NoSelectedBill()
                  : _CollectionForm(ctrl: ctrl, bill: bill, onSave: onSave),
            ),
          ),
        ],
      ),
    );
    if (embedded) return SizedBox(height: 620, child: content);
    return content;
  }
}

class _NoSelectedBill extends StatelessWidget {
  const _NoSelectedBill();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Icon(DueCollectionEntryIcons.receipt,
                size: 46, color: DueCollectionEntryColors.textMuted),
            SizedBox(height: 12),
            Text('Select bill', style: DueCollectionEntryStyles.sectionTitle),
            SizedBox(height: 5),
            Text('Collection form will appear here.',
                style: DueCollectionEntryStyles.muted),
          ],
        ),
      ),
    );
  }
}

class _CollectionForm extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final DueCollectionBillModel bill;
  final VoidCallback onSave;

  const _CollectionForm(
      {required this.ctrl, required this.bill, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BillSummaryBox(bill: bill),
        const SizedBox(height: 14),
        const Text('Collection Amount', style: DueCollectionEntryStyles.label),
        const SizedBox(height: 7),
        TextField(
          controller: ctrl.amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: DueCollectionEntryStyles.amount.copyWith(fontSize: 24),
          decoration: InputDecoration(
            prefixIcon: const Icon(DueCollectionEntryIcons.amount,
                color: DueCollectionEntryColors.brandGold),
            hintText: '0.00',
            filled: true,
            fillColor: DueCollectionEntryColors.panelSoft,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: DueCollectionEntryColors.bodyBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: DueCollectionEntryColors.brandGold, width: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _QuickAmountButton(
                    label: DueCollectionEntryStrings.fullDue,
                    onTap: ctrl.setFullDueAmount)),
            const SizedBox(width: 10),
            Expanded(
                child: _QuickAmountButton(
                    label: DueCollectionEntryStrings.halfDue,
                    onTap: ctrl.setHalfDueAmount)),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Payment Mode', style: DueCollectionEntryStyles.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DueCollectionPaymentMode.values
              .map((mode) => _ModeChip(
                  mode: mode,
                  selected: ctrl.paymentMode == mode,
                  onTap: () => ctrl.setPaymentMode(mode)))
              .toList(),
        ),
        if (ctrl.requiresBankAccount) ...[
          const SizedBox(height: 14),
          const Text('Bank Account', style: DueCollectionEntryStyles.label),
          const SizedBox(height: 7),
          _BankAccountDropdown(ctrl: ctrl),
        ],
        const SizedBox(height: 14),
        const Text('Notes', style: DueCollectionEntryStyles.label),
        const SizedBox(height: 7),
        TextField(
          controller: ctrl.notesCtrl,
          minLines: 3,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Optional narration',
            hintStyle: DueCollectionEntryStyles.muted,
            filled: true,
            fillColor: DueCollectionEntryColors.panelSoft,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: DueCollectionEntryColors.bodyBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: DueCollectionEntryColors.brandGold, width: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SettlementPreview(ctrl: ctrl, bill: bill),
        const SizedBox(height: 16),
        _SaveButton(ctrl: ctrl, onSave: onSave),
      ],
    );
  }
}

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(bill.billNo,
                      style: DueCollectionEntryStyles.sectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
              _StatusBadge(bill: bill),
            ],
          ),
          const SizedBox(height: 9),
          Text(bill.customerName,
              style: DueCollectionEntryStyles.rowTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
              '${bill.mobile}  |  ${DueCollectionEntryController.formatDate(bill.billDate)}',
              style: DueCollectionEntryStyles.rowSub),
          const SizedBox(height: 12),
          _MoneyLine(
              label: 'Bill Amount',
              value: bill.finalAmount,
              color: DueCollectionEntryColors.textPrimary),
          const SizedBox(height: 7),
          _MoneyLine(
              label: 'Paid Amount',
              value: bill.paidAmount,
              color: DueCollectionEntryColors.success),
          const SizedBox(height: 7),
          _MoneyLine(
              label: 'Due Balance',
              value: bill.dueAmount,
              color: DueCollectionEntryColors.warning),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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

class _BankAccountDropdown extends StatelessWidget {
  final DueCollectionEntryController ctrl;

  const _BankAccountDropdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.bankAccounts.isEmpty) {
      return const _MessageBox(
          message: 'No active bank account found.', isError: true);
    }
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: DueCollectionEntryStyles.flatPanel(
          color: DueCollectionEntryColors.panelSoft),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: ctrl.selectedBankAccountId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: ctrl.bankAccounts
              .map((account) => DropdownMenuItem<int>(
                  value: account.id,
                  child: Text(account.label,
                      maxLines: 1, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: ctrl.setBankAccount,
        ),
      ),
    );
  }
}

class _SettlementPreview extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final DueCollectionBillModel bill;

  const _SettlementPreview({required this.ctrl, required this.bill});

  @override
  Widget build(BuildContext context) {
    final balance = (bill.dueAmount - ctrl.amount).clamp(0.0, double.infinity);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DueCollectionEntryStyles.flatPanel(
          color: DueCollectionEntryColors.panelSoft),
      child: Column(
        children: [
          _MoneyLine(
              label: 'Collecting Now',
              value: ctrl.amount,
              color: DueCollectionEntryColors.success),
          const SizedBox(height: 8),
          _MoneyLine(
              label: 'Balance After Save',
              value: balance,
              color: balance <= 0.5
                  ? DueCollectionEntryColors.success
                  : DueCollectionEntryColors.warning),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final VoidCallback onSave;

  const _SaveButton({required this.ctrl, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final enabled = ctrl.canSave;
    return GestureDetector(
      onTap: enabled ? onSave : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? DueCollectionEntryColors.brandGold
              : DueCollectionEntryColors.bodyBorder,
          borderRadius: BorderRadius.circular(10),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: DueCollectionEntryColors.brandGold
                        .withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (ctrl.isSaving)
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF111827)))
            else
              const Icon(DueCollectionEntryIcons.save,
                  size: 18, color: Color(0xFF111827)),
            const SizedBox(width: 8),
            Text(
              ctrl.isSaving
                  ? DueCollectionEntryStrings.saving
                  : DueCollectionEntryStrings.saveCollection,
              style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }
}

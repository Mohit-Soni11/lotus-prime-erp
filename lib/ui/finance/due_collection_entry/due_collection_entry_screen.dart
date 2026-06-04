import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../due_receipt_history/due_receipt_history_screen.dart';
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

  Future<void> _handleSave({bool printReceipt = false}) async {
    final receiptBill = _ctrl.selectedBill;
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

    if (result.success && printReceipt && receiptBill != null) {
      await _printDueReceipt(receiptBill);
    }
  }

  Future<void> _printDueReceipt(DueCollectionBillModel bill) async {
    final receiptNo = _ctrl.lastReceiptNo ?? 'DUE-RECEIPT';
    final received = _ctrl.lastCollectedAmount;
    final discount = _ctrl.lastDiscountAmount;
    final balance = _ctrl.lastBalanceDue;
    final mode = _ctrl.lastPaymentModeLabel ?? _ctrl.paymentMode.label;
    final promiseDate = _ctrl.lastPromiseDate;
    final pdf = pw.Document();

    pw.Widget line(String label, String value, {bool bold = false}) {
      final style = pw.TextStyle(
        fontSize: 10,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: style),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child:
                  pw.Text(value, style: style, textAlign: pw.TextAlign.right),
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text('LOTUS ERP',
                textAlign: pw.TextAlign.center,
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('DUE COLLECTION RECEIPT',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 11)),
            pw.Divider(height: 22, thickness: 1),
            line('Receipt No', receiptNo, bold: true),
            line('Invoice No', bill.billNo, bold: true),
            line('Customer', bill.customerName),
            line('Mobile', bill.mobile),
            line('Receipt Date',
                DueCollectionEntryController.formatDate(DateTime.now())),
            pw.Divider(height: 18),
            line('Bill Amount',
                DueCollectionEntryController.formatAmount(bill.finalAmount)),
            line('Previous Due',
                DueCollectionEntryController.formatAmount(bill.dueAmount)),
            line(
                'Received', DueCollectionEntryController.formatAmount(received),
                bold: true),
            if (discount > 0.5)
              line('Discount',
                  DueCollectionEntryController.formatAmount(discount)),
            line('Balance Due',
                DueCollectionEntryController.formatAmount(balance),
                bold: true),
            line('Payment Mode', mode.toUpperCase()),
            if (promiseDate != null && balance > 0.5)
              line('Next Promise',
                  DueCollectionEntryController.formatDate(promiseDate)),
            pw.Spacer(),
            pw.Divider(height: 16),
            pw.Text('This is a computer generated receipt.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      ),
    );

    try {
      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Receipt saved, but print preview could not open.',
              style: TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: DueCollectionEntryColors.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
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
                                ctrl: _ctrl,
                                onSave: () => _handleSave(),
                                onSaveAndPrint: () =>
                                    _handleSave(printReceipt: true))),
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
                            ctrl: _ctrl,
                            onSave: () => _handleSave(),
                            onSaveAndPrint: () =>
                                _handleSave(printReceipt: true),
                            embedded: true),
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
          _SelectedCustomerCard(customer: ctrl.selectedCustomer),
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
  final DueCollectionCustomerModel? customer;

  const _SelectedCustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final item = customer;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DueCollectionEntryStyles.panel(
          color: DueCollectionEntryColors.panelSoft),
      child: item == null
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selected Customer',
                    style: DueCollectionEntryStyles.label),
                SizedBox(height: 8),
                Text('Search customer, mobile, or invoice to start collection.',
                    style: DueCollectionEntryStyles.muted),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selected Customer',
                    style: DueCollectionEntryStyles.label),
                const SizedBox(height: 10),
                Text(item.name,
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
                    label: 'Total Due',
                    value: item.totalDue,
                    color: DueCollectionEntryColors.warning),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Due Bills',
                          style: DueCollectionEntryStyles.label),
                    ),
                    Text('${item.billCount}',
                        style: DueCollectionEntryStyles.rowTitle.copyWith(
                            color: DueCollectionEntryColors.info,
                            fontSize: 14)),
                  ],
                ),
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
                  const Icon(DueCollectionEntryIcons.customer,
                      color: DueCollectionEntryColors.brandGold, size: 19),
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
              child: ctrl.customers.isEmpty
                  ? const _EmptyBills()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final split = constraints.maxWidth >= 760;
                        if (split) {
                          return Row(
                            children: [
                              SizedBox(
                                width: 310,
                                child: _CustomerResultsList(ctrl: ctrl),
                              ),
                              Container(
                                  width: 1,
                                  color: DueCollectionEntryColors.bodyBorder),
                              Expanded(child: _CustomerDueDetail(ctrl: ctrl)),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            SizedBox(
                              height: 188,
                              child: _CustomerResultsList(ctrl: ctrl),
                            ),
                            Container(
                                height: 1,
                                color: DueCollectionEntryColors.bodyBorder),
                            Expanded(child: _CustomerDueDetail(ctrl: ctrl)),
                          ],
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
      child: Text('$count customers',
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
        padding: const EdgeInsets.all(10),
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
        padding: const EdgeInsets.all(11),
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
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DueCollectionEntryColors.infoBg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color:
                        DueCollectionEntryColors.info.withValues(alpha: 0.18)),
              ),
              child: const Icon(DueCollectionEntryIcons.customer,
                  color: DueCollectionEntryColors.info, size: 19),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MiniTag('${customer.billCount} bills'),
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

  const _MiniTag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: DueCollectionEntryColors.brandGoldLight,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: DueCollectionEntryColors.brandGold.withValues(alpha: 0.2)),
      ),
      child: Text(text,
          style: DueCollectionEntryStyles.rowSub
              .copyWith(color: DueCollectionEntryColors.brandGold)),
    );
  }
}

class _CustomerDueDetail extends StatelessWidget {
  final DueCollectionEntryController ctrl;

  const _CustomerDueDetail({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final customer = ctrl.selectedCustomer;
    if (customer == null) return const _NoCustomerSelected();
    return Column(
      children: [
        _CustomerProfileBanner(customer: customer),
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

  const _CustomerProfileBanner({required this.customer});

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
                child: _CustomerMetricPill(
                  label: 'Due Bills',
                  value: customer.billCount.toString(),
                  color: DueCollectionEntryColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CustomerMetricPill(
                  label: 'Total Due',
                  value: DueCollectionEntryController.formatCompact(
                      customer.totalDue),
                  color: DueCollectionEntryColors.warning,
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

  const _CustomerMetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
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
              style: DueCollectionEntryStyles.rowTitle.copyWith(color: color),
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

class _CollectionPanel extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final VoidCallback onSave;
  final VoidCallback onSaveAndPrint;
  final bool embedded;

  const _CollectionPanel({
    required this.ctrl,
    required this.onSave,
    required this.onSaveAndPrint,
    this.embedded = false,
  });

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
                  : _CollectionForm(
                      ctrl: ctrl,
                      bill: bill,
                      onSave: onSave,
                      onSaveAndPrint: onSaveAndPrint,
                    ),
            ),
          ),
        ],
      ),
    );
    if (embedded) return SizedBox(height: 760, child: content);
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
  final VoidCallback onSaveAndPrint;

  const _CollectionForm({
    required this.ctrl,
    required this.bill,
    required this.onSave,
    required this.onSaveAndPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BillSummaryBox(bill: bill),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _AmountInput(
                label: 'Collection Amount',
                controller: ctrl.amountCtrl,
                icon: DueCollectionEntryIcons.amount,
                autofocusColor: DueCollectionEntryColors.brandGold,
                textStyle:
                    DueCollectionEntryStyles.amount.copyWith(fontSize: 22),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AmountInput(
                label: 'Discount / Waiver',
                controller: ctrl.discountCtrl,
                icon: DueCollectionEntryIcons.discount,
                autofocusColor: DueCollectionEntryColors.warning,
                textStyle: DueCollectionEntryStyles.amount.copyWith(
                    fontSize: 18, color: DueCollectionEntryColors.warning),
              ),
            ),
          ],
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
            const SizedBox(width: 10),
            Expanded(
                child: _QuickAmountButton(
                    label: 'Clear Disc.', onTap: ctrl.clearDiscount)),
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
        _PromiseDateField(ctrl: ctrl),
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
        if (ctrl.needsPromiseDate && ctrl.promiseDate == null) ...[
          const SizedBox(height: 10),
          const _MessageBox(
              message: 'Select next promise date for remaining due.',
              isError: true),
        ],
        if (ctrl.lastReceiptNo != null) ...[
          const SizedBox(height: 12),
          _ReceiptReadyBox(
            receiptNo: ctrl.lastReceiptNo!,
            billNo: bill.billNo,
            amount: ctrl.lastCollectedAmount,
            discount: ctrl.lastDiscountAmount,
            balance: ctrl.lastBalanceDue,
            mode: ctrl.lastPaymentModeLabel ?? ctrl.paymentMode.label,
          ),
        ],
        const SizedBox(height: 16),
        _SaveActions(
          ctrl: ctrl,
          onSave: onSave,
          onSaveAndPrint: onSaveAndPrint,
        ),
      ],
    );
  }
}

class _AmountInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color autofocusColor;
  final TextStyle textStyle;

  const _AmountInput({
    required this.label,
    required this.controller,
    required this.icon,
    required this.autofocusColor,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: DueCollectionEntryStyles.label),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: textStyle,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: autofocusColor),
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
              borderSide: BorderSide(color: autofocusColor, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromiseDateField extends StatelessWidget {
  final DueCollectionEntryController ctrl;

  const _PromiseDateField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final required = ctrl.needsPromiseDate;
    final selected = ctrl.promiseDate;
    final color = required && selected == null
        ? DueCollectionEntryColors.warning
        : DueCollectionEntryColors.brandGold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Next Promise Date',
                style: DueCollectionEntryStyles.label.copyWith(color: color)),
            const Spacer(),
            _TinyPromiseButton(
                label: '7D', onTap: () => ctrl.setQuickPromiseDays(7)),
            const SizedBox(width: 6),
            _TinyPromiseButton(
                label: '15D', onTap: () => ctrl.setQuickPromiseDays(15)),
            const SizedBox(width: 6),
            _TinyPromiseButton(
                label: '30D', onTap: () => ctrl.setQuickPromiseDays(30)),
          ],
        ),
        const SizedBox(height: 7),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: selected ?? now.add(const Duration(days: 7)),
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 5),
            );
            if (picked != null) ctrl.setPromiseDate(picked);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: DueCollectionEntryStyles.flatPanel(
                color: DueCollectionEntryColors.panelSoft),
            child: Row(
              children: [
                Icon(DueCollectionEntryIcons.calendar, size: 18, color: color),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    selected == null
                        ? 'Tap to set follow-up date'
                        : DueCollectionEntryController.formatDate(selected),
                    style: DueCollectionEntryStyles.rowTitle.copyWith(
                        color: selected == null
                            ? DueCollectionEntryColors.textMuted
                            : DueCollectionEntryColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selected != null)
                  IconButton(
                    tooltip: 'Clear',
                    onPressed: () => ctrl.setPromiseDate(null),
                    icon: const Icon(DueCollectionEntryIcons.clear, size: 17),
                    color: DueCollectionEntryColors.textMuted,
                  )
                else
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: DueCollectionEntryColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TinyPromiseButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TinyPromiseButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: DueCollectionEntryColors.bodyPanel,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: DueCollectionEntryColors.bodyBorder),
        ),
        child: Text(label, style: DueCollectionEntryStyles.rowSub),
      ),
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
                    color: DueCollectionEntryColors.success, size: 19),
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
    final collected = ctrl.amount.clamp(0.0, bill.dueAmount).toDouble();
    final discount = ctrl.discountAmount.clamp(0.0, bill.dueAmount).toDouble();
    final settlement =
        (collected + discount).clamp(0.0, bill.dueAmount).toDouble();
    final balance = ctrl.balanceAfterSave;
    final progress = bill.dueAmount <= 0 ? 0.0 : settlement / bill.dueAmount;
    final isClosing = balance <= 0.5 && settlement > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DueCollectionEntryStyles.flatPanel(
          color: DueCollectionEntryColors.panelSoft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MoneyLine(
              label: 'Collecting Now',
              value: collected,
              color: DueCollectionEntryColors.success),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _MoneyLine(
                label: 'Discount / Waiver',
                value: discount,
                color: DueCollectionEntryColors.warning),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress.clamp(0.0, 1.0),
              backgroundColor: DueCollectionEntryColors.bodyBorder,
              valueColor: AlwaysStoppedAnimation<Color>(isClosing
                  ? DueCollectionEntryColors.success
                  : DueCollectionEntryColors.brandGold),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  isClosing
                      ? 'Bill will close after save'
                      : 'Partial settlement',
                  style: DueCollectionEntryStyles.label.copyWith(
                    color: isClosing
                        ? DueCollectionEntryColors.success
                        : DueCollectionEntryColors.warning,
                  ),
                ),
              ),
              Text(
                DueCollectionEntryController.formatAmount(balance),
                style: DueCollectionEntryStyles.rowTitle.copyWith(
                  color: isClosing
                      ? DueCollectionEntryColors.success
                      : DueCollectionEntryColors.warning,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaveActions extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final VoidCallback onSave;
  final VoidCallback onSaveAndPrint;

  const _SaveActions({
    required this.ctrl,
    required this.onSave,
    required this.onSaveAndPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SaveActionButton(
            ctrl: ctrl,
            label: ctrl.isSaving
                ? DueCollectionEntryStrings.saving
                : DueCollectionEntryStrings.saveCollection,
            icon: DueCollectionEntryIcons.save,
            onTap: onSave,
            filled: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SaveActionButton(
            ctrl: ctrl,
            label: DueCollectionEntryStrings.saveAndPrint,
            icon: DueCollectionEntryIcons.printReceipt,
            onTap: onSaveAndPrint,
            filled: false,
          ),
        ),
      ],
    );
  }
}

class _SaveActionButton extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _SaveActionButton({
    required this.ctrl,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = ctrl.canSave;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? (filled
                  ? DueCollectionEntryColors.brandGold
                  : DueCollectionEntryColors.bodyPanel)
              : DueCollectionEntryColors.bodyBorder,
          borderRadius: BorderRadius.circular(10),
          border: filled
              ? null
              : Border.all(
                  color: enabled
                      ? DueCollectionEntryColors.brandGold
                      : DueCollectionEntryColors.bodyBorder),
          boxShadow: enabled && filled
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
            if (ctrl.isSaving && filled)
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF111827)))
            else
              Icon(icon,
                  size: 18,
                  color: filled
                      ? const Color(0xFF111827)
                      : DueCollectionEntryColors.brandGold),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    color: filled
                        ? const Color(0xFF111827)
                        : DueCollectionEntryColors.brandGold,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

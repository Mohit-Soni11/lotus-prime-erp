import 'package:flutter/material.dart';

import '../../../logic/finance/due_report/due_report_controller.dart';
import '../../../models/finance/due_report/due_report_model.dart';
import '../../../theme/finance/due_report/due_report_theme.dart';

class DueReportBillPanel extends StatelessWidget {
  final DueCustomerGroupModel? group;
  final ValueChanged<DueCustomerGroupModel>? onCollectDue;

  const DueReportBillPanel({
    super.key,
    required this.group,
    this.onCollectDue,
  });

  @override
  Widget build(BuildContext context) {
    final selected = group;
    return Container(
      decoration: DueReportStyles.panel(),
      child: selected == null
          ? const _NoSelection()
          : Column(
              children: [
                _CustomerHeader(
                  group: selected,
                  onCollectDue: onCollectDue,
                ),
                const Divider(height: 1, color: DueReportColors.divider),
                Expanded(child: _BillList(group: selected)),
              ],
            ),
    );
  }
}

class _CustomerHeader extends StatelessWidget {
  final DueCustomerGroupModel group;
  final ValueChanged<DueCustomerGroupModel>? onCollectDue;

  const _CustomerHeader({
    required this.group,
    required this.onCollectDue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DueReportColors.goldSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DueReportColors.gold.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  DueReportIcons.bill,
                  color: DueReportColors.gold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.customerName,
                      style: DueReportStyles.sectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _contactLine(group),
                      style: DueReportStyles.muted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Total Due',
                  value: DueReportController.formatCompact(group.totalDue),
                  color: DueReportColors.danger,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'Bills',
                  value: group.billCount.toString(),
                  color: DueReportColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'Overdue',
                  value: group.overdueBillCount.toString(),
                  color: DueReportColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CollectDueButton(
            enabled: onCollectDue != null,
            onTap: () => onCollectDue?.call(group),
          ),
          if (group.address.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  DueReportIcons.location,
                  size: 15,
                  color: DueReportColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    group.address,
                    style: DueReportStyles.muted,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _contactLine(DueCustomerGroupModel group) {
    final city = group.city.trim().isEmpty ? 'No city' : group.city;
    return '${group.mobile} | $city';
  }
}

class _CollectDueButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _CollectDueButton({
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_CollectDueButton> createState() => _CollectDueButtonState();
}

class _CollectDueButtonState extends State<_CollectDueButton> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted || _hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled;
    final bg = _hovered && active
        ? DueReportColors.appBarBg
        : DueReportColors.goldSoft;
    final fg =
        _hovered && active ? DueReportColors.textLight : DueReportColors.gold;

    return MouseRegion(
      cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: active ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? DueReportColors.gold : DueReportColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(DueReportIcons.collect, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(
                'Collect Due',
                style: DueReportStyles.label.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: DueReportStyles.muted.copyWith(fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: DueReportStyles.rowTitle.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BillList extends StatelessWidget {
  final DueCustomerGroupModel group;
  const _BillList({required this.group});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        if (compact) {
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: group.bills.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) =>
                _CompactBillCard(bill: group.bills[index]),
          );
        }

        return Column(
          children: [
            const _BillTableHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: group.bills.length,
                itemBuilder: (_, index) =>
                    _BillRow(bill: group.bills[index], alternate: index.isOdd),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BillTableHeader extends StatelessWidget {
  const _BillTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      color: DueReportColors.panelSoft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _cell('Bill', 2),
          _cell('Date', 2, center: true),
          _cell('Final', 2, center: true),
          _cell('Paid', 2, center: true),
          _cell('Due', 2, center: true),
          _cell('Promise', 2, center: true),
        ],
      ),
    );
  }

  Widget _cell(String label, int flex, {bool center = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: DueReportStyles.tableHeader,
        textAlign: center ? TextAlign.center : TextAlign.left,
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final DueBillModel bill;
  final bool alternate;

  const _BillRow({required this.bill, required this.alternate});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: alternate ? DueReportColors.rowAlt : DueReportColors.panelBg,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.billNo, style: DueReportStyles.rowTitle),
                const SizedBox(height: 2),
                _BillStatusText(bill: bill),
              ],
            ),
          ),
          _amountCell(
            DueReportController.formatShortDate(bill.billDate),
            2,
            DueReportColors.textSecondary,
          ),
          _amountCell(
            DueReportController.formatCompact(bill.finalAmount),
            2,
            DueReportColors.textPrimary,
          ),
          _amountCell(
            DueReportController.formatCompact(bill.paidAmount),
            2,
            DueReportColors.success,
          ),
          _amountCell(
            DueReportController.formatCompact(bill.dueAmount),
            2,
            DueReportColors.danger,
          ),
          Expanded(
            flex: 2,
            child: Center(child: _PromiseBadge(bill: bill)),
          ),
        ],
      ),
    );
  }

  Widget _amountCell(String text, int flex, Color color) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: DueReportStyles.rowSub.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _CompactBillCard extends StatelessWidget {
  final DueBillModel bill;
  const _CompactBillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DueReportStyles.flatPanel(color: DueReportColors.panelSoft),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(bill.billNo, style: DueReportStyles.rowTitle),
              ),
              _PromiseBadge(bill: bill),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DueReportController.formatDate(bill.billDate),
            style: DueReportStyles.muted,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniAmount(
                label: 'Final',
                value: bill.finalAmount,
                color: DueReportColors.textSecondary,
              ),
              _MiniAmount(
                label: 'Paid',
                value: bill.paidAmount,
                color: DueReportColors.success,
              ),
              _MiniAmount(
                label: 'Due',
                value: bill.dueAmount,
                color: DueReportColors.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAmount extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MiniAmount({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: DueReportStyles.muted.copyWith(fontSize: 10)),
          const SizedBox(height: 3),
          Text(
            DueReportController.formatCompact(value),
            style: DueReportStyles.rowTitle.copyWith(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillStatusText extends StatelessWidget {
  final DueBillModel bill;
  const _BillStatusText({required this.bill});

  @override
  Widget build(BuildContext context) {
    final color =
        bill.isUnpaid ? DueReportColors.danger : DueReportColors.warning;
    return Text(
      bill.statusLabel,
      style: DueReportStyles.rowSub.copyWith(
        color: color,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _PromiseBadge extends StatelessWidget {
  final DueBillModel bill;
  const _PromiseBadge({required this.bill});

  @override
  Widget build(BuildContext context) {
    final config = _config();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.soft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: config.accent.withValues(alpha: 0.2)),
      ),
      child: Text(
        config.label,
        style: DueReportStyles.label.copyWith(
          color: config.accent,
          fontSize: 10,
        ),
      ),
    );
  }

  _PromiseConfig _config() {
    if (bill.isOverdue) {
      return _PromiseConfig(
        '${bill.promiseOverdueDays}d late',
        DueReportColors.danger,
        DueReportColors.dangerSoft,
      );
    }
    if (bill.isDueToday) {
      return const _PromiseConfig(
        'Today',
        DueReportColors.warning,
        DueReportColors.warningSoft,
      );
    }
    if (bill.promiseDate == null) {
      return const _PromiseConfig(
        'No date',
        DueReportColors.textMuted,
        DueReportColors.panelSoft,
      );
    }
    return _PromiseConfig(
      DueReportController.formatShortDate(bill.promiseDate!),
      DueReportColors.success,
      DueReportColors.successSoft,
    );
  }
}

class _NoSelection extends StatelessWidget {
  const _NoSelection();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: DueReportColors.indigoSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              DueReportIcons.bill,
              color: DueReportColors.indigo,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Select a customer', style: DueReportStyles.sectionTitle),
          const SizedBox(height: 6),
          const Text(
            'Bill-wise due details will appear here.',
            style: DueReportStyles.muted,
          ),
        ],
      ),
    );
  }
}

class _PromiseConfig {
  final String label;
  final Color accent;
  final Color soft;

  const _PromiseConfig(this.label, this.accent, this.soft);
}

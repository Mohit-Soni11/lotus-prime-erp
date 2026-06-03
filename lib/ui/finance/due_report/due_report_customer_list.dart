import 'package:flutter/material.dart';

import '../../../logic/finance/due_report/due_report_controller.dart';
import '../../../models/finance/due_report/due_report_model.dart';
import '../../../theme/finance/due_report/due_report_theme.dart';

class DueReportCustomerList extends StatelessWidget {
  final DueReportController ctrl;

  const DueReportCustomerList({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DueReportStyles.panel(),
      child: Column(
        children: [
          _Header(ctrl: ctrl),
          const Divider(height: 1, color: DueReportColors.divider),
          Expanded(child: _Body(ctrl: ctrl)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final DueReportController ctrl;
  const _Header({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(
            DueReportIcons.customers,
            color: DueReportColors.info,
            size: 20,
          ),
          const SizedBox(width: 9),
          const Text(
            DueReportStrings.customerLedger,
            style: DueReportStyles.sectionTitle,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: DueReportColors.infoSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DueReportColors.info.withValues(alpha: 0.14),
              ),
            ),
            child: Text(
              '${ctrl.groups.length} shown',
              style: DueReportStyles.label.copyWith(
                color: DueReportColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final DueReportController ctrl;
  const _Body({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.isLoading) return const _LoadingRows();
    if (ctrl.errorMessage != null) return _Error(message: ctrl.errorMessage!);
    if (ctrl.groups.isEmpty) return const _Empty();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        if (compact) {
          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: ctrl.groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final group = ctrl.groups[index];
              return _CompactTile(
                group: group,
                selected: group.key == ctrl.selectedGroup?.key,
                onTap: () => ctrl.selectGroup(group),
              );
            },
          );
        }

        return Column(
          children: [
            const _TableHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: ctrl.groups.length,
                itemBuilder: (_, index) {
                  final group = ctrl.groups[index];
                  return _CustomerRow(
                    group: group,
                    selected: group.key == ctrl.selectedGroup?.key,
                    alternate: index.isOdd,
                    onTap: () => ctrl.selectGroup(group),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      color: DueReportColors.panelSoft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          _cell('Customer', flex: 4),
          _cell('Status', flex: 2, center: true),
          _cell('Bills', flex: 1, center: true),
          _cell('Due Amount', flex: 2, center: true),
          _cell('Oldest', flex: 2, center: true),
          _cell('Promise', flex: 2, center: true),
          _cell('', flex: 1, center: true),
        ],
      ),
    );
  }

  Widget _cell(String text, {required int flex, bool center = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: DueReportStyles.tableHeader,
      ),
    );
  }
}

class _CustomerRow extends StatefulWidget {
  final DueCustomerGroupModel group;
  final bool selected;
  final bool alternate;
  final VoidCallback onTap;

  const _CustomerRow({
    required this.group,
    required this.selected,
    required this.alternate,
    required this.onTap,
  });

  @override
  State<_CustomerRow> createState() => _CustomerRowState();
}

class _CustomerRowState extends State<_CustomerRow> {
  bool _hover = false;

  void _setHover(bool value) {
    if (!mounted || _hover == value) return;
    setState(() => _hover = value);
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final bg = widget.selected
        ? DueReportColors.rowSelected
        : _hover
            ? DueReportColors.rowHover
            : widget.alternate
                ? DueReportColors.rowAlt
                : DueReportColors.panelBg;

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
              Expanded(flex: 4, child: _CustomerCell(group: group)),
              Expanded(
                flex: 2,
                child: Center(child: _StatusBadge(group: group)),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    group.billCount.toString(),
                    style: DueReportStyles.rowTitle,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    DueReportController.formatCompact(group.totalDue),
                    style: DueReportStyles.amountDanger.copyWith(fontSize: 14),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    DueReportController.formatShortDate(group.oldestBillDate),
                    style: DueReportStyles.rowSub,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(child: _PromiseText(group: group)),
              ),
              const Expanded(
                flex: 1,
                child: Center(
                  child: Icon(
                    DueReportIcons.arrow,
                    size: 20,
                    color: DueReportColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactTile extends StatelessWidget {
  final DueCustomerGroupModel group;
  final bool selected;
  final VoidCallback onTap;

  const _CompactTile({
    required this.group,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: DueReportStyles.flatPanel(
          color:
              selected ? DueReportColors.rowSelected : DueReportColors.panelBg,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _CustomerCell(group: group)),
                _StatusBadge(group: group),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  DueReportController.formatCompact(group.totalDue),
                  style: DueReportStyles.amountDanger.copyWith(fontSize: 16),
                ),
                const Spacer(),
                Text('${group.billCount} bills', style: DueReportStyles.label),
                const SizedBox(width: 12),
                _PromiseText(group: group),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCell extends StatelessWidget {
  final DueCustomerGroupModel group;
  const _CustomerCell({required this.group});

  @override
  Widget build(BuildContext context) {
    final initial = group.customerName.isNotEmpty
        ? group.customerName[0].toUpperCase()
        : '?';
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: DueReportColors.indigoSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: DueReportColors.indigo.withValues(alpha: 0.16),
            ),
          ),
          child: Center(
            child: Text(
              initial,
              style: DueReportStyles.rowTitle.copyWith(
                color: DueReportColors.indigo,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.customerName,
                style: DueReportStyles.rowTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                _subLine(group),
                style: DueReportStyles.rowSub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _subLine(DueCustomerGroupModel group) {
    final city = group.city.trim().isEmpty ? 'No city' : group.city;
    return '${group.mobile} | $city';
  }
}

class _StatusBadge extends StatelessWidget {
  final DueCustomerGroupModel group;
  const _StatusBadge({required this.group});

  @override
  Widget build(BuildContext context) {
    final config = _config();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: config.soft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.accent.withValues(alpha: 0.2)),
      ),
      child: Text(
        config.label,
        style: DueReportStyles.label.copyWith(
          color: config.accent,
          fontSize: 11,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  _BadgeConfig _config() {
    if (group.hasOverdue) {
      return const _BadgeConfig(
        'OVERDUE',
        DueReportColors.danger,
        DueReportColors.dangerSoft,
      );
    }
    if (group.hasDueToday) {
      return const _BadgeConfig(
        'TODAY',
        DueReportColors.warning,
        DueReportColors.warningSoft,
      );
    }
    if (group.noPromiseBillCount == group.billCount) {
      return const _BadgeConfig(
        'NO DATE',
        DueReportColors.textMuted,
        DueReportColors.panelSoft,
      );
    }
    return const _BadgeConfig(
      'PROMISED',
      DueReportColors.success,
      DueReportColors.successSoft,
    );
  }
}

class _PromiseText extends StatelessWidget {
  final DueCustomerGroupModel group;
  const _PromiseText({required this.group});

  @override
  Widget build(BuildContext context) {
    if (group.nearestPromiseDate == null) {
      return const Text('No date', style: DueReportStyles.rowSub);
    }
    final color = group.hasOverdue
        ? DueReportColors.danger
        : group.hasDueToday
            ? DueReportColors.warning
            : DueReportColors.textSecondary;
    return Text(
      DueReportController.formatShortDate(group.nearestPromiseDate!),
      style: DueReportStyles.rowSub.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _LoadingRows extends StatelessWidget {
  const _LoadingRows();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 8,
      itemBuilder: (_, __) => Container(
        height: 58,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: DueReportStyles.flatPanel(color: DueReportColors.panelSoft),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

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
              color: DueReportColors.successSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              DueReportIcons.empty,
              color: DueReportColors.success,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            DueReportStrings.emptyTitle,
            style: DueReportStyles.sectionTitle,
          ),
          const SizedBox(height: 6),
          const Text(
            DueReportStrings.emptySubtitle,
            style: DueReportStyles.muted,
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String message;
  const _Error({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: DueReportStyles.sectionTitle.copyWith(
          color: DueReportColors.danger,
        ),
      ),
    );
  }
}

class _BadgeConfig {
  final String label;
  final Color accent;
  final Color soft;

  const _BadgeConfig(this.label, this.accent, this.soft);
}

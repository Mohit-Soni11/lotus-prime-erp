import 'package:flutter/material.dart';

import '../../../../models/reports/sales_report/sales_report_models.dart';
import '../../../../theme/reports/sales_report/sales_report_theme.dart';
import '../sales_report_formatters.dart';

class SalesReportItemLedger extends StatelessWidget {
  final List<SalesReportItemRow> items;

  const SalesReportItemLedger({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: SalesReportStyles.panel(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _LedgerHeader(
            title: 'Sales Item Ledger',
            subtitle: 'Item-wise HUID, purity, weight, rate and value audit',
            icon: Icons.inventory_2_rounded,
          ),
          if (items.isEmpty)
            const _EmptyLedger(message: 'No item rows found.')
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowHeight: 46,
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 68,
                      columnSpacing: 24,
                      horizontalMargin: 24,
                      headingTextStyle: SalesReportStyles.body.copyWith(
                        color: SalesReportColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                      dataTextStyle: SalesReportStyles.body.copyWith(
                        color: SalesReportColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      columns: const [
                        DataColumn(label: _ColumnLabel('S. No.')),
                        DataColumn(label: _ColumnLabel('Bill No')),
                        DataColumn(label: _ColumnLabel('Customer')),
                        DataColumn(label: _ColumnLabel('Metal')),
                        DataColumn(label: _ColumnLabel('Item Name')),
                        DataColumn(label: _ColumnLabel('HUID')),
                        DataColumn(label: _ColumnLabel('Purity')),
                        DataColumn(label: _ColumnLabel('Qty'), numeric: true),
                        DataColumn(
                            label: _ColumnLabel('Gross Wt'), numeric: true),
                        DataColumn(
                            label: _ColumnLabel('Less Wt'), numeric: true),
                        DataColumn(
                            label: _ColumnLabel('Net Wt'), numeric: true),
                        DataColumn(label: _ColumnLabel('Rate'), numeric: true),
                        DataColumn(
                            label: _ColumnLabel('Making'), numeric: true),
                        DataColumn(
                            label: _ColumnLabel('Line Total'), numeric: true),
                      ],
                      rows: _buildRows(),
                    ),
                  ),
                );
              },
            ),
            _ItemTotalsBar(items: items),
          ],
        ],
      ),
    );
  }

  List<DataRow> _buildRows() {
    return [
      for (var index = 0; index < items.length; index++)
        _buildRow(items[index], index),
    ];
  }

  DataRow _buildRow(SalesReportItemRow item, int index) {
    return DataRow(
      cells: [
        DataCell(_LedgerText('${index + 1}')),
        DataCell(_LedgerText(item.billNo, fontWeight: FontWeight.w900)),
        DataCell(_LedgerText(item.customerName)),
        DataCell(_LedgerText(item.metalType)),
        DataCell(_LedgerText(item.itemName)),
        DataCell(_HuidCell(item.huid)),
        DataCell(_LedgerText(item.purity)),
        DataCell(_LedgerText('${item.quantity}', alignRight: true)),
        DataCell(_LedgerText(
          salesReportWeight(item.grossWeight),
          alignRight: true,
        )),
        DataCell(_LedgerText(
          salesReportWeight(item.lessWeight),
          alignRight: true,
        )),
        DataCell(_LedgerText(
          salesReportWeight(item.netWeight),
          alignRight: true,
          fontWeight: FontWeight.w900,
        )),
        DataCell(_LedgerText(
          salesReportMoney(item.rate),
          alignRight: true,
        )),
        DataCell(_LedgerText(
          salesReportMoney(item.makingCharge),
          alignRight: true,
        )),
        DataCell(_LedgerText(
          salesReportMoney(item.itemTotal),
          alignRight: true,
          fontWeight: FontWeight.w900,
        )),
      ],
    );
  }
}

class _ItemTotalsBar extends StatelessWidget {
  final List<SalesReportItemRow> items;

  const _ItemTotalsBar({required this.items});

  @override
  Widget build(BuildContext context) {
    final pieces = items.fold<int>(0, (total, item) => total + item.quantity);
    final gross = _sum((item) => item.grossWeight);
    final net = _sum((item) => item.netWeight);
    final making = _sum((item) => item.makingCharge);
    final total = _sum((item) => item.itemTotal);

    return _TotalsStrip(
      children: [
        _TotalTile(label: 'Item Lines', value: '${items.length}'),
        _TotalTile(label: 'Total Qty', value: '$pieces'),
        _TotalTile(label: 'Gross Wt', value: salesReportWeight(gross)),
        _TotalTile(label: 'Net Wt', value: salesReportWeight(net)),
        _TotalTile(label: 'Making Value', value: salesReportMoney(making)),
        _TotalTile(
          label: 'Line Total',
          value: salesReportMoney(total),
          emphasized: true,
        ),
      ],
    );
  }

  double _sum(double Function(SalesReportItemRow item) selector) {
    return items.fold<double>(0, (total, item) => total + selector(item));
  }
}

class _LedgerHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _LedgerHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Icon(icon, color: SalesReportColors.brandGold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SalesReportStyles.pageTitle.copyWith(
                    color: SalesReportColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: SalesReportStyles.body.copyWith(
                    color: SalesReportColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HuidCell extends StatelessWidget {
  final String huid;

  const _HuidCell(this.huid);

  @override
  Widget build(BuildContext context) {
    final value = huid.isEmpty ? 'Not Linked' : huid;
    return SizedBox(
      width: 120,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: SalesReportStyles.body.copyWith(
          color: SalesReportColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ColumnLabel extends StatelessWidget {
  final String value;

  const _ColumnLabel(this.value);

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: SalesReportStyles.body.copyWith(
        color: SalesReportColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _LedgerText extends StatelessWidget {
  final String value;
  final bool alignRight;
  final FontWeight fontWeight;

  const _LedgerText(
    this.value, {
    this.alignRight = false,
    this.fontWeight = FontWeight.w800,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: SalesReportStyles.body.copyWith(
        fontSize: 14,
        fontWeight: fontWeight,
        color: SalesReportColors.textPrimary,
      ),
    );
  }
}

class _TotalsStrip extends StatelessWidget {
  final List<Widget> children;

  const _TotalsStrip({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: SalesReportColors.bodySubtle,
        border: Border(
          top: BorderSide(
            color: SalesReportColors.bodyBorder.withValues(alpha: 0.9),
          ),
        ),
      ),
      child: Wrap(spacing: 10, runSpacing: 10, children: children),
    );
  }
}

class _TotalTile extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _TotalTile({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = emphasized
        ? SalesReportColors.brandGold
        : SalesReportColors.textPrimary;
    return Container(
      constraints: const BoxConstraints(minWidth: 148, minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: emphasized
            ? SalesReportColors.goldGradientStart.withValues(alpha: 0.12)
            : SalesReportColors.bodyPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: emphasized
              ? SalesReportColors.brandGold.withValues(alpha: 0.35)
              : SalesReportColors.bodyBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: SalesReportStyles.body.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: SalesReportStyles.pageTitle.copyWith(
                color: accent,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLedger extends StatelessWidget {
  final String message;

  const _EmptyLedger({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(message, style: SalesReportStyles.body)),
    );
  }
}

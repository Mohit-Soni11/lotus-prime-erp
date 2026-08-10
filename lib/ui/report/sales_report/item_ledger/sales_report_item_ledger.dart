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
            title: 'Item Ledger',
            subtitle: 'HUID, purity, weight, rate, making and item total',
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
                      headingRowHeight: 42,
                      dataRowMinHeight: 52,
                      dataRowMaxHeight: 58,
                      columnSpacing: 26,
                      horizontalMargin: 24,
                      columns: const [
                        DataColumn(label: Text('S.No')),
                        DataColumn(label: Text('Invoice')),
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Metal')),
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('HUID')),
                        DataColumn(label: Text('Purity')),
                        DataColumn(label: Text('Pcs'), numeric: true),
                        DataColumn(label: Text('Gross'), numeric: true),
                        DataColumn(label: Text('Less'), numeric: true),
                        DataColumn(label: Text('Net'), numeric: true),
                        DataColumn(label: Text('Rate'), numeric: true),
                        DataColumn(label: Text('Making'), numeric: true),
                        DataColumn(label: Text('Total'), numeric: true),
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
        DataCell(Text('${index + 1}')),
        DataCell(_StrongText(item.billNo)),
        DataCell(Text(item.customerName)),
        DataCell(Text(item.metalType)),
        DataCell(Text(item.itemName)),
        DataCell(_HuidCell(item.huid)),
        DataCell(Text(item.purity)),
        DataCell(Text('${item.quantity}')),
        DataCell(Text(salesReportWeight(item.grossWeight))),
        DataCell(Text(salesReportWeight(item.lessWeight))),
        DataCell(_StrongText(salesReportWeight(item.netWeight))),
        DataCell(Text(salesReportMoney(item.rate))),
        DataCell(Text(salesReportMoney(item.makingCharge))),
        DataCell(_StrongText(salesReportMoney(item.itemTotal))),
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
        _TotalTile(label: 'Items', value: '${items.length}'),
        _TotalTile(label: 'Pieces', value: '$pieces'),
        _TotalTile(label: 'Gross Weight', value: salesReportWeight(gross)),
        _TotalTile(label: 'Net Weight', value: salesReportWeight(net)),
        _TotalTile(label: 'Making', value: salesReportMoney(making)),
        _TotalTile(
          label: 'Item Total',
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
                  style: SalesReportStyles.pageTitle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: SalesReportStyles.body),
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
      ),
    );
  }
}

class _StrongText extends StatelessWidget {
  final String value;

  const _StrongText(this.value);

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
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
    final accent =
        emphasized ? SalesReportColors.brandGold : SalesReportColors.textMuted;
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
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: SalesReportStyles.pageTitle.copyWith(fontSize: 17),
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

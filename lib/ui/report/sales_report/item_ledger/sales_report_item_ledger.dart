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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _LedgerHeader(
            title: 'Item Ledger',
            subtitle: 'HUID, purity, weight, making, stock cost and profit',
            icon: Icons.inventory_2_rounded,
          ),
          if (items.isEmpty)
            const _EmptyLedger(message: 'No item rows found.')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 42,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 58,
                columns: const [
                  DataColumn(label: Text('Invoice')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Metal')),
                  DataColumn(label: Text('Item')),
                  DataColumn(label: Text('HUID / SKU')),
                  DataColumn(label: Text('Purity')),
                  DataColumn(label: Text('Pcs'), numeric: true),
                  DataColumn(label: Text('Gross'), numeric: true),
                  DataColumn(label: Text('Less'), numeric: true),
                  DataColumn(label: Text('Net'), numeric: true),
                  DataColumn(label: Text('Rate'), numeric: true),
                  DataColumn(label: Text('Making'), numeric: true),
                  DataColumn(label: Text('Total'), numeric: true),
                  DataColumn(label: Text('Cost'), numeric: true),
                  DataColumn(label: Text('Profit'), numeric: true),
                ],
                rows: [
                  for (final item in items)
                    DataRow(
                      cells: [
                        DataCell(_StrongText(item.billNo)),
                        DataCell(Text(item.customerName)),
                        DataCell(Text(item.metalType)),
                        DataCell(Text(item.itemName)),
                        DataCell(_HuidSkuCell(item)),
                        DataCell(Text(item.purity)),
                        DataCell(Text('${item.quantity}')),
                        DataCell(Text(salesReportWeight(item.grossWeight))),
                        DataCell(Text(salesReportWeight(item.lessWeight))),
                        DataCell(
                            _StrongText(salesReportWeight(item.netWeight))),
                        DataCell(Text(salesReportMoney(item.rate))),
                        DataCell(Text(salesReportMoney(item.makingCharge))),
                        DataCell(_StrongText(salesReportMoney(item.itemTotal))),
                        DataCell(Text(salesReportMoney(item.stockCostAmount))),
                        DataCell(Text(
                          salesReportMoney(item.profitAmount),
                          style: TextStyle(
                            color: item.profitAmount >= 0
                                ? SalesReportColors.positive
                                : const Color(0xFFC63F3F),
                            fontWeight: FontWeight.w800,
                          ),
                        )),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
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
                Text(title,
                    style: SalesReportStyles.pageTitle.copyWith(fontSize: 18)),
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

class _HuidSkuCell extends StatelessWidget {
  final SalesReportItemRow item;

  const _HuidSkuCell(this.item);

  @override
  Widget build(BuildContext context) {
    final top = item.huid.isEmpty ? 'Not Linked' : item.huid;
    final bottom = item.stockSku.isEmpty ? 'No SKU' : item.stockSku;
    return SizedBox(
      width: 140,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(top, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            bottom,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, color: SalesReportColors.textMuted),
          ),
        ],
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

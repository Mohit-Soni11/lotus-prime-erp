import 'package:flutter/material.dart';

import '../../../../models/reports/sales_report/sales_report_models.dart';
import '../../../../theme/reports/sales_report/sales_report_theme.dart';
import '../sales_report_formatters.dart';

class SalesReportInvoiceLedger extends StatelessWidget {
  final List<SalesReportInvoiceRow> invoices;
  final List<SalesReportItemRow> items;

  const SalesReportInvoiceLedger({
    super.key,
    required this.invoices,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final weightIndex = _MetalWeightIndex(items);

    return Container(
      decoration: SalesReportStyles.panel(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _LedgerHeader(
            title: 'Invoice Ledger',
            subtitle: 'Bill-wise taxable, GST, discount and final amount audit',
            icon: Icons.receipt_long_rounded,
          ),
          if (invoices.isEmpty)
            const _EmptyLedger(message: 'No invoices found.')
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
                      dataRowMaxHeight: 74,
                      columnSpacing: 26,
                      horizontalMargin: 24,
                      columns: const [
                        DataColumn(label: Text('S.No')),
                        DataColumn(label: Text('Invoice')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Metal')),
                        DataColumn(label: Text('Metal Weight')),
                        DataColumn(label: Text('Gross'), numeric: true),
                        DataColumn(label: Text('Discount'), numeric: true),
                        DataColumn(label: Text('Taxable'), numeric: true),
                        DataColumn(label: Text('GST'), numeric: true),
                        DataColumn(label: Text('Round Off'), numeric: true),
                        DataColumn(label: Text('Final'), numeric: true),
                      ],
                      rows: _buildRows(weightIndex),
                    ),
                  ),
                );
              },
            ),
            _InvoiceTotalsBar(invoices: invoices, items: items),
          ],
        ],
      ),
    );
  }

  List<DataRow> _buildRows(_MetalWeightIndex weightIndex) {
    return [
      for (var index = 0; index < invoices.length; index++)
        _buildRow(invoices[index], index, weightIndex),
    ];
  }

  DataRow _buildRow(
    SalesReportInvoiceRow invoice,
    int index,
    _MetalWeightIndex weightIndex,
  ) {
    return DataRow(
      cells: [
        DataCell(Text('${index + 1}')),
        DataCell(_StrongText(invoice.billNo)),
        DataCell(Text(salesReportDateTime(invoice.billDate))),
        DataCell(_CustomerCell(invoice)),
        DataCell(_TypeBadge(isGst: invoice.isGst)),
        DataCell(Text(invoice.metalMix.replaceAll(',', ' / '))),
        DataCell(
            _MetalWeightCell(weights: weightIndex.forBill(invoice.billId))),
        DataCell(Text(salesReportMoney(invoice.grossAmount))),
        DataCell(Text(salesReportMoney(invoice.discountAmount))),
        DataCell(Text(salesReportMoney(invoice.taxableAmount))),
        DataCell(Text(salesReportMoney(invoice.gstAmount))),
        DataCell(Text(salesReportMoney(invoice.roundOffAmount))),
        DataCell(_StrongText(
          salesReportMoney(invoice.finalAmount),
          alignRight: true,
        )),
      ],
    );
  }
}

class _InvoiceTotalsBar extends StatelessWidget {
  final List<SalesReportInvoiceRow> invoices;
  final List<SalesReportItemRow> items;

  const _InvoiceTotalsBar({required this.invoices, required this.items});

  @override
  Widget build(BuildContext context) {
    final gross = _sum((invoice) => invoice.grossAmount);
    final discount = _sum((invoice) => invoice.discountAmount);
    final taxable = _sum((invoice) => invoice.taxableAmount);
    final gst = _sum((invoice) => invoice.gstAmount);
    final finalAmount = _sum((invoice) => invoice.finalAmount);
    final metalWeights = _MetalWeightIndex(items).totals;
    final totalWeight = metalWeights.values.fold<double>(
      0,
      (total, weight) => total + weight,
    );

    return _TotalsStrip(
      children: [
        _TotalTile(label: 'Invoices', value: '${invoices.length}'),
        for (final entry in metalWeights.entries)
          _TotalTile(
            label: '${entry.key} Net Wt',
            value: salesReportWeight(entry.value),
          ),
        _TotalTile(
            label: 'Total Net Wt', value: salesReportWeight(totalWeight)),
        _TotalTile(label: 'Gross', value: salesReportMoney(gross)),
        _TotalTile(label: 'Discount', value: salesReportMoney(discount)),
        _TotalTile(label: 'Taxable', value: salesReportMoney(taxable)),
        _TotalTile(label: 'GST', value: salesReportMoney(gst)),
        _TotalTile(
          label: 'Final Total',
          value: salesReportMoney(finalAmount),
          emphasized: true,
        ),
      ],
    );
  }

  double _sum(double Function(SalesReportInvoiceRow invoice) selector) {
    return invoices.fold<double>(
      0,
      (total, invoice) => total + selector(invoice),
    );
  }
}

class _MetalWeightCell extends StatelessWidget {
  final Map<String, double> weights;

  const _MetalWeightCell({required this.weights});

  @override
  Widget build(BuildContext context) {
    if (weights.isEmpty) {
      return const Text(
        '-',
        style: TextStyle(color: SalesReportColors.textMuted),
      );
    }

    return SizedBox(
      width: 170,
      child: Wrap(
        spacing: 6,
        runSpacing: 5,
        children: [
          for (final entry in weights.entries)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: SalesReportColors.goldGradientStart.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: SalesReportColors.brandGold.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                '${entry.key} ${salesReportWeight(entry.value)}',
                style: SalesReportStyles.body.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: SalesReportColors.textPrimary,
                ),
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

class _MetalWeightIndex {
  final Map<int, Map<String, double>> _byBill;
  final Map<String, double> totals;

  _MetalWeightIndex(List<SalesReportItemRow> items)
      : _byBill = _buildByBill(items),
        totals = _buildTotals(items);

  Map<String, double> forBill(int billId) {
    return _byBill[billId] ?? const {};
  }

  static Map<int, Map<String, double>> _buildByBill(
    List<SalesReportItemRow> items,
  ) {
    final grouped = <int, Map<String, double>>{};
    for (final item in items) {
      final metal = _displayMetal(item.metalType);
      if (metal.isEmpty) continue;
      final billWeights = grouped.putIfAbsent(item.billId, () => {});
      billWeights[metal] = (billWeights[metal] ?? 0) + item.netWeight;
    }
    return {
      for (final entry in grouped.entries) entry.key: _sortWeights(entry.value),
    };
  }

  static Map<String, double> _buildTotals(List<SalesReportItemRow> items) {
    final totals = <String, double>{};
    for (final item in items) {
      final metal = _displayMetal(item.metalType);
      if (metal.isEmpty) continue;
      totals[metal] = (totals[metal] ?? 0) + item.netWeight;
    }
    return _sortWeights(totals);
  }

  static Map<String, double> _sortWeights(Map<String, double> source) {
    final entries = source.entries.toList()
      ..sort((a, b) {
        final priority = _metalPriority(a.key).compareTo(_metalPriority(b.key));
        if (priority != 0) return priority;
        return a.key.compareTo(b.key);
      });
    return Map<String, double>.fromEntries(entries);
  }

  static int _metalPriority(String metal) {
    switch (metal.toLowerCase()) {
      case 'gold':
        return 0;
      case 'silver':
        return 1;
      case 'platinum':
        return 2;
      case 'diamond':
        return 3;
      default:
        return 10;
    }
  }

  static String _displayMetal(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final lower = trimmed.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}

class _CustomerCell extends StatelessWidget {
  final SalesReportInvoiceRow invoice;

  const _CustomerCell(this.invoice);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            invoice.customerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (invoice.mobile.isNotEmpty)
            Text(
              invoice.mobile,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: SalesReportColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final bool isGst;

  const _TypeBadge({required this.isGst});

  @override
  Widget build(BuildContext context) {
    final color =
        isGst ? SalesReportColors.onlineGreen : SalesReportColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        isGst ? 'GST' : 'NON-GST',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StrongText extends StatelessWidget {
  final String value;
  final bool alignRight;

  const _StrongText(this.value, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
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

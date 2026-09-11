import 'package:flutter/material.dart';

import '../../../../models/reports/sales_report/sales_report_models.dart';
import '../../../../theme/reports/sales_report/sales_report_theme.dart';
import '../sales_report_formatters.dart';

const Color _invoiceLedgerDueColor = Color(0xFFB91C1C);

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
    final hasDue = invoices.any((invoice) => invoice.dueAmount.abs() > 0.005);

    return Container(
      decoration: SalesReportStyles.panel(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _LedgerHeader(
            title: 'Sales Invoice Ledger',
            subtitle:
                'Invoice-wise customer, metal, sale value, GST and due audit',
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
                      headingRowHeight: 46,
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 78,
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
                      columns: _buildColumns(hasDue: hasDue),
                      rows: _buildRows(weightIndex, hasDue: hasDue),
                    ),
                  ),
                );
              },
            ),
            _InvoiceTotalsBar(
              invoices: invoices,
              items: items,
              hasDue: hasDue,
            ),
          ],
        ],
      ),
    );
  }

  List<DataColumn> _buildColumns({required bool hasDue}) {
    return [
      const DataColumn(label: _ColumnLabel('S. No.')),
      const DataColumn(label: _ColumnLabel('Bill No')),
      const DataColumn(label: _ColumnLabel('Date')),
      const DataColumn(label: _ColumnLabel('Customer')),
      const DataColumn(label: _ColumnLabel('Bill Type')),
      const DataColumn(label: _ColumnLabel('Metal')),
      const DataColumn(label: _ColumnLabel('Net Weight')),
      const DataColumn(label: _ColumnLabel('Sale Amount'), numeric: true),
      const DataColumn(label: _ColumnLabel('Discount'), numeric: true),
      const DataColumn(label: _ColumnLabel('GST'), numeric: true),
      const DataColumn(label: _ColumnLabel('Net Total'), numeric: true),
      if (hasDue)
        const DataColumn(
          label: _ColumnLabel('Due Amount', isDue: true),
          numeric: true,
        ),
    ];
  }

  List<DataRow> _buildRows(
    _MetalWeightIndex weightIndex, {
    required bool hasDue,
  }) {
    return [
      for (var index = 0; index < invoices.length; index++)
        _buildRow(
          invoices[index],
          index,
          weightIndex,
          hasDue: hasDue,
        ),
    ];
  }

  DataRow _buildRow(
    SalesReportInvoiceRow invoice,
    int index,
    _MetalWeightIndex weightIndex, {
    required bool hasDue,
  }) {
    return DataRow(
      cells: [
        DataCell(_LedgerText('${index + 1}')),
        DataCell(_LedgerText(invoice.billNo, fontWeight: FontWeight.w900)),
        DataCell(_LedgerText(salesReportDateTime(invoice.billDate))),
        DataCell(_CustomerCell(invoice)),
        DataCell(_TypeBadge(isGst: invoice.isGst)),
        DataCell(_LedgerText(invoice.metalMix.replaceAll(',', ' / '))),
        DataCell(
            _MetalWeightCell(weights: weightIndex.forBill(invoice.billId))),
        DataCell(_LedgerText(
          salesReportMoney(invoice.grossAmount),
          alignRight: true,
        )),
        DataCell(_LedgerText(
          salesReportMoney(invoice.discountAmount),
          alignRight: true,
        )),
        DataCell(_LedgerText(
          salesReportMoney(invoice.gstAmount),
          alignRight: true,
        )),
        DataCell(_LedgerText(
          salesReportMoney(invoice.finalAmount),
          alignRight: true,
        )),
        if (hasDue)
          DataCell(_LedgerText(
            salesReportMoney(invoice.dueAmount),
            alignRight: true,
            color: _invoiceLedgerDueColor,
            fontWeight: FontWeight.w900,
          )),
      ],
    );
  }
}

class _InvoiceTotalsBar extends StatelessWidget {
  final List<SalesReportInvoiceRow> invoices;
  final List<SalesReportItemRow> items;
  final bool hasDue;

  const _InvoiceTotalsBar({
    required this.invoices,
    required this.items,
    required this.hasDue,
  });

  @override
  Widget build(BuildContext context) {
    final gross = _sum((invoice) => invoice.grossAmount);
    final discount = _sum((invoice) => invoice.discountAmount);
    final gst = _sum((invoice) => invoice.gstAmount);
    final finalAmount = _sum((invoice) => invoice.finalAmount);
    final due = _sum((invoice) => invoice.dueAmount);
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
        _TotalTile(label: 'Sale Amount', value: salesReportMoney(gross)),
        _TotalTile(label: 'Discount', value: salesReportMoney(discount)),
        _TotalTile(label: 'GST', value: salesReportMoney(gst)),
        _TotalTile(
          label: 'Net Total',
          value: salesReportMoney(finalAmount),
          emphasized: true,
        ),
        if (hasDue)
          _TotalTile(
            label: 'Due Amount',
            value: salesReportMoney(due),
            accent: _invoiceLedgerDueColor,
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
        style: TextStyle(
          color: SalesReportColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
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
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
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
      width: 220,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            invoice.customerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalesReportStyles.body.copyWith(
              color: SalesReportColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (invoice.mobile.isNotEmpty)
            Text(
              'Mobile: ${invoice.mobile}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SalesReportStyles.body.copyWith(
                color: SalesReportColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
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
        isGst ? SalesReportColors.onlineGreen : SalesReportColors.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        isGst ? 'GST BILL' : 'NORMAL',
        style: const TextStyle(
          color: SalesReportColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ColumnLabel extends StatelessWidget {
  final String value;
  final bool isDue;

  const _ColumnLabel(this.value, {this.isDue = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: SalesReportStyles.body.copyWith(
        color: isDue ? _invoiceLedgerDueColor : SalesReportColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _LedgerText extends StatelessWidget {
  final String value;
  final bool alignRight;
  final Color color;
  final FontWeight fontWeight;

  const _LedgerText(
    this.value, {
    this.alignRight = false,
    this.color = SalesReportColors.textPrimary,
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
        color: color,
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
  final Color? accent;
  final bool emphasized;

  const _TotalTile({
    required this.label,
    required this.value,
    this.accent,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accent ??
        (emphasized
            ? SalesReportColors.brandGold
            : SalesReportColors.textPrimary);
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
              color: effectiveAccent,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: SalesReportStyles.pageTitle.copyWith(
                color: effectiveAccent,
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

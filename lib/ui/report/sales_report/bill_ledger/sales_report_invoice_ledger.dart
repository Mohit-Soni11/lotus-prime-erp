import 'package:flutter/material.dart';

import '../../../../models/reports/sales_report/sales_report_models.dart';
import '../../../../theme/reports/sales_report/sales_report_theme.dart';
import '../sales_report_formatters.dart';

class SalesReportInvoiceLedger extends StatelessWidget {
  final List<SalesReportInvoiceRow> invoices;

  const SalesReportInvoiceLedger({super.key, required this.invoices});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: SalesReportStyles.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _LedgerHeader(
            title: 'Invoice Ledger',
            subtitle: 'Bill-wise sales, tax, payment and due audit',
            icon: Icons.receipt_long_rounded,
          ),
          if (invoices.isEmpty)
            const _EmptyLedger(message: 'No invoices found.')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 42,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 58,
                columns: const [
                  DataColumn(label: Text('Invoice')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Metal')),
                  DataColumn(label: Text('Gross'), numeric: true),
                  DataColumn(label: Text('Discount'), numeric: true),
                  DataColumn(label: Text('GST'), numeric: true),
                  DataColumn(label: Text('Round Off'), numeric: true),
                  DataColumn(label: Text('Final'), numeric: true),
                  DataColumn(label: Text('Paid'), numeric: true),
                  DataColumn(label: Text('Due'), numeric: true),
                  DataColumn(label: Text('Payment')),
                ],
                rows: [
                  for (final invoice in invoices)
                    DataRow(
                      cells: [
                        DataCell(_StrongText(invoice.billNo)),
                        DataCell(Text(salesReportDateTime(invoice.billDate))),
                        DataCell(_CustomerCell(invoice)),
                        DataCell(_TypeBadge(isGst: invoice.isGst)),
                        DataCell(Text(invoice.metalMix.replaceAll(',', ' / '))),
                        DataCell(Text(salesReportMoney(invoice.grossAmount))),
                        DataCell(
                            Text(salesReportMoney(invoice.discountAmount))),
                        DataCell(Text(salesReportMoney(invoice.gstAmount))),
                        DataCell(
                            Text(salesReportMoney(invoice.roundOffAmount))),
                        DataCell(_StrongText(
                          salesReportMoney(invoice.finalAmount),
                          alignRight: true,
                        )),
                        DataCell(Text(salesReportMoney(invoice.paidAmount))),
                        DataCell(Text(
                          salesReportMoney(invoice.dueAmount),
                          style: TextStyle(
                            color: invoice.dueAmount > 0.005
                                ? const Color(0xFFC63F3F)
                                : SalesReportColors.positive,
                            fontWeight: FontWeight.w800,
                          ),
                        )),
                        DataCell(Text(
                          'C ${salesReportMoney(invoice.cashAmount)} / '
                          'U ${salesReportMoney(invoice.upiAmount)} / '
                          'Card ${salesReportMoney(invoice.cardAmount)}',
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
                  fontSize: 12, color: SalesReportColors.textMuted),
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

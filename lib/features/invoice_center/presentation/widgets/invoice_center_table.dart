import 'package:flutter/material.dart';

import '../../domain/invoice_center_models.dart';
import '../invoice_center_style.dart';

enum InvoiceCenterRowAction { share, copyNumber }

class InvoiceCenterTable extends StatelessWidget {
  const InvoiceCenterTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onView,
    required this.onPrint,
    required this.onMore,
  });

  final List<InvoiceCenterRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<InvoiceCenterRow> onView;
  final ValueChanged<InvoiceCenterRow> onPrint;
  final void Function(InvoiceCenterRow, InvoiceCenterRowAction) onMore;

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: InvoiceCenterStyle.panel(),
        child: rows.isEmpty
            ? const SizedBox(
                height: 260,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 36, color: InvoiceCenterStyle.muted),
                      SizedBox(height: 12),
                      Text(
                        'No invoices match these filters.',
                        style: TextStyle(
                          color: InvoiceCenterStyle.muted,
                          fontSize: InvoiceCenterStyle.bodyTextSize,
                          fontWeight: InvoiceCenterStyle.bodyTextWeight,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: const WidgetStatePropertyAll(
                          InvoiceCenterStyle.header),
                      headingRowHeight: 50,
                      dataRowMinHeight: 58,
                      dataRowMaxHeight: 62,
                      horizontalMargin: 18,
                      columnSpacing: 24,
                      dividerThickness: 0.6,
                      headingTextStyle: const TextStyle(
                        color: InvoiceCenterStyle.ink,
                        fontSize: InvoiceCenterStyle.bodyTextSize,
                        fontWeight: FontWeight.w800,
                      ),
                      dataTextStyle: const TextStyle(
                        color: InvoiceCenterStyle.ink,
                        fontSize: InvoiceCenterStyle.bodyTextSize,
                        fontWeight: InvoiceCenterStyle.bodyTextWeight,
                      ),
                      columns: const [
                        DataColumn(label: Text('S. No.')),
                        DataColumn(label: Text('Invoice No.')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Customer Name')),
                        DataColumn(label: Text('Metal')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Total (₹)'), numeric: true),
                        DataColumn(label: Text('Paid (₹)'), numeric: true),
                        DataColumn(label: Text('Due (₹)'), numeric: true),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Action')),
                      ],
                      rows: [
                        for (var index = 0; index < rows.length; index++)
                          _buildRow(rows[index], index),
                      ],
                    ),
                  ),
                ),
              ),
      );

  DataRow _buildRow(InvoiceCenterRow row, int index) => DataRow(
        color: WidgetStatePropertyAll(
          index.isOdd ? InvoiceCenterStyle.rowAlternate : Colors.white,
        ),
        cells: [
          DataCell(Text('${(page - 1) * pageSize + index + 1}')),
          DataCell(
            Text(
              row.number,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          DataCell(Text(InvoiceCenterFormat.date(row.issuedAt))),
          DataCell(SizedBox(
            width: 150,
            child: Text(row.customerName,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          DataCell(SizedBox(
            width: 110,
            child: Text(
                row.metals.isEmpty ? '—' : row.metals.replaceAll(',', ', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          )),
          DataCell(_TypeChip(category: row.category)),
          DataCell(Text(InvoiceCenterFormat.money(row.total))),
          DataCell(Text(InvoiceCenterFormat.money(row.paid))),
          DataCell(Text(InvoiceCenterFormat.money(row.due))),
          DataCell(_StatusChip(status: row.status)),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: ValueKey('invoice-view-${row.kind.name}-${row.id}'),
                onPressed: () => onView(row),
                tooltip: 'View original PDF',
                color: InvoiceCenterStyle.ink,
                icon: const Icon(Icons.visibility_outlined, size: 20),
              ),
              IconButton(
                onPressed: () => onPrint(row),
                tooltip: 'Print original PDF',
                color: InvoiceCenterStyle.ink,
                icon: const Icon(Icons.print_outlined, size: 20),
              ),
              PopupMenuButton<InvoiceCenterRowAction>(
                tooltip: 'More invoice actions',
                iconColor: InvoiceCenterStyle.ink,
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onSelected: (action) => onMore(row, action),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: InvoiceCenterRowAction.share,
                    child: Text('Share original PDF'),
                  ),
                  PopupMenuItem(
                    value: InvoiceCenterRowAction.copyNumber,
                    child: Text('Copy invoice number'),
                  ),
                ],
              ),
            ],
          )),
        ],
      );
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.category});

  final InvoiceCenterTab category;

  @override
  Widget build(BuildContext context) {
    final color = InvoiceCenterFormat.color(category);
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        category == InvoiceCenterTab.cancelled
            ? 'Cancelled'
            : category == InvoiceCenterTab.advance
                ? 'Advance'
                : category == InvoiceCenterTab.gst
                    ? 'GST'
                    : 'Regular',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: InvoiceCenterStyle.ink,
          fontSize: InvoiceCenterStyle.bodyTextSize,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = InvoiceCenterFormat.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            InvoiceCenterFormat.status(status),
            style: const TextStyle(
              color: InvoiceCenterStyle.ink,
              fontSize: InvoiceCenterStyle.bodyTextSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

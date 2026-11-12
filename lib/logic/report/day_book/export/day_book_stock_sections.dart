import 'package:intl/intl.dart';

import '../../../../models/reports/day_book/day_book_models.dart';
import '../../../../models/reports/day_book/day_book_owned_stock_position.dart';
import 'day_book_report_model.dart';

typedef Cell = DayBookReportCell;

class DayBookStockSections {
  const DayBookStockSections._();

  static List<DayBookReportSection> build(DayBookSummary summary) {
    final owned = summary.ownedStockPosition;
    final batches = [...summary.stockAddedBatches]
      ..sort((a, b) => a.postedAt.compareTo(b.postedAt));
    return [
      DayBookReportSection(
        title: 'Owned Gold and Silver Position',
        headers: const [
          'Metal',
          'Opening Net',
          'Inward Net',
          'Sold Net',
          'Other Out Net',
          'Closing Net',
          'Status'
        ],
        rows: [
          _metalRow('Gold', owned?.gold),
          _metalRow('Silver', owned?.silver),
        ],
      ),
      DayBookReportSection(
        title: 'Stock Added Today - Add Stock Batches',
        headers: const [
          'Batch Code',
          'Posted At',
          'Metal',
          'Pieces',
          'Net Weight',
          'Rate / g',
          'Making',
          'Purchase Value'
        ],
        rows: [
          for (final batch in batches)
            [
              Cell(batch.batchCode),
              Cell(DateFormat('HH:mm').format(batch.postedAt)),
              Cell(batch.metal),
              Cell.count(batch.pieces),
              Cell.weight(batch.netWeightGrams),
              batch.hasMixedRates
                  ? const Cell('Mixed rates')
                  : Cell.money(batch.ratePerGram),
              Cell.money(batch.makingTotal),
              Cell.money(batch.purchaseValue),
            ],
        ],
      ),
      DayBookReportSection(
        title: 'Customer Metal Sold Today',
        headers: const ['Metal', 'Invoices', 'Net Weight'],
        rows: [
          [
            const Cell('Gold'),
            summary.customerMetalSales == null
                ? const Cell('Unverified')
                : Cell.count(summary.customerMetalSales!.goldInvoices),
            Cell.weight(summary.customerMetalSales?.goldGrams),
          ],
          [
            const Cell('Silver'),
            summary.customerMetalSales == null
                ? const Cell('Unverified')
                : Cell.count(summary.customerMetalSales!.silverInvoices),
            Cell.weight(summary.customerMetalSales?.silverGrams),
          ],
        ],
      ),
      DayBookReportSection(
        title: 'Owned Stock Movement Detail',
        headers: const [
          'Source',
          'Metal',
          'Purity',
          'Item',
          'Pieces',
          'Gross Delta',
          'Net Delta',
          'Fine Delta'
        ],
        rows: [
          for (final move in summary.stockMovements)
            [
              Cell('${move.sourceNumber ?? move.sourceId}'
                  '${move.sourceLineNo == null ? '' : ' #${move.sourceLineNo}'}'),
              Cell(move.metal),
              Cell(move.puritySnapshot ?? 'Unverified'),
              Cell(move.itemName),
              Cell.count(move.quantityDelta),
              Cell.weight(move.grossWeightDelta),
              Cell.weight(move.netWeightDelta),
              Cell.weight(move.fineWeightDelta),
            ],
        ],
      ),
      _custody(summary),
    ];
  }

  static List<Cell> _metalRow(
      String metal, DayBookOwnedMetalPosition? position) {
    if (position == null || !position.isConsistent) {
      return [
        Cell(metal),
        for (var i = 0; i < 5; i++) const Cell('Unverified'),
        const Cell('Unverified'),
      ];
    }
    return [
      Cell(metal),
      Cell.weight(position.openingGrams),
      Cell.weight(position.inwardGrams),
      Cell.weight(position.soldGrams),
      Cell.weight(position.otherOutGrams),
      Cell.weight(position.closingGrams),
      const Cell('Calculated'),
    ];
  }

  static DayBookReportSection _custody(DayBookSummary summary) {
    final custody = summary.custodyPosition;
    return DayBookReportSection(
      title: 'Girvi Custody - Customer Property',
      headers: const [
        'Stage',
        'Ticket',
        'Metal',
        'Purity',
        'Item',
        'Pieces',
        'Gross',
        'Net',
        'Fine'
      ],
      rows: [
        if (custody != null)
          for (final (stage, lines) in [
            ('Opening', custody.opening),
            ('Received', custody.received),
            ('Released', custody.released),
            (
              custody.closingVerified ? 'Closing' : 'Closing Unverified',
              custody.closing
            ),
          ])
            for (final line in lines)
              [
                Cell(stage),
                Cell(line.ticketNo),
                Cell(line.metal),
                Cell(line.purity),
                Cell(line.itemName),
                Cell.count(line.pieces),
                Cell.weight(line.grossWeight),
                Cell.weight(line.netWeight),
                Cell.weight(line.fineWeight),
              ],
      ],
    );
  }
}

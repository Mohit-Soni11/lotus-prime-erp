import '../../../../models/reports/day_book/day_book_activity_event.dart';
import '../../../../models/reports/day_book/day_book_document.dart';
import '../../../../models/reports/day_book/day_book_models.dart';
import '../../../../models/reports/day_book/day_book_receipts_register.dart';
import 'day_book_report_model.dart';

typedef Cell = DayBookReportCell;

class DayBookSourceSections {
  const DayBookSourceSections._();

  static List<DayBookReportSection> build(DayBookSummary summary) {
    final documents = [...summary.documents]
      ..sort((a, b) => a.date.compareTo(b.date));
    final register = DayBookReceiptsRegister.fromSummary(summary);
    return [
      _documentSummary(documents),
      _documentRegister(documents),
      _documentTaxAndCollection(documents),
      _documentItems(documents),
      _dueRegister(register),
      _receiptRegister(register),
      _expenseSummary(summary),
      _expenseRegister(summary),
      _activityRegister(summary),
    ];
  }

  static DayBookReportSection _documentSummary(List<DayBookDocument> docs) =>
      DayBookReportSection(
        title: 'Source Document Summary',
        headers: const [
          'Document Type',
          'Count',
          'Face Value',
          'Saved Tax',
          'Collected Today',
          'Current Due'
        ],
        rows: [
          for (final kind in DayBookDocumentKind.values)
            _summaryRow(
                kind,
                docs
                    .where((doc) => doc.kind == kind && !doc.isVoided)
                    .toList()),
        ],
      );

  static List<Cell> _summaryRow(
          DayBookDocumentKind kind, List<DayBookDocument> docs) =>
      [
        Cell(kind.label),
        Cell.count(docs.length),
        Cell.money(docs.fold<double>(0, (sum, doc) => sum + doc.amount)),
        Cell.money(_sumKnown(docs.map((doc) => doc.tax))),
        Cell.money(_sumKnown(docs.map((doc) => doc.collection))),
        Cell.money(
            _sumKnown(docs.map((doc) => doc.savedDue ?? doc.outstanding))),
      ];

  static double? _sumKnown(Iterable<double?> amounts) {
    var total = 0.0;
    for (final amount in amounts) {
      if (amount == null) return null;
      total += amount;
    }
    return total;
  }

  static DayBookReportSection _documentRegister(List<DayBookDocument> docs) =>
      DayBookReportSection(
        title: 'Source Document Register',
        headers: const [
          'Reference',
          'Type',
          'Customer / Party',
          'Phone',
          'Status',
          'Face Value',
          'Saved Paid',
          'Current Due',
          'Issue Evidence',
        ],
        rows: [
          for (final doc in docs)
            [
              Cell(doc.number),
              Cell(doc.kind.label),
              Cell(doc.partyName ?? '-'),
              Cell(doc.mobile ?? '-'),
              Cell(doc.status),
              Cell.money(doc.amount),
              Cell.money(doc.savedPaid),
              Cell.money(doc.savedDue ?? doc.outstanding),
              Cell(doc.issueSnapshotAvailable ? 'Archived' : 'Unverified'),
            ],
        ],
      );

  static DayBookReportSection _documentTaxAndCollection(
          List<DayBookDocument> docs) =>
      DayBookReportSection(
        title: 'Source Document Tax and Collection',
        headers: const ['Reference', 'Saved Tax', 'Collected Today'],
        rows: [
          for (final doc in docs)
            [
              Cell(doc.number),
              Cell.money(doc.tax),
              Cell.money(doc.collection),
            ],
        ],
      );

  static DayBookReportSection _documentItems(List<DayBookDocument> docs) =>
      DayBookReportSection(
        title: 'Source Document Metal Items',
        headers: const ['Reference', 'Metal', 'Item', 'Pieces', 'Net Weight'],
        rows: [
          for (final doc in docs)
            for (final item in doc.items)
              [
                Cell(doc.number),
                Cell(item.metal),
                Cell(item.name),
                Cell.count(item.quantity),
                Cell.weight(item.netWeightGrams),
              ],
        ],
      );

  static DayBookReportSection _dueRegister(DayBookReceiptsRegister register) =>
      DayBookReportSection(
        title: 'Invoice Dues and Due Collection',
        headers: const [
          'Invoice',
          'Type',
          'Customer',
          'Phone',
          'Invoice Value',
          'Saved Paid',
          'Collected Against Due Today',
          'Current Due'
        ],
        rows: [
          for (final due in register.dues)
            [
              Cell(due.reference),
              Cell(due.type),
              Cell(due.customerName ?? '-'),
              Cell(due.phone ?? '-'),
              Cell.money(due.totalValue),
              Cell.money(due.amountPaid),
              Cell.money(due.paidAgainstDue),
              Cell.money(due.dueAmount),
            ],
        ],
      );

  static DayBookReportSection _receiptRegister(
          DayBookReceiptsRegister register) =>
      DayBookReportSection(
        title: 'Money Received by Source',
        headers: const [
          'Reference',
          'Type',
          'Customer / Party',
          'Phone',
          'Payment Mode',
          'Amount'
        ],
        rows: [
          for (final receipt in register.received)
            [
              Cell(receipt.reference),
              Cell(receipt.type),
              Cell(receipt.customerName ?? '-'),
              Cell(receipt.phone ?? '-'),
              Cell(receipt.mode),
              Cell.money(receipt.amount),
            ],
        ],
      );

  static DayBookReportSection _expenseSummary(DayBookSummary summary) {
    final totals = <String, double>{};
    for (final record in summary.expenseRecords) {
      final key = '${record.category} / ${record.paymentMode}';
      totals[key] = (totals[key] ?? 0) + record.amount;
    }
    final groups = totals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return DayBookReportSection(
      title: 'Expense Entry Summary',
      headers: const ['Category / Mode', 'Amount'],
      rows: [
        [
          const Cell('Total Expenses Paid'),
          Cell.money(summary.expenseRecords
              .fold<double>(0, (sum, record) => sum + record.amount)),
        ],
        for (final group in groups) [Cell(group.key), Cell.money(group.value)],
      ],
    );
  }

  static DayBookReportSection _expenseRegister(DayBookSummary summary) =>
      DayBookReportSection(
        title: 'Expense Entry Register',
        headers: const [
          'Reference',
          'Category',
          'Party',
          'Payment Mode',
          'Amount',
          'Note'
        ],
        rows: [
          for (final expense in summary.expenseRecords)
            [
              Cell(expense.reference),
              Cell(expense.category),
              Cell(expense.partyName ?? '-'),
              Cell(expense.paymentMode),
              Cell.money(expense.amount),
              Cell(expense.description ?? '-'),
            ],
        ],
      );

  static DayBookReportSection _activityRegister(DayBookSummary summary) =>
      DayBookReportSection(
        title: 'Girvi, Interest and Due Activity',
        headers: const [
          'Reference',
          'Activity',
          'Customer',
          'Phone',
          'Amount',
          'Saved Due'
        ],
        rows: [
          for (final event in summary.activityEvents)
            [
              Cell(event.number),
              Cell(switch (event.kind) {
                DayBookActivityKind.girviRelease => 'Girvi Release',
                DayBookActivityKind.girviInterest => 'Girvi Interest',
                DayBookActivityKind.girviMelted => 'Girvi Melted',
                DayBookActivityKind.dueCollection => 'Due Collection',
              }),
              Cell(event.partyName ?? '-'),
              Cell(event.mobile ?? '-'),
              Cell.money(event.amount),
              Cell.money(event.savedDue),
            ],
        ],
      );
}

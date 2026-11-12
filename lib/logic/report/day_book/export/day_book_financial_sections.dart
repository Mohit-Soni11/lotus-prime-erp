import '../../../../models/reports/day_book/day_book_models.dart';
import '../../../../models/reports/day_book/day_book_money_flow.dart';
import 'day_book_report_model.dart';

typedef Cell = DayBookReportCell;

class DayBookFinancialSections {
  const DayBookFinancialSections._();

  static List<DayBookReportSection> build(DayBookSummary summary) {
    final flow = summary.moneyFlow;
    if (flow == null) {
      return const [
        DayBookReportSection(
          title: 'Money Position',
          headers: ['Status'],
          rows: [
            [Cell('Posted money position unavailable')]
          ],
        ),
      ];
    }
    return [
      DayBookReportSection(
        title: 'Opening and Closing Balance',
        headers: const ['Position', 'Cash', 'Bank', 'Total'],
        rows: [
          [
            const Cell('Opening'),
            Cell.money(flow.openingCash),
            Cell.money(flow.openingBank),
            Cell.money(flow.openingTotal),
          ],
          [
            const Cell('Closing'),
            Cell.money(flow.closingCash),
            Cell.money(flow.closingBank),
            Cell.money(flow.closingTotal),
          ],
        ],
      ),
      DayBookReportSection(
        title: 'Money Movement',
        headers: const ['Movement', 'Amount'],
        rows: [
          [const Cell('Cash In'), Cell.money(flow.cashIn)],
          [const Cell('Cash Out'), Cell.money(flow.cashOut)],
          [const Cell('Bank In'), Cell.money(flow.bankIn)],
          [const Cell('Bank Out'), Cell.money(flow.bankOut)],
          [const Cell('Business Money In'), Cell.money(flow.moneyIn)],
          [const Cell('Business Money Out'), Cell.money(flow.moneyOut)],
          [const Cell('Internal Transfer In'), Cell.money(flow.internalIn)],
          [const Cell('Internal Transfer Out'), Cell.money(flow.internalOut)],
        ],
      ),
      _breakdown('Money In by Source', flow.bySource(incoming: true)),
      _breakdown('Money Out by Source', flow.bySource(incoming: false)),
      _breakdown('Money In by Payment Mode', flow.byMode(incoming: true)),
      _breakdown('Money Out by Payment Mode', flow.byMode(incoming: false)),
      _breakdown('Bank In by Account', flow.byBankAccount(incoming: true)),
      _breakdown('Bank Out by Account', flow.byBankAccount(incoming: false)),
      _breakdown('Bank Receipts by Settlement Status',
          flow.byBankReconciliation(incoming: true)),
      _breakdown('Bank Payments by Settlement Status',
          flow.byBankReconciliation(incoming: false)),
      _transactions(flow),
    ];
  }

  static DayBookReportSection _breakdown(
      String title, Map<String, double> values) {
    final sorted = values.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return DayBookReportSection(
      title: title,
      headers: const ['Source', 'Amount'],
      rows: [
        for (final entry in sorted) [Cell(entry.key), Cell.money(entry.value)],
      ],
    );
  }

  static DayBookReportSection _transactions(DayBookMoneyFlow flow) {
    final sorted = [...flow.entries]..sort((a, b) => a.date.compareTo(b.date));
    return DayBookReportSection(
      title: 'Posted Transaction Register',
      headers: const [
        'Transaction',
        'Time',
        'Direction',
        'Source',
        'Mode / Account',
        'Party',
        'Reference',
        'Amount'
      ],
      rows: [
        for (final entry in sorted)
          [
            Cell(entry.transactionId),
            Cell('${entry.date.hour.toString().padLeft(2, '0')}:'
                '${entry.date.minute.toString().padLeft(2, '0')}'),
            Cell(entry.incoming ? 'In' : 'Out'),
            Cell(entry.category),
            Cell(entry.accountName == null
                ? entry.paymentMode
                : '${entry.paymentMode} / ${entry.accountName}'),
            Cell(entry.partyName ?? '-'),
            Cell(entry.referenceId ?? entry.transactionId),
            Cell.money(entry.amount),
          ],
      ],
    );
  }
}

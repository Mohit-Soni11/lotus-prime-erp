import 'package:intl/intl.dart';

import 'day_book_export_data.dart';
import 'day_book_report_model.dart';

typedef Cell = DayBookReportCell;

class DayBookAuditSections {
  const DayBookAuditSections._();

  static List<DayBookReportSection> build(DayBookExportData data) => [
        _openingVerification(data),
        _closing(data),
        _denominations(data),
        _metalCount(data),
      ];

  static DayBookReportSection _openingVerification(DayBookExportData data) {
    final verification = data.openingVerification;
    if (verification == null) {
      return const DayBookReportSection(
        title: 'Daily Balance Verification',
        headers: ['Status'],
        rows: [
          [Cell('No saved opening verification for this day')]
        ],
      );
    }
    final combinedVariance = verification.actualCash +
        verification.actualBank -
        verification.expectedCash -
        verification.expectedBank;
    final shortage = -combinedVariance;
    return DayBookReportSection(
      title: 'Daily Balance Verification',
      headers: const ['Field', 'Value'],
      rows: [
        [const Cell('Verified At'), Cell(_dateTime(verification.verifiedAt))],
        [
          const Cell('Verified By'),
          Cell(verification.verifiedBy ?? 'Not recorded')
        ],
        [const Cell('Expected Cash'), Cell.money(verification.expectedCash)],
        [const Cell('Counted Cash'), Cell.money(verification.actualCash)],
        [const Cell('Cash Variance'), Cell.money(verification.cashVariance)],
        [const Cell('Expected Bank'), Cell.money(verification.expectedBank)],
        [const Cell('Counted Bank'), Cell.money(verification.actualBank)],
        [const Cell('Bank Variance'), Cell.money(verification.bankVariance)],
        [
          const Cell('Expected Total'),
          Cell.money(verification.expectedCash + verification.expectedBank)
        ],
        [
          const Cell('Counted Total'),
          Cell.money(verification.actualCash + verification.actualBank)
        ],
        [const Cell('Combined Difference'), Cell.money(combinedVariance)],
        if (verification.cashAdjusted) ...[
          [
            const Cell('Posted Adjustment Type'),
            Cell(shortage >= 0.01 ? 'Expense' : 'Cash surplus'),
          ],
          [
            const Cell('Posted Adjustment Amount'),
            Cell.money(shortage >= 0.01 ? shortage : verification.cashVariance),
          ],
        ],
        [const Cell('Cash Category'), Cell(verification.cashCategory ?? '-')],
        [const Cell('Cash Reason'), Cell(verification.cashReason ?? '-')],
        [const Cell('Bank Reason'), Cell(verification.bankReason ?? '-')],
        [
          const Cell('Adjustment Reference'),
          Cell(verification.cashAdjustmentTransactionId ?? '-')
        ],
      ],
    );
  }

  static DayBookReportSection _closing(DayBookExportData data) {
    final closing = data.closing;
    if (closing == null) {
      if (data.legacyClosedAt != null) {
        return DayBookReportSection(
          title: 'Day Closing Audit',
          headers: const ['Field', 'Value'],
          rows: [
            const [Cell('Status'), Cell('Closed under legacy day lock')],
            [const Cell('Closed At'), Cell(_dateTime(data.legacyClosedAt))],
            [
              const Cell('Closed By'),
              Cell(data.legacyClosedBy ?? 'Not recorded')
            ],
            const [Cell('Physical Count'), Cell('Not recorded in legacy data')],
            const [Cell('Snapshot Hash'), Cell('Not available in legacy data')],
          ],
        );
      }
      return const DayBookReportSection(
        title: 'Day Closing Audit',
        headers: ['Status'],
        rows: [
          [Cell('Day remains open - no saved closing count')]
        ],
      );
    }
    final hash = closing.sourceHash
        .replaceAllMapped(
          RegExp('.{1,16}'),
          (match) => '${match.group(0)} ',
        )
        .trim();
    return DayBookReportSection(
      title: 'Day Closing Audit',
      headers: const ['Field', 'Value'],
      rows: [
        const [Cell('Status'), Cell('Closed and locked')],
        [const Cell('Closed At'), Cell(_dateTime(closing.closedAt))],
        [const Cell('Closed By'), Cell(closing.closedBy ?? 'Not recorded')],
        [const Cell('Counted Cash'), Cell.money(closing.physicalCash)],
        [const Cell('Counted Bank'), Cell.money(closing.physicalBank)],
        [
          const Cell('Counted Total'),
          Cell.money(closing.physicalBank == null
              ? null
              : closing.physicalCash + closing.physicalBank!)
        ],
        [
          const Cell('Snapshot SHA-256'),
          Cell(closing.sourceHash, display: hash)
        ],
      ],
    );
  }

  static DayBookReportSection _denominations(DayBookExportData data) {
    final counts = data.closing?.denominations;
    final sorted = counts?.entries.toList()
      ?..sort((a, b) {
        if (a.key == 'coins') return 1;
        if (b.key == 'coins') return -1;
        return (int.tryParse(b.key) ?? 0).compareTo(int.tryParse(a.key) ?? 0);
      });
    return DayBookReportSection(
      title: 'Physical Cash Note Count',
      headers: const ['Denomination', 'Quantity', 'Amount'],
      rows: [
        if (sorted != null)
          for (final entry in sorted)
            [
              Cell(entry.key == 'coins' ? 'Coins' : 'INR ${entry.key}'),
              Cell(entry.key == 'coins' ? '-' : entry.value.toString()),
              Cell.money(entry.key == 'coins'
                  ? entry.value
                  : (int.tryParse(entry.key) ?? 0) * entry.value),
            ],
      ],
    );
  }

  static DayBookReportSection _metalCount(DayBookExportData data) {
    final metal = data.closing?.metal;
    if (metal == null) {
      return const DayBookReportSection(
        title: 'Physical Metal Count',
        headers: ['Status'],
        rows: [
          [Cell('No saved physical metal count evidence')]
        ],
      );
    }
    final byKey = {for (final line in metal.counted) line.key: line};
    return DayBookReportSection(
      title: 'Physical Metal Count',
      headers: const ['Item / Purity', 'System', 'Physical'],
      rows: [
        [
          const Cell('Verified By'),
          Cell(metal.verifiedBy),
          Cell(_dateTime(metal.verifiedAt)),
        ],
        if (metal.expected.isEmpty)
          const [
            Cell('Empty owned stock'),
            Cell('0 items'),
            Cell('Physically confirmed'),
          ],
        for (final line in metal.expected)
          [
            Cell('${line.metal} ${line.item} · ${line.purity}'),
            Cell('${line.pieces} pcs · ${line.grossGrams.toStringAsFixed(3)} '
                'gross · ${line.netGrams.toStringAsFixed(3)} net · '
                '${line.fineGrams?.toStringAsFixed(3) ?? 'unknown'} fine g'),
            Cell(byKey[line.key] == null
                ? 'Count missing'
                : '${byKey[line.key]!.pieces} pcs · '
                    '${byKey[line.key]!.grossGrams.toStringAsFixed(3)} gross · '
                    '${byKey[line.key]!.netGrams.toStringAsFixed(3)} net · '
                    '${byKey[line.key]!.fineGrams.toStringAsFixed(3)} fine g'),
          ],
      ],
    );
  }

  static String _dateTime(DateTime? date) => date == null
      ? 'Not recorded'
      : DateFormat('d MMM yyyy, h:mm a').format(date);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/reports/day_book/day_book_document.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookDocumentSummaryPanel extends StatelessWidget {
  const DayBookDocumentSummaryPanel({super.key, required this.documents});

  final List<DayBookDocument> documents;

  @override
  Widget build(BuildContext context) {
    final active = documents.where((document) => !document.isVoided).toList();
    final voidCount = documents.length - active.length;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: 'INR ');
    return Container(
      decoration: DayBookStyles.panel(),
      child: ExpansionTile(
        initiallyExpanded: false,
        title:
            Text('Source Document Summary', style: DayBookStyles.sectionTitle),
        subtitle: Text(
          'Invoices, advances, Girvi loans, purchases and returns stay in their own categories.',
          style: DayBookStyles.sectionSubtitle,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 840,
              child: Column(children: [
                _row('Source', 'Count', 'Face Value', 'Saved Tax',
                    'Posted Collection', 'Saved Outstanding',
                    header: true),
                const Divider(height: 1),
                for (final kind in DayBookDocumentKind.values)
                  _summaryRow(kind, active, currency),
              ]),
            ),
          ),
          if (voidCount > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('$voidCount voided documents excluded from totals.',
                  style: DayBookStyles.label),
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'A dash means the source has no reliable value for that field. Advance receipts and Girvi principal are not sales turnover.',
              style: DayBookStyles.label,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(DayBookDocumentKind kind, List<DayBookDocument> documents,
      NumberFormat currency) {
    final rows = documents.where((document) => document.kind == kind).toList();
    double? totalOf(double? Function(DayBookDocument) value) {
      if (rows.isEmpty) return null;
      if (rows.any((row) => value(row) == null)) return null;
      return rows.fold<double>(0, (sum, row) => sum + value(row)!);
    }

    String money(double? value) => value == null ? '—' : currency.format(value);
    return _row(
      kind.label,
      '${rows.length}',
      money(rows.fold<double>(0, (sum, row) => sum + row.amount)),
      money(totalOf((row) => row.tax)),
      money(totalOf((row) => row.collection)),
      money(totalOf((row) => row.outstanding)),
    );
  }

  Widget _row(String source, String count, String amount, String tax,
      String collection, String outstanding,
      {bool header = false}) {
    final style = header ? DayBookStyles.labelStrong : DayBookStyles.label;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        SizedBox(width: 175, child: Text(source, style: style)),
        SizedBox(width: 55, child: Text(count, style: style)),
        SizedBox(width: 145, child: Text(amount, style: style)),
        SizedBox(width: 135, child: Text(tax, style: style)),
        SizedBox(width: 160, child: Text(collection, style: style)),
        Expanded(child: Text(outstanding, style: style)),
      ]),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../models/reports/day_book/day_book_activity_event.dart';
import '../../../models/reports/day_book/day_book_document.dart';
import '../../../models/reports/day_book/day_book_document_explorer.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_smart_format.dart';

class DayBookDocumentExplorerSummary extends StatelessWidget {
  const DayBookDocumentExplorerSummary({
    super.key,
    required this.tab,
    required this.entries,
  });

  final DayBookExplorerTab tab;
  final List<DayBookExplorerEntry> entries;

  @override
  Widget build(BuildContext context) {
    final metrics = _metrics();
    return LayoutBuilder(builder: (context, constraints) {
      final inline = constraints.maxWidth >= 850;
      final width = inline ? constraints.maxWidth : metrics.length * 180.0;
      final strip = Container(
        width: width,
        height: 68,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [
            Color(0xFFFFFCF6),
            Color(0xFFFBF7EF),
          ]),
          border: Border.all(color: DayBookColors.brandGoldBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          for (var index = 0; index < metrics.length; index++) ...[
            if (index != 0)
              Container(width: 1, height: 35, color: DayBookColors.bodyBorder),
            Expanded(child: _MetricTile(metric: metrics[index])),
          ],
        ]),
      );
      return inline
          ? strip
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: strip,
            );
    });
  }

  List<_Metric> _metrics() {
    final docs = entries
        .map((entry) => entry.document)
        .whereType<DayBookDocument>()
        .toList();
    final count = entries.length;
    final range = count == 0
        ? '—'
        : count == 1
            ? entries.first.reference
            : '${entries.first.reference} to ${entries.last.reference}';
    final total = entries.fold<double>(0, (sum, row) => sum + row.amount);
    final paid = _sumKnown(docs, (row) => row.savedPaid ?? row.collection);
    final due = _sumKnown(docs, (row) => row.savedDue ?? row.outstanding);

    final countMetric = _Metric(
        tab == DayBookExplorerTab.sales || tab == DayBookExplorerTab.gstSales
            ? 'Total Invoices'
            : 'Total Records',
        '$count',
        Icons.receipt_long_outlined);
    final rangeMetric = _Metric('Invoice Range', range, Icons.tag_rounded);
    return switch (tab) {
      DayBookExplorerTab.sales || DayBookExplorerTab.gstSales => [
          countMetric,
          rangeMetric,
          _Metric('Total Sales', dayBookSmartMoney(total),
              Icons.shopping_cart_outlined),
          _Metric('Total Paid', _money(paid),
              Icons.account_balance_wallet_outlined),
          _Metric('Total Due', _money(due), Icons.schedule_outlined),
        ],
      DayBookExplorerTab.girvi => [
          countMetric,
          rangeMetric,
          _Metric(
              'Loan Given',
              dayBookSmartMoney(_totalFor((entry) =>
                  entry.document?.kind == DayBookDocumentKind.girviTicket)),
              Icons.arrow_upward_rounded),
          _Metric(
              'Release Receipts',
              dayBookSmartMoney(_totalFor((entry) =>
                  entry.event?.kind == DayBookActivityKind.girviRelease)),
              Icons.arrow_downward_rounded),
          _Metric(
              'Interest',
              dayBookSmartMoney(_totalFor((entry) =>
                  entry.event?.kind == DayBookActivityKind.girviInterest)),
              Icons.percent_rounded),
        ],
      DayBookExplorerTab.advance => [
          countMetric,
          rangeMetric,
          _Metric('Advance Received', dayBookSmartMoney(total),
              Icons.account_balance_wallet_outlined),
        ],
      DayBookExplorerTab.returns => [
          countMetric,
          rangeMetric,
          _Metric(
              'Return Value',
              dayBookSmartMoney(_totalFor((entry) =>
                  entry.document?.kind == DayBookDocumentKind.returnVoucher)),
              Icons.keyboard_return_rounded),
          _Metric(
              'Cancellation Value',
              dayBookSmartMoney(_totalFor((entry) =>
                  entry.document?.kind ==
                  DayBookDocumentKind.advanceCancellationVoucher)),
              Icons.cancel_outlined),
          _Metric('Refund Due', _money(due), Icons.schedule_outlined),
        ],
      DayBookExplorerTab.purchase => [
          countMetric,
          rangeMetric,
          _Metric('Purchase Value', dayBookSmartMoney(total),
              Icons.inventory_2_outlined),
          _Metric('Total Paid', _money(paid),
              Icons.account_balance_wallet_outlined),
          _Metric('Total Due', _money(due), Icons.schedule_outlined),
        ],
    };
  }

  double _totalFor(bool Function(DayBookExplorerEntry) include) =>
      entries.where(include).fold<double>(0, (sum, row) => sum + row.amount);

  double? _sumKnown(
      List<DayBookDocument> docs, double? Function(DayBookDocument) value) {
    if (docs.any((row) => value(row) == null)) return null;
    return docs.fold<double>(0, (sum, row) => sum + (value(row) ?? 0));
  }

  String _money(double? value) =>
      value == null ? '—' : dayBookSmartMoney(value);
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});
  final _Metric metric;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Icon(metric.icon, size: 22, color: DayBookColors.goldMetal),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DayBookStyles.label.copyWith(fontSize: 13)),
              Text(metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DayBookStyles.labelStrong
                      .copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          )),
        ]),
      );
}

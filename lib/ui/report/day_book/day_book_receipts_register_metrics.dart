import 'package:flutter/material.dart';

import '../../../models/reports/day_book/day_book_receipts_register.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_smart_format.dart';

class DayBookReceiptsRegisterMetrics extends StatelessWidget {
  const DayBookReceiptsRegisterMetrics({
    super.key,
    required this.register,
    required this.tab,
  });

  final DayBookReceiptsRegister register;
  final DayBookRegisterTab tab;

  @override
  Widget build(BuildContext context) {
    final metrics = _metrics();
    return LayoutBuilder(builder: (context, constraints) {
      final inline = constraints.maxWidth >= 720;
      final strip = Container(
        width: inline ? constraints.maxWidth : 760,
        height: 57,
        decoration: BoxDecoration(
          color: const Color(0xFFFCF9F4),
          border: Border.all(color: DayBookColors.bodyBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          for (var index = 0; index < metrics.length; index++) ...[
            if (index != 0)
              Container(width: 1, height: 32, color: DayBookColors.bodyBorder),
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
    if (tab == DayBookRegisterTab.due) {
      final dues = register.dues;
      final allKnown = dues.every((row) => row.dueBeforeReceipts != null);
      final opening = allKnown
          ? dues.fold<double>(0, (sum, row) => sum + row.dueBeforeReceipts!)
          : null;
      final balanceKnown = dues.every((row) => row.dueAmount != null);
      final balance = balanceKnown
          ? dues.fold<double>(0, (sum, row) => sum + row.dueAmount!)
          : null;
      final customers = dues
          .map((row) =>
              row.customerId?.toString() ?? row.customerName ?? row.reference)
          .toSet()
          .length;
      final paid = dues.fold<double>(0, (sum, row) => sum + row.paidAgainstDue);
      return [
        _Metric('Total Dues', _money(opening), Icons.folder_outlined),
        _Metric('Customers', '$customers', Icons.people_outline_rounded),
        _Metric('Paid (Against Due)', _money(paid),
            Icons.currency_rupee_rounded, DayBookColors.positive),
        _Metric('Balance Due', _money(balance), Icons.schedule_outlined,
            DayBookColors.negative),
      ];
    }
    if (tab == DayBookRegisterTab.received) {
      final rows = register.received;
      final total = rows.fold<double>(0, (sum, row) => sum + row.amount);
      final cash = rows
          .where((row) => row.mode.toUpperCase() == 'CASH')
          .fold<double>(0, (sum, row) => sum + row.amount);
      return [
        _Metric('Total Received', _money(total),
            Icons.account_balance_wallet_outlined, DayBookColors.positive),
        _Metric('Receipts', '${rows.length}', Icons.receipt_long_outlined),
        _Metric('Cash In', _money(cash), Icons.money_outlined),
        _Metric('Bank / Digital', _money(total - cash),
            Icons.account_balance_outlined),
      ];
    }
    final rows = register.expenses;
    final total = rows.fold<double>(0, (sum, row) => sum + row.amount);
    final cash = rows
        .where((row) => row.paymentMode.toUpperCase() == 'CASH')
        .fold<double>(0, (sum, row) => sum + row.amount);
    return [
      _Metric('Total Expense', _money(total), Icons.receipt_long_outlined,
          DayBookColors.negative),
      _Metric('Entries', '${rows.length}', Icons.description_outlined),
      _Metric('Cash Out', _money(cash), Icons.money_outlined),
      _Metric('Bank / Digital', _money(total - cash),
          Icons.account_balance_outlined),
    ];
  }

  String _money(double? value) =>
      value == null ? '—' : dayBookSmartMoney(value);
}

class _Metric {
  const _Metric(this.label, this.value, this.icon,
      [this.valueColor = DayBookColors.textPrimary]);
  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});
  final _Metric metric;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        child: Row(children: [
          Icon(metric.icon, size: 21, color: DayBookColors.goldMetal),
          const SizedBox(width: 9),
          Expanded(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DayBookStyles.label.copyWith(fontSize: 10.5)),
              Text(metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DayBookStyles.labelStrong.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: metric.valueColor)),
            ],
          )),
        ]),
      );
}

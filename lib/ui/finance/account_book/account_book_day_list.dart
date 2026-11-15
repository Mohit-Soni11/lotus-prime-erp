import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/finance/account_book/account_book_month.dart';
import '../../../theme/finance/account_book/account_book_theme.dart';

class AccountBookDayList extends StatelessWidget {
  const AccountBookDayList({
    super.key,
    required this.report,
    required this.filter,
    required this.onOpenDayBook,
  });

  final AccountBookMonth report;
  final AccountBookActivityType? filter;
  final ValueChanged<DateTime> onOpenDayBook;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (final day in report.days.reversed)
        if (filter == null || day.activities.any((item) => item.type == filter))
          _DayCard(day: day, filter: filter, onOpenDayBook: onOpenDayBook),
    ]);
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard(
      {required this.day, required this.filter, required this.onOpenDayBook});

  final AccountBookDay day;
  final AccountBookActivityType? filter;
  final ValueChanged<DateTime> onOpenDayBook;

  @override
  Widget build(BuildContext context) {
    final activities = filter == null
        ? day.activities
        : day.activities.where((item) => item.type == filter).toList();
    final hasActivity = activities.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: AccountBookTheme.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
            color:
                hasActivity ? AccountBookTheme.border : const Color(0xFFD9DEE5),
            width: 1.2),
      ),
      child: ExpansionTile(
        key: PageStorageKey(
            '${day.date.year}-${day.date.month}-${day.date.day}-$filter'),
        initiallyExpanded: hasActivity &&
            day.date.day == DateTime.now().day &&
            day.date.month == DateTime.now().month &&
            day.date.year == DateTime.now().year,
        shape: const Border(),
        collapsedShape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 13),
        iconColor: AccountBookTheme.ink,
        collapsedIconColor: AccountBookTheme.ink,
        title: Text(DateFormat('EEE, d MMM yyyy').format(day.date),
            style:
                AccountBookTheme.label.copyWith(fontWeight: FontWeight.w800)),
        subtitle: Text(
          '${activities.length} activities  ·  Cash ${_money(day.closingCash)}  ·  Bank ${_money(day.closingBank)}',
          overflow: TextOverflow.ellipsis,
          style: AccountBookTheme.detail,
        ),
        children: [
          _balances(),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => onOpenDayBook(day.date),
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              label: const Text('View full Day Book'),
              style: TextButton.styleFrom(
                foregroundColor: AccountBookTheme.ink,
                textStyle: AccountBookTheme.detail
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (!hasActivity)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No posted activity on this day.',
                  style: AccountBookTheme.detail),
            )
          else
            for (final activity in activities) _row(activity),
        ],
      ),
    );
  }

  Widget _balances() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AccountBookTheme.softSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                  'Cash ${_money(day.openingCash)} → ${_money(day.closingCash)}'),
              Text(
                  'Bank ${_money(day.openingBank)} → ${_money(day.closingBank)}'),
              if (day.bankOpeningAdditions != 0)
                Text('New bank opening ${_money(day.bankOpeningAdditions)}'),
              Text(
                  'In ${_money(day.cashIn + day.bankIn)} · Out ${_money(day.cashOut + day.bankOut)}'),
            ]
                .map((text) => DefaultTextStyle.merge(
                      style: AccountBookTheme.detail,
                      child: text,
                    ))
                .toList()),
      );

  Widget _row(AccountBookActivity item) {
    final isMoney = item.type == AccountBookActivityType.money;
    final color = switch (item.type) {
      AccountBookActivityType.money => item.incoming == true
          ? AccountBookTheme.income
          : AccountBookTheme.expense,
      AccountBookActivityType.document => AccountBookTheme.gold,
      AccountBookActivityType.stock => AccountBookTheme.stock,
      AccountBookActivityType.girvi => AccountBookTheme.girvi,
      AccountBookActivityType.balance => AccountBookTheme.secondaryInk,
    };
    final icon = switch (item.type) {
      AccountBookActivityType.money => item.incoming == true
          ? Icons.south_west_rounded
          : Icons.north_east_rounded,
      AccountBookActivityType.document => Icons.description_outlined,
      AccountBookActivityType.stock => Icons.inventory_2_outlined,
      AccountBookActivityType.girvi => Icons.diamond_outlined,
      AccountBookActivityType.balance => Icons.account_balance_outlined,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.title,
              style:
                  AccountBookTheme.label.copyWith(fontWeight: FontWeight.w800)),
          Text(
              '${DateFormat('HH:mm').format(item.date)}  ·  ${item.reference}'
              '${item.detail?.isNotEmpty == true ? '  ·  ${item.detail}' : ''}',
              style: AccountBookTheme.detail),
        ])),
        if (item.amount != null)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
                '${isMoney ? item.incoming == true ? '+' : '−' : ''}${_money(item.amount!)}',
                style: AccountBookTheme.label.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isMoney ? color : AccountBookTheme.ink)),
            if (!isMoney)
              Text(
                  switch (item.type) {
                    AccountBookActivityType.document => 'Document value',
                    AccountBookActivityType.balance => 'Opening balance',
                    _ => 'Recorded value',
                  },
                  style: AccountBookTheme.detail),
            if (item.isInternalTransfer)
              const Text('Internal transfer', style: AccountBookTheme.detail),
          ]),
      ]),
    );
  }

  static String _money(double value) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2)
          .format(value);
}

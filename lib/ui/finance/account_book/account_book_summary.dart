import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/finance/account_book/account_book_month.dart';
import '../../../theme/finance/account_book/account_book_theme.dart';

class AccountBookSummary extends StatelessWidget {
  const AccountBookSummary({super.key, required this.report});

  final AccountBookMonth report;

  @override
  Widget build(BuildContext context) {
    final flow = report.money;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MONTHLY POSITION', style: AccountBookTheme.heading),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth < 680
              ? 2
              : constraints.maxWidth < 1100
                  ? 3
                  : 6;
          final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            _card('Opening Cash', flow.openingCash,
                Icons.account_balance_wallet_outlined, width),
            _card('Opening Bank', flow.openingBank,
                Icons.account_balance_outlined, width),
            _card('Money In', flow.moneyIn, Icons.south_west_rounded, width,
                color: AccountBookTheme.income),
            _card('Money Out', flow.moneyOut, Icons.north_east_rounded, width,
                color: AccountBookTheme.expense),
            _card('Closing Cash', flow.closingCash, Icons.payments_outlined,
                width),
            _card('Closing Bank', flow.closingBank,
                Icons.account_balance_rounded, width),
          ]);
        }),
        const SizedBox(height: 8),
        Text(
          'Posted movements: cash in ${_money(flow.cashIn)} · cash out ${_money(flow.cashOut)} · '
          'bank in ${_money(flow.bankIn)} · bank out ${_money(flow.bankOut)}. '
          'Internal transfers are included in balances and excluded from Money In/Out.'
          '${flow.bankOpeningAdditions == 0 ? '' : ' New bank accounts added ${_money(flow.bankOpeningAdditions)} to the bank balance.'}',
          style: AccountBookTheme.detail,
        ),
      ],
    );
  }

  static String _money(double value) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2)
          .format(value);

  Widget _card(String label, double value, IconData icon, double width,
      {Color color = AccountBookTheme.ink}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AccountBookTheme.surface,
        border: Border.all(color: AccountBookTheme.border, width: 1.2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon,
              size: 18,
              color: color == AccountBookTheme.ink
                  ? AccountBookTheme.gold
                  : color),
          const SizedBox(width: 7),
          Expanded(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: AccountBookTheme.label)),
        ]),
        const SizedBox(height: 8),
        Text(_money(value),
            overflow: TextOverflow.ellipsis,
            style: AccountBookTheme.amount.copyWith(color: color)),
      ]),
    );
  }
}

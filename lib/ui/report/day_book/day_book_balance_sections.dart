import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookPreviousClosing extends StatelessWidget {
  const DayBookPreviousClosing({
    super.key,
    required this.date,
    required this.cash,
    required this.bank,
  });

  final DateTime date;
  final double cash;
  final double bank;

  @override
  Widget build(BuildContext context) {
    final prior = DateTime(date.year, date.month, date.day - 1);
    final money =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    return _BalanceSection(
      key: const ValueKey('previous-day-closing'),
      icon: Icons.history_rounded,
      title: 'Previous Day Closing · ${DateFormat('d MMM yyyy').format(prior)}',
      child: Row(children: [
        Expanded(
            child: _BalanceTile(
                label: 'Cash',
                value: money.format(cash),
                icon: Icons.payments_outlined)),
        const SizedBox(width: 8),
        Expanded(
            child: _BalanceTile(
                label: 'Bank',
                value: money.format(bank),
                icon: Icons.account_balance_outlined)),
        const SizedBox(width: 8),
        Expanded(
            child: _BalanceTile(
                label: 'Total',
                value: money.format(cash + bank),
                icon: Icons.stacked_bar_chart_rounded,
                highlighted: true)),
      ]),
    );
  }
}

class DayBookOpeningInputs extends StatelessWidget {
  const DayBookOpeningInputs({
    super.key,
    required this.date,
    required this.cash,
    required this.bank,
    required this.readOnly,
    required this.bankAccountConfigured,
  });

  final DateTime date;
  final TextEditingController cash;
  final TextEditingController bank;
  final bool readOnly;
  final bool bankAccountConfigured;

  @override
  Widget build(BuildContext context) => _BalanceSection(
        icon: Icons.calendar_today_outlined,
        title:
            'Today’s Opening Count · ${DateFormat('d MMM yyyy').format(date)}',
        child: LayoutBuilder(builder: (context, constraints) {
          final cashField = _input(
            keyName: 'actual-cash',
            controller: cash,
            label: 'Counted Cash',
            icon: Icons.payments_outlined,
            allowNegative: false,
          );
          final bankField = _input(
            keyName: 'actual-bank',
            controller: bank,
            label: 'Bank Balance',
            icon: Icons.account_balance_outlined,
            allowNegative: true,
          );
          if (constraints.maxWidth < 440) {
            return Column(children: [
              cashField,
              const SizedBox(height: 8),
              bankField,
            ]);
          }
          return Row(children: [
            Expanded(child: cashField),
            const SizedBox(width: 10),
            Expanded(child: bankField),
          ]);
        }),
      );

  Widget _input({
    required String keyName,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool allowNegative,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: DayBookColors.bodyPanel,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: DayBookColors.bodyBorder),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _IconBadge(icon),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(label,
                    style: DayBookStyles.labelStrong.copyWith(
                        fontSize: 13, color: DayBookColors.textPrimary)),
                const SizedBox(height: 4),
                TextFormField(
                  key: ValueKey(keyName),
                  controller: controller,
                  readOnly: readOnly,
                  keyboardType: TextInputType.numberWithOptions(
                      signed: allowNegative, decimal: true),
                  style: DayBookStyles.value
                      .copyWith(fontSize: 16, color: DayBookColors.textPrimary),
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixText: '₹ ',
                    hintText: '0.00',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  ),
                  validator: (value) {
                    final amount = double.tryParse(
                        (value ?? '').trim().replaceAll(',', ''));
                    if (amount == null ||
                        !amount.isFinite ||
                        (!allowNegative && amount < 0) ||
                        (amount * 100 - (amount * 100).round()).abs() >
                            0.000001) {
                      return 'Enter a valid amount.';
                    }
                    if (keyName == 'actual-bank' &&
                        !bankAccountConfigured &&
                        amount.abs() >= 0.01) {
                      return 'Add a bank account first.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ]),
      );
}

class _BalanceSection extends StatelessWidget {
  const _BalanceSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: DayBookColors.bodySubtle,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DayBookColors.bodyBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(icon, color: DayBookColors.goldMetal, size: 20),
              const SizedBox(width: 9),
              Flexible(
                  child: Text(title,
                      style: DayBookStyles.sectionTitle.copyWith(
                          fontSize: 16, color: DayBookColors.goldMetal))),
            ]),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({
    required this.label,
    required this.value,
    required this.icon,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        decoration: BoxDecoration(
          gradient: highlighted
              ? const LinearGradient(
                  colors: [Color(0xFFFFFBF0), Color(0xFFF8E8BE)])
              : null,
          color: highlighted ? null : DayBookColors.bodyPanel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: highlighted
                  ? DayBookColors.brandGoldBorder
                  : DayBookColors.bodyBorder),
        ),
        child: Row(children: [
          _IconBadge(icon),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: DayBookStyles.labelStrong.copyWith(
                        fontSize: 13, color: DayBookColors.textPrimary)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: DayBookStyles.value.copyWith(
                          fontSize: 17, color: DayBookColors.textPrimary)),
                ),
              ],
            ),
          ),
        ]),
      );
}

class _IconBadge extends StatelessWidget {
  const _IconBadge(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 29,
        height: 29,
        decoration: BoxDecoration(
          color: DayBookColors.brandGoldSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: DayBookColors.goldMetal, size: 18),
      );
}

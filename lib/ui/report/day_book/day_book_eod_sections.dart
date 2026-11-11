import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../models/reports/day_book/day_book_money_flow.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
String _money(num value) => _currency.format(value);

class EodPanel extends StatelessWidget {
  const EodPanel(
      {super.key,
      required this.title,
      required this.icon,
      required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DayBookColors.bodySubtle,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: DayBookColors.bodyBorder),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(icon, color: DayBookColors.goldMetal, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text(title,
                    style: DayBookStyles.sectionTitle.copyWith(fontSize: 16))),
          ]),
          const SizedBox(height: 10),
          child,
        ]),
      );
}

class EodSystemClosing extends StatelessWidget {
  const EodSystemClosing(
      {super.key,
      required this.date,
      required this.flow,
      this.expenseTotal = 0});
  final DateTime date;
  final DayBookMoneyFlow flow;
  final double expenseTotal;

  @override
  Widget build(BuildContext context) => EodPanel(
        title: 'System Closing · ${DateFormat('d MMM yyyy').format(date)}',
        icon: Icons.history_rounded,
        child: Column(children: [
          LayoutBuilder(builder: (context, constraints) {
            final count = expenseTotal > 0.005 ? 3 : 2;
            final columns = constraints.maxWidth < 450 ? 1 : count;
            final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
            return Wrap(spacing: 8, runSpacing: 8, children: [
              _ClosingMetric(
                  label: 'Cash Balance',
                  amount: flow.closingCash,
                  icon: Icons.payments_outlined,
                  width: width),
              _ClosingMetric(
                  label: 'Bank Balance',
                  amount: flow.closingBank,
                  icon: Icons.account_balance_outlined,
                  width: width),
              if (expenseTotal > 0.005)
                _ClosingMetric(
                    label: 'Expenses Paid',
                    amount: expenseTotal,
                    icon: Icons.receipt_long_outlined,
                    width: width,
                    amountColor: DayBookColors.negative),
            ]);
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: DayBookColors.brandGoldSoft,
              border: Border.all(color: DayBookColors.brandGoldBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: DayBookColors.goldMetal, size: 21),
              const SizedBox(width: 9),
              Expanded(
                  child: Text('Total Expected Closing',
                      style: DayBookStyles.labelStrong.copyWith(fontSize: 14))),
              Text(_money(flow.closingTotal),
                  style: DayBookStyles.value.copyWith(fontSize: 18)),
            ]),
          ),
          if (flow.unclearedChequeIn != 0 || flow.unclearedChequeOut != 0) ...[
            const SizedBox(height: 8),
            Text(
              'Bank ledger includes uncleared cheques: received ${_money(flow.unclearedChequeIn)} · issued ${_money(flow.unclearedChequeOut)}. Check clearing status before comparing the bank statement.',
              style: DayBookStyles.labelStrong
                  .copyWith(fontSize: 13, color: DayBookColors.warning),
            ),
          ],
        ]),
      );
}

class _ClosingMetric extends StatelessWidget {
  const _ClosingMetric(
      {required this.label,
      required this.icon,
      required this.amount,
      required this.width,
      this.amountColor});
  final String label;
  final IconData icon;
  final double amount;
  final double width;
  final Color? amountColor;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: DayBookColors.bodyBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: DayBookColors.goldMetal, size: 19),
            const SizedBox(width: 7),
            Expanded(
                child: Text(label,
                    style: DayBookStyles.labelStrong.copyWith(fontSize: 13))),
          ]),
          const SizedBox(height: 7),
          FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(_money(amount),
                  style: DayBookStyles.value
                      .copyWith(fontSize: 18, color: amountColor))),
        ]),
      ));
}

class EodCashCount extends StatelessWidget {
  const EodCashCount(
      {super.key, required this.ctrl, required this.onCountChanged});
  final DayBookController ctrl;
  final VoidCallback onCountChanged;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (500, ctrl.denom500Ctrl),
      (200, ctrl.denom200Ctrl),
      (100, ctrl.denom100Ctrl),
      (50, ctrl.denom50Ctrl),
      (20, ctrl.denom20Ctrl),
      (10, ctrl.denom10Ctrl),
      (1, ctrl.denomCoinsCtrl),
    ];
    return EodPanel(
      title: 'Physical Cash Count',
      icon: Icons.payments_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Enter note quantities and the total coin value.',
            style: DayBookStyles.labelStrong.copyWith(fontSize: 13)),
        const SizedBox(height: 9),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final row in rows)
            _DenominationInput(
              value: row.$1,
              controller: row.$2,
              onChanged: onCountChanged,
              total: row.$1 == 1
                  ? ctrl.denomination.coins
                  : row.$1 * (int.tryParse(row.$2.text) ?? 0),
            ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: Text('Counted cash',
                  style: DayBookStyles.labelStrong.copyWith(fontSize: 14))),
          Text(_money(ctrl.physicalCashAmount),
              style: DayBookStyles.value.copyWith(fontSize: 18)),
        ]),
      ]),
    );
  }
}

class _DenominationInput extends StatelessWidget {
  const _DenominationInput(
      {required this.value,
      required this.controller,
      required this.total,
      required this.onChanged});
  final int value;
  final TextEditingController controller;
  final num total;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Container(
        width: 148,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: DayBookColors.bodyBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value == 1 ? 'Coins · amount' : '₹$value · notes',
              style: DayBookStyles.labelStrong.copyWith(fontSize: 13)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            keyboardType: TextInputType.numberWithOptions(decimal: value == 1),
            inputFormatters: [
              value == 1
                  ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                  : FilteringTextInputFormatter.digitsOnly,
            ],
            style: DayBookStyles.value.copyWith(fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: '0',
              prefixText: value == 1 ? '₹ ' : null,
            ),
          ),
          const SizedBox(height: 5),
          Text(_money(total),
              style: DayBookStyles.labelStrong.copyWith(fontSize: 13)),
        ]),
      );
}

class EodBankCount extends StatelessWidget {
  const EodBankCount(
      {super.key, required this.controller, required this.expected});
  final TextEditingController controller;
  final double expected;

  @override
  Widget build(BuildContext context) => EodPanel(
        title: 'Actual Bank Balance',
        icon: Icons.account_balance_outlined,
        child: LayoutBuilder(builder: (context, constraints) {
          final expectedLabel = Text('Expected ${_money(expected)}',
              style: DayBookStyles.labelStrong.copyWith(fontSize: 14));
          final input = TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}'))
            ],
            style: DayBookStyles.value.copyWith(fontSize: 15),
            decoration: const InputDecoration(
              labelText: 'Counted bank balance',
              prefixText: '₹ ',
              isDense: true,
            ),
          );
          if (constraints.maxWidth < 420) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [expectedLabel, const SizedBox(height: 9), input]);
          }
          return Row(children: [
            Expanded(child: expectedLabel),
            const SizedBox(width: 12),
            SizedBox(width: 220, child: input),
          ]);
        }),
      );
}

class EodVerificationSummary extends StatelessWidget {
  const EodVerificationSummary(
      {super.key,
      required this.expectedCash,
      required this.countedCash,
      required this.expectedBank,
      required this.countedBank,
      this.expenseTotal = 0});
  final double expectedCash;
  final double? countedCash;
  final double expectedBank;
  final double? countedBank;
  final double expenseTotal;

  @override
  Widget build(BuildContext context) {
    final cashDiff = countedCash == null ? null : countedCash! - expectedCash;
    final bankDiff = countedBank == null ? null : countedBank! - expectedBank;
    final expectedTotal = expectedCash + expectedBank;
    final countedTotal = countedCash == null || countedBank == null
        ? null
        : countedCash! + countedBank!;
    final matched = cashDiff != null &&
        bankDiff != null &&
        cashDiff.abs() < 0.01 &&
        bankDiff.abs() < 0.01;
    return EodPanel(
      title: 'Verification Summary',
      icon: Icons.fact_check_outlined,
      child: Column(children: [
        _DiffLine(
            label: 'Cash',
            expected: expectedCash,
            actual: countedCash,
            difference: cashDiff),
        const SizedBox(height: 7),
        _DiffLine(
            label: 'Bank',
            expected: expectedBank,
            actual: countedBank,
            difference: bankDiff),
        if (expenseTotal > 0.005) ...[
          const SizedBox(height: 7),
          Row(children: [
            Text('Expenses Paid',
                style: DayBookStyles.labelStrong.copyWith(fontSize: 14)),
            const Spacer(),
            Text(_money(expenseTotal),
                style: DayBookStyles.value
                    .copyWith(fontSize: 15, color: DayBookColors.negative)),
          ]),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: DayBookColors.brandGoldSoft,
            border: Border.all(color: DayBookColors.brandGoldBorder),
            borderRadius: BorderRadius.circular(9),
          ),
          child: _DiffLine(
            label: 'Total',
            expected: expectedTotal,
            actual: countedTotal,
            difference:
                countedTotal == null ? null : countedTotal - expectedTotal,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: matched
                ? DayBookColors.positiveSoft
                : DayBookColors.warningSoft,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
                color: matched
                    ? DayBookColors.positiveBorder
                    : DayBookColors.warningBorder),
          ),
          child: Row(children: [
            Icon(matched ? Icons.verified_outlined : Icons.info_outline_rounded,
                color:
                    matched ? DayBookColors.positive : DayBookColors.warning),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    matched
                        ? 'Cash and bank both match the system closing.'
                        : 'Complete both counts and resolve each difference.',
                    style: DayBookStyles.labelStrong.copyWith(fontSize: 14))),
            if (cashDiff != null && bankDiff != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: matched
                      ? DayBookColors.positiveSoft
                      : DayBookColors.negativeSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: matched
                        ? DayBookColors.positiveBorder
                        : DayBookColors.negativeBorder,
                  ),
                ),
                child: Text(matched ? 'Verified' : 'Mismatch',
                    style: DayBookStyles.labelStrong.copyWith(
                      fontSize: 13,
                      color: matched
                          ? DayBookColors.positive
                          : DayBookColors.negative,
                    )),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _DiffLine extends StatelessWidget {
  const _DiffLine(
      {required this.label,
      required this.expected,
      required this.actual,
      required this.difference});
  final String label;
  final double expected;
  final double? actual;
  final double? difference;

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(
            width: 45,
            child: Text(label,
                style: DayBookStyles.labelStrong.copyWith(fontSize: 14))),
        Expanded(
            child: Text('System ${_money(expected)}',
                style: DayBookStyles.labelStrong.copyWith(fontSize: 13))),
        Expanded(
            child: Text('Counted ${actual == null ? '—' : _money(actual!)}',
                style: DayBookStyles.labelStrong.copyWith(fontSize: 13))),
        Text(
            difference == null
                ? 'Pending'
                : difference!.abs() < 0.01
                    ? 'Matched'
                    : _money(difference!),
            style: DayBookStyles.labelStrong.copyWith(
                fontSize: 13,
                color: difference == null
                    ? DayBookColors.warning
                    : difference!.abs() < 0.01
                        ? DayBookColors.positive
                        : DayBookColors.negative)),
      ]);
}

class EodNotice extends StatelessWidget {
  const EodNotice({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DayBookColors.warningSoft,
          border: Border.all(color: DayBookColors.warningBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.warning_amber_rounded,
              color: DayBookColors.warning, size: 21),
          const SizedBox(width: 9),
          Expanded(
              child: Text(text,
                  style: DayBookStyles.labelStrong.copyWith(fontSize: 13))),
        ]),
      );
}

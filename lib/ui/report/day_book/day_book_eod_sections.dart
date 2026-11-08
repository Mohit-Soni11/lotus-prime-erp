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
  const EodSystemClosing({super.key, required this.date, required this.flow});
  final DateTime date;
  final DayBookMoneyFlow flow;

  @override
  Widget build(BuildContext context) => EodPanel(
        title: 'System Closing · ${DateFormat('d MMM yyyy').format(date)}',
        icon: Icons.history_rounded,
        child: Column(children: [
          _BalanceLine(
              label: 'Cash',
              icon: Icons.payments_outlined,
              opening: flow.openingCash,
              incoming: flow.cashIn,
              outgoing: flow.cashOut,
              closing: flow.closingCash),
          const SizedBox(height: 7),
          _BalanceLine(
              label: 'Bank',
              icon: Icons.account_balance_outlined,
              opening: flow.openingBank,
              incoming: flow.bankIn,
              outgoing: flow.bankOut,
              closing: flow.closingBank),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('Total expected closing', style: DayBookStyles.labelStrong),
            const SizedBox(width: 12),
            Text(_money(flow.closingTotal),
                style: DayBookStyles.value.copyWith(fontSize: 17)),
          ]),
        ]),
      );
}

class _BalanceLine extends StatelessWidget {
  const _BalanceLine(
      {required this.label,
      required this.icon,
      required this.opening,
      required this.incoming,
      required this.outgoing,
      required this.closing});
  final String label;
  final IconData icon;
  final double opening;
  final double incoming;
  final double outgoing;
  final double closing;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: DayBookColors.bodyBorder),
        ),
        child: Row(children: [
          Icon(icon, color: DayBookColors.goldMetal, size: 20),
          const SizedBox(width: 8),
          SizedBox(
              width: 45,
              child: Text(label,
                  style: DayBookStyles.labelStrong.copyWith(fontSize: 14))),
          Expanded(
              child: Text(
            '${_money(opening)} + ${_money(incoming)} − ${_money(outgoing)}',
            textAlign: TextAlign.right,
            style: DayBookStyles.labelStrong.copyWith(fontSize: 13),
          )),
          const SizedBox(width: 9),
          Text(_money(closing),
              style: DayBookStyles.value.copyWith(fontSize: 15)),
        ]),
      );
}

class EodCashCount extends StatelessWidget {
  const EodCashCount(
      {super.key,
      required this.ctrl,
      required this.confirmed,
      required this.onConfirmed});
  final DayBookController ctrl;
  final bool confirmed;
  final ValueChanged<bool> onConfirmed;

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
        const SizedBox(height: 4),
        CheckboxListTile(
          value: confirmed,
          onChanged: (value) => onConfirmed(value ?? false),
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text('I counted the entire cash drawer',
              style: DayBookStyles.labelStrong.copyWith(fontSize: 13)),
        ),
      ]),
    );
  }
}

class _DenominationInput extends StatelessWidget {
  const _DenominationInput(
      {required this.value, required this.controller, required this.total});
  final int value;
  final TextEditingController controller;
  final num total;

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
      required this.countedBank});
  final double expectedCash;
  final double? countedCash;
  final double expectedBank;
  final double? countedBank;

  @override
  Widget build(BuildContext context) {
    final cashDiff = countedCash == null ? null : countedCash! - expectedCash;
    final bankDiff = countedBank == null ? null : countedBank! - expectedBank;
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
        const SizedBox(height: 10),
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
              Text(_money(cashDiff + bankDiff),
                  style: DayBookStyles.value.copyWith(
                      fontSize: 15,
                      color: matched
                          ? DayBookColors.positive
                          : DayBookColors.negative)),
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

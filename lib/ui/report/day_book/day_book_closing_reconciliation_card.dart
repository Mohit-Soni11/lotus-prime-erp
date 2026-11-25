import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_eod_sections.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

class EodClosingReconciliation extends StatelessWidget {
  const EodClosingReconciliation({
    super.key,
    required this.expectedCash,
    required this.countedCash,
    required this.expectedBank,
    required this.countedBank,
  });

  final double expectedCash;
  final double? countedCash;
  final double expectedBank;
  final double? countedBank;

  @override
  Widget build(BuildContext context) {
    final cashDifference =
        countedCash == null ? null : countedCash! - expectedCash;
    final bankDifference =
        countedBank == null ? null : countedBank! - expectedBank;
    final actualTotal = countedCash == null || countedBank == null
        ? null
        : countedCash! + countedBank!;
    final balanced = cashDifference != null &&
        bankDifference != null &&
        cashDifference.abs() < 0.01 &&
        bankDifference.abs() < 0.01;
    final offsetting = !balanced &&
        cashDifference != null &&
        bankDifference != null &&
        (cashDifference + bankDifference).abs() < 0.01;
    final rows = [
      _BalanceLine('Cash', expectedCash, countedCash, cashDifference),
      _BalanceLine('Bank', expectedBank, countedBank, bankDifference),
      _BalanceLine(
        'Total',
        expectedCash + expectedBank,
        actualTotal,
        actualTotal == null ? null : actualTotal - expectedCash - expectedBank,
        offsetting: offsetting,
      ),
    ];

    return EodPanel(
      title: 'Balance Reconciliation',
      icon: Icons.fact_check_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < 480) {
              return Column(children: [
                for (final row in rows) ...[
                  if (row != rows.first) const SizedBox(height: 7),
                  _CompactBalanceLine(row: row),
                ],
              ]);
            }
            return Column(children: [
              const _TableHeader(),
              for (final row in rows) _WideBalanceLine(row: row),
            ]);
          }),
          if (balanced || countedCash == null || countedBank == null) ...[
            const SizedBox(height: 9),
            Row(children: [
              Icon(
                balanced ? Icons.verified_rounded : Icons.info_outline_rounded,
                size: 19,
                color:
                    balanced ? DayBookColors.positive : DayBookColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  balanced
                      ? 'Cash and bank match. Ready to close.'
                      : 'Enter physical cash and actual bank balances.',
                  style: DayBookStyles.labelStrong.copyWith(fontSize: 13),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

class _BalanceLine {
  const _BalanceLine(this.label, this.recorded, this.actual, this.difference,
      {this.offsetting = false});

  final String label;
  final double recorded;
  final double? actual;
  final double? difference;
  final bool offsetting;

  String get recordedText => _currency.format(recorded);
  String get actualText => actual == null ? '—' : _currency.format(actual);
  String get resultText => difference == null
      ? 'Pending'
      : difference!.abs() < 0.01
          ? offsetting
              ? 'Net zero'
              : 'Matched'
          : difference! < 0
              ? 'Short ${_currency.format(-difference!)}'
              : 'Excess ${_currency.format(difference)}';
  Color get resultColor => difference == null
      ? DayBookColors.warning
      : difference!.abs() < 0.01
          ? offsetting
              ? DayBookColors.warning
              : DayBookColors.positive
          : difference! < 0
              ? DayBookColors.negative
              : DayBookColors.information;
  Color get resultBackground => difference == null || offsetting
      ? DayBookColors.warningSoft
      : difference!.abs() < 0.01
          ? DayBookColors.positiveSoft
          : difference! < 0
              ? DayBookColors.negativeSoft
              : DayBookColors.informationSoft;
  IconData get resultIcon => difference == null || offsetting
      ? Icons.info_outline_rounded
      : difference!.abs() < 0.01
          ? Icons.check_circle_outline_rounded
          : difference! < 0
              ? Icons.remove_circle_outline_rounded
              : Icons.add_circle_outline_rounded;
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) => Row(children: [
        const SizedBox(width: 70),
        Expanded(child: _value('Recorded')),
        Expanded(child: _value('Actual')),
        Expanded(child: _value('Difference')),
      ]);
}

class _WideBalanceLine extends StatelessWidget {
  const _WideBalanceLine({required this.row});
  final _BalanceLine row;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          SizedBox(width: 70, child: _value(row.label)),
          Expanded(child: _value(row.recordedText)),
          Expanded(child: _value(row.actualText)),
          Expanded(child: _VarianceBadge(row: row)),
        ]),
      );
}

class _CompactBalanceLine extends StatelessWidget {
  const _CompactBalanceLine({required this.row});
  final _BalanceLine row;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: DayBookColors.bodyBorder),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: _value(row.label)),
            Flexible(child: _VarianceBadge(row: row)),
          ]),
          const SizedBox(height: 5),
          Wrap(spacing: 12, runSpacing: 4, children: [
            _value('Recorded ${row.recordedText}'),
            _value('Actual ${row.actualText}'),
          ]),
        ]),
      );
}

class _VarianceBadge extends StatelessWidget {
  const _VarianceBadge({required this.row});

  final _BalanceLine row;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: row.resultBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: row.resultColor.withValues(alpha: 0.24)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(row.resultIcon, size: 15, color: row.resultColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                row.resultText,
                style: DayBookStyles.labelStrong
                    .copyWith(fontSize: 13, color: row.resultColor),
              ),
            ),
          ]),
        ),
      );
}

Widget _value(String text, {Color? color}) => Text(
      text,
      style: DayBookStyles.labelStrong.copyWith(fontSize: 13, color: color),
    );

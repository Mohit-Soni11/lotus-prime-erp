import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/reports/day_book/day_book_money_flow.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_transaction_register.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: 'INR ');

class DayBookMoneyPanel extends StatelessWidget {
  const DayBookMoneyPanel({super.key, required this.flow});

  final DayBookMoneyFlow flow;

  @override
  Widget build(BuildContext context) {
    final sourceIn = flow.bySource(incoming: true);
    final sourceOut = flow.bySource(incoming: false);
    final modeIn = flow.byMode(incoming: true);
    final modeOut = flow.byMode(incoming: false);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: DayBookStyles.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Money Movement', style: DayBookStyles.pageTitle),
          const SizedBox(height: 4),
          Text(
            'Posted cash and bank movements for the selected day. Internal transfers are shown separately.',
            style: DayBookStyles.sectionSubtitle,
          ),
          const SizedBox(height: 16),
          _ResponsivePair(
            first: _PositionCard(
              title: 'Physical Cash',
              icon: DayBookIcons.cash,
              opening: flow.openingCash,
              incoming: flow.cashIn,
              outgoing: flow.cashOut,
              closing: flow.closingCash,
            ),
            second: _PositionCard(
              title: 'Bank Accounts',
              icon: DayBookIcons.bank,
              opening: flow.openingBank,
              incoming: flow.bankIn,
              outgoing: flow.bankOut,
              closing: flow.closingBank,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bank position follows recorded entries; cheque clearing may occur later.',
            style: DayBookStyles.label,
          ),
          if (flow.internalIn != 0 || flow.internalOut != 0) ...[
            const SizedBox(height: 12),
            Text(
              'Internal transfers: in ${_currency.format(flow.internalIn)} · out ${_currency.format(flow.internalOut)}',
              style: DayBookStyles.label,
            ),
          ],
          if ((flow.internalIn - flow.internalOut).abs() > 0.005) ...[
            const SizedBox(height: 6),
            Text(
              'Internal transfers are not balanced. Check the matching cash or bank entry.',
              style: DayBookStyles.labelStrong.copyWith(
                color: DayBookColors.negative,
              ),
            ),
          ],
          if (flow.unclearedChequeIn != 0 || flow.unclearedChequeOut != 0) ...[
            const SizedBox(height: 6),
            Text(
              'Uncleared cheques: received ${_currency.format(flow.unclearedChequeIn)} · issued ${_currency.format(flow.unclearedChequeOut)}. Recorded bank balance includes these entries.',
              style: DayBookStyles.labelStrong.copyWith(
                color: DayBookColors.warning,
              ),
            ),
          ],
          if (sourceIn.isNotEmpty || sourceOut.isNotEmpty) ...[
            const SizedBox(height: 18),
            if (sourceIn.isNotEmpty && sourceOut.isNotEmpty)
              _ResponsivePair(
                first: _BreakdownCard(
                    title: 'Money In by Source', values: sourceIn),
                second: _BreakdownCard(
                    title: 'Money Out by Source', values: sourceOut),
              )
            else
              _BreakdownCard(
                title: sourceIn.isNotEmpty
                    ? 'Money In by Source'
                    : 'Money Out by Source',
                values: sourceIn.isNotEmpty ? sourceIn : sourceOut,
              ),
          ],
          if (modeIn.isNotEmpty || modeOut.isNotEmpty) ...[
            const SizedBox(height: 12),
            if (modeIn.isNotEmpty && modeOut.isNotEmpty)
              _ResponsivePair(
                first:
                    _BreakdownCard(title: 'Money In by Mode', values: modeIn),
                second:
                    _BreakdownCard(title: 'Money Out by Mode', values: modeOut),
              )
            else
              _BreakdownCard(
                title: modeIn.isNotEmpty
                    ? 'Money In by Mode'
                    : 'Money Out by Mode',
                values: modeIn.isNotEmpty ? modeIn : modeOut,
              ),
          ],
          if (flow.byBankAccount(incoming: true).isNotEmpty ||
              flow.byBankAccount(incoming: false).isNotEmpty) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Bank Account & Reconciliation Detail',
                  style: DayBookStyles.sectionTitle),
              children: [
                _ResponsivePair(
                  first: _BreakdownCard(
                    title: 'Bank In by Account',
                    values: flow.byBankAccount(incoming: true),
                  ),
                  second: _BreakdownCard(
                    title: 'Bank Out by Account',
                    values: flow.byBankAccount(incoming: false),
                  ),
                ),
                const SizedBox(height: 12),
                _ResponsivePair(
                  first: _BreakdownCard(
                    title: 'Bank Receipts by Reconciliation',
                    values: flow.byBankReconciliation(incoming: true),
                  ),
                  second: _BreakdownCard(
                    title: 'Bank Payments by Reconciliation',
                    values: flow.byBankReconciliation(incoming: false),
                  ),
                ),
              ],
            ),
          ],
          if (flow.entries.isNotEmpty) ...[
            const SizedBox(height: 12),
            DayBookTransactionRegister(entries: flow.entries),
          ],
        ],
      ),
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 680
            ? Column(children: [first, const SizedBox(height: 12), second])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: first),
                  const SizedBox(width: 12),
                  Expanded(child: second),
                ],
              ),
      );
}

class _PositionCard extends StatelessWidget {
  const _PositionCard({
    required this.title,
    required this.icon,
    required this.opening,
    required this.incoming,
    required this.outgoing,
    required this.closing,
  });

  final String title;
  final IconData icon;
  final double opening;
  final double incoming;
  final double outgoing;
  final double closing;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: DayBookStyles.softPanel(
          color: DayBookColors.bodySubtle,
          borderColor: DayBookColors.bodyBorder,
        ),
        child: Column(
          children: [
            Row(children: [
              Icon(icon, size: 18, color: DayBookColors.brandGold),
              const SizedBox(width: 8),
              Text(title, style: DayBookStyles.sectionTitle),
            ]),
            const SizedBox(height: 12),
            _AmountLine('Opening', opening),
            _AmountLine('In', incoming),
            _AmountLine('Out', outgoing),
            const Divider(color: DayBookColors.bodyBorder),
            _AmountLine('Closing', closing, strong: true),
          ],
        ),
      );
}

class _AmountLine extends StatelessWidget {
  const _AmountLine(this.label, this.amount, {this.strong = false});
  final String label;
  final double amount;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(label,
              style: strong ? DayBookStyles.labelStrong : DayBookStyles.label),
          const Spacer(),
          Flexible(
            child: Text(
              _currency.format(amount),
              style: strong ? DayBookStyles.value : DayBookStyles.labelStrong,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      );
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.title, required this.values});
  final String title;
  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    final sorted = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: DayBookStyles.softPanel(
        color: DayBookColors.bodySubtle,
        borderColor: DayBookColors.bodyBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DayBookStyles.sectionTitle),
          const SizedBox(height: 10),
          if (sorted.isEmpty)
            Text('No movements', style: DayBookStyles.label)
          else
            for (final item in sorted)
              _AmountLine(_readable(item.key), item.value),
        ],
      ),
    );
  }
}

String _readable(String value) {
  final words = value.replaceAll('_', ' ').toLowerCase().split(' ');
  return words
      .map((word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

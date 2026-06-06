import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookEodDialog extends StatefulWidget {
  const DayBookEodDialog({super.key, required this.ctrl});

  final DayBookController ctrl;

  @override
  State<DayBookEodDialog> createState() => _DayBookEodDialogState();
}

class _DayBookEodDialogState extends State<DayBookEodDialog> {
  bool _isClosing = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 780),
        decoration: BoxDecoration(
          color: DayBookColors.bodyPanel,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: DayBookColors.overlay,
              blurRadius: 32,
              offset: Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ListenableBuilder(
          listenable: widget.ctrl,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogHeader(onClose: () => Navigator.of(context).pop()),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionIntro(),
                        const SizedBox(height: 20),
                        _DenominationTable(ctrl: widget.ctrl),
                        const SizedBox(height: 20),
                        _ReconciliationSummary(ctrl: widget.ctrl),
                      ],
                    ),
                  ),
                ),
                _DialogActions(
                  ctrl: widget.ctrl,
                  isClosing: _isClosing,
                  onClose: _closeDay,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _closeDay() async {
    setState(() => _isClosing = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final closed = await widget.ctrl.closeDay();

    if (!mounted) return;
    setState(() => _isClosing = false);

    if (closed) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text(DayBookStrings.closeSuccess)),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('The cash count must match before closing the day.'),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DayBookColors.shellBg,
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DayBookColors.brandGold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DayBookColors.brandGold.withValues(alpha: 0.28),
              ),
            ),
            child: const Icon(
              DayBookIcons.reconcile,
              color: DayBookColors.brandGold,
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DayBookStrings.settlementTitle,
                  style: DayBookStyles.appBarTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  DayBookStrings.settlementSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DayBookStyles.appBarSubtitle,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: DayBookStrings.cancel,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: DayBookColors.shellMuted,
          ),
        ],
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          DayBookIcons.cash,
          color: DayBookColors.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Physical cash count', style: DayBookStyles.sectionTitle),
              const SizedBox(height: 4),
              Text(
                'Enter the quantity for each denomination in the cash drawer.',
                style: DayBookStyles.sectionSubtitle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DenominationTable extends StatelessWidget {
  const _DenominationTable({required this.ctrl});

  final DayBookController ctrl;

  @override
  Widget build(BuildContext context) {
    final rows = <_DenominationRowData>[
      _DenominationRowData(
        label: 'INR 500',
        multiplier: 500,
        controller: ctrl.denom500Ctrl,
      ),
      _DenominationRowData(
        label: 'INR 200',
        multiplier: 200,
        controller: ctrl.denom200Ctrl,
      ),
      _DenominationRowData(
        label: 'INR 100',
        multiplier: 100,
        controller: ctrl.denom100Ctrl,
      ),
      _DenominationRowData(
        label: 'INR 50',
        multiplier: 50,
        controller: ctrl.denom50Ctrl,
      ),
      _DenominationRowData(
        label: 'INR 20',
        multiplier: 20,
        controller: ctrl.denom20Ctrl,
      ),
      _DenominationRowData(
        label: 'INR 10',
        multiplier: 10,
        controller: ctrl.denom10Ctrl,
      ),
      _DenominationRowData(
        label: 'Coins',
        multiplier: 1,
        controller: ctrl.denomCoinsCtrl,
        allowDecimal: true,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: DayBookColors.bodyBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 620,
          child: Column(
            children: [
              Container(
                color: DayBookColors.bodySubtle,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DayBookStrings.denomination,
                        style: DayBookStyles.label,
                      ),
                    ),
                    SizedBox(
                      width: 96,
                      child: Text(
                        DayBookStrings.quantity,
                        textAlign: TextAlign.center,
                        style: DayBookStyles.label,
                      ),
                    ),
                    SizedBox(
                      width: 128,
                      child: Text(
                        DayBookStrings.amount,
                        textAlign: TextAlign.right,
                        style: DayBookStyles.label,
                      ),
                    ),
                  ],
                ),
              ),
              for (var index = 0; index < rows.length; index++)
                _DenominationRow(
                  data: rows[index],
                  showDivider: index != rows.length - 1,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DenominationRowData {
  const _DenominationRowData({
    required this.label,
    required this.multiplier,
    required this.controller,
    this.allowDecimal = false,
  });

  final String label;
  final double multiplier;
  final TextEditingController controller;
  final bool allowDecimal;
}

class _DenominationRow extends StatelessWidget {
  const _DenominationRow({
    required this.data,
    required this.showDivider,
  });

  final _DenominationRowData data;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final count = double.tryParse(data.controller.text.trim()) ?? 0;
    final amount = count * data.multiplier;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: DayBookColors.bodyBorder),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(data.label, style: DayBookStyles.labelStrong),
          ),
          SizedBox(
            width: 96,
            child: TextField(
              controller: data.controller,
              keyboardType: TextInputType.numberWithOptions(
                decimal: data.allowDecimal,
              ),
              inputFormatters: [
                if (data.allowDecimal)
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                else
                  FilteringTextInputFormatter.digitsOnly,
              ],
              textAlign: TextAlign.center,
              style: DayBookStyles.value,
              decoration: const InputDecoration(
                isDense: true,
                hintText: '0',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: 128,
            child: Text(
              _money(amount),
              textAlign: TextAlign.right,
              style: DayBookStyles.value,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReconciliationSummary extends StatelessWidget {
  const _ReconciliationSummary({required this.ctrl});

  final DayBookController ctrl;

  @override
  Widget build(BuildContext context) {
    final difference = ctrl.cashDifference;
    final matched = ctrl.isCashMatched;
    final differenceColor = matched
        ? DayBookColors.positive
        : difference < 0
            ? DayBookColors.negative
            : DayBookColors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 540;
            final metrics = [
              _SummaryMetric(
                label: DayBookStrings.systemBalance,
                value: _money(ctrl.systemCashAmount),
                icon: Icons.computer_rounded,
              ),
              _SummaryMetric(
                label: DayBookStrings.physicalBalance,
                value: _money(ctrl.physicalCashAmount),
                icon: Icons.payments_outlined,
              ),
              _SummaryMetric(
                label: DayBookStrings.difference,
                value: _signedMoney(difference),
                icon: Icons.compare_arrows_rounded,
                color: differenceColor,
              ),
            ];

            if (stacked) {
              return Column(
                children: [
                  for (var index = 0; index < metrics.length; index++) ...[
                    metrics[index],
                    if (index != metrics.length - 1) const SizedBox(height: 8),
                  ],
                ],
              );
            }

            return Row(
              children: [
                for (var index = 0; index < metrics.length; index++) ...[
                  Expanded(child: metrics[index]),
                  if (index != metrics.length - 1) const SizedBox(width: 8),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: differenceColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: differenceColor.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            children: [
              Icon(
                matched
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                color: differenceColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  matched ? DayBookStrings.matched : DayBookStrings.mismatch,
                  style: DayBookStyles.labelStrong.copyWith(
                    color: differenceColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.color = DayBookColors.textPrimary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DayBookColors.bodySubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DayBookColors.bodyBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: DayBookColors.textMuted, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: DayBookStyles.label),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: DayBookStyles.value.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({
    required this.ctrl,
    required this.isClosing,
    required this.onClose,
  });

  final DayBookController ctrl;
  final bool isClosing;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final resetButton = OutlinedButton.icon(
      onPressed: isClosing ? null : ctrl.resetDenomination,
      icon: const Icon(Icons.restart_alt_rounded, size: 18),
      label: const Text(DayBookStrings.reset),
    );
    final cancelButton = TextButton(
      onPressed: isClosing ? null : () => Navigator.of(context).pop(),
      child: const Text(DayBookStrings.cancel),
    );
    final closeButton = FilledButton.icon(
      onPressed: ctrl.isCashMatched && !isClosing ? onClose : null,
      icon: isClosing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.lock_outline_rounded, size: 18),
      label: Text(
        isClosing ? 'Closing day...' : DayBookStrings.closeAndLock,
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      decoration: const BoxDecoration(
        color: DayBookColors.bodyPanel,
        border: Border(
          top: BorderSide(color: DayBookColors.bodyBorder),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 500) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                closeButton,
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: resetButton),
                    const SizedBox(width: 8),
                    Expanded(child: cancelButton),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              resetButton,
              const Spacer(),
              cancelButton,
              const SizedBox(width: 8),
              closeButton,
            ],
          );
        },
      ),
    );
  }
}

String _money(double value) {
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'INR ',
    decimalDigits: 2,
  ).format(value);
}

String _signedMoney(double value) {
  if (value == 0) return _money(0);
  final prefix = value > 0 ? '+' : '-';
  return '$prefix${_money(value.abs())}';
}

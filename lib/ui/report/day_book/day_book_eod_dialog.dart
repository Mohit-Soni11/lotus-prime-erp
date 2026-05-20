// =============================================================================
// FILE        : day_book_eod_dialog.dart
// MODULE      : Reports & Analytics â†’ Day Book
// LAYER       : UI
// DESCRIPTION : End of Day Settlement Dialog.
//               â€¢ Denomination calculator (physical cash count)
//               â€¢ System amount vs physical amount comparison
//               â€¢ Match â†’ "Close Day & Lock Ledger" button active
//               â€¢ Mismatch â†’ difference highlighted in red
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import '../../../logic/report/day_book/day_book_controller.dart';

class DayBookEodDialog extends StatelessWidget {
  final DayBookController ctrl;
  const DayBookEodDialog({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ListenableBuilder(
        listenable: ctrl,
        builder: (_, __) {
          final isMatched = ctrl.isCashMatched;
          final diff = ctrl.cashDifference;

          return Container(
            width: 560,
            constraints: const BoxConstraints(maxHeight: 680),
            decoration: DayBookStyles.eodCard,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _EodHeader(),

                const Divider(height: 1, color: DayBookColors.divider),

                // â”€â”€ Body (scrollable) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      // System Amount Card
                      _SummaryRow(
                        label: DayBookStrings.eodSystemAmt,
                        value: ctrl.systemCashAmount,
                        color: DayBookColors.info,
                        icon: DayBookIcons.vaultIcon,
                      ),
                      const SizedBox(height: 12),

                      // Denomination Input Grid
                      _DenominationGrid(ctrl: ctrl),
                      const SizedBox(height: 16),

                      // Physical Count Row
                      _SummaryRow(
                        label: DayBookStrings.eodPhysAmt,
                        value: ctrl.physicalCashAmount,
                        color: DayBookColors.cashInAccent,
                        icon: DayBookIcons.denomCalc,
                      ),
                      const SizedBox(height: 8),

                      // Difference Row
                      _DifferenceRow(diff: diff, isMatched: isMatched),
                    ]),
                  ),
                ),

                const Divider(height: 1, color: DayBookColors.divider),

                // â”€â”€ Footer Buttons â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _EodFooter(ctrl: ctrl, isMatched: isMatched, context: context),
              ],
            ),
          );
        },
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Header
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _EodHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: DayBookColors.shellPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [DayBookColors.goldGradStart, DayBookColors.brandGold],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              const Icon(DayBookIcons.eodSettle, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(DayBookStrings.eodTitle,
              style: DayBookStyles.appBarTitle.copyWith(fontSize: 15)),
          Text(DayBookStrings.eodSubtitle, style: DayBookStyles.appBarSub),
        ]),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: DayBookColors.shellBorder.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(DayBookIcons.close,
                color: DayBookColors.shellTitle, size: 16),
          ),
        ),
      ]),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Denomination Grid
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DenominationGrid extends StatelessWidget {
  final DayBookController ctrl;
  const _DenominationGrid({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DayBookColors.bodyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DayBookColors.bodyBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        // Header row
        const Row(children: [
          Expanded(
              flex: 2,
              child: Text('Denomination',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DayBookColors.textMuted,
                      letterSpacing: 0.5))),
          Expanded(
              child: Text('Count',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DayBookColors.textMuted,
                      letterSpacing: 0.5))),
          Expanded(
              child: Text('Amount',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DayBookColors.textMuted,
                      letterSpacing: 0.5))),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1, color: DayBookColors.divider),
        const SizedBox(height: 10),

        // Denomination rows
        _DenomRow(
            label: DayBookStrings.note500,
            ctrl: ctrl.denom500Ctrl,
            multiplier: 500),
        _DenomRow(
            label: DayBookStrings.note200,
            ctrl: ctrl.denom200Ctrl,
            multiplier: 200),
        _DenomRow(
            label: DayBookStrings.note100,
            ctrl: ctrl.denom100Ctrl,
            multiplier: 100),
        _DenomRow(
            label: DayBookStrings.note50,
            ctrl: ctrl.denom50Ctrl,
            multiplier: 50),
        _DenomRow(
            label: DayBookStrings.note20,
            ctrl: ctrl.denom20Ctrl,
            multiplier: 20),
        _DenomRow(
            label: DayBookStrings.note10,
            ctrl: ctrl.denom10Ctrl,
            multiplier: 10),
        _DenomRow(
            label: DayBookStrings.coins,
            ctrl: ctrl.denomCoinsCtrl,
            multiplier: 1,
            isLast: true),
      ]),
    );
  }
}

class _DenomRow extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final int multiplier;
  final bool isLast;

  const _DenomRow({
    required this.label,
    required this.ctrl,
    required this.multiplier,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: ListenableBuilder(
        listenable: ctrl,
        builder: (_, __) {
          final count = int.tryParse(ctrl.text) ?? 0;
          final amount = count * multiplier;

          return Row(children: [
            // Denomination label
            Expanded(
              flex: 2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: DayBookColors.brandGoldLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: DayBookColors.brandGold.withValues(alpha: 0.25)),
                ),
                child: Text(label,
                    style: DayBookStyles.denomLabel
                        .copyWith(color: DayBookColors.brandGold)),
              ),
            ),
            const SizedBox(width: 8),

            // Count input
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: DayBookStyles.denomLabel,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    filled: true,
                    fillColor: DayBookColors.bodyPanel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: DayBookColors.bodyBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: DayBookColors.brandGold, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: DayBookColors.bodyBorder),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Computed amount
            Expanded(
              child: Text(
                'â‚¹${_fmtNum(amount.toDouble())}',
                textAlign: TextAlign.end,
                style: DayBookStyles.denomTotal,
              ),
            ),
          ]);
        },
      ),
    );
  }

  String _fmtNum(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Summary Amount Row
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Text(label, style: DayBookStyles.labelBold),
        const Spacer(),
        Text(
          'â‚¹${value.toStringAsFixed(2)}',
          style: DayBookStyles.amountMedium.copyWith(color: color),
        ),
      ]),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Difference Row
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DifferenceRow extends StatelessWidget {
  final double diff;
  final bool isMatched;

  const _DifferenceRow({required this.diff, required this.isMatched});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:
            isMatched ? DayBookColors.eodMatchBg : DayBookColors.eodMismatchBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMatched
              ? DayBookColors.cashInBorder
              : DayBookColors.cashOutBorder,
          width: isMatched ? 1.0 : 1.5,
        ),
      ),
      child: Row(children: [
        Icon(
          isMatched ? Icons.check_circle_rounded : Icons.error_rounded,
          color: isMatched
              ? DayBookColors.cashInAccent
              : DayBookColors.cashOutAccent,
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(
          isMatched ? DayBookStrings.eodMatched : DayBookStrings.eodMismatch,
          style: DayBookStyles.labelBold.copyWith(
            color: isMatched
                ? DayBookColors.cashInText
                : DayBookColors.cashOutText,
          ),
        ),
        const Spacer(),
        if (!isMatched)
          Text(
            '${diff > 0 ? '+' : ''}â‚¹${diff.toStringAsFixed(2)}',
            style: DayBookStyles.amountSmall.copyWith(
              color: DayBookColors.cashOutAccent,
            ),
          ),
        if (isMatched)
          const Icon(Icons.verified_rounded,
              color: DayBookColors.cashInAccent, size: 16),
      ]),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Footer Buttons
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _EodFooter extends StatelessWidget {
  final DayBookController ctrl;
  final bool isMatched;
  final BuildContext context;

  const _EodFooter({
    required this.ctrl,
    required this.isMatched,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        // Reset button
        OutlinedButton.icon(
          onPressed: ctrl.resetDenomination,
          icon: const Icon(Icons.refresh_rounded, size: 15),
          label: const Text('Reset'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DayBookColors.textSecondary,
            side: const BorderSide(color: DayBookColors.bodyBorder),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        const SizedBox(width: 10),

        // Cancel button
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: DayBookColors.textSecondary,
            side: const BorderSide(color: DayBookColors.bodyBorder),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Cancel'),
        ),

        const Spacer(),

        // Close Day button
        AnimatedOpacity(
          opacity: isMatched ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: ElevatedButton.icon(
            onPressed: isMatched
                ? () async {
                    await ctrl.closeDay();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Day closed & ledger locked âœ“',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        backgroundColor: DayBookColors.cashInAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                : null,
            icon: const Icon(DayBookIcons.lockDay, size: 16),
            label: const Text(DayBookStrings.closeDay,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isMatched ? DayBookColors.brandGold : DayBookColors.textMuted,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: isMatched ? 2 : 0,
            ),
          ),
        ),
      ]),
    );
  }
}

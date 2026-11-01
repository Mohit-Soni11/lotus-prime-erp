import 'package:flutter/material.dart';

import '../../../logic/finance/cash_book/cash_book_controller.dart';
import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';

class CashBookPeriodBar extends StatelessWidget {
  const CashBookPeriodBar({super.key, required this.ctrl});

  final CashBookController ctrl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final modes = _PeriodModes(ctrl: ctrl);
        final navigator = _DateNavigator(ctrl: ctrl);
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CashBookColors.bodyPanel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CashBookColors.bodyBorder),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [modes, const SizedBox(height: 10), navigator],
                )
              : Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Cash Ledger',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: CashBookColors.textDark,
                        ),
                      ),
                    ),
                    SizedBox(width: 310, child: modes),
                    const SizedBox(width: 12),
                    SizedBox(width: 245, child: navigator),
                  ],
                ),
        );
      },
    );
  }
}

class _PeriodModes extends StatelessWidget {
  const _PeriodModes({required this.ctrl});

  final CashBookController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: CashBookColors.summaryChipBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CashBookColors.bodyBorder),
      ),
      child: Row(
        children: [
          for (final mode in CashBookViewMode.values)
            Expanded(
              child: Material(
                color: ctrl.viewMode == mode
                    ? CashBookColors.brandGold
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => ctrl.setViewMode(mode),
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: Text(
                      switch (mode) {
                        CashBookViewMode.daily => CashBookStrings.viewDaily,
                        CashBookViewMode.monthly => CashBookStrings.viewMonthly,
                        CashBookViewMode.yearly => CashBookStrings.viewYearly,
                      },
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CashBookColors.textDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({required this.ctrl});

  final CashBookController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CashBookColors.bodyBorder),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: ctrl.navigatePrevious,
            tooltip: 'Previous period',
            icon: const Icon(CashBookIcons.previous),
          ),
          Expanded(
            child: InkWell(
              onTap: ctrl.isToday ? null : ctrl.jumpToToday,
              child: Center(
                child: Text(
                  ctrl.activeDateLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: CashBookColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: ctrl.isToday && ctrl.viewMode == CashBookViewMode.daily
                ? null
                : ctrl.navigateNext,
            tooltip: 'Next period',
            icon: const Icon(CashBookIcons.next),
          ),
        ],
      ),
    );
  }
}

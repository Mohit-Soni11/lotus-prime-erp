import 'package:flutter/material.dart';

import '../../../models/finance/expense/expense_draft.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_shortage_action_button.dart';

class DayBookClosingFooter extends StatelessWidget {
  const DayBookClosingFooter({
    super.key,
    required this.ready,
    required this.closing,
    required this.expenseDrafts,
    required this.onExpenseDraft,
    required this.onReset,
    required this.onVerify,
  });

  final bool ready;
  final bool closing;
  final List<ExpenseDraft> expenseDrafts;
  final ValueChanged<ExpenseDraft> onExpenseDraft;
  final VoidCallback onReset;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 11, 18, 14),
        decoration: const BoxDecoration(
          color: DayBookColors.bodyPanel,
          border: Border(top: BorderSide(color: DayBookColors.bodyBorder)),
        ),
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 9,
          runSpacing: 8,
          children: [
            for (final draft in expenseDrafts)
              DayBookShortageActionButton(
                draft: draft,
                onPressed: closing ? null : () => onExpenseDraft(draft),
              ),
            OutlinedButton.icon(
              onPressed: closing ? null : onReset,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset Entries'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 17),
                foregroundColor: DayBookColors.goldMetal,
                side: const BorderSide(color: DayBookColors.brandGoldBorder),
                backgroundColor: DayBookColors.brandGoldSoft,
                textStyle: DayBookStyles.button.copyWith(fontSize: 14),
              ),
            ),
            FilledButton.icon(
              onPressed: ready && !closing ? onVerify : null,
              icon: closing
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_outlined, size: 19),
              label: Text(closing ? 'Verifying...' : 'Verify Day Closing'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                backgroundColor: DayBookColors.brandGold,
                foregroundColor: DayBookColors.textPrimary,
                disabledBackgroundColor: DayBookColors.brandGoldSoft,
                disabledForegroundColor: DayBookColors.goldMetal,
                side: const BorderSide(color: DayBookColors.brandGoldBorder),
                elevation: 2,
                textStyle: DayBookStyles.button.copyWith(fontSize: 14),
              ),
            ),
          ],
        ),
      );
}

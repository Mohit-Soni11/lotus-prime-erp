import 'package:flutter/material.dart';

import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookIncomeHeader extends StatelessWidget {
  const DayBookIncomeHeader({super.key, required this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 17, 13, 14),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: DayBookColors.brandGoldSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DayBookColors.brandGoldBorder),
            ),
            child: const Icon(Icons.add_card_rounded,
                color: DayBookColors.goldMetal, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add Income',
                  style: DayBookStyles.pageTitle
                      .copyWith(fontSize: 22, color: DayBookColors.goldMetal)),
              Text('Record a receipt without an invoice.',
                  style: DayBookStyles.labelStrong.copyWith(
                      fontSize: 13, color: DayBookColors.textPrimary)),
            ]),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: DayBookColors.bodySubtle,
              side: const BorderSide(color: DayBookColors.bodyBorder),
            ),
          ),
        ]),
      );
}

class DayBookIncomeSection extends StatelessWidget {
  const DayBookIncomeSection({
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DayBookColors.bodySubtle,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DayBookColors.bodyBorder),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(icon, color: DayBookColors.goldMetal, size: 20),
            const SizedBox(width: 9),
            Text(title,
                style: DayBookStyles.sectionTitle
                    .copyWith(fontSize: 16, color: DayBookColors.goldMetal)),
          ]),
          const SizedBox(height: 11),
          child,
        ]),
      );
}

class DayBookIncomeFooter extends StatelessWidget {
  const DayBookIncomeFooter({
    super.key,
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  final bool saving;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 11, 18, 14),
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: DayBookColors.bodyBorder))),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 19),
              foregroundColor: DayBookColors.textPrimary,
              textStyle: DayBookStyles.button.copyWith(fontSize: 14),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 9),
          FilledButton.icon(
            onPressed: onSave,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              backgroundColor: DayBookColors.brandGold,
              foregroundColor: DayBookColors.textPrimary,
              textStyle: DayBookStyles.button.copyWith(fontSize: 14),
            ),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text(saving ? 'Saving...' : 'Save Income'),
          ),
        ]),
      );
}

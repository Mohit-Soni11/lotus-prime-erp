import 'package:flutter/material.dart';

import '../../../logic/finance/cash_book/cash_book_history_controller.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';

class CashBookViewCards extends StatelessWidget {
  const CashBookViewCards({super.key, required this.controller});

  final CashBookHistoryController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ViewCard(
            title: 'Monthly',
            subtitle: 'Month by month cash activity',
            icon: Icons.calendar_view_month_rounded,
            selected: controller.view == CashBookHistoryView.monthly,
            onTap: controller.showMonthly,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ViewCard(
            title: 'Yearly',
            subtitle: 'Year by year cash activity',
            icon: Icons.calendar_today_rounded,
            selected: controller.view == CashBookHistoryView.yearly,
            onTap: controller.showYearly,
          ),
        ),
      ],
    );
  }
}

class _ViewCard extends StatelessWidget {
  const _ViewCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected ? CashBookColors.brandGoldLight : CashBookColors.bodyPanel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? CashBookColors.brandGold
                  : CashBookColors.bodyBorder,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: CashBookColors.brandGold),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,
                        style: CashBookStyles.labelPrimary
                            .copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CashBookStyles.labelMuted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

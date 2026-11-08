import 'package:flutter/material.dart';

import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookBalanceAttention extends StatelessWidget {
  const DayBookBalanceAttention({super.key});

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('balance-attention'),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFFF7E8), Color(0xFFFFF1DD)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DayBookColors.warningBorder),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.warning_amber_rounded,
              color: DayBookColors.warning, size: 23),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Attention Needed',
                    style: DayBookStyles.sectionTitle.copyWith(
                        fontSize: 16, color: DayBookColors.goldMetal)),
                const SizedBox(height: 4),
                Text(
                  'Cash and bank do not match yesterday’s closing. Check the payment modes and any cash–bank transfer before verifying today’s opening.',
                  style: DayBookStyles.labelStrong
                      .copyWith(fontSize: 13, color: DayBookColors.textPrimary),
                ),
              ],
            ),
          ),
        ]),
      );
}

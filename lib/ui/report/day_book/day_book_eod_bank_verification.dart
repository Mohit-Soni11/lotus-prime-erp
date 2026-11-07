import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/reports/day_book/day_book_balance_verification.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookEodBankVerification extends StatelessWidget {
  const DayBookEodBankVerification({
    super.key,
    required this.verification,
  });

  final DayBookBalanceVerification verification;

  @override
  Widget build(BuildContext context) {
    final money =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final pending = verification.bankNeedsReview;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: DayBookStyles.softPanel(
        color: pending ? DayBookColors.warningSoft : DayBookColors.positiveSoft,
        borderColor: pending
            ? DayBookColors.warningBorder
            : DayBookColors.positiveBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(Icons.account_balance_outlined,
                color: pending ? DayBookColors.warning : DayBookColors.positive,
                size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Opening Bank Verification',
                  style: DayBookStyles.sectionTitle),
            ),
          ]),
          const SizedBox(height: 8),
          _row('Expected', money.format(verification.expectedBank)),
          _row('Actual', money.format(verification.actualBank)),
          _row('Difference', money.format(verification.bankVariance),
              color: pending ? DayBookColors.warning : DayBookColors.positive),
          if (pending) ...[
            const SizedBox(height: 7),
            Text(
              'Reconciliation pending · ${verification.bankReason ?? 'Reason unavailable'}',
              style: DayBookStyles.labelStrong
                  .copyWith(color: DayBookColors.warning),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(child: Text(label, style: DayBookStyles.label)),
          Text(value, style: DayBookStyles.value.copyWith(color: color)),
        ]),
      );
}

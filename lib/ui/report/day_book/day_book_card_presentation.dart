import 'package:flutter/material.dart';

import '../../../models/reports/day_book/day_book_smart_summary.dart';
import 'day_book_smart_format.dart';

class DayBookCardPresentation {
  const DayBookCardPresentation({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
    required this.iconBackground,
    required this.border,
    required this.gradientStart,
    required this.gradientEnd,
    required this.valueColor,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;
  final Color iconBackground;
  final Color border;
  final Color gradientStart;
  final Color gradientEnd;
  final Color valueColor;

  factory DayBookCardPresentation.fromCard(DayBookSmartCard card) {
    final money = card.hasUnknownDue ? '—' : dayBookSmartMoney(card.amount);
    final count = card.count;
    final groups = card.groups;
    final collection =
        groups.fold<double>(0, (sum, row) => sum + row.collection);
    final returns = groups.firstWhere((group) => group.label == 'Sales returns',
        orElse: () => const DayBookSmartGroup('Sales returns'));
    final cancellations = groups.firstWhere(
        (group) => group.label == 'Advance cancellations',
        orElse: () => const DayBookSmartGroup('Advance cancellations'));

    return switch (card.type) {
      DayBookCardType.sales => DayBookCardPresentation(
          label: card.title,
          value: money,
          caption: '$count bills · Collected ${dayBookSmartMoney(collection)}',
          icon: Icons.shopping_bag_outlined,
          accent: const Color(0xFF178E48),
          iconBackground: const Color(0xFFDDF6E5),
          border: const Color(0xFFCDEBD9),
          gradientStart: const Color(0xFFF5FCF7),
          gradientEnd: const Color(0xFFEAF8EF),
          valueColor: const Color(0xFF15793F),
        ),
      DayBookCardType.girviGiven => DayBookCardPresentation(
          label: card.title,
          value: money,
          caption: '$count loans · Principal disbursed',
          icon: Icons.account_balance_rounded,
          accent: const Color(0xFFC73C48),
          iconBackground: const Color(0xFFFFE1E4),
          border: const Color(0xFFF4D4D8),
          gradientStart: const Color(0xFFFFF8F8),
          gradientEnd: const Color(0xFFFFEFF1),
          valueColor: const Color(0xFFB32635),
        ),
      DayBookCardType.advanceReceived => DayBookCardPresentation(
          label: card.title,
          value: money,
          caption: '$count receipts · Customer advances',
          icon: Icons.event_available_rounded,
          accent: const Color(0xFF178E48),
          iconBackground: const Color(0xFFDDF6E5),
          border: const Color(0xFFCDEBD9),
          gradientStart: const Color(0xFFF5FCF7),
          gradientEnd: const Color(0xFFEAF8EF),
          valueColor: const Color(0xFF15793F),
        ),
      DayBookCardType.returnAndCancellation => DayBookCardPresentation(
          label: card.title,
          value: money,
          caption:
              '${returns.count} returns · ${cancellations.count} cancellations',
          icon: Icons.assignment_return_outlined,
          accent: const Color(0xFFC73C48),
          iconBackground: const Color(0xFFFFE1E4),
          border: const Color(0xFFF4D4D8),
          gradientStart: const Color(0xFFFFF8F8),
          gradientEnd: const Color(0xFFFFEFF1),
          valueColor: const Color(0xFFB32635),
        ),
      DayBookCardType.customerMetalPurchase => DayBookCardPresentation(
          label: card.title,
          value: money,
          caption: '$count purchases · Paid ${dayBookSmartMoney(collection)}',
          icon: Icons.diamond_outlined,
          accent: const Color(0xFFC73C48),
          iconBackground: const Color(0xFFFFE1E4),
          border: const Color(0xFFF4D4D8),
          gradientStart: const Color(0xFFFFF8F8),
          gradientEnd: const Color(0xFFFFEFF1),
          valueColor: const Color(0xFFB32635),
        ),
      DayBookCardType.dues => DayBookCardPresentation(
          label: card.title,
          value: money,
          caption: card.hasUnknownDue
              ? '$count invoices · Issue due unavailable'
              : '$count invoices · Newly outstanding',
          icon: Icons.schedule_rounded,
          accent: const Color(0xFFAD7800),
          iconBackground: const Color(0xFFFFEAB8),
          border: const Color(0xFFF5E2B9),
          gradientStart: const Color(0xFFFFFBF1),
          gradientEnd: const Color(0xFFFFF7E5),
          valueColor: const Color(0xFF9E6900),
        ),
      DayBookCardType.receipts => DayBookCardPresentation(
          label: card.title,
          value: money,
          caption: '$count posted receipts · Cash + bank',
          icon: Icons.south_west_rounded,
          accent: const Color(0xFF178E48),
          iconBackground: const Color(0xFFDDF6E5),
          border: const Color(0xFFCDEBD9),
          gradientStart: const Color(0xFFF5FCF7),
          gradientEnd: const Color(0xFFEAF8EF),
          valueColor: const Color(0xFF15793F),
        ),
      DayBookCardType.expenses => DayBookCardPresentation(
          label: card.title,
          value: money,
          caption: '$count entries · Expense Entry records',
          icon: Icons.receipt_long_outlined,
          accent: const Color(0xFFC73C48),
          iconBackground: const Color(0xFFFFE1E4),
          border: const Color(0xFFF4D4D8),
          gradientStart: const Color(0xFFFFF8F8),
          gradientEnd: const Color(0xFFFFEFF1),
          valueColor: const Color(0xFFB32635),
        ),
    };
  }
}

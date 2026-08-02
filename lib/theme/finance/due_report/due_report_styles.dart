import 'package:flutter/material.dart';

import 'due_report_colors.dart';

class DueReportStyles {
  const DueReportStyles._();

  static const TextStyle appBarTitle = TextStyle(
    color: DueReportColors.textLight,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle appBarSubtitle = TextStyle(
    color: DueReportColors.textMuted,
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle onlineBadge = TextStyle(
    color: DueReportColors.onlineGreen,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: DueReportColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const TextStyle label = TextStyle(
    color: DueReportColors.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle muted = TextStyle(
    color: DueReportColors.textMuted,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle amount = TextStyle(
    color: DueReportColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const TextStyle amountDanger = TextStyle(
    color: DueReportColors.danger,
    fontSize: 18,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const TextStyle tableHeader = TextStyle(
    color: DueReportColors.textPrimary,
    fontSize: 13.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const TextStyle rowTitle = TextStyle(
    color: DueReportColors.textPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const TextStyle rowSub = TextStyle(
    color: DueReportColors.textMuted,
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static BoxDecoration panel({Color color = DueReportColors.panelBg}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: DueReportColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  static BoxDecoration flatPanel({Color color = DueReportColors.panelBg}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: DueReportColors.border),
    );
  }
}

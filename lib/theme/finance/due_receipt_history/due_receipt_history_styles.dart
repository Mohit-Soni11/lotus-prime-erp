import 'package:flutter/material.dart';

import 'due_receipt_history_colors.dart';

class DueReceiptHistoryStyles {
  const DueReceiptHistoryStyles._();

  static const TextStyle appBarTitle = TextStyle(
    color: DueReceiptHistoryColors.textLight,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle appBarSubtitle = TextStyle(
    color: DueReceiptHistoryColors.textMuted,
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle onlineBadge = TextStyle(
    color: DueReceiptHistoryColors.onlineGreen,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: DueReceiptHistoryColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const TextStyle label = TextStyle(
    color: DueReceiptHistoryColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle muted = TextStyle(
    color: DueReceiptHistoryColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle amount = TextStyle(
    color: DueReceiptHistoryColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const TextStyle amountSuccess = TextStyle(
    color: DueReceiptHistoryColors.success,
    fontSize: 18,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const TextStyle tableHeader = TextStyle(
    color: DueReceiptHistoryColors.textPrimary,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const TextStyle rowTitle = TextStyle(
    color: DueReceiptHistoryColors.textPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const TextStyle rowSub = TextStyle(
    color: DueReceiptHistoryColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static BoxDecoration panel({Color color = DueReceiptHistoryColors.panelBg}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: DueReceiptHistoryColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  static BoxDecoration flatPanel(
      {Color color = DueReceiptHistoryColors.panelBg}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: DueReceiptHistoryColors.border),
    );
  }
}

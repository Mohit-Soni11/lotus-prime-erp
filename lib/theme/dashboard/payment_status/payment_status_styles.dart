// =============================================================================
// FILE        : payment_status_styles.dart
// MODULE      : Dashboard / Payment Status
// =============================================================================

import 'package:flutter/material.dart';
import 'payment_status_colors.dart';
import '../../../models/dashboard/payment_bill_item.dart';

class PaymentStatusStyles {
  // â”€â”€ DIMENSIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const double cardBorderRadius = 20.0;
  static const double rowBorderRadius = 12.0;
  static const double avatarSize = 40.0;
  static const double badgeBorderRadius = 20.0;
  static const double tabHeight = 32.0;
  static const double tabBorderRadius = 8.0;

  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);
  static const EdgeInsets rowPadding = EdgeInsets.all(14.0);

  // â”€â”€ CARD DECORATION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get cardDecoration => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PaymentStatusColors.cardBgStart,
            PaymentStatusColors.cardBgEnd
          ],
        ),
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 25,
            offset: Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      );

  // â”€â”€ BILL ROW DECORATION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration rowDecoration(PaymentStatus s,
      {bool isPressed = false}) {
    return BoxDecoration(
      color: isPressed
          ? PaymentStatusColors.accentFor(s).withValues(alpha: 0.06)
          : PaymentStatusColors.rowBg,
      borderRadius: BorderRadius.circular(rowBorderRadius),
      border: Border.all(
        color: isPressed
            ? PaymentStatusColors.accentFor(s).withValues(alpha: 0.3)
            : PaymentStatusColors.rowBorder,
      ),
    );
  }

  // â”€â”€ AVATAR DECORATION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration avatarDecoration(PaymentStatus s) => BoxDecoration(
        shape: BoxShape.circle,
        color: PaymentStatusColors.accentDimFor(s),
        border: Border.all(
          color: PaymentStatusColors.accentFor(s).withValues(alpha: 0.35),
        ),
      );

  // â”€â”€ BADGE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration badgeDecoration(PaymentStatus s) => BoxDecoration(
        color: PaymentStatusColors.badgeBgFor(s),
        borderRadius: BorderRadius.circular(badgeBorderRadius),
        border: Border.all(
          color: PaymentStatusColors.accentFor(s).withValues(alpha: 0.3),
        ),
      );

  // â”€â”€ FILTER TAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration tabDecoration({required bool isActive}) => BoxDecoration(
        color: isActive
            ? PaymentStatusColors.tabActiveBg
            : PaymentStatusColors.tabInactiveBg,
        borderRadius: BorderRadius.circular(tabBorderRadius),
        border: isActive
            ? Border.all(color: Colors.white.withValues(alpha: 0.12))
            : null,
      );

  // â”€â”€ STAT CHIP â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const BoxDecoration statChipDecoration = BoxDecoration(
    color: PaymentStatusColors.statChipBg,
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );

  // â”€â”€ TEXT STYLES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const TextStyle headerStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w700,
    color: PaymentStatusColors.accentGold,
    letterSpacing: 1.5,
  );

  static const TextStyle customerNameStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    color: PaymentStatusColors.textPrimary,
  );

  static const TextStyle billNoStyle = TextStyle(
    fontSize: 11.0,
    color: PaymentStatusColors.textSecondary,
  );

  static const TextStyle totalAmountStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    color: PaymentStatusColors.textPrimary,
  );

  static const TextStyle dateStyle = TextStyle(
    fontSize: 11.0,
    color: PaymentStatusColors.textSecondary,
  );

  static const TextStyle amountLabelStyle = TextStyle(
    fontSize: 11.5,
    color: PaymentStatusColors.textSecondary,
  );

  static const TextStyle paidAmountStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w700,
    color: PaymentStatusColors.amountPaid,
  );

  static TextStyle dueAmountStyle(double due) => TextStyle(
        fontSize: 13.0,
        fontWeight: FontWeight.w700,
        color: due > 0
            ? PaymentStatusColors.amountDue
            : PaymentStatusColors.amountZero,
      );

  static const TextStyle badgeStyle = TextStyle(
    fontSize: 9.0,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.3,
  );

  static const TextStyle tabStyle = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle avatarStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  // Stat chip
  static const TextStyle statValueStyle = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w800,
    color: PaymentStatusColors.textPrimary,
  );

  static const TextStyle statLabelStyle = TextStyle(
    fontSize: 10.0,
    color: PaymentStatusColors.textSecondary,
    letterSpacing: 0.3,
  );

  static const TextStyle showMoreStyle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: PaymentStatusColors.accentGold,
  );

  static const TextStyle emptyStyle = TextStyle(
    fontSize: 13.0,
    color: PaymentStatusColors.textSecondary,
  );
}

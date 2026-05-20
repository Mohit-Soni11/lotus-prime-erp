// =============================================================================
// FILE        : payment_status_colors.dart
// MODULE      : Dashboard / Payment Status
// =============================================================================

import 'package:flutter/material.dart';
import '../../../models/dashboard/payment_bill_item.dart';

class PaymentStatusColors {
  // ── CARD BACKGROUND — Same as BillCard/ShopCard ───────────────────────────
  static const Color cardBgStart = Color(0xFF1F2937);
  static const Color cardBgEnd = Color(0xFF0F172A);

  // ── HEADER ────────────────────────────────────────────────────────────────
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentGoldBright = Color(0xFFFFD700);
  static const Gradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
  );

  // ── SUMMARY STAT CHIPS ────────────────────────────────────────────────────
  static const Color statChipBg = Color(0xFF374151); // Glass chip bg
  static const Color statChipBorder = Color(0x1AFFFFFF);

  // ── FILTER TABS ───────────────────────────────────────────────────────────
  static const Color tabActiveBg = Color(0xFF374151);
  static const Color tabInactiveBg = Colors.transparent;
  static const Color tabActiveText = Colors.white;
  static const Color tabInactiveText = Color(0xFF9CA3AF);
  static const Color tabBorder = Color(0x1AFFFFFF);

  // ── BILL ROW ──────────────────────────────────────────────────────────────
  static const Color rowBg = Color(0xFF1C2533); // Slightly darker than card
  static const Color rowBorder = Color(0x14FFFFFF); // 8% white
  static const Color rowDivider = Color(0x0FFFFFFF); // very subtle

  // ── STATUS COLORS — Per payment status ───────────────────────────────────

  // PAID — Emerald Green
  static const Color paidAccent = Color(0xFF10B981);
  static const Color paidAccentDim = Color(0x2010B981);
  static const Color paidBadgeBg = Color(0x2810B981);
  static const Color paidBadgeText = Color(0xFF34D399);
  static const Color paidText = Color(0xFF34D399);

  // PARTIAL — Amber/Gold
  static const Color partialAccent = Color(0xFFF59E0B);
  static const Color partialAccentDim = Color(0x25F59E0B);
  static const Color partialBadgeBg = Color(0x30F59E0B);
  static const Color partialBadgeText = Color(0xFFFBBF24);
  static const Color partialText = Color(0xFFFBBF24);

  // UNPAID — Red
  static const Color unpaidAccent = Color(0xFFEF4444);
  static const Color unpaidAccentDim = Color(0x25EF4444);
  static const Color unpaidBadgeBg = Color(0x30EF4444);
  static const Color unpaidBadgeText = Color(0xFFFC8181);
  static const Color unpaidText = Color(0xFFFC8181);

  // ── TEXT ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0x61FFFFFF);

  // ── PAID AMOUNT always green, DUE always red ──────────────────────────────
  static const Color amountPaid = Color(0xFF34D399);
  static const Color amountDue = Color(0xFFFC8181);
  static const Color amountZero = Color(0xFF6B7280);

  // ── SHIMMER ───────────────────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFF1F2937);
  static const Color shimmerHighlight = Color(0xFF374151);

  // ── STATUS HELPERS ────────────────────────────────────────────────────────
  static Color accentFor(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.paid:
        return paidAccent;
      case PaymentStatus.partial:
        return partialAccent;
      case PaymentStatus.unpaid:
        return unpaidAccent;
    }
  }

  static Color accentDimFor(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.paid:
        return paidAccentDim;
      case PaymentStatus.partial:
        return partialAccentDim;
      case PaymentStatus.unpaid:
        return unpaidAccentDim;
    }
  }

  static Color badgeBgFor(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.paid:
        return paidBadgeBg;
      case PaymentStatus.partial:
        return partialBadgeBg;
      case PaymentStatus.unpaid:
        return unpaidBadgeBg;
    }
  }

  static Color badgeTextFor(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.paid:
        return paidBadgeText;
      case PaymentStatus.partial:
        return partialBadgeText;
      case PaymentStatus.unpaid:
        return unpaidBadgeText;
    }
  }

  static String badgeLabelFor(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.paid:
        return 'PAID';
      case PaymentStatus.partial:
        return 'PARTIAL';
      case PaymentStatus.unpaid:
        return 'UNPAID';
    }
  }
}

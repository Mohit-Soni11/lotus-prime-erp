// =============================================================================
// FILE        : alert_row_colors.dart
// MODULE      : Dashboard / Alert Row
// LAYER       : Theme / Colors
// DESCRIPTION : Dark theme — BillCard/ShopCard jaisa SAME dark background.
//               Status color sirf accent ke liye (orb, icon, badge, bar).
//               Card background kabhi change nahi hoga.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../models/dashboard/alert_card_model.dart';

class AlertRowColors {
  // ── CARD BACKGROUND — sab cards ka same dark slate (BillCard jaisa) ───────
  static const Color cardBgStart = Color(0xFF1F2937); // Dark Slate
  static const Color cardBgEnd = Color(0xFF0F172A); // Rich Navy Black
  static const Color cardBorder = Color(0x14FFFFFF); // White 8% — default

  // ── SHIMMER ───────────────────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFF1F2937);
  static const Color shimmerHighlight = Color(0xFF374151);

  // ── SHARED TEXT ───────────────────────────────────────────────────────────
  static const Color textWhite = Colors.white;
  static const Color textMuted = Color(0x99FFFFFF); // 60% white
  static const Color textSubtle = Color(0x61FFFFFF); // 38% white

  // ── STATUS ACCENT COLORS (sirf accent ke liye, background nahi!) ──────────

  // CRITICAL — Red
  static const Color criticalAccent = Color(0xFFEF4444);
  static const Color criticalAccentDim = Color(0x25EF4444); // 15% opacity
  static const Color criticalBadgeBg = Color(0x33EF4444); // 20% opacity
  static const Color criticalBadgeText = Color(0xFFFC8181);

  // WARNING — Amber
  static const Color warningAccent = Color(0xFFF59E0B);
  static const Color warningAccentDim = Color(0x25F59E0B);
  static const Color warningBadgeBg = Color(0x33F59E0B);
  static const Color warningBadgeText = Color(0xFFFBBF24);

  // SAFE — Emerald
  static const Color safeAccent = Color(0xFF10B981);
  static const Color safeAccentDim = Color(0x2010B981);
  static const Color safeBadgeBg = Color(0x2810B981);
  static const Color safeBadgeText = Color(0xFF34D399);

  // ── STATUS HELPERS ────────────────────────────────────────────────────────
  static Color accentFor(AlertStatus s) {
    switch (s) {
      case AlertStatus.critical:
        return criticalAccent;
      case AlertStatus.warning:
        return warningAccent;
      case AlertStatus.safe:
        return safeAccent;
    }
  }

  static Color accentDimFor(AlertStatus s) {
    switch (s) {
      case AlertStatus.critical:
        return criticalAccentDim;
      case AlertStatus.warning:
        return warningAccentDim;
      case AlertStatus.safe:
        return safeAccentDim;
    }
  }

  static Color badgeBgFor(AlertStatus s) {
    switch (s) {
      case AlertStatus.critical:
        return criticalBadgeBg;
      case AlertStatus.warning:
        return warningBadgeBg;
      case AlertStatus.safe:
        return safeBadgeBg;
    }
  }

  static Color badgeTextFor(AlertStatus s) {
    switch (s) {
      case AlertStatus.critical:
        return criticalBadgeText;
      case AlertStatus.warning:
        return warningBadgeText;
      case AlertStatus.safe:
        return safeBadgeText;
    }
  }

  static String badgeLabelFor(AlertStatus s) {
    switch (s) {
      case AlertStatus.critical:
        return 'ACTION NEEDED';
      case AlertStatus.warning:
        return 'ATTENTION';
      case AlertStatus.safe:
        return 'NORMAL';
    }
  }

  static double severityFillFor(AlertStatus s) {
    switch (s) {
      case AlertStatus.critical:
        return 1.0;
      case AlertStatus.warning:
        return 0.58;
      case AlertStatus.safe:
        return 0.18;
    }
  }
}

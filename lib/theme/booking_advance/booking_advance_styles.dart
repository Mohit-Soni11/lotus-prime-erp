// =============================================================================
// FILE        : booking_advance_styles.dart
// MODULE      : Sales → Booking & Advance
// LAYER       : Theme / Styles
// DESCRIPTION : TextStyles & BoxDecorations — exact same as SalesPosStyles.
// =============================================================================

import 'package:flutter/material.dart';
import 'booking_advance_colors.dart';

class BookingAdvanceStyles {
  BookingAdvanceStyles._();

  // ── APP BAR TITLE ─────────────────────────────────────────────────────────
  static const TextStyle headerTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: BookingAdvanceColors.shellTextTitle,
    letterSpacing: 1.2,
  );

  // ── SECTION HEADER (same as SalesPosStyles.highVisHeader) ─────────────────
  static const TextStyle highVisHeader = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
    color: BookingAdvanceColors.textDark,
  );

  // ── SUBTITLE MUTED ────────────────────────────────────────────────────────
  static TextStyle subTitleMuted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: BookingAdvanceColors.bodyTextMuted.withOpacity(0.70),
  );

  // ── INPUT TEXT ────────────────────────────────────────────────────────────
  static const TextStyle inputText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w900,
    color: BookingAdvanceColors.textDark,
  );

  // ── GRAND TOTAL ───────────────────────────────────────────────────────────
  static const TextStyle grandTotalText = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: BookingAdvanceColors.brandGold,
    height: 1.0,
  );

  // ── SUMMARY ROW ───────────────────────────────────────────────────────────
  static const TextStyle summaryLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: BookingAdvanceColors.bodyTextMuted,
  );

  static const TextStyle summaryValue = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: BookingAdvanceColors.textDark,
  );

  static const TextStyle totalRowLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w900,
    color: BookingAdvanceColors.textDark,
    letterSpacing: 0.5,
  );

  static const TextStyle totalRowValue = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w900,
    color: BookingAdvanceColors.brandGold,
  );

  // ── SHELL PANEL (AppBar) ──────────────────────────────────────────────────
  static const BoxDecoration shellPanel = BoxDecoration(
    color: BookingAdvanceColors.shellPanelBg,
    border: Border(
      bottom: BorderSide(color: BookingAdvanceColors.shellBorder, width: 1),
    ),
    boxShadow: [
      BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3)),
    ],
  );

  // ── WHITE CARD (body panels) ──────────────────────────────────────────────
  static BoxDecoration get whiteCard => BoxDecoration(
    color: BookingAdvanceColors.bodyPanelBg,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: BookingAdvanceColors.bodyBorder),
    boxShadow: const [
      BoxShadow(color: BookingAdvanceColors.shadowLight, blurRadius: 8, offset: Offset(0, 2)),
      BoxShadow(color: BookingAdvanceColors.shadowDark, blurRadius: 20, offset: Offset(0, 6)),
    ],
  );

  // ── GOLD BORDER CARD (customer panel) ─────────────────────────────────────
  static BoxDecoration goldBorderCard = BoxDecoration(
    color: BookingAdvanceColors.bodyPanelBg,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: BookingAdvanceColors.brandGold.withOpacity(0.12),
        blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 4),
      ),
      const BoxShadow(
        color: BookingAdvanceColors.shadowDark,
        blurRadius: 10, offset: Offset(0, 2),
      ),
    ],
    border: Border.all(
      color: BookingAdvanceColors.brandGold.withOpacity(0.3),
      width: 1.5,
    ),
  );

  // ── RIGHT PANEL ───────────────────────────────────────────────────────────
  static BoxDecoration get rightPanel => BoxDecoration(
    color: BookingAdvanceColors.bodyPanelBg,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: BookingAdvanceColors.bodyBorder, width: 1.5),
    boxShadow: const [
      BoxShadow(color: BookingAdvanceColors.shadowLight, blurRadius: 8, offset: Offset(0, 2)),
      BoxShadow(color: BookingAdvanceColors.shadowDark, blurRadius: 24, offset: Offset(0, 8)),
    ],
  );

  // ── PANEL DIVIDER ─────────────────────────────────────────────────────────
  static BoxDecoration get panelDivider => BoxDecoration(
    gradient: LinearGradient(colors: [
      BookingAdvanceColors.brandGold.withOpacity(0.05),
      BookingAdvanceColors.bodyBorder,
      BookingAdvanceColors.brandGold.withOpacity(0.05),
    ]),
  );

  // ── SAVE BUTTON (gold gradient) ───────────────────────────────────────────
  static BoxDecoration get saveButton => BoxDecoration(
    gradient: const LinearGradient(
      colors: [BookingAdvanceColors.goldGradientStart, BookingAdvanceColors.brandGold],
    ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: BookingAdvanceColors.brandGold.withOpacity(0.45),
        blurRadius: 16, offset: const Offset(0, 5),
      ),
    ],
  );

  // ── INPUT DECORATION ──────────────────────────────────────────────────────
  static InputDecoration inputDecoration({
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? prefixText,
    String? suffixText,
    Color? focusBorderColor,
  }) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        prefixText: prefixText,
        suffixText: suffixText,
        hintStyle: TextStyle(
          color: BookingAdvanceColors.bodyTextMuted.withOpacity(0.6),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: BookingAdvanceColors.formInputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: BookingAdvanceColors.bodyBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: BookingAdvanceColors.bodyBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: focusBorderColor ?? BookingAdvanceColors.brandGold,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      );
}
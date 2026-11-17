import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'metal_rate_colors.dart';

class MetalRateHubStyles {
  const MetalRateHubStyles._();

  static const pagePadding = EdgeInsets.fromLTRB(24, 28, 24, 48);

  static TextStyle get heading => GoogleFonts.manrope(
        color: MetalRateColors.textDark,
        fontSize: 23,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get description => GoogleFonts.inter(
        color: MetalRateColors.textBody,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get metalTitle => GoogleFonts.manrope(
        color: MetalRateColors.textDark,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get caption => GoogleFonts.inter(
        color: MetalRateColors.textBody,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get metricLabel => GoogleFonts.inter(
        color: MetalRateColors.textBody,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get metricValue => GoogleFonts.manrope(
        color: MetalRateColors.textDark,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      );

  static BoxDecoration card(Color accent, {required bool hovered}) =>
      BoxDecoration(
        color: MetalRateColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hovered
              ? accent.withValues(alpha: 0.75)
              : accent.withValues(alpha: 0.3),
          width: hovered ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hovered
                ? accent.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.07),
            blurRadius: hovered ? 20 : 12,
            offset: const Offset(0, 5),
          ),
        ],
      );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'metal_rate_colors.dart';

class MetalRateDetailStyles {
  MetalRateDetailStyles._();

  static const canvas = Color(0xFFF8F5F1);
  static const goldInk = Color(0xFF9A6700);
  static const greenInk = Color(0xFF087A30);
  static const orangeInk = Color(0xFFB9510A);
  static const violetInk = Color(0xFF5726A5);

  static TextStyle get title => GoogleFonts.manrope(
        color: MetalRateColors.textDark,
        fontSize: 21,
        fontWeight: FontWeight.w900,
      );

  static TextStyle get body => GoogleFonts.inter(
        color: MetalRateColors.textBody,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get value => GoogleFonts.manrope(
        color: MetalRateColors.textDark,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      );

  static BoxDecoration panel() => BoxDecoration(
        color: MetalRateColors.cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE7E3DE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      );

  static BoxDecoration tint(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.065),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      );
}

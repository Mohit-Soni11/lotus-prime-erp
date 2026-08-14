import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'gst_report_colors.dart';

class GstReportStyles {
  GstReportStyles._();

  static ThemeData get theme {
    const scheme = ColorScheme.light(
      primary: GstReportColors.taxGreen,
      onPrimary: Colors.white,
      surface: GstReportColors.bodyPanel,
      onSurface: GstReportColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: GstReportColors.bodyBg,
      dividerColor: GstReportColors.bodyBorder,
      splashFactory: InkSparkle.splashFactory,
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: GstReportColors.shellPanel,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: GstReportColors.shellTitle,
        ),
      ),
    );
  }

  static TextStyle get appBarTitle => GoogleFonts.inter(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: GstReportColors.shellTitle,
      );

  static TextStyle get appBarSubtitle => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: GstReportColors.shellMuted,
      );

  static TextStyle get pageTitle => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: GstReportColors.textPrimary,
      );

  static TextStyle get sectionTitle => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: GstReportColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: GstReportColors.textSecondary,
      );

  static TextStyle get onlineBadge => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: GstReportColors.onlineGreen,
      );

  static BoxDecoration panel() {
    return BoxDecoration(
      color: GstReportColors.bodyPanel,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: GstReportColors.bodyBorder),
      boxShadow: const [
        BoxShadow(
          color: GstReportColors.shadow,
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}

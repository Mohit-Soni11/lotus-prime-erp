import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'sales_report_colors.dart';

class SalesReportStyles {
  SalesReportStyles._();

  static ThemeData get theme {
    const scheme = ColorScheme.light(
      primary: SalesReportColors.brandGold,
      onPrimary: SalesReportColors.shellBg,
      surface: SalesReportColors.bodyPanel,
      onSurface: SalesReportColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: SalesReportColors.bodyBg,
      dividerColor: SalesReportColors.bodyBorder,
      splashFactory: InkSparkle.splashFactory,
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: SalesReportColors.shellPanel,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: SalesReportColors.shellTitle,
        ),
      ),
    );
  }

  static TextStyle get appBarTitle => GoogleFonts.inter(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: SalesReportColors.shellTitle,
      );

  static TextStyle get appBarSubtitle => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: SalesReportColors.shellMuted,
      );

  static TextStyle get pageTitle => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: SalesReportColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: SalesReportColors.textSecondary,
      );

  static TextStyle get onlineBadge => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: SalesReportColors.onlineGreen,
      );

  static BoxDecoration panel() {
    return BoxDecoration(
      color: SalesReportColors.bodyPanel,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: SalesReportColors.bodyBorder),
      boxShadow: const [
        BoxShadow(
          color: SalesReportColors.shadow,
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}

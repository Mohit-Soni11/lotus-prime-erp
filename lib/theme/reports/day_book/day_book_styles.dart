import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'day_book_colors.dart';

class DayBookStyles {
  DayBookStyles._();

  static ThemeData get theme {
    const colorScheme = ColorScheme.light(
      primary: DayBookColors.brandGold,
      onPrimary: DayBookColors.shellBg,
      secondary: DayBookColors.information,
      onSecondary: DayBookColors.textOnAccent,
      surface: DayBookColors.bodyPanel,
      onSurface: DayBookColors.textPrimary,
      error: DayBookColors.negative,
      onError: DayBookColors.textOnAccent,
    );

    final outlineShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: DayBookColors.bodyBg,
      dividerColor: DayBookColors.bodyBorder,
      splashFactory: InkSparkle.splashFactory,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DayBookColors.bodyPanel,
        hintStyle: label.copyWith(color: DayBookColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DayBookColors.bodyBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: DayBookColors.brandGold,
            width: 1.4,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DayBookColors.bodyBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(40, 40),
          backgroundColor: DayBookColors.brandGold,
          foregroundColor: DayBookColors.shellBg,
          disabledBackgroundColor: DayBookColors.bodyBorder,
          disabledForegroundColor: DayBookColors.textMuted,
          textStyle: button,
          shape: outlineShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(40, 40),
          foregroundColor: DayBookColors.textPrimary,
          side: const BorderSide(color: DayBookColors.bodyBorder),
          textStyle: button,
          shape: outlineShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DayBookColors.information,
          textStyle: button,
          shape: outlineShape,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DayBookColors.shellPanel,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: DayBookColors.shellTitle,
        ),
        behavior: SnackBarBehavior.floating,
        shape: outlineShape,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DayBookColors.brandGold,
        linearTrackColor: DayBookColors.bodyBorder,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          DayBookColors.textMuted.withValues(alpha: 0.48),
        ),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(6),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: DayBookColors.shellPanel,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: DayBookColors.shellTitle,
        ),
      ),
    );
  }

  static TextStyle get appBarTitle => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: DayBookColors.shellTitle,
      );

  static TextStyle get appBarSubtitle => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: DayBookColors.shellMuted,
      );

  static TextStyle get pageTitle => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: DayBookColors.textPrimary,
      );

  static TextStyle get sectionTitle => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: DayBookColors.textPrimary,
      );

  static TextStyle get sectionSubtitle => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: DayBookColors.textSecondary,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: DayBookColors.textSecondary,
      );

  static TextStyle get labelStrong => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: DayBookColors.textPrimary,
      );

  static TextStyle get value => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: DayBookColors.textPrimary,
      );

  static TextStyle get valueLarge => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: DayBookColors.textPrimary,
      );

  static TextStyle get valueHero => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: DayBookColors.textPrimary,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      );

  static BoxDecoration panel({Color? color, Color? borderColor}) {
    return BoxDecoration(
      color: color ?? DayBookColors.bodyPanel,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: borderColor ?? DayBookColors.bodyBorder),
      boxShadow: const [
        BoxShadow(
          color: DayBookColors.shadow,
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    );
  }

  static BoxDecoration softPanel({
    required Color color,
    required Color borderColor,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: borderColor),
    );
  }
}

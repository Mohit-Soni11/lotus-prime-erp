import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'banking_colors.dart';

class BankingStyles {
  // --- Text Sizes ---
  static const double szSectionTitle = 16.0;
  static const double szSectionSub = 11.0;
  static const double szFieldLabel = 13.0;
  static const double szFieldText = 15.0;
  static const double szFieldHint = 13.0;

  // --- Radii ---
  static const double rCard = 12.0;
  static const double rInput = 8.0;
  static const double rHeaderIcon = 8.0;
  static const double rBtn = 6.0;

  // --- Dimensions ---
  static const double hInputField = 50.0;
  static const EdgeInsets padCardInternal = EdgeInsets.all(24.0);

  // --- Separated Text Styles ---
  static TextStyle pageTitle = GoogleFonts.manrope(
      fontSize: 24.0,
      fontWeight: FontWeight.w800,
      color: BankingColors.textWhite,
      letterSpacing: 0);
  static TextStyle pageSub =
      GoogleFonts.inter(fontSize: 14.0, color: BankingColors.textWhite70);
  static TextStyle statusPillText = GoogleFonts.inter(
      color: BankingColors.statusActiveText,
      fontWeight: FontWeight.w700,
      fontSize: 13.5);
  static TextStyle addBtnText = GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: BankingColors.goldAccent);

  static TextStyle sectionTitle = GoogleFonts.manrope(
      fontSize: szSectionTitle,
      fontWeight: FontWeight.w700,
      color: BankingColors.textDark);
  static TextStyle sectionSub = GoogleFonts.inter(
      fontSize: szSectionSub,
      fontWeight: FontWeight.w800,
      color: BankingColors.textMuted,
      letterSpacing: 1.2);
  static TextStyle fieldLabel = GoogleFonts.manrope(
      fontSize: szFieldLabel,
      fontWeight: FontWeight.w700,
      color: BankingColors.textBody);
  static TextStyle fieldText = GoogleFonts.manrope(
      fontSize: szFieldText,
      fontWeight: FontWeight.w700,
      color: BankingColors.textDark);
  static TextStyle fieldHint =
      GoogleFonts.inter(color: BankingColors.textHint, fontSize: szFieldHint);

  static TextStyle badgeText(Color color) => GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
      color: color);
  static TextStyle accountMasked(bool isPrimary) => GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: BankingColors.textMuted,
      letterSpacing: isPrimary ? 2 : 1);
  static TextStyle lockStatusText(bool isLocked) => GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color:
          isLocked ? BankingColors.lockedIcon : BankingColors.statusActiveText);
  static TextStyle qrUploadText(bool isLocked) => GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: isLocked ? BankingColors.textHint : BankingColors.textDark);

  static TextStyle bottomSheetTitle = GoogleFonts.manrope(
      fontSize: 18, fontWeight: FontWeight.bold, color: BankingColors.textDark);
  static TextStyle listTileText = GoogleFonts.inter(
      fontWeight: FontWeight.w600, color: BankingColors.textBody, fontSize: 15);
  static TextStyle cropDialogTitle =
      const TextStyle(color: BankingColors.cardBg, fontWeight: FontWeight.bold);

  // --- Dynamic Badge Logic ---
  static Color getBadgeBgColor(String type) {
    if (type == "Current") {
      return BankingColors.goldAccent.withValues(alpha: 0.15);
    }
    if (type == "Savings") {
      return BankingColors.brandTeal.withValues(alpha: 0.15);
    }
    return BankingColors.brandOrange.withValues(alpha: 0.15);
  }

  static Color getBadgeTextColor(String type) {
    if (type == "Current") return BankingColors.brandGoldDark;
    if (type == "Savings") return BankingColors.brandTealDark;
    return BankingColors.brandOrangeDark;
  }

  // --- Decorations ---
  static BoxDecoration cardDecoration = BoxDecoration(
    color: BankingColors.cardBg,
    borderRadius: BorderRadius.circular(rCard),
    border: Border.all(color: BankingColors.borderLight, width: 1),
    boxShadow: [
      BoxShadow(
        color: BankingColors.overlayDark.withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration uploadZoneDecoration = BoxDecoration(
    color: BankingColors.uploadZoneBg,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: BankingColors.borderLight, width: 1),
  );

  // --- Input Field (Normal / Locked) ---
  static BoxDecoration inputDecoration(bool isLocked) {
    return BoxDecoration(
      color: isLocked ? BankingColors.uploadZoneBg : BankingColors.inputBg,
      borderRadius: BorderRadius.circular(rInput),
      border: Border.all(
        color: BankingColors.borderLight,
        width: 1,
      ),
    );
  }

  // --- Input Field (Active / Focused) ---
  static BoxDecoration activeInputDecoration = BoxDecoration(
      color: BankingColors.inputBg,
      borderRadius: BorderRadius.circular(rInput),
      border: Border.all(
        color: BankingColors.goldAccent,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: BankingColors.goldAccent.withValues(alpha: 0.15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        )
      ]);
}

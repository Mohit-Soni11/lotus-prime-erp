// -----------------------------------------------------------------------------
// FILE: basic_info_styles.dart
// TYPE: Theme / Styles
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'basic_info_colors.dart';

class BasicInfoStyles {
  // ==========================================
  // 1. TYPOGRAPHY (Text Sizes)
  // ==========================================
  static const double szPageTitle = 24.0;
  static const double szTitle20 =
      20.0; // ðŸš€ UPGRADE: Extracted from UI Dialogs
  static const double szHeader18 =
      18.0; // ðŸš€ UPGRADE: Extracted from UI Headers
  static const double szPageSub = 14.0;
  static const double szSectionTitle = 16.0;
  static const double szSectionSub = 11.0;
  static const double szFieldLabel = 13.0;
  static const double szFieldText = 15.0;
  static const double szFieldHint = 13.0;

  static const double szBadgeText = 10.0; // For "VERIFIED" badge

  // ==========================================
  // 2. SHAPE SYSTEM (Radii)
  // ==========================================
  static const double rCard = 16.0; // More rounded for modern feel
  static const double rInput = 10.0; // Softer corners for inputs
  static const double rInputRadius = 10.0; // Alias for safety

  static const double rHeaderIcon = 8.0;
  static const double rBtn = 8.0; // Action buttons
  static const double rStatusPill = 20.0; // Badges

  // ==========================================
  // 3. DIMENSIONS (Spacing & Sizing)
  // ==========================================
  static const double hInputField = 52.0; // Taller for better touch target
  static const double imgUploadSize = 140.0;

  static const EdgeInsets padCardInternal = EdgeInsets.all(24.0);
  static const EdgeInsets padAll24 =
      EdgeInsets.all(24.0); // ðŸš€ UPGRADE: Extracted
  static const EdgeInsets padAll20 =
      EdgeInsets.all(20.0); // ðŸš€ UPGRADE: Extracted

  // Padding for small action buttons (Upload/Preview)
  static const EdgeInsets padActionBtn =
      EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  static const EdgeInsets padDialogOption = EdgeInsets.symmetric(
      horizontal: 16, vertical: 10); // ðŸš€ UPGRADE: Extracted

  // ==========================================
  // 4. DECORATIONS (The Visual Layer)
  // ==========================================

  // --- Main Card (Floating Effect) ---
  static BoxDecoration cardDecoration = BoxDecoration(
    color: BasicInfoColors.cardBg,
    borderRadius: BorderRadius.circular(rCard),
    border: Border.all(color: BasicInfoColors.borderLight, width: 1),
    boxShadow: const [
      BoxShadow(
        color: BasicInfoColors.shadowSubtle, // Premium soft shadow
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );

  // --- Input Field (Normal / Locked) ---
  static BoxDecoration inputDecoration(bool isLocked) {
    return BoxDecoration(
      color: isLocked ? BasicInfoColors.inputBgLocked : BasicInfoColors.inputBg,
      borderRadius: BorderRadius.circular(rInput),
      border: Border.all(
        color: BasicInfoColors.borderLight,
        width: 1,
      ),
    );
  }

  // --- Input Field (Active / Focused) ---
  static BoxDecoration activeInputDecoration = BoxDecoration(
      color: BasicInfoColors.inputBg,
      borderRadius: BorderRadius.circular(rInput),
      border: Border.all(
        color: BasicInfoColors.goldAccent,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color:
              BasicInfoColors.goldAccent.withValues(alpha: 0.15), // Golden Glow
          blurRadius: 8,
          offset: const Offset(0, 3),
        )
      ]);

  // --- Warning State (Validation Error) ---
  static BoxDecoration warningInputDecoration = BoxDecoration(
    color: BasicInfoColors.inputBg,
    borderRadius: BorderRadius.circular(rInput),
    border: Border.all(
      color: BasicInfoColors.borderWarning,
      width: 1,
    ),
  );
}

// -----------------------------------------------------------------------------
// FILE: address_styles.dart
// TYPE: Theme / Styles & Dimensions
// AUTHOR: Senior System Architect
// DESCRIPTION: Centralized dimensions, radii, and decorations. Zero dynamic 
//              opacities to ensure 60-FPS UI rendering.
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'address_colors.dart';

class AddressStyles {
  // --- Typography Sizes (Extracted from UI) ---
  static const double szPageTitle = 24.0;
  static const double szPageSub = 14.0;
  static const double szSectionTitle = 16.0;
  static const double szSectionSub = 11.0;
  static const double szFieldLabel = 13.0;
  static const double szFieldText = 15.0;
  static const double szFieldHint = 13.0;
  static const double szChipText = 11.0;
  static const double szButtonText = 12.0;

  // --- Radii ---
  static const double rCard = 16.0; 
  static const double rInput = 10.0; 
  static const double rHeaderIcon = 8.0;
  static const double rStatusPill = 20.0; 
  static const double rMapContainer = 12.0; // Extracted from UI
  static const double rMapClip = 10.0;      // Extracted from UI
  static const double rChip = 8.0;          // Extracted from UI
  static const double rButton = 6.0;        // Extracted from UI

  // --- Dimensions & Paddings ---
  static const double hInputField = 52.0; 
  static const EdgeInsets padCardInternal = EdgeInsets.all(24.0);
  static const EdgeInsets padChip = EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0);
  static const EdgeInsets padActionBtn = EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0);

  // --- Decorations ---
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: AddressColors.cardBg,
    borderRadius: BorderRadius.circular(rCard),
    border: Border.all(color: AddressColors.borderLight, width: 1),
    boxShadow: const [
      BoxShadow(
        color: AddressColors.shadowSubtle,
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );

  // Input States
  static BoxDecoration inputDecoration(bool isLocked) {
    return BoxDecoration(
      color: isLocked ? AddressColors.inputBgLocked : AddressColors.inputBg,
      borderRadius: BorderRadius.circular(rInput),
      border: Border.all(
        color: AddressColors.borderLight, 
        width: 1,
      ),
    );
  }
  
  // Active State (Gold Glow - Optimized Opacity for 60-FPS)
  static final BoxDecoration activeInputDecoration = BoxDecoration(
    color: AddressColors.inputBg,
    borderRadius: BorderRadius.circular(rInput),
    border: Border.all(
      color: AddressColors.goldAccent,
      width: 1.5,
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x26D4AF37), // 🚀 UPGRADE: Pre-calculated 15% opacity
        blurRadius: 8,
        offset: Offset(0, 3),
      )
    ]
  );
}
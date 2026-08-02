// =============================================================================
// FILE        : delivery_styles.dart
// MODULE      : Sales â†’ Delivery Management
// LAYER       : Theme / Styles
// DESCRIPTION : TextStyles & BoxDecorations for Delivery Management module.
// =============================================================================

import 'package:flutter/material.dart';
import 'delivery_colors.dart';

class DeliveryStyles {
  DeliveryStyles._();

  // â”€â”€ APP BAR TITLE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const TextStyle headerTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: DeliveryColors.shellTextTitle,
    letterSpacing: 1.2,
  );

  // â”€â”€ SECTION HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
    color: DeliveryColors.textDark,
  );

  // â”€â”€ SUBTITLE MUTED â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle subTitleMuted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: DeliveryColors.bodyTextMuted.withValues(alpha: 0.75),
  );

  // â”€â”€ CARD TITLE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const TextStyle cardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: DeliveryColors.bodyTextMain,
  );

  // â”€â”€ CARD SUBTITLE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: DeliveryColors.bodyTextMuted,
  );

  // â”€â”€ DELIVERY NO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const TextStyle deliveryNoText = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    color: DeliveryColors.brandGold,
    letterSpacing: 0.5,
  );

  // â”€â”€ AMOUNT LARGE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const TextStyle amountLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: DeliveryColors.brandGold,
    height: 1.0,
  );

  // â”€â”€ AMOUNT MEDIUM â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const TextStyle amountMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: DeliveryColors.bodyTextMain,
  );

  // â”€â”€ DUE AMOUNT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const TextStyle dueAmount = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: DeliveryColors.urgencyOverdue,
  );

  // â”€â”€ INPUT TEXT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const TextStyle inputText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w900,
    color: DeliveryColors.textDark,
  );

  // â”€â”€ TAB TEXT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const TextStyle tabActive = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: DeliveryColors.shellTextTitle,
    letterSpacing: 0.3,
  );

  static const TextStyle tabInactive = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: DeliveryColors.shellTextMuted,
    letterSpacing: 0.3,
  );

  // â”€â”€ DECORATIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static BoxDecoration get shellPanel => const BoxDecoration(
        color: DeliveryColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(color: DeliveryColors.shellBorder, width: 1),
        ),
      );

  static BoxDecoration get bodyCard => BoxDecoration(
        color: DeliveryColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeliveryColors.bodyBorder, width: 1),
        boxShadow: const [
          BoxShadow(
              color: DeliveryColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      );

  static BoxDecoration get selectedCard => BoxDecoration(
        color: DeliveryColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeliveryColors.brandGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: DeliveryColors.brandGold.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      );

  static BoxDecoration get sidePanel => const BoxDecoration(
        color: DeliveryColors.bodyPanelBg,
        border: Border(
          left: BorderSide(color: DeliveryColors.bodyBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: DeliveryColors.shadowDark,
            blurRadius: 16,
            offset: Offset(-4, 0),
          ),
        ],
      );

  static BoxDecoration inputDecoration(bool focused) => BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: focused ? DeliveryColors.brandGold : DeliveryColors.bodyBorder,
          width: focused ? 1.5 : 1,
        ),
      );

  static BoxDecoration get goldButton => const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DeliveryColors.goldGradientStart,
            DeliveryColors.goldGradientEnd
          ],
        ),
      );
}

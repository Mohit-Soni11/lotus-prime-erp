// =============================================================================
// FILE        : counter_security_styles.dart
// MODULE      : Dashboard / Counter Security Check
// =============================================================================

import 'package:flutter/material.dart';
import 'counter_security_colors.dart';

class CounterSecurityStyles {
  // â”€â”€ DIMENSIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const double cardBorderRadius = 20.0;
  static const double innerBorderRadius = 12.0;
  static const double chipHeight = 32.0;
  static const double chipBorderRadius = 8.0;
  static const double inputHeight = 46.0;
  static const double btnHeight = 44.0;
  static const double btnBorderRadius = 10.0;
  static const double resultBorderRadius = 14.0;

  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);
  static const EdgeInsets innerPadding = EdgeInsets.all(16.0);

  // â”€â”€ OUTER CARD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get cardDecoration => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CounterSecurityColors.cardBgStart,
            CounterSecurityColors.cardBgEnd
          ],
        ),
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 25,
            offset: Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      );

  // â”€â”€ INNER SECTION (state-aware) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration innerDecoration({
    required Color bg,
    required Color border,
    double borderWidth = 1.0,
  }) =>
      BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(innerBorderRadius),
        border: Border.all(color: border, width: borderWidth),
      );

  // â”€â”€ METAL CHIP â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration metalChip(
          {required bool isActive, required Color activeColor}) =>
      BoxDecoration(
        color: isActive ? activeColor : CounterSecurityColors.chipInactive,
        borderRadius: BorderRadius.circular(chipBorderRadius),
        border: isActive
            ? null
            : Border.all(color: CounterSecurityColors.chipInactiveBorder),
        boxShadow: isActive
            ? [
                BoxShadow(
                    color: activeColor.withValues(alpha: 0.3), blurRadius: 8)
              ]
            : null,
      );

  // â”€â”€ INPUT DECORATION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static InputDecoration inputDecoration({
    required String label,
    required String hint,
    required bool isFocused,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: isFocused
              ? CounterSecurityColors.inputFocus
              : CounterSecurityColors.inputLabel,
          letterSpacing: 0.5,
        ),
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 13,
          color: CounterSecurityColors.inputHint,
        ),
        filled: true,
        fillColor: CounterSecurityColors.inputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: CounterSecurityColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: CounterSecurityColors.inputBorder.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: CounterSecurityColors.inputFocus,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      );

  // â”€â”€ LOCKED BADGE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get lockedBadge => BoxDecoration(
        color: CounterSecurityColors.lockedBadge,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: CounterSecurityColors.lockedBadge.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      );

  // â”€â”€ RESULT BOX â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration resultBox({required bool matched}) => BoxDecoration(
        color: matched
            ? CounterSecurityColors.matchedBg
            : CounterSecurityColors.mismatchBg,
        borderRadius: BorderRadius.circular(resultBorderRadius),
        border: Border.all(
          color: matched
              ? CounterSecurityColors.matchedBorder
              : CounterSecurityColors.mismatchBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (matched
                    ? CounterSecurityColors.matchedBorder
                    : CounterSecurityColors.mismatchBorder)
                .withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      );

  // â”€â”€ TEXT STYLES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const TextStyle headerStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w700,
    color: CounterSecurityColors.accentGold,
    letterSpacing: 1.5,
  );

  static const TextStyle stepLabelStyle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: CounterSecurityColors.textMuted,
    letterSpacing: 1.0,
  );

  static const TextStyle metalChipStyle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  static const TextStyle lockedBadgeStyle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle resultMainStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle resultSubStyle = TextStyle(
    fontSize: 12.5,
    color: CounterSecurityColors.textMuted,
  );
}

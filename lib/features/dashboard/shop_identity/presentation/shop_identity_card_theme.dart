import 'package:flutter/material.dart';

abstract final class ShopIdentityCardTheme {
  static const Color backgroundStart = Color(0xFF1F2937);
  static const Color backgroundEnd = Color(0xFF0F172A);
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldBorder = Color(0xFFC8A660);
  static const Color secondaryText = Color(0xFFC0C0C0);
  static const Color mutedText = Color(0xFF9CA3AF);

  static const EdgeInsets padding = EdgeInsets.all(20);
  static const double logoSize = 90;
  static const double borderRadius = 20;

  static BoxDecoration get decoration => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backgroundStart, backgroundEnd],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      );
}

import 'package:flutter/material.dart';
import 'shop_card_colors.dart';

class ShopCardStyles {
  // --- Layout Dimensions ---
  static const double borderRadius = 20.0;
  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);
  
  // --- Typography ---
  static const TextStyle shopNameStyle = TextStyle(
    fontSize: 22.0, // Matches NAME_SIZE approx
    fontWeight: FontWeight.bold,
    color: ShopCardColors.textGold,
    letterSpacing: 0.5,
    fontFamily: 'Roboto', // Or Serif if you prefer
  );

  static const TextStyle ownerNameStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: ShopCardColors.textOwner,
  );

  static const TextStyle locationStyle = TextStyle(
    fontSize: 14.0,
    fontStyle: FontStyle.italic,
    color: ShopCardColors.textLocation,
  );

  // --- Details Text (Mobile, GST etc) ---
  static const TextStyle detailTextStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: ShopCardColors.textSilver,
  );

  static const TextStyle linkStyle = TextStyle(
    fontSize: 14.0,
    color: ShopCardColors.textLink,
    decoration: TextDecoration.underline,
  );

  // --- Image Box ---
  static const double imgBoxSize = 90.0;
  static const double imgRadius = 15.0; // Slightly rounded square looks modern
  static const double imgBorderWidth = 2.0;

  // --- Premium Decoration (Copied for consistency) ---
  static BoxDecoration get premiumCardDecoration => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [ShopCardColors.cardBgStart, ShopCardColors.cardBgEnd],
    ),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
    boxShadow: const [
      BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10)),
    ],
  );
}
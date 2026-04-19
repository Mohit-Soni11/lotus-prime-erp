import 'package:flutter/material.dart';

// ============================================================
// 🎨 LIVE RATES CARD THEME
// Saare colors, styles, strings ek jagah
// Kuch bhi change karna ho — sirf yahan aao
// ============================================================

// --- COLORS ---
class LiveRatesColors {
  LiveRatesColors._();

  // Card Backgrounds
  static const Color cardBg = Color(0xFF1A2238);
  static const Color sectionBg = Color(0xFF0F172A);
  static const Color expandedBg = Color(0xFF111827);

  // Gold Palette
  static const Color goldMain = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE8C96A);
  static const Color goldDark = Color(0xFF9A7B1C);
  static const Color goldText = Color(0xFFF5E6A3);
  static const Color goldBg = Color(0xFF2C2310);

  // Silver Palette
  static const Color silverMain = Color(0xFFB8C5D6);
  static const Color silverLight = Color(0xFFD4DDE8);
  static const Color silverText = Color(0xFFE2E8F0);
  static const Color silverBg = Color(0xFF1A2030);

  // Text
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Status
  static const Color upGreen = Color(0xFF10B981);
  static const Color upGreenBg = Color(0xFF0D2B1F);
  static const Color downRed = Color(0xFFEF4444);
  static const Color downRedBg = Color(0xFF2B0D0D);

  // Divider
  static const Color divider = Color(0xFF1E293B);
  static const Color shimmerBase = Color(0xFF1E293B);
  static const Color shimmerHighlight = Color(0xFF334155);

  // Header gradient
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF2C2310), Color(0xFF1A1608)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Gold shimmer gradient (text pe lagta hai)
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFF5E6A3), Color(0xFFD4AF37)],
    stops: [0.0, 0.5, 1.0],
  );

  // Ambient glow for cards
  static const Color goldGlow = Color(0x1AD4AF37);
  static const Color silverGlow = Color(0x0AB8C5D6);

  // Demo badge
  static const Color demoBadgeBg = Color(0xFF2D3748);
  static const Color demoBadgeText = Color(0xFFF6AD55);
}

// --- STRINGS ---
class LiveRatesStrings {
  LiveRatesStrings._();

  static const String cardTitle = 'Live Rates';
  static const String goldTitle = '24 KT GOLD';
  static const String silverTitle = 'SILVER';
  static const String goldRatesLabel = 'GOLD RATES';
  static const String silverRatesLabel = 'SILVER RATES';
  static const String showMore = 'Show More';
  static const String showLess = 'Show Less';
  static const String lastUpdated = 'Last Updated';
  static const String perTenGm = '/ 10gm';
  static const String perKg = '/ KG';
  static const String kt22 = '22 KT';
  static const String kt18 = '18 KT';
  static const String idols = 'Idols & Utensils';
  static const String jewellery = 'Jewellery';
  static const String purchaseHeader = 'OLD GOLD & SILVER — PURCHASE / EXCHANGE RATE';
  static const String priceTrackerHeader = 'PRICE TRACKER TREND';
  static const String marketAnalysisHeader = 'MARKET ANALYSIS & RATE BREAKDOWN';
  static const String goldBuyLabel = 'GOLD';
  static const String silverBuyLabel = 'SILVER';
  static const String buy24k = '24 KT (Buy)';
  static const String buy22k = '22 KT (Buy)';
  static const String buy18k = '18 KT (Buy)';
  static const String silverBuyRate = 'Silver Buy Rate';
  static const String demoNote = 'Demo Data — Set rates in Settings';
  static const String setRatesTip = 'Go to Settings → Set Daily Rates';
}

// --- STYLES ---
class LiveRatesStyles {
  LiveRatesStyles._();

  // Card
  static const double cardBorderRadius = 20;
  static const EdgeInsets cardPadding = EdgeInsets.all(20);

  // Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: LiveRatesColors.cardBg,
    borderRadius: BorderRadius.circular(cardBorderRadius),
    border: Border.all(color: Colors.white.withOpacity(0.06)),
    boxShadow: [
      BoxShadow(
        color: LiveRatesColors.goldMain.withOpacity(0.08),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration sectionDecoration({bool isGold = true}) => BoxDecoration(
    color: isGold ? LiveRatesColors.goldBg : LiveRatesColors.silverBg,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: isGold
          ? LiveRatesColors.goldMain.withOpacity(0.2)
          : LiveRatesColors.silverMain.withOpacity(0.15),
    ),
    boxShadow: [
      BoxShadow(
        color: isGold ? LiveRatesColors.goldGlow : LiveRatesColors.silverGlow,
        blurRadius: 20,
        spreadRadius: 0,
      ),
    ],
  );

  static BoxDecoration expandedSectionDecoration = BoxDecoration(
    color: LiveRatesColors.expandedBg,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.white.withOpacity(0.05)),
  );

  // Text Styles
  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: LiveRatesColors.textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle sectionLabelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: LiveRatesColors.textSecondary,
    letterSpacing: 1.5,
  );

  static const TextStyle metalTitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  static const TextStyle bigPriceStyle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static const TextStyle subPriceStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: LiveRatesColors.textPrimary,
  );

  static const TextStyle subLabelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: LiveRatesColors.textSecondary,
  );

  static const TextStyle unitStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: LiveRatesColors.textMuted,
  );

  static const TextStyle changeStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle timestampStyle = TextStyle(
    fontSize: 11,
    color: LiveRatesColors.textMuted,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle trackerHeaderStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: LiveRatesColors.goldText,
    letterSpacing: 0.5,
  );
}
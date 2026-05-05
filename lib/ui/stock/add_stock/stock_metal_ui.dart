import 'package:flutter/material.dart';
import 'package:lotus_erp/models/stock/stock_enums/stock_enums.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';

class StockMetalUiData {
  final StockCategory category;
  final String title;
  final String hindiTitle;
  final String tagLine;
  final String helperLine;
  final String quickTag;
  final IconData icon;
  final Color accent;
  final Color softSurface;
  final Color softTint;
  final LinearGradient gradient;

  const StockMetalUiData({
    required this.category,
    required this.title,
    required this.hindiTitle,
    required this.tagLine,
    required this.helperLine,
    required this.quickTag,
    required this.icon,
    required this.accent,
    required this.softSurface,
    required this.softTint,
    required this.gradient,
  });
}

StockMetalUiData stockMetalUiFor(StockCategory metal) {
  switch (metal) {
    case StockCategory.gold:
      return const StockMetalUiData(
        category: StockCategory.gold,
        title: 'Gold',
        hindiTitle: 'Sona',
        tagLine: 'Hallmarked bridal and daily-wear inventory',
        helperLine: 'HUID, purity presets and cost-led pricing ready',
        quickTag: '22K · 18K · 24K',
        icon: Icons.diamond_rounded,
        accent: AddStockColors.brandGold,
        softSurface: Color(0xFFFFFBF2),
        softTint: Color(0xFFFFF2C6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE7A3), Color(0xFFD4AF37)],
        ),
      );
    case StockCategory.silver:
      return const StockMetalUiData(
        category: StockCategory.silver,
        title: 'Silver',
        hindiTitle: 'Chaandi',
        tagLine: 'Lightweight articles and fast-moving counter stock',
        helperLine: 'Sterling presets, higher quantity entry and clean racks',
        quickTag: '999 · 925 · 800',
        icon: Icons.toll_rounded,
        accent: Color(0xFF748A98),
        softSurface: Color(0xFFF5F8FA),
        softTint: Color(0xFFD8E4EB),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDDE7ED), Color(0xFF8BA1AF)],
        ),
      );
    case StockCategory.diamond:
      return const StockMetalUiData(
        category: StockCategory.diamond,
        title: 'Diamond',
        hindiTitle: 'Heera',
        tagLine: 'Studded collections and solitaire-focused intake',
        helperLine: 'Stone value, carats and premium ticket planning',
        quickTag: 'Solitaire · Studded · Fancy',
        icon: Icons.auto_awesome_rounded,
        accent: Color(0xFF1FA8E7),
        softSurface: Color(0xFFF1FAFF),
        softTint: Color(0xFFCAEEFF),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF90E0FF), Color(0xFF1FA8E7)],
        ),
      );
    case StockCategory.platinum:
      return const StockMetalUiData(
        category: StockCategory.platinum,
        title: 'Platinum',
        hindiTitle: 'Platinum',
        tagLine: 'Refined wedding bands and premium custom orders',
        helperLine: 'Minimal, high-value stock with precise purity capture',
        quickTag: '950 · 900 · 850',
        icon: Icons.radio_button_checked_rounded,
        accent: Color(0xFF586E7C),
        softSurface: Color(0xFFF4F6F8),
        softTint: Color(0xFFD9E1E6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD4DDE3), Color(0xFF728996)],
        ),
      );
    case StockCategory.antique:
    case StockCategory.other:
      return const StockMetalUiData(
        category: StockCategory.other,
        title: 'Other',
        hindiTitle: 'Misc',
        tagLine: 'Flexible inventory lane for non-standard items',
        helperLine: 'Manual setup with custom purity and pricing',
        quickTag: 'Custom setup',
        icon: Icons.category_rounded,
        accent: Color(0xFF8B6F47),
        softSurface: Color(0xFFF8F4ED),
        softTint: Color(0xFFE7D8C4),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3DDC1), Color(0xFFC99A5F)],
        ),
      );
  }
}

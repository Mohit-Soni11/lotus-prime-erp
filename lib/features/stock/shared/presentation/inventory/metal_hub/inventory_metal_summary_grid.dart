import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lotus_erp/features/stock/shared/domain/models/inventory/inventory_stats_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/features/stock/shared/presentation/add_stock/stock_metal_ui.dart';
import 'package:lotus_erp/features/stock/shared/presentation/inventory/metal_hub/inventory_metal_summary_card.dart';

class InventoryMetalSummaryGrid extends StatelessWidget {
  final InventoryStats stats;
  final StockCategory? selectedMetal;
  final ValueChanged<StockCategory> onMetalSelected;

  const InventoryMetalSummaryGrid({
    super.key,
    required this.stats,
    required this.selectedMetal,
    required this.onMetalSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cards = _buildCards();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 960
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final card in cards)
              SizedBox(
                width: cardWidth,
                child: InventoryMetalSummaryCard(
                  title: card.title,
                  subtitle: card.subtitle,
                  primaryLabel: card.primaryLabel,
                  primaryValue: card.primaryValue,
                  weightLabel: card.weightLabel,
                  weightValue: card.weightValue,
                  actionLabel: card.actionLabel,
                  icon: card.icon,
                  logoAsset: card.logoAsset,
                  accent: card.accent,
                  surface: card.surface,
                  tint: card.tint,
                  gradient: card.gradient,
                  textOnGradient: card.textOnGradient,
                  selected: selectedMetal == card.category,
                  onTap: () => onMetalSelected(card.category),
                ),
              ),
          ],
        );
      },
    );
  }

  List<_InventoryMetalCardData> _buildCards() {
    return [
      _card(
        category: StockCategory.gold,
        title: 'Gold Inventory Ledger',
        subtitle: 'HUID stock, purity-wise balance and sale movement tracking',
        itemCount: stats.goldCount,
        weight: stats.goldWeight,
      ),
      _card(
        category: StockCategory.silver,
        title: 'Silver Inventory Ledger',
        subtitle: 'Weight-based stock, article groups and supplier batches',
        itemCount: stats.silverCount,
        weight: stats.silverWeight,
      ),
      _card(
        category: StockCategory.diamond,
        title: 'Diamond Inventory Ledger',
        subtitle: 'Studded articles, premium items and value-focused tracking',
        itemCount: stats.diamondCount,
        weight: null,
      ),
      _card(
        category: StockCategory.platinum,
        title: 'Platinum Inventory Ledger',
        subtitle:
            'Premium pieces, precise weight control and clean status view',
        itemCount: stats.platinumCount,
        weight: stats.platinumWeight,
      ),
    ];
  }

  _InventoryMetalCardData _card({
    required StockCategory category,
    required String title,
    required String subtitle,
    required int itemCount,
    required double? weight,
  }) {
    final ui = stockMetalUiFor(category);
    return _InventoryMetalCardData(
      category: category,
      title: title,
      subtitle: subtitle,
      primaryLabel: 'Available Items',
      primaryValue: '$itemCount pcs',
      weightLabel: weight == null ? 'Tracking Mode' : 'Gross Weight',
      weightValue: weight == null ? 'By item' : _weight(weight),
      actionLabel: 'Open ${ui.title} Ledger',
      icon: ui.icon,
      logoAsset: ui.logoAsset,
      accent: ui.accent,
      surface: ui.softSurface,
      tint: ui.softTint,
      gradient: ui.gradient,
      textOnGradient: ui.textOnGradient,
    );
  }

  String _weight(double value) {
    return '${NumberFormat('##,##0.000', 'en_IN').format(value)} g';
  }
}

class _InventoryMetalCardData {
  final StockCategory category;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final String primaryValue;
  final String weightLabel;
  final String weightValue;
  final String actionLabel;
  final IconData icon;
  final String? logoAsset;
  final Color accent;
  final Color surface;
  final Color tint;
  final LinearGradient gradient;
  final Color textOnGradient;

  const _InventoryMetalCardData({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.primaryValue,
    required this.weightLabel,
    required this.weightValue,
    required this.actionLabel,
    required this.icon,
    required this.logoAsset,
    required this.accent,
    required this.surface,
    required this.tint,
    required this.gradient,
    required this.textOnGradient,
  });
}

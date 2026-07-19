import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/stock/shared/application/low_stock_alert_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/features/stock/shared/presentation/add_stock/stock_metal_ui.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/app_bar/low_stock_alert_app_bar.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_alert_widgets.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_smart_card.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class LowStockGroupDetailScreen extends StatelessWidget {
  final LowStockAlertController controller;
  final LowStockStockCard groupCard;

  const LowStockGroupDetailScreen({
    super.key,
    required this.controller,
    required this.groupCard,
  });

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(StockCategory.fromLabel(groupCard.metalType));
    final detailCards = controller.detailCardsForGroup(groupCard);
    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: LowStockAlertAppBar(
        onBack: () => Navigator.of(context).maybePop(),
        onRefresh: controller.load,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _DetailHeader(ui: ui, card: groupCard),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            sliver: SliverToBoxAdapter(
              child: detailCards.isEmpty
                  ? const LowStockEmptyState(
                      title: 'No Detail Found',
                      subtitle: 'This group has no stock detail yet.',
                      icon: Icons.layers_clear_outlined,
                    )
                  : _DetailGrid(cards: detailCards),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  final List<LowStockStockCard> cards;

  const _DetailGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1260
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth >= 820
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: LowStockSmartCard(
                  card: card,
                  actionLabel: 'Review Detail',
                  titleOverride: _isSilver(card) ? card.gradeLabel : card.title,
                  subtitleOverride: _isSilver(card)
                      ? '${card.itemType} / ${card.metalType}'
                      : card.subtitle,
                ),
              ),
          ],
        );
      },
    );
  }

  bool _isSilver(LowStockStockCard card) {
    return card.metalType.trim().toLowerCase() == 'silver';
  }
}

class _DetailHeader extends StatelessWidget {
  final StockMetalUiData ui;
  final LowStockStockCard card;

  const _DetailHeader({required this.ui, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: ui.gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ui.accent.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
            ),
            child: Icon(ui.icon, color: ui.textOnGradient, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: ui.textOnGradient,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Previous, current, sold and add-stock requirement detail.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ui.textOnGradient.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          _HeaderMetric(
            label: 'Previous',
            value: '${card.totalUnits} pcs',
            textColor: ui.textOnGradient,
          ),
          const SizedBox(width: 12),
          _HeaderMetric(
            label: 'Current',
            value: '${card.availableUnits} pcs',
            textColor: ui.textOnGradient,
          ),
          const SizedBox(width: 12),
          _HeaderMetric(
            label: 'Add Stock',
            value: '${card.suggestedReorderUnits} pcs',
            textColor: ui.textOnGradient,
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;

  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: textColor.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

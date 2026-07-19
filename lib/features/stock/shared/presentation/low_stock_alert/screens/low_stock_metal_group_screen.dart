import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/stock/shared/application/low_stock_alert_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/features/stock/shared/presentation/add_stock/stock_metal_ui.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/app_bar/low_stock_alert_app_bar.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/screens/low_stock_group_detail_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_alert_widgets.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_smart_card.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class LowStockMetalGroupScreen extends StatelessWidget {
  final LowStockAlertController controller;
  final LowStockStockCard metalCard;

  const LowStockMetalGroupScreen({
    super.key,
    required this.controller,
    required this.metalCard,
  });

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(StockCategory.fromLabel(metalCard.metalType));
    final groupCards = controller.groupCardsForMetal(metalCard.metalType);
    final isSilver = metalCard.metalType.trim().toLowerCase() == 'silver';

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
              child: _GroupHeader(
                ui: ui,
                card: metalCard,
                title: isSilver
                    ? '${ui.title} Low Stock Items'
                    : '${ui.title} Low Stock Grades',
                subtitle: isSilver
                    ? 'Select an item type to review grade-wise stock need.'
                    : 'Select a purity grade to review item-type stock need.',
              ),
            ),
          ),
          if (groupCards.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _MessageCard(
                icon: ui.icon,
                accent: ui.accent,
                title: 'No ${ui.title} Alert Groups',
                message: 'This metal has no grouped stock detail yet.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              sliver: SliverToBoxAdapter(
                child: _GroupGrid(
                  cards: groupCards,
                  actionLabel:
                      isSilver ? 'Open Item Detail' : 'Open Grade Detail',
                  onTap: (card) => _openGroupDetail(context, card),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openGroupDetail(BuildContext context, LowStockStockCard groupCard) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, __) => LowStockGroupDetailScreen(
          controller: controller,
          groupCard: groupCard,
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.025, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _GroupGrid extends StatelessWidget {
  final List<LowStockStockCard> cards;
  final String actionLabel;
  final ValueChanged<LowStockStockCard> onTap;

  const _GroupGrid({
    required this.cards,
    required this.actionLabel,
    required this.onTap,
  });

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
                  actionLabel: actionLabel,
                  onTap: () => onTap(card),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final StockMetalUiData ui;
  final LowStockStockCard card;
  final String title;
  final String subtitle;

  const _GroupHeader({
    required this.ui,
    required this.card,
    required this.title,
    required this.subtitle,
  });

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
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: ui.textOnGradient,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
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
            label: 'Current Pcs',
            value: '${card.availableUnits} pcs',
            textColor: ui.textOnGradient,
          ),
          const SizedBox(width: 12),
          _HeaderMetric(
            label: 'Need Stock',
            value: '${card.suggestedReorderUnits} pcs',
            textColor: ui.textOnGradient,
          ),
          const SizedBox(width: 12),
          _HeaderMetric(
            label: 'Need Weight',
            value: lowStockWeight(card.suggestedReorderNetWeight),
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
      constraints: const BoxConstraints(minWidth: 130),
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

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String message;

  const _MessageCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: InvColors.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accent, size: 34),
              const SizedBox(height: 12),
              Text(title, style: InvStyles.sectionTitle),
              const SizedBox(height: 6),
              Text(message,
                  style: InvStyles.cardNote, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:lotus_erp/features/stock/shared/application/low_stock_alert_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/screens/low_stock_metal_group_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_alert_header.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_alert_rules_panel.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_metal_cards_panel.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class LowStockAlertBody extends StatelessWidget {
  final LowStockAlertController controller;

  const LowStockAlertBody({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.load,
      color: InvColors.brandGold,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LowStockAlertHeader(
              summary: controller.summary,
              metalCards: controller.alertMetalCards,
            ),
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 14),
              _ErrorBanner(message: controller.errorMessage!),
            ],
            const SizedBox(height: 18),
            if (controller.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 42),
                child: Center(
                  child: CircularProgressIndicator(color: InvColors.brandGold),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LowStockAlertRulesPanel(controller: controller),
                  const SizedBox(height: 18),
                  LowStockMetalCardsPanel(
                    cards: controller.alertMetalCards,
                    onOpenMetal: (card) => _openMetalGroups(context, card),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _openMetalGroups(BuildContext context, LowStockStockCard card) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, __) => LowStockMetalGroupScreen(
          controller: controller,
          metalCard: card,
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

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: InvColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InvColors.danger.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: InvColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: InvStyles.cardSubValue.copyWith(color: InvColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

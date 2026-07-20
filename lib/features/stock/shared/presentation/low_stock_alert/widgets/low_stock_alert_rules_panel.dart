import 'package:flutter/material.dart';

import 'package:lotus_erp/features/stock/shared/application/low_stock_alert_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/screens/low_stock_manual_rule_editor_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/screens/low_stock_rule_studio_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_alert_widgets.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class LowStockAlertRulesPanel extends StatelessWidget {
  final LowStockAlertController controller;

  const LowStockAlertRulesPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final manualRules = controller.rules
        .where((rule) => rule.ruleMode == LowStockRuleMode.manual)
        .toList(growable: false);
    final stockMetalCount = controller.inventoryRuleMetalCards.length;

    return LowStockPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LowStockSectionHeader(
            icon: Icons.tune_rounded,
            title: 'Alert Rule Studio',
            subtitle: 'Pick inventory stock and set low-stock alert levels.',
            trailing: IconButton.filled(
              tooltip: 'Create manual alert rule',
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add_rounded),
              style: IconButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: InvColors.brandGold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _ActionCard(
            icon: Icons.inventory_2_rounded,
            title: 'Stock Rule Setup',
            subtitle:
                '$stockMetalCount metal stock cards. Click to set item rules.',
            color: InvColors.success,
            onTap: () => _openStudio(context, 0),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.edit_note_rounded,
            title: 'Saved Alert Rules',
            subtitle:
                '${manualRules.length} custom rules. Click to view and edit.',
            color: InvColors.brandGold,
            onTap: () => _openStudio(context, 1),
          ),
          const SizedBox(height: 14),
          if (manualRules.isEmpty)
            const LowStockEmptyState(
              title: 'Manual Rules Not Set',
              subtitle:
                  'Open Stock Rule Setup to define red, yellow and green levels.',
              icon: Icons.rule_folder_outlined,
            )
          else
            ...manualRules.take(3).map(
                  (rule) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RuleCard(
                      rule: rule,
                      onTap: () => _openEditor(context, rule: rule),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  void _openStudio(BuildContext context, int initialTab) {
    Navigator.of(context).push(_route(
      LowStockRuleStudioScreen(
        controller: controller,
        initialTab: initialTab,
      ),
    ));
  }

  void _openEditor(BuildContext context, {LowStockAlertRule? rule}) {
    Navigator.of(context).push(_route(
      LowStockManualRuleEditorScreen(controller: controller, rule: rule),
    ));
  }

  PageRouteBuilder<void> _route(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
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
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.24)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: InvStyles.itemName),
                    const SizedBox(height: 3),
                    Text(subtitle, style: InvStyles.itemSku),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final LowStockAlertRule rule;
  final VoidCallback onTap;

  const _RuleCard({required this.rule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF7),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: InvColors.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: InvColors.brandGold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rule.scopeLabel, style: InvStyles.itemName),
                    const SizedBox(height: 3),
                    Text(
                      'Red ${rule.criticalUnits} | Yellow ${rule.thresholdUnits} | Target ${rule.targetUnits}',
                      style: InvStyles.itemSku,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: InvColors.brandGold),
            ],
          ),
        ),
      ),
    );
  }
}

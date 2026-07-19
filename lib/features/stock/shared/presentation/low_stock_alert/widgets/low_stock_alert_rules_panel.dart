import 'package:flutter/material.dart';

import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_alert_widgets.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class LowStockAlertRulesPanel extends StatelessWidget {
  final List<LowStockAlertRule> rules;

  const LowStockAlertRulesPanel({super.key, required this.rules});

  @override
  Widget build(BuildContext context) {
    return LowStockPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LowStockSectionHeader(
            icon: Icons.tune_rounded,
            title: 'Alert Rule Studio',
            subtitle:
                'Default reorder guardrails are active. Item-specific rules can be added in the next polish pass.',
          ),
          const SizedBox(height: 14),
          if (rules.isEmpty)
            const LowStockEmptyState(
              title: 'No Rules Active',
              subtitle:
                  'Default rules will be seeded automatically on refresh.',
              icon: Icons.rule_folder_outlined,
            )
          else
            ...rules.map(
              (rule) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RuleCard(rule: rule),
              ),
            ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final LowStockAlertRule rule;

  const _RuleCard({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: InvColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: InvColors.brandGoldLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.rule_rounded,
              color: InvColors.brandGold,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.scopeLabel,
                  style: InvStyles.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Alert below ${rule.thresholdUnits} pcs or ${lowStockWeight(rule.thresholdNetWeight)}',
                  style: InvStyles.itemSku,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          LowStockStatusPill(
            label: 'Target ${rule.reorderTargetUnits} pcs',
            color: InvColors.success,
          ),
        ],
      ),
    );
  }
}

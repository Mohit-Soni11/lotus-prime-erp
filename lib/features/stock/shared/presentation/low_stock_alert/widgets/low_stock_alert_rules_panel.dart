import 'package:flutter/material.dart';

import 'package:lotus_erp/features/stock/shared/application/low_stock_alert_controller.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/screens/low_stock_rule_studio_screen.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_alert_widgets.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class LowStockAlertRulesPanel extends StatelessWidget {
  final LowStockAlertController controller;

  const LowStockAlertRulesPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final stockMetalCount = controller.inventoryRuleMetalCards.length;
    final watchedGroups = controller.summary.watchedGroups;

    return LowStockPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LowStockSectionHeader(
            icon: Icons.rule_folder_rounded,
            title: 'Stock Alert Rule Setup',
            subtitle: 'Create alert levels from live inventory stock cards.',
            trailing: LowStockStatusPill(
              label: '$stockMetalCount METALS',
              color: InvColors.success,
            ),
          ),
          const SizedBox(height: 14),
          _RuleSetupConsole(
            metalCount: stockMetalCount,
            watchedGroups: watchedGroups,
            onTap: () => _openStudio(context, 0),
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

class _RuleSetupConsole extends StatelessWidget {
  final int metalCount;
  final int watchedGroups;
  final VoidCallback onTap;

  const _RuleSetupConsole({
    required this.metalCount,
    required this.watchedGroups,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: InvColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: InvColors.success.withValues(alpha: 0.24),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final content = [
                _SetupStatTile(
                  label: 'Metals',
                  value: '$metalCount',
                  icon: Icons.category_rounded,
                ),
                _SetupStatTile(
                  label: 'Rule Cards',
                  value: '$watchedGroups',
                  icon: Icons.inventory_2_rounded,
                ),
              ];
              return Flex(
                direction: compact ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: compact
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.center,
                children: [
                  if (compact)
                    const _RuleSetupIntro()
                  else
                    const Expanded(child: _RuleSetupIntro()),
                  SizedBox(width: compact ? 0 : 18, height: compact ? 14 : 0),
                  Flex(
                    direction: compact ? Axis.vertical : Axis.horizontal,
                    children: [
                      for (final tile in content) ...[
                        if (compact)
                          tile
                        else
                          SizedBox(width: 132, child: tile),
                        if (tile != content.last)
                          SizedBox(
                            width: compact ? 0 : 10,
                            height: compact ? 10 : 0,
                          ),
                      ],
                    ],
                  ),
                  SizedBox(width: compact ? 0 : 18, height: compact ? 14 : 0),
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: InvColors.success,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Open Setup',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RuleSetupIntro extends StatelessWidget {
  const _RuleSetupIntro();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: InvColors.success.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: InvColors.success,
            size: 24,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Inventory Rule Setup', style: InvStyles.itemName),
              const SizedBox(height: 3),
              Text(
                'Open Gold, Silver and item cards to set red, yellow and green levels.',
                style: InvStyles.itemSku,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetupStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SetupStatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: InvColors.success.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: InvColors.success, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: InvStyles.cardLabel),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: InvStyles.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// FILE        : delivery_stats_header.dart
// MODULE      : Sales â†’ Delivery Management
// LAYER       : UI
// DESCRIPTION : Top stats row â€” 4 metric cards showing Active, Action Required,
//               Due Ledger, Completed counts. Responsive, animated.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../logic/sales_orders/delivery/delivery_management_controller.dart';
import '../../../theme/sales/delivery/delivery_theme.dart';

class DeliveryStatsHeader extends StatelessWidget {
  final DeliveryManagementController ctrl;

  const DeliveryStatsHeader({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final s = ctrl.summary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      color: DeliveryColors.bodyBg,
      child: LayoutBuilder(builder: (_, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        if (isNarrow) {
          return Column(children: [
            Row(children: [
              Expanded(
                  child: _StatCard(
                      label: DeliveryStrings.statTotalActive,
                      value: s.totalActive.toString(),
                      icon: DeliveryIcons.tabActiveOrders,
                      color: DeliveryColors.statusBooked)),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatCard(
                      label: DeliveryStrings.statActionRequired,
                      value: s.actionRequired.toString(),
                      icon: DeliveryIcons.tabActionRequired,
                      color: DeliveryColors.urgencyOverdue,
                      highlight: s.actionRequired > 0)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: _StatCard(
                      label: DeliveryStrings.statDueLedger,
                      value: s.dueLedgerCount.toString(),
                      icon: DeliveryIcons.tabDueLedger,
                      color: DeliveryColors.paymentPartial,
                      highlight: s.dueLedgerCount > 0)),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatCard(
                      label: DeliveryStrings.statCompleted,
                      value: s.completedCount.toString(),
                      icon: DeliveryIcons.tabCompleted,
                      color: DeliveryColors.paymentPaid)),
            ]),
          ]);
        }
        return Row(children: [
          Expanded(
              child: _StatCard(
                  label: DeliveryStrings.statTotalActive,
                  value: s.totalActive.toString(),
                  icon: DeliveryIcons.tabActiveOrders,
                  color: DeliveryColors.statusBooked)),
          const SizedBox(width: 12),
          Expanded(
              child: _StatCard(
                  label: DeliveryStrings.statActionRequired,
                  value: s.actionRequired.toString(),
                  icon: DeliveryIcons.tabActionRequired,
                  color: DeliveryColors.urgencyOverdue,
                  highlight: s.actionRequired > 0)),
          const SizedBox(width: 12),
          Expanded(
              child: _StatCard(
                  label: DeliveryStrings.statDueLedger,
                  value: s.dueLedgerCount.toString(),
                  icon: DeliveryIcons.tabDueLedger,
                  color: DeliveryColors.paymentPartial,
                  highlight: s.dueLedgerCount > 0)),
          const SizedBox(width: 12),
          Expanded(
              child: _StatCard(
                  label: DeliveryStrings.statCompleted,
                  value: s.completedCount.toString(),
                  icon: DeliveryIcons.tabCompleted,
                  color: DeliveryColors.paymentPaid)),
          if (s.totalDueAmount > 0) ...[
            const SizedBox(width: 12),
            Expanded(child: _DueAmountCard(amount: s.totalDueAmount)),
          ],
        ]);
      }),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlight;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DeliveryColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? color.withValues(alpha: 0.4)
              : DeliveryColors.bodyBorder,
          width: highlight ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: highlight
                ? color.withValues(alpha: 0.08)
                : DeliveryColors.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: highlight ? color : DeliveryColors.bodyTextMain,
                  height: 1.1,
                ),
              ),
              Text(label,
                  style: DeliveryStyles.cardSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ]),
    );
  }
}

class _DueAmountCard extends StatelessWidget {
  final double amount;
  const _DueAmountCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DeliveryColors.urgencyOverdueBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: DeliveryColors.urgencyOverdue.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: DeliveryColors.urgencyOverdue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(DeliveryIcons.dueAmount,
              color: DeliveryColors.urgencyOverdue, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'â‚¹${_formatAmount(amount)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: DeliveryColors.urgencyOverdue,
                  height: 1.1,
                ),
              ),
              const Text(DeliveryStrings.statTotalDue,
                  style: DeliveryStyles.cardSubtitle),
            ],
          ),
        ),
      ]),
    );
  }

  String _formatAmount(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

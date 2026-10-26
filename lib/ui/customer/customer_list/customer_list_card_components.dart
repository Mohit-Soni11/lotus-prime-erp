import 'package:flutter/material.dart';

import '../../../models/customer/customer_list/customer_list_ui_model.dart';
import '../../../theme/customer/customer_list/customer_list_theme.dart';

class CustomerListMetricRail extends StatelessWidget {
  final CustomerListItemModel customer;
  final bool compact;

  const CustomerListMetricRail({
    super.key,
    required this.customer,
    this.compact = false,
  });
  @override
  Widget build(BuildContext context) {
    final metrics = [
      CustomerListMetricTile(
        icon: CustomerListIcons.invoice,
        label: "Invoices",
        value: customer.billCount.toString(),
        accent: CustomerListColors.info,
        background: CustomerListColors.infoBg,
      ),
      CustomerListMetricTile(
        icon: CustomerListIcons.due,
        label: "Due",
        value: _formatMoney(customer.dueAmount),
        accent: customer.hasDue
            ? CustomerListColors.danger
            : CustomerListColors.success,
        background: customer.hasDue
            ? CustomerListColors.dangerBg
            : CustomerListColors.successBg,
      ),
      CustomerListMetricTile(
        icon: CustomerListIcons.girvi,
        label: "Girvi",
        value: customer.activeGirviCount.toString(),
        accent: CustomerListColors.violet,
        background: CustomerListColors.violetBg,
      ),
      CustomerListMetricTile(
        icon: CustomerListIcons.advance,
        label: "Advance",
        value: customer.activeAdvanceCount.toString(),
        accent: CustomerListColors.teal,
        background: CustomerListColors.tealBg,
      ),
    ];

    if (compact) {
      return Wrap(spacing: 8, runSpacing: 8, children: metrics);
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (int i = 0; i < metrics.length; i++) ...[
        metrics[i],
        if (i != metrics.length - 1) const SizedBox(width: 8),
      ],
    ]);
  }

  static String _formatMoney(double value) {
    if (value <= 0.01) return "Rs 0";
    if (value >= 10000000) {
      return "Rs ${(value / 10000000).toStringAsFixed(1)}Cr";
    }
    if (value >= 100000) return "Rs ${(value / 100000).toStringAsFixed(1)}L";
    if (value >= 1000) return "Rs ${(value / 1000).toStringAsFixed(1)}K";
    return "Rs ${value.toStringAsFixed(0)}";
  }
}

class CustomerListMetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color background;

  const CustomerListMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(height: 6),
          Text(
            value,
            style: CustomerListStyles.metricValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            label.toUpperCase(),
            style: CustomerListStyles.metricLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class CustomerActivityPalette {
  final Color accent;
  final Color background;

  const CustomerActivityPalette({
    required this.accent,
    required this.background,
  });
}

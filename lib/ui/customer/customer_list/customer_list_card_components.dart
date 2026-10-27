import 'package:flutter/material.dart';

import '../../../models/customer/customer_list/customer_list_ui_model.dart';
import '../../../theme/customer/customer_list/customer_list_theme.dart';
import 'customer_list_number_format.dart';

class CustomerListMetricRail extends StatelessWidget {
  const CustomerListMetricRail({super.key, required this.customer});

  final CustomerListItemModel customer;

  @override
  Widget build(BuildContext context) {
    final metrics = <Widget>[
      CustomerListMetricTile(
        icon: CustomerListIcons.invoice,
        label: 'Invoices',
        value: CustomerListNumberFormat.count(customer.billCount),
        accent: CustomerListColors.info,
        background: CustomerListColors.infoBg,
      ),
      if (customer.hasDueInvoices)
        CustomerListMetricTile(
          icon: CustomerListIcons.due,
          label: 'Due Invoices',
          value: CustomerListNumberFormat.count(customer.dueInvoiceCount),
          accent: CustomerListColors.dangerText,
          background: CustomerListColors.dangerBg,
        ),
      if (customer.activeGirviCount > 0)
        CustomerListMetricTile(
          icon: CustomerListIcons.girvi,
          label: 'Active Girvi Loans',
          value: CustomerListNumberFormat.count(customer.activeGirviCount),
          accent: CustomerListColors.violet,
          background: CustomerListColors.violetBg,
        ),
      if (customer.activeAdvanceCount > 0)
        CustomerListMetricTile(
          icon: CustomerListIcons.advance,
          label: 'Open Advance Orders',
          value: CustomerListNumberFormat.count(customer.activeAdvanceCount),
          accent: CustomerListColors.teal,
          background: CustomerListColors.tealBg,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final availableColumns = ((constraints.maxWidth + gap) / 150)
            .floor()
            .clamp(1, metrics.length);
        final columns =
            metrics.length == 4 && availableColumns == 3 ? 2 : availableColumns;
        final width = ((constraints.maxWidth - gap * (columns - 1)) / columns)
            .clamp(0.0, 185.0)
            .toDouble();
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in metrics) SizedBox(width: width, child: metric),
          ],
        );
      },
    );
  }
}

class CustomerListMetricTile extends StatelessWidget {
  const CustomerListMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.background,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 17, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: CustomerListStyles.metricLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 23,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(value, style: CustomerListStyles.metricValue),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../models/customer/customer_list/customer_list_ui_model.dart';
import '../../../theme/customer/customer_list/customer_list_theme.dart';
import 'customer_list_number_format.dart';

class CustomerListStatsDashboard extends StatelessWidget {
  const CustomerListStatsDashboard({super.key, required this.stats});

  final CustomerListStatsModel stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      CustomerListStatCard(
        icon: CustomerListIcons.customers,
        title: CustomerListStrings.totalCustomers,
        value: _count(stats.totalCount),
        caption: '${stats.activePercentage}% active customer accounts',
        accent: CustomerListColors.brandGoldDark,
        iconBackground: CustomerListColors.brandGoldBg,
      ),
      CustomerListStatCard(
        icon: CustomerListIcons.active,
        title: CustomerListStrings.activeAccounts,
        value: _count(stats.activeCount),
        caption: 'Customer accounts currently active',
        accent: CustomerListColors.successText,
        iconBackground: CustomerListColors.successBg,
      ),
      CustomerListStatCard(
        icon: CustomerListIcons.month,
        title: CustomerListStrings.newThisMonth,
        value: _count(stats.monthCount),
        caption:
            '${CustomerListNumberFormat.count(stats.todayCount)} added today',
        accent: CustomerListColors.info,
        iconBackground: CustomerListColors.infoBg,
      ),
      CustomerListStatCard(
        icon: CustomerListIcons.due,
        title: CustomerListStrings.totalOutstandingAmount,
        value: stats.isLoading
            ? '—'
            : CustomerListNumberFormat.money(stats.totalDueAmount),
        caption:
            '${CustomerListNumberFormat.count(stats.dueCustomerCount)} ${_plural(stats.dueCustomerCount, 'customer')} with outstanding balance',
        accent: CustomerListColors.dangerText,
        iconBackground: CustomerListColors.dangerBg,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 12.0;
          final columns = constraints.maxWidth >= 1160
              ? 4
              : constraints.maxWidth >= 640
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final card in cards) SizedBox(width: width, child: card),
            ],
          );
        },
      ),
    );
  }

  String _count(int value) =>
      stats.isLoading ? '—' : CustomerListNumberFormat.count(value);

  String _plural(int count, String word) => count == 1 ? word : '${word}s';
}

class CustomerListStatCard extends StatelessWidget {
  const CustomerListStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
    required this.accent,
    required this.iconBackground,
  });

  final IconData icon;
  final String title;
  final String value;
  final String caption;
  final Color accent;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 158,
      padding: const EdgeInsets.all(18),
      decoration: CustomerListStyles.statsCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: CustomerListStyles.statsLabel,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 31,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(value, style: CustomerListStyles.statsValue),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: CustomerListStyles.statsCaption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../models/customer/customer_list/customer_list_ui_model.dart';
import '../../../theme/customer/customer_list/customer_list_theme.dart';

class CustomerListStatsDashboard extends StatelessWidget {
  final CustomerListStatsModel stats;

  const CustomerListStatsDashboard({super.key, required this.stats});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 12.0;
          final columns = constraints.maxWidth >= 1260
              ? 4
              : constraints.maxWidth >= 760
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              SizedBox(
                width: width,
                child: CustomerListStatCard(
                  icon: CustomerListIcons.customers,
                  title: CustomerListStrings.totalCustomers,
                  value:
                      stats.isLoading ? "--" : _formatCount(stats.totalCount),
                  caption: stats.isLoading
                      ? "Calculating active rate"
                      : "${stats.activePercentage}% active accounts",
                  accent: CustomerListColors.brandGold,
                  background: CustomerListColors.brandGoldBg,
                  trailing: CustomerListActiveRing(
                    value: stats.isLoading ? 0 : stats.activeRatio,
                    label:
                        stats.isLoading ? "--" : "${stats.activePercentage}%",
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: CustomerListStatCard(
                  icon: CustomerListIcons.active,
                  title: CustomerListStrings.activeAccounts,
                  value:
                      stats.isLoading ? "--" : _formatCount(stats.activeCount),
                  caption: stats.isLoading
                      ? "Reading live accounts"
                      : "${stats.totalBillCount} invoices recorded",
                  accent: CustomerListColors.success,
                  background: CustomerListColors.successBg,
                  progress: stats.isLoading ? 0 : stats.activeRatio,
                ),
              ),
              SizedBox(
                width: width,
                child: CustomerListStatCard(
                  icon: CustomerListIcons.month,
                  title: CustomerListStrings.newThisMonth,
                  value:
                      stats.isLoading ? "--" : _formatCount(stats.monthCount),
                  caption: stats.isLoading
                      ? "Checking enrollments"
                      : "${stats.todayCount} added today",
                  accent: CustomerListColors.info,
                  background: CustomerListColors.infoBg,
                  progress: stats.totalCount == 0 || stats.isLoading
                      ? 0
                      : stats.monthCount / stats.totalCount,
                ),
              ),
              SizedBox(
                width: width,
                child: CustomerListStatCard(
                  icon: CustomerListIcons.due,
                  title: CustomerListStrings.dueExposure,
                  value: stats.isLoading
                      ? "--"
                      : _formatMoney(stats.totalDueAmount),
                  caption: stats.isLoading
                      ? "Auditing customer dues"
                      : "${stats.dueCustomerCount} customers with pending due",
                  accent: stats.totalDueAmount > 0
                      ? CustomerListColors.danger
                      : CustomerListColors.teal,
                  background: stats.totalDueAmount > 0
                      ? CustomerListColors.dangerBg
                      : CustomerListColors.tealBg,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatCount(int value) {
    if (value >= 1000000) return "${(value / 1000000).toStringAsFixed(1)}M";
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(1)}K";
    return value.toString();
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

class CustomerListStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String caption;
  final Color accent;
  final Color background;
  final double? progress;
  final Widget? trailing;

  const CustomerListStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
    required this.accent,
    required this.background,
    this.progress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = (progress ?? 0).clamp(0.0, 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(15),
      decoration: CustomerListStyles.statsCardDecoration,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 21, color: accent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: CustomerListStyles.statsLabel),
                const SizedBox(height: 6),
                Text(value, style: CustomerListStyles.statsValue),
                const SizedBox(height: 5),
                Text(
                  caption,
                  style: CustomerListStyles.statsCaption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (progress != null) ...[
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: clampedProgress),
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 5,
                          backgroundColor: CustomerListColors.bodyBorder
                              .withValues(alpha: 0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class CustomerListActiveRing extends StatelessWidget {
  final double value;
  final String label;

  const CustomerListActiveRing({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return SizedBox(
          width: 58,
          height: 58,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: animatedValue,
                strokeWidth: 6,
                backgroundColor: CustomerListColors.bodyBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  CustomerListColors.brandGold,
                ),
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Text(
                  label,
                  style: CustomerListStyles.statsCaption.copyWith(
                    color: CustomerListColors.brandGoldDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

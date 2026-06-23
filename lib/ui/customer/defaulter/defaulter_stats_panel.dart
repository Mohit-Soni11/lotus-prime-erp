// =============================================================================
// FILE        : defaulter_stats_panel.dart
// MODULE      : Risk & Collections
// DESCRIPTION : Responsive executive summary cards for Girvi collection risk.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../logic/customer/defaulter_logic.dart';
import '../../../models/customer/defaulter_model.dart';
import '../../../theme/customer/defaulter/defaulter_theme.dart';

class DefaulterStatsPanel extends StatelessWidget {
  final DefaulterStatsModel stats;
  final bool isLoading;

  const DefaulterStatsPanel({
    super.key,
    required this.stats,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1180
              ? 4
              : constraints.maxWidth >= 760
                  ? 2
                  : 1;
          final spacing = columns == 1 ? 10.0 : 14.0;
          final cardWidth =
              (constraints.maxWidth - (spacing * (columns - 1))) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: 12,
            children: [
              SizedBox(
                width: cardWidth,
                child: _StatCard(
                  isLoading: isLoading,
                  iconData: DefaulterIcons.totalCount,
                  iconBg: DefaulterColors.statTotalBg,
                  iconColor: DefaulterColors.statTotalIcon,
                  label: DefaulterStrings.statTotal,
                  value: stats.totalRiskAccounts.toString(),
                  valueStyle: DefaulterStyles.statValue,
                  footer: _RiskPills(
                    overdue: stats.overdueCount,
                    settlement: stats.settlementPendingCount,
                  ),
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: _StatCard(
                  isLoading: isLoading,
                  iconData: DefaulterIcons.totalAmount,
                  iconBg: DefaulterColors.statAmountBg,
                  iconColor: DefaulterColors.statAmountIcon,
                  label: DefaulterStrings.statTotalDue,
                  value: DefaulterLogic.formatAmountCompact(
                    stats.totalAmountDue,
                  ),
                  valueStyle: DefaulterStyles.statAmountValue,
                  footerText:
                      'Interest due ${DefaulterLogic.formatAmountCompact(stats.totalInterestDue)}',
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: _StatCard(
                  isLoading: isLoading,
                  iconData: DefaulterIcons.principal,
                  iconBg: DefaulterColors.statPrincipalBg,
                  iconColor: DefaulterColors.statPrincipalIcon,
                  label: DefaulterStrings.statPrincipal,
                  value: DefaulterLogic.formatAmountCompact(
                    stats.totalPrincipalDue,
                  ),
                  valueStyle: DefaulterStyles.statAmountValue.copyWith(
                    color: DefaulterColors.statPrincipalText,
                  ),
                  footerText: '${stats.criticalCount} critical accounts',
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: _StatCard(
                  isLoading: isLoading,
                  iconData: DefaulterIcons.collected,
                  iconBg: DefaulterColors.statReceivedBg,
                  iconColor: DefaulterColors.statReceivedIcon,
                  label: DefaulterStrings.statReceived,
                  value: DefaulterLogic.formatAmountCompact(
                    stats.totalReceived,
                  ),
                  valueStyle: DefaulterStyles.statAmountValue.copyWith(
                    color: DefaulterColors.statReceivedText,
                  ),
                  footerText: 'Updated ${stats.lastRefreshedAt}',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final bool isLoading;
  final IconData iconData;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final TextStyle valueStyle;
  final Widget? footer;
  final String? footerText;

  const _StatCard({
    required this.isLoading,
    required this.iconData,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueStyle,
    this.footer,
    this.footerText,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(16),
      decoration: DefaulterStyles.statCardDecoration,
      child: isLoading ? _buildShimmer() : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconData, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: DefaulterStyles.statLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Text(
              value,
              key: ValueKey(value),
              style: valueStyle,
              maxLines: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        footer ??
            Text(
              footerText ?? '',
              style: DefaulterStyles.statSuffix,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 110, height: 14, decoration: _shimmerBox),
          const SizedBox(height: 16),
          Container(width: 140, height: 26, decoration: _shimmerBox),
          const SizedBox(height: 12),
          Container(width: 120, height: 12, decoration: _shimmerBox),
        ],
      ),
    );
  }

  static BoxDecoration get _shimmerBox => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      );
}

class _RiskPills extends StatelessWidget {
  final int overdue;
  final int settlement;

  const _RiskPills({
    required this.overdue,
    required this.settlement,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _pill(
          '$overdue overdue',
          DefaulterColors.riskCriticalText,
          DefaulterColors.riskCriticalBg,
        ),
        if (settlement > 0)
          _pill(
            '$settlement settlement',
            DefaulterColors.riskHighText,
            DefaulterColors.riskHighBg,
          ),
        if (overdue == 0 && settlement == 0)
          const Text('Portfolio controlled', style: DefaulterStyles.statSuffix),
      ],
    );
  }

  Widget _pill(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

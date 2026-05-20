// ==========================================
// FILE: defaulter_stats_panel.dart
// MODULE: Customer → Defaulter List
// DESCRIPTION: Three animated summary stat cards at the top of the screen.
//              Shows: Total Defaulters | Total Amount Due | Critical Cases
// ==========================================

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../models/customer/defaulter_model.dart';
import '../../../theme/customer/defaulter/defaulter_theme.dart';
import '../../../logic/customer/defaulter_logic.dart';

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
      child: Row(
        children: [
          // --- Card 1: Total Defaulters ---
          Expanded(
            child: _StatCard(
              isLoading: isLoading,
              iconData: DefaulterIcons.totalCount,
              iconBg: DefaulterColors.statTotalBg,
              iconColor: DefaulterColors.statTotalIcon,
              label: DefaulterStrings.statTotal,
              valueWidget: _AnimatedCountText(
                value: stats.totalDefaulters.toString(),
                style: DefaulterStyles.statValue,
              ),
              suffixText: DefaulterStrings.statSuffix,
              bottomRow: _RiskPills(
                critical: stats.criticalCount,
                high: stats.highCount,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // --- Card 2: Total Amount Due ---
          Expanded(
            child: _StatCard(
              isLoading: isLoading,
              iconData: DefaulterIcons.totalAmount,
              iconBg: DefaulterColors.statAmountBg,
              iconColor: DefaulterColors.statAmountIcon,
              label: DefaulterStrings.statTotalDue,
              valueWidget: _AnimatedCountText(
                value: DefaulterLogic.formatAmountCompact(stats.totalAmountDue),
                style: DefaulterStyles.statAmountValue,
              ),
              suffixText: null,
              bottomRow: const Text(
                'Principal + Interest',
                style: DefaulterStyles.statSuffix,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // --- Card 3: Critical Cases ---
          Expanded(
            child: _StatCard(
              isLoading: isLoading,
              iconData: DefaulterIcons.criticalCount,
              iconBg: DefaulterColors.statCriticalBg,
              iconColor: DefaulterColors.statCriticalIcon,
              label: DefaulterStrings.statCritical,
              valueWidget: _AnimatedCountText(
                value: stats.criticalCount.toString(),
                style: DefaulterStyles.statCriticalValue,
              ),
              suffixText: '> 90 days',
              bottomRow: Text(
                'Need immediate action',
                style: DefaulterStyles.statSuffix.copyWith(
                  color: DefaulterColors.riskCriticalText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final bool isLoading;
  final IconData iconData;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Widget valueWidget;
  final String? suffixText;
  final Widget bottomRow;

  const _StatCard({
    required this.isLoading,
    required this.iconData,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.valueWidget,
    required this.suffixText,
    required this.bottomRow,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: DefaulterStyles.statCardDecoration,
      child: isLoading ? _buildShimmer() : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + Label row
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

        // Value
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            valueWidget,
            if (suffixText != null) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(suffixText!, style: DefaulterStyles.statSuffix),
              ),
            ],
          ],
        ),

        const SizedBox(height: 8),

        // Bottom row (risk pills or note)
        bottomRow,
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
          Container(width: 80, height: 14, decoration: _shimmerBox),
          const SizedBox(height: 12),
          Container(width: 60, height: 28, decoration: _shimmerBox),
          const SizedBox(height: 8),
          Container(width: 100, height: 12, decoration: _shimmerBox),
        ],
      ),
    );
  }

  static BoxDecoration get _shimmerBox => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      );
}

// ─────────────────────────────────────────
// ANIMATED COUNT TEXT
// ─────────────────────────────────────────

class _AnimatedCountText extends StatelessWidget {
  final String value;
  final TextStyle style;

  const _AnimatedCountText({required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.elasticOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: Text(
        value,
        key: ValueKey<String>(value),
        style: style,
      ),
    );
  }
}

// ─────────────────────────────────────────
// RISK PILLS (inside total card)
// ─────────────────────────────────────────

class _RiskPills extends StatelessWidget {
  final int critical;
  final int high;

  const _RiskPills({required this.critical, required this.high});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (critical > 0)
          _pill(
            label: '$critical Critical',
            color: DefaulterColors.riskCriticalText,
            bg: DefaulterColors.riskCriticalBg,
          ),
        if (critical > 0 && high > 0) const SizedBox(width: 6),
        if (high > 0)
          _pill(
            label: '$high High',
            color: DefaulterColors.riskHighText,
            bg: DefaulterColors.riskHighBg,
          ),
        if (critical == 0 && high == 0)
          const Text('All manageable', style: DefaulterStyles.statSuffix),
      ],
    );
  }

  Widget _pill({
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

import 'metal_valuation_tokens.dart';

class MetalValuationSummaryPanel extends StatelessWidget {
  final MetalValuationSnapshot snapshot;

  const MetalValuationSummaryPanel({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4BF), Color(0xFFE0B11F)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Color(0xFF6B4A00),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metal Valuation Control',
                          style: MetalValuationText.sectionTitle.copyWith(
                            fontSize: 26,
                            color: const Color(0xFF3B2A08),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Live purchase cost, sale recovery and stock margin from linked inventory records.',
                          style: MetalValuationText.body.copyWith(
                            color: const Color(0xFF4B3A12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _MetalSmartCardGrid(
                rows: snapshot.breakdown,
                compact: compact,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetalSmartCardGrid extends StatelessWidget {
  final List<MetalValuationBreakdown> rows;
  final bool compact;

  const _MetalSmartCardGrid({
    required this.rows,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows
        .where((row) => row.availableUnits > 0 || row.soldUnits > 0)
        .toList();

    if (visibleRows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white),
        ),
        child: Text(
          'No metal stock available for valuation.',
          style: MetalValuationText.body.copyWith(
            color: const Color(0xFF3B2A08),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleRows.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 136,
      ),
      itemBuilder: (context, index) {
        return _MetalSmartCard(row: visibleRows[index]);
      },
    );
  }
}

class _MetalSmartCard extends StatelessWidget {
  final MetalValuationBreakdown row;

  const _MetalSmartCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final colors = _MetalTone.forMetal(row.metalType);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: colors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titleCase(row.metalType),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MetalValuationText.sectionTitle.copyWith(
                    fontSize: 18,
                    color: const Color(0xFF2E2109),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Available Weight',
            style: MetalValuationText.label.copyWith(
              color: const Color(0xFF2E2109),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatGram(row.availableNetWeight),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MetalValuationText.value.copyWith(
              fontSize: 24,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${row.availableUnits} available',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MetalValuationText.body.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF2E2109),
                  ),
                ),
              ),
              Text(
                '${row.soldUnits} sold',
                style: MetalValuationText.body.copyWith(
                  fontSize: 12,
                  color: row.soldUnits > 0
                      ? MetalValuationColors.red
                      : const Color(0xFF2E2109),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetalTone {
  final Color background;
  final Color border;
  final Color accent;

  const _MetalTone({
    required this.background,
    required this.border,
    required this.accent,
  });

  static _MetalTone forMetal(String metalType) {
    switch (metalType.trim().toUpperCase()) {
      case 'GOLD':
        return const _MetalTone(
          background: Color(0xFFFFF7D6),
          border: Color(0xFFEACB65),
          accent: Color(0xFFB8860B),
        );
      case 'SILVER':
        return const _MetalTone(
          background: Color(0xFFF1F6F8),
          border: Color(0xFFCBDCE4),
          accent: Color(0xFF607D8B),
        );
      case 'PLATINUM':
        return const _MetalTone(
          background: Color(0xFFF3F4F6),
          border: Color(0xFFC7CED8),
          accent: Color(0xFF475569),
        );
      case 'DIAMOND':
        return const _MetalTone(
          background: Color(0xFFEEF6FF),
          border: Color(0xFFBFDBFE),
          accent: Color(0xFF2563EB),
        );
      default:
        return const _MetalTone(
          background: Color(0xFFF7F3EA),
          border: Color(0xFFE7DCC8),
          accent: Color(0xFF7C5A16),
        );
    }
  }
}

class MetalValuationMetricStrip extends StatelessWidget {
  final MetalValuationSummary summary;

  const MetalValuationMetricStrip({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 900 ? 2 : 4;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: columns == 2 ? 3.2 : 3.1,
          children: [
            _DeskMetric(
              label: 'Available Units',
              value: '${summary.availableUnits}',
              helper: formatGram(summary.availableNetWeight),
              icon: Icons.widgets_rounded,
              accent: MetalValuationColors.green,
            ),
            _DeskMetric(
              label: 'Sold Units',
              value: '${summary.soldUnits}',
              helper: formatGram(summary.soldNetWeight),
              icon: Icons.shopping_bag_rounded,
              accent: MetalValuationColors.red,
            ),
            _DeskMetric(
              label: 'Actual Fine',
              value: formatGram(summary.availableActualFine),
              helper: 'Available stock',
              icon: Icons.scale_rounded,
              accent: MetalValuationColors.blue,
            ),
            _DeskMetric(
              label: 'Valuation Fine',
              value: formatGram(summary.availableValuationFine),
              helper: 'Available stock',
              icon: Icons.analytics_rounded,
              accent: MetalValuationColors.goldDark,
            ),
          ],
        );
      },
    );
  }
}

class _DeskMetric extends StatelessWidget {
  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color accent;

  const _DeskMetric({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: valuationPanelDecoration(color: Colors.white),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: MetalValuationText.label),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MetalValuationText.value.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 2),
                Text(
                  helper,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MetalValuationText.body.copyWith(
                    fontSize: 12,
                    color: MetalValuationColors.mutedInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

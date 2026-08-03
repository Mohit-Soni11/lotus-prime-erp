import 'package:flutter/material.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

import 'metal_valuation_tokens.dart';

class MetalValuationBreakdownPanel extends StatelessWidget {
  final List<MetalValuationBreakdown> rows;
  final ValueChanged<MetalValuationBreakdown>? onMetalSelected;

  const MetalValuationBreakdownPanel({
    super.key,
    required this.rows,
    this.onMetalSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: valuationPanelDecoration(color: Colors.white),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Metal Performance',
            subtitle: 'Available and sold net weight grouped by metal.',
            icon: Icons.donut_large_rounded,
          ),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            const _EmptyState(message: 'No valuation records found.')
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 920 ? 1 : 3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 222,
                  ),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return _BreakdownCard(
                      row: row,
                      onTap: onMetalSelected == null
                          ? null
                          : () => onMetalSelected!(row),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final MetalValuationBreakdown row;
  final VoidCallback? onTap;

  const _BreakdownCard({required this.row, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: MetalValuationColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MetalValuationMetalImage(
                    metalType: row.metalType,
                    borderColor: MetalValuationColors.line,
                    fallbackColor: MetalValuationColors.goldDark,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      titleCase(row.metalType),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MetalValuationText.sectionTitle.copyWith(
                        fontSize: 18,
                      ),
                    ),
                  ),
                  _StatusPill(
                    label: row.soldUnits > 0 ? 'Movement' : 'Available',
                    color: row.soldUnits > 0
                        ? MetalValuationColors.goldDark
                        : MetalValuationColors.green,
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: MetalValuationColors.goldDark,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniFact(
                      label: 'Available Net Weight',
                      value: formatGram(row.availableNetWeight),
                      valueColor: MetalValuationColors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniFact(
                      label: 'Sold Net Weight',
                      value: formatGram(row.soldNetWeight),
                      valueColor: row.soldNetWeight > 0
                          ? MetalValuationColors.red
                          : MetalValuationColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MiniFact(
                      label: 'Available Units',
                      value: '${row.availableUnits}',
                      valueColor: MetalValuationColors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniFact(
                      label: 'Sold Units',
                      value: '${row.soldUnits}',
                      valueColor: row.soldUnits > 0
                          ? MetalValuationColors.red
                          : MetalValuationColors.ink,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: MetalValuationText.label.copyWith(color: color),
      ),
    );
  }
}

class _MiniFact extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MiniFact({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MetalValuationColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: MetalValuationText.label.copyWith(fontSize: 11)),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MetalValuationText.body.copyWith(
              color: valueColor ?? MetalValuationColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: MetalValuationColors.gold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: MetalValuationColors.goldDark, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: MetalValuationText.sectionTitle),
              const SizedBox(height: 3),
              Text(subtitle, style: MetalValuationText.body),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(26),
      child: Center(
        child: Text(message, style: MetalValuationText.body),
      ),
    );
  }
}

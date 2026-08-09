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
            subtitle: 'Live stock balance, sold movement and margin by metal.',
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
                    mainAxisExtent: constraints.maxWidth < 560 ? 418 : 386,
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
              _MetricBand(
                title: 'Available Stock',
                value: formatGram(row.availableNetWeight),
                caption: '${row.availableQuantityLabel} in hand',
                color: MetalValuationColors.green,
                icon: Icons.inventory_2_rounded,
              ),
              const SizedBox(height: 10),
              _MetricBand(
                title: 'Sold Movement',
                value: formatGram(row.soldNetWeight),
                caption: '${row.soldQuantityLabel} sold',
                color: row.soldUnits > 0
                    ? MetalValuationColors.red
                    : MetalValuationColors.softInk,
                icon: Icons.point_of_sale_rounded,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MiniFact(
                      label: 'Stock Cost',
                      value: formatMoney(row.availableCost),
                      valueColor: MetalValuationColors.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniFact(
                      label: 'Sale Value',
                      value: formatMoney(row.saleValue),
                      valueColor: MetalValuationColors.goldDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniFact(
                      label: 'Profit',
                      value: formatMoney(row.profit),
                      valueColor: row.profit >= 0
                          ? MetalValuationColors.green
                          : MetalValuationColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MiniFact(
                      label: 'Sold Cost',
                      value: formatMoney(row.soldCost),
                      valueColor: row.soldCost > 0
                          ? MetalValuationColors.ink
                          : MetalValuationColors.softInk,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniFact(
                      label: 'Margin',
                      value: formatPercent(row.marginPercent),
                      valueColor: row.marginPercent >= 0
                          ? MetalValuationColors.green
                          : MetalValuationColors.red,
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

class _MetricBand extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final Color color;
  final IconData icon;

  const _MetricBand({
    required this.title,
    required this.value,
    required this.caption,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MetalValuationText.label),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MetalValuationText.value.copyWith(
                    color: color,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: MetalValuationText.label.copyWith(
                color: MetalValuationColors.mutedInk,
                fontSize: 11,
              ),
            ),
          ),
        ],
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

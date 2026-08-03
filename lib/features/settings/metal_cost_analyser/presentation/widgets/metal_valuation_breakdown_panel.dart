import 'package:flutter/material.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

import 'metal_valuation_tokens.dart';

class MetalValuationBreakdownPanel extends StatelessWidget {
  final List<MetalValuationBreakdown> rows;

  const MetalValuationBreakdownPanel({super.key, required this.rows});

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
            subtitle: 'Cost, sale value and stock margin grouped by metal.',
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
                    return _BreakdownCard(row: rows[index]);
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

  const _BreakdownCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final profitColor =
        row.profit >= 0 ? MetalValuationColors.green : MetalValuationColors.red;
    return Container(
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
              Text(
                '${row.availableUnits} live',
                style: MetalValuationText.label.copyWith(
                  color: MetalValuationColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniFact(
                  label: 'Available Cost',
                  value: formatMoney(row.availableCost),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniFact(
                  label: 'Sold Cost',
                  value: formatMoney(row.soldCost),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniFact(
                  label: 'Sale Value',
                  value: formatMoney(row.saleValue),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniFact(
                  label: 'Margin',
                  value: formatMoney(row.profit),
                  valueColor: profitColor,
                ),
              ),
            ],
          ),
        ],
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

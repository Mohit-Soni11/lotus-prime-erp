import 'package:flutter/material.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_grade_models.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

import 'metal_valuation_tokens.dart';

class SilverItemMovementGrid extends StatelessWidget {
  final List<MetalValuationGradeRow> items;
  final List<BatchValuationRow> Function(String itemLabel) batchesForItem;
  final ValueChanged<MetalValuationGradeRow> onItemTap;
  final ValueChanged<BatchValuationRow> onBatchTap;

  const SilverItemMovementGrid({
    super.key,
    required this.items,
    required this.batchesForItem,
    required this.onItemTap,
    required this.onBatchTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1240
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth >= 780
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: SilverItemMovementCard(
                  item: item,
                  batches: batchesForItem(item.gradeLabel),
                  onTap: () => onItemTap(item),
                  onBatchTap: onBatchTap,
                ),
              ),
          ],
        );
      },
    );
  }
}

class SilverItemMovementCard extends StatelessWidget {
  final MetalValuationGradeRow item;
  final List<BatchValuationRow> batches;
  final VoidCallback onTap;
  final ValueChanged<BatchValuationRow> onBatchTap;

  const SilverItemMovementCard({
    super.key,
    required this.item,
    required this.batches,
    required this.onTap,
    required this.onBatchTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSaleMovement = item.soldUnits > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: valuationPanelDecoration(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SilverItemHeader(item: item, hasSaleMovement: hasSaleMovement),
              const SizedBox(height: 14),
              _SilverStockMovement(item: item),
              const SizedBox(height: 12),
              _SilverCostMovement(item: item),
              const SizedBox(height: 10),
              _SilverSalesMovement(item: item),
              if (batches.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SilverLinkedBatchStrip(
                  batches: batches,
                  onBatchTap: onBatchTap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SilverItemHeader extends StatelessWidget {
  final MetalValuationGradeRow item;
  final bool hasSaleMovement;

  const _SilverItemHeader({
    required this.item,
    required this.hasSaleMovement,
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
            color: MetalValuationColors.slate.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            hasSaleMovement
                ? Icons.trending_up_rounded
                : Icons.inventory_2_rounded,
            color: MetalValuationColors.slate,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            titleCase(item.gradeLabel),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MetalValuationText.sectionTitle.copyWith(fontSize: 19),
          ),
        ),
        _SilverStatusPill(
          label: item.statusLabel,
          active: hasSaleMovement,
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.arrow_forward_rounded,
          color: MetalValuationColors.slate,
          size: 18,
        ),
      ],
    );
  }
}

class _SilverStockMovement extends StatelessWidget {
  final MetalValuationGradeRow item;

  const _SilverStockMovement({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SilverMetricBand(
            label: 'Available Stock',
            value: formatUnitCount(item.availableUnits),
            helper: formatGram(item.availableNetWeight),
            color: MetalValuationColors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SilverMetricBand(
            label: 'Sold Movement',
            value: formatUnitCount(item.soldUnits),
            helper: formatGram(item.soldNetWeight),
            color: item.soldUnits > 0
                ? MetalValuationColors.red
                : MetalValuationColors.softInk,
          ),
        ),
      ],
    );
  }
}

class _SilverCostMovement extends StatelessWidget {
  final MetalValuationGradeRow item;

  const _SilverCostMovement({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SilverFact(
            label: 'Available Cost',
            value: formatMoney(item.availableCost),
            valueColor: MetalValuationColors.slate,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SilverFact(
            label: 'Sold Cost',
            value: formatMoney(item.soldCost),
          ),
        ),
      ],
    );
  }
}

class _SilverSalesMovement extends StatelessWidget {
  final MetalValuationGradeRow item;

  const _SilverSalesMovement({required this.item});

  @override
  Widget build(BuildContext context) {
    final profitColor = item.profit >= 0
        ? MetalValuationColors.green
        : MetalValuationColors.red;
    final marginColor = item.marginPercent >= 0
        ? MetalValuationColors.green
        : MetalValuationColors.red;
    return Row(
      children: [
        Expanded(
          child: _SilverFact(
            label: 'Sales Value',
            value: formatMoney(item.saleValue),
            valueColor: MetalValuationColors.slate,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SilverFact(
            label: 'Profit',
            value: formatMoney(item.profit),
            valueColor: profitColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SilverFact(
            label: 'Margin',
            value: formatPercent(item.marginPercent),
            valueColor: marginColor,
          ),
        ),
      ],
    );
  }
}

class _SilverLinkedBatchStrip extends StatelessWidget {
  final List<BatchValuationRow> batches;
  final ValueChanged<BatchValuationRow> onBatchTap;

  const _SilverLinkedBatchStrip({
    required this.batches,
    required this.onBatchTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleBatches = batches.take(2).toList(growable: false);
    final hiddenCount = batches.length - visibleBatches.length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MetalValuationColors.slate.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: MetalValuationColors.slate.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Linked Batches',
                  style: MetalValuationText.label.copyWith(
                    color: MetalValuationColors.ink,
                  ),
                ),
              ),
              Text(
                '${batches.length} ${batches.length == 1 ? 'batch' : 'batches'}',
                style: MetalValuationText.label.copyWith(
                  color: MetalValuationColors.slate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final batch in visibleBatches) ...[
            _SilverBatchMiniRow(
              batch: batch,
              onTap: () => onBatchTap(batch),
            ),
            if (batch != visibleBatches.last) const SizedBox(height: 6),
          ],
          if (hiddenCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              '+$hiddenCount more in item detail',
              style: MetalValuationText.label.copyWith(
                color: MetalValuationColors.mutedInk,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SilverBatchMiniRow extends StatelessWidget {
  final BatchValuationRow batch;
  final VoidCallback onTap;

  const _SilverBatchMiniRow({
    required this.batch,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: MetalValuationColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batch.batchCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MetalValuationText.label.copyWith(
                      color: MetalValuationColors.ink,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatDate(batch.createdAt)}  |  ${batch.supplierName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MetalValuationText.label.copyWith(
                      color: MetalValuationColors.mutedInk,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                formatGram(batch.totalNetWeight),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: MetalValuationText.label.copyWith(
                  color: MetalValuationColors.green,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                formatMoney(batch.totalCost),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: MetalValuationText.label.copyWith(
                  color: MetalValuationColors.slate,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_rounded,
              color: MetalValuationColors.slate,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}

class _SilverMetricBand extends StatelessWidget {
  final String label;
  final String value;
  final String helper;
  final Color color;

  const _SilverMetricBand({
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: MetalValuationText.label),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MetalValuationText.value.copyWith(
              color: color,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MetalValuationText.label.copyWith(
              color: MetalValuationColors.mutedInk,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SilverFact extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SilverFact({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: MetalValuationColors.panel,
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

class _SilverStatusPill extends StatelessWidget {
  final String label;
  final bool active;

  const _SilverStatusPill({
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        active ? MetalValuationColors.slate : MetalValuationColors.green;
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

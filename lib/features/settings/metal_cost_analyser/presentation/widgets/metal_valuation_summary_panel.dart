import 'package:flutter/material.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

import 'metal_valuation_tokens.dart';

class MetalValuationSummaryPanel extends StatelessWidget {
  final MetalValuationSnapshot snapshot;
  final ValueChanged<MetalValuationBreakdown>? onMetalSelected;

  const MetalValuationSummaryPanel({
    super.key,
    required this.snapshot,
    this.onMetalSelected,
  });

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
                onMetalSelected: onMetalSelected,
                columns: constraints.maxWidth < 620
                    ? 1
                    : compact
                        ? 2
                        : 4,
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
  final ValueChanged<MetalValuationBreakdown>? onMetalSelected;
  final int columns;

  const _MetalSmartCardGrid({
    required this.rows,
    this.onMetalSelected,
    required this.columns,
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
        crossAxisCount: columns,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 236,
      ),
      itemBuilder: (context, index) {
        final row = visibleRows[index];
        return _MetalSmartCard(
          row: row,
          onTap: onMetalSelected == null ? null : () => onMetalSelected!(row),
        );
      },
    );
  }
}

class _MetalSmartCard extends StatelessWidget {
  final MetalValuationBreakdown row;
  final VoidCallback? onTap;

  const _MetalSmartCard({
    required this.row,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _MetalTone.forMetal(row.metalType);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
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
                  MetalValuationMetalImage(
                    metalType: row.metalType,
                    borderColor: colors.border,
                    fallbackColor: colors.accent,
                    size: 38,
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
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: colors.accent,
                      size: 18,
                    ),
                ],
              ),
              const Spacer(),
              _SmartMetric(
                label: 'Available Net Weight',
                value: formatGram(row.availableNetWeight),
                color: colors.accent,
              ),
              const SizedBox(height: 10),
              _SmartMetric(
                label: 'Available Cost Price',
                value: formatMoney(row.availableCost),
                color: const Color(0xFF2E2109),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SmartChip(
                      label: '${row.availableQuantityLabel} available',
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SmartChip(
                      label: '${row.soldQuantityLabel} sold',
                      color: row.soldUnits > 0
                          ? MetalValuationColors.red
                          : const Color(0xFF2E2109),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SmartFooterValue(
                      label: 'Sold Wt',
                      value: formatGram(row.soldNetWeight),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SmartFooterValue(
                      label: 'Profit',
                      value: formatMoney(row.profit),
                      color: row.profit >= 0
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

class _SmartMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SmartMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: MetalValuationText.label.copyWith(
            color: const Color(0xFF2E2109),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: MetalValuationText.value.copyWith(
            fontSize: 21,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SmartChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SmartChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: MetalValuationText.body.copyWith(
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }
}

class _SmartFooterValue extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SmartFooterValue({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: MetalValuationText.label.copyWith(
        fontSize: 11,
        color: color ?? const Color(0xFF2E2109),
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

import 'package:flutter/material.dart';

import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

class PosGstClassificationCard extends StatelessWidget {
  final bool hasJewelleryItems;
  final bool hasLooseDiamondItems;

  const PosGstClassificationCard({
    super.key,
    required this.hasJewelleryItems,
    required this.hasLooseDiamondItems,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasJewelleryItems && !hasLooseDiamondItems) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        border: Border.all(
          color: SalesPosColors.brandGold.withValues(alpha: 0.35),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GST CLASSIFICATION',
            style: TextStyle(
              fontSize: SalesPosStyles.fontCaption,
              fontWeight: FontWeight.w900,
              color: SalesPosColors.bodyTextMain,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          if (hasJewelleryItems)
            const _ClassificationLine(
              code: 'HSN 7113',
              title: 'Jewellery Sale',
              subtitle: 'Gold, silver and platinum jewellery',
              taxLabel: 'GST 3%',
            ),
          if (hasLooseDiamondItems) ...[
            if (hasJewelleryItems) const SizedBox(height: 8),
            const _ClassificationLine(
              code: 'HSN 7102',
              title: 'Loose Diamond / Stone',
              subtitle: 'Use only for loose stones, not jewellery items',
              taxLabel: 'Rate as configured',
            ),
          ],
        ],
      ),
    );
  }
}

class _ClassificationLine extends StatelessWidget {
  final String code;
  final String title;
  final String subtitle;
  final String taxLabel;

  const _ClassificationLine({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.taxLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: SalesPosColors.brandGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: SalesPosColors.brandGold.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            code,
            style: const TextStyle(
              fontSize: SalesPosStyles.fontCaption,
              fontWeight: FontWeight.w900,
              color: SalesPosColors.brandGold,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: SalesPosStyles.fontLabel,
                  fontWeight: FontWeight.w900,
                  color: SalesPosColors.bodyTextMain,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: SalesPosStyles.fontCaption,
                  fontWeight: FontWeight.w800,
                  color: SalesPosColors.bodyTextMuted,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          taxLabel,
          style: const TextStyle(
            fontSize: SalesPosStyles.fontCaption,
            fontWeight: FontWeight.w900,
            color: SalesPosColors.success,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../features/sales_pos/domain/services/pos_gst_classification_resolver.dart';
import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

class PosGstClassificationCard extends StatelessWidget {
  final List<PosGstClassificationLine> lines;

  const PosGstClassificationCard({
    super.key,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
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
          for (var index = 0; index < lines.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            _ClassificationLine(line: lines[index]),
          ],
        ],
      ),
    );
  }
}

class _ClassificationLine extends StatelessWidget {
  final PosGstClassificationLine line;

  const _ClassificationLine({required this.line});

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
            line.code,
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
                line.title,
                style: const TextStyle(
                  fontSize: SalesPosStyles.fontLabel,
                  fontWeight: FontWeight.w900,
                  color: SalesPosColors.bodyTextMain,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                line.subtitle,
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
          line.taxLabel,
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

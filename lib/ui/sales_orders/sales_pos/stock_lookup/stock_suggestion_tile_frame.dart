import 'package:flutter/material.dart';

import '../../../../models/sales_orders/sales_pos_models/pos_stock_lookup_model.dart';
import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

class StockSuggestionTileFrame extends StatelessWidget {
  final PosStockLookupModel item;
  final VoidCallback onTap;
  final Color accentColor;
  final Color huidIconColor;
  final List<String> metadata;
  final List<String> identifiers;

  const StockSuggestionTileFrame({
    super.key,
    required this.item,
    required this.onTap,
    required this.accentColor,
    required this.huidIconColor,
    required this.metadata,
    required this.identifiers,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: accentColor.withValues(alpha: 0.08),
      splashColor: accentColor.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 11,
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SalesPosStyles.bodyText.copyWith(
                            color: SalesPosColors.bodyTextMain,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _MetadataRibbon(
                          values: metadata.isEmpty ? [item.sku] : metadata,
                          accentColor: accentColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 10,
              child: _StockIdentifierStack(
                values: identifiers,
                iconColor: huidIconColor,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 68,
              child: Text(
                '${_formatWeight(item.grossWeight)} g',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: SalesPosStyles.bodyText.copyWith(
                  color: SalesPosColors.bodyTextMain,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatWeight(double value) {
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _MetadataRibbon extends StatelessWidget {
  final List<String> values;
  final Color accentColor;

  const _MetadataRibbon({
    required this.values,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final visibleValues = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .take(3)
        .toList(growable: false);
    if (visibleValues.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: [
        for (final value in visibleValues)
          Container(
            constraints: const BoxConstraints(maxWidth: 118),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.caption.copyWith(
                color: SalesPosColors.bodyTextMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _StockIdentifierStack extends StatelessWidget {
  final List<String> values;
  final Color iconColor;

  const _StockIdentifierStack({
    required this.values,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cleanValues = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final visibleValues = cleanValues.take(2).toList(growable: false);
    final overflowCount = cleanValues.length - visibleValues.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < visibleValues.length; index++) ...[
          _StockIdentifierPill(
            text: visibleValues[index],
            iconColor: iconColor,
          ),
          if (index < visibleValues.length - 1) const SizedBox(height: 4),
        ],
        if (overflowCount > 0) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '+$overflowCount more',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.caption.copyWith(
                color: SalesPosColors.bodyTextMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StockIdentifierPill extends StatelessWidget {
  final String text;
  final Color iconColor;

  const _StockIdentifierPill({
    required this.text,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 23,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_outlined,
            size: 12,
            color: iconColor.withValues(alpha: 0.88),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.caption.copyWith(
                color: SalesPosColors.bodyTextMain,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

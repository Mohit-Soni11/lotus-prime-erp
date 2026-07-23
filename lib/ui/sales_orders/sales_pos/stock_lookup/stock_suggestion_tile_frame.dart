import 'package:flutter/material.dart';

import '../../../../models/sales_orders/sales_pos_models/pos_stock_lookup_model.dart';
import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

class StockSuggestionTileFrame extends StatelessWidget {
  final PosStockLookupModel item;
  final VoidCallback onTap;
  final Color accentColor;
  final Color huidIconColor;
  final String metadata;
  final String huidText;

  const StockSuggestionTileFrame({
    super.key,
    required this.item,
    required this.onTap,
    required this.accentColor,
    required this.huidIconColor,
    required this.metadata,
    required this.huidText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: accentColor.withValues(alpha: 0.08),
      splashColor: accentColor.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 34,
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
                        const SizedBox(height: 4),
                        Text(
                          metadata,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SalesPosStyles.caption.copyWith(
                            color: SalesPosColors.bodyTextMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
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
              child: _StockIdentifierPill(
                text: huidText,
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
      height: 28,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_outlined,
            size: 13,
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

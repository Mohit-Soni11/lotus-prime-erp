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
    final displayAccent = _readableAccent(accentColor);
    final cleanMetadata = metadata
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .where(
          (value) =>
              !RegExp(r'^\d+\s*pcs$', caseSensitive: false).hasMatch(value),
        )
        .toList(growable: false);

    return InkWell(
      onTap: onTap,
      hoverColor: displayAccent.withValues(alpha: 0.08),
      splashColor: displayAccent.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 70,
              decoration: BoxDecoration(
                color: displayAccent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SalesPosStyles.bodyText.copyWith(
                            color: SalesPosColors.bodyTextMain,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _AvailableQuantityBadge(
                        quantity: item.availableQuantity,
                        unitLabel: item.quantityUnitLabel,
                        accentColor: displayAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  _MetadataRibbon(
                    values: cleanMetadata.isEmpty ? [item.sku] : cleanMetadata,
                    accentColor: displayAccent,
                  ),
                  if (identifiers.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _StockIdentifierStack(
                      values: identifiers,
                      iconColor: _readableAccent(huidIconColor),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _NetWeightPill(
                    netWeight: item.netWeight,
                    accentColor: displayAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _readableAccent(Color color) {
    if (color == SalesPosColors.brandSilver ||
        color == SalesPosColors.brandPlatinum) {
      return const Color(0xFF2563EB);
    }
    return color;
  }

  static String _formatWeight(double value) {
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _AvailableQuantityBadge extends StatelessWidget {
  final double quantity;
  final String unitLabel;
  final Color accentColor;

  const _AvailableQuantityBadge({
    required this.quantity,
    required this.unitLabel,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 86),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: accentColor.withValues(alpha: 0.32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Available',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: SalesPosStyles.caption.copyWith(
              color: SalesPosColors.bodyTextMain,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_formatQuantity(quantity)} ${_unitName(quantity, unitLabel)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: SalesPosStyles.bodyText.copyWith(
              color: accentColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1.0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatQuantity(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.001) return rounded.toStringAsFixed(0);
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }

  static String _unitName(double quantity, String unitLabel) {
    final label = unitLabel.trim().toLowerCase();
    final singular = switch (label) {
      'packet' || 'pack' => 'packet',
      'pair' => 'pair',
      'set' => 'set',
      'lot' || 'bulk' => 'lot',
      _ => 'pcs',
    };
    if ((quantity - 1).abs() < 0.001) return singular;
    return switch (singular) {
      'packet' => 'packets',
      'pair' => 'pairs',
      'set' => 'sets',
      'lot' => 'lots',
      _ => 'pcs',
    };
  }
}

class _NetWeightPill extends StatelessWidget {
  final double netWeight;
  final Color accentColor;

  const _NetWeightPill({
    required this.netWeight,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return _StockMetricPill(
      label: 'Net Weight',
      value: '${StockSuggestionTileFrame._formatWeight(netWeight)} g',
      accentColor: accentColor,
    );
  }
}

class _StockMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _StockMetricPill({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.30),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: SalesPosStyles.caption.copyWith(
            color: SalesPosColors.bodyTextMain,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(
                color: accentColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
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
      runSpacing: 5,
      children: [
        for (final value in visibleValues)
          Container(
            constraints: const BoxConstraints(maxWidth: 132),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.20),
              ),
            ),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.caption.copyWith(
                color: SalesPosColors.bodyTextMain,
                fontSize: 11.5,
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

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        for (final value in visibleValues)
          _StockIdentifierPill(
            text: value,
            iconColor: iconColor,
          ),
        if (overflowCount > 0)
          _StockIdentifierPill(
            text: '+$overflowCount more',
            iconColor: iconColor,
          ),
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
      constraints: const BoxConstraints(maxWidth: 150),
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: iconColor.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_outlined,
            size: 13,
            color: iconColor,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.caption.copyWith(
                color: SalesPosColors.bodyTextMain,
                fontSize: 11.5,
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

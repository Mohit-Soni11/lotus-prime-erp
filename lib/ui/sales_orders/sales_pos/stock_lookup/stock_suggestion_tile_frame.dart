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
    final accent = _readableAccent(accentColor);
    final identifierAccent = _readableAccent(huidIconColor);
    final cleanMetadata = metadata
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .where(
          (value) =>
              !RegExp(r'^\d+\s*pcs$', caseSensitive: false).hasMatch(value),
        )
        .take(3)
        .toList(growable: false);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: accent.withValues(alpha: 0.07),
        splashColor: accent.withValues(alpha: 0.12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE7DAC5)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _StockIdentity(
                          title: item.displayTitle,
                          metadata: cleanMetadata,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _AvailableQuantityBadge(
                        quantity: item.availableQuantity,
                        unitLabel: item.quantityUnitLabel,
                        accentColor: accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  _IdentifierLine(
                    values: identifiers,
                    accentColor: identifierAccent,
                  ),
                  const SizedBox(height: 7),
                  _StockFactsLine(
                    item: item,
                    accentColor: accent,
                    compact: compact,
                  ),
                ],
              );
            },
          ),
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

  static String formatWeight(double value) {
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _StockIdentity extends StatelessWidget {
  final String title;
  final List<String> metadata;

  const _StockIdentity({
    required this.title,
    required this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.trim().isEmpty ? 'Stock Item' : title.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SalesPosStyles.bodyText.copyWith(
            color: SalesPosColors.bodyTextMain,
            fontSize: 15.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        _MetadataChips(values: metadata),
      ],
    );
  }
}

class _MetadataChips extends StatelessWidget {
  final List<String> values;

  const _MetadataChips({required this.values});

  @override
  Widget build(BuildContext context) {
    final cleanValues = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (cleanValues.isEmpty) {
      return Text(
        'Ready Stock',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: SalesPosStyles.caption.copyWith(
          color: SalesPosColors.bodyTextMain,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        for (final value in cleanValues)
          Container(
            constraints: const BoxConstraints(maxWidth: 120),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F1),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFE7DAC5)),
            ),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.caption.copyWith(
                color: SalesPosColors.bodyTextMain,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
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
      constraints: const BoxConstraints(minWidth: 78),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.28)),
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
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${_formatQuantity(quantity)} ${_unitName(quantity, unitLabel)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: SalesPosStyles.bodyText.copyWith(
              color: accentColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1,
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

class _IdentifierLine extends StatelessWidget {
  final List<String> values;
  final Color accentColor;

  const _IdentifierLine({
    required this.values,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cleanValues = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final label = cleanValues.length > 1 ? 'HUID Set' : 'HUID';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 66,
          child: Text(
            cleanValues.isEmpty ? 'HUID' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalesPosStyles.caption.copyWith(
              color: SalesPosColors.bodyTextMain,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: cleanValues.isEmpty
              ? Text(
                  'Not Linked',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.caption.copyWith(
                    color: SalesPosColors.bodyTextMain,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (final value in cleanValues.take(3))
                      _IdentifierToken(
                        text: value,
                        accentColor: accentColor,
                      ),
                    if (cleanValues.length > 3)
                      _IdentifierToken(
                        text: '+${cleanValues.length - 3} more',
                        accentColor: accentColor,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _IdentifierToken extends StatelessWidget {
  final String text;
  final Color accentColor;

  const _IdentifierToken({
    required this.text,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 122),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: accentColor.withValues(alpha: 0.24)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: SalesPosStyles.caption.copyWith(
          color: SalesPosColors.bodyTextMain,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _StockFactsLine extends StatelessWidget {
  final PosStockLookupModel item;
  final Color accentColor;
  final bool compact;

  const _StockFactsLine({
    required this.item,
    required this.accentColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final facts = <_FactData>[
      _FactData(
        'Net Wt',
        '${StockSuggestionTileFrame.formatWeight(item.netWeight)} g',
      ),
      if (!compact &&
          item.grossWeight > 0 &&
          (item.grossWeight - item.netWeight).abs() > 0.001)
        _FactData(
          'Gross Wt',
          '${StockSuggestionTileFrame.formatWeight(item.grossWeight)} g',
        ),
      if (item.purity.trim().isNotEmpty) _FactData('Purity', item.purity),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var index = 0; index < facts.length; index++)
          _FactPill(
            fact: facts[index],
            accentColor: accentColor,
            highlighted: index == 0,
          ),
      ],
    );
  }
}

class _FactData {
  final String label;
  final String value;

  const _FactData(this.label, this.value);
}

class _FactPill extends StatelessWidget {
  final _FactData fact;
  final Color accentColor;
  final bool highlighted;

  const _FactPill({
    required this.fact,
    required this.accentColor,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: highlighted ? accentColor.withValues(alpha: 0.09) : Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: highlighted
              ? accentColor.withValues(alpha: 0.24)
              : const Color(0xFFE7DAC5),
        ),
      ),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: SalesPosStyles.caption.copyWith(
            color: SalesPosColors.bodyTextMain,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          children: [
            TextSpan(text: '${fact.label}: '),
            TextSpan(
              text: fact.value,
              style: TextStyle(
                color: highlighted ? accentColor : SalesPosColors.bodyTextMain,
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

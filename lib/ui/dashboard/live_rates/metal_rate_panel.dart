import 'package:flutter/material.dart';

import '../../../models/setting/metal_rate/metal_rate_model.dart';
import '../../../theme/dashboard/live_rates/live_rates_theme.dart';

class MetalRateRow {
  const MetalRateRow({
    required this.purity,
    required this.perGram,
    required this.perBaseUnit,
  });

  final String purity;
  final String perGram;
  final String perBaseUnit;
}

class MetalRatePanel extends StatelessWidget {
  const MetalRatePanel({
    super.key,
    required this.metal,
    required this.rows,
  });

  final MetalRateMetal metal;
  final List<MetalRateRow> rows;

  @override
  Widget build(BuildContext context) {
    final isGold = metal == MetalRateMetal.gold;
    final accent = isGold ? LiveRatesColors.gold : LiveRatesColors.silver;
    final baseUnit =
        isGold ? LiveRatesStrings.perTenGrams : LiveRatesStrings.perKilogram;
    return Container(
      decoration: LiveRatesStyles.panel(isGold: isGold),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      metal.assetPath,
                      width: 38,
                      height: 35,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    isGold ? LiveRatesStrings.gold : LiveRatesStrings.silver,
                    style: LiveRatesStyles.panelTitle.copyWith(color: accent),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.black.withValues(alpha: 0.18),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: _columns(
                LiveRatesStrings.purity,
                LiveRatesStrings.perGram,
                baseUnit,
                header: true,
              ),
            ),
            for (final (index, row) in rows.indexed) ...[
              if (index > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 12,
                  endIndent: 12,
                  color: LiveRatesColors.divider,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: _columns(
                  row.purity,
                  _amount(row.perGram, '/g'),
                  _amount(row.perBaseUnit, isGold ? '/10g' : '/kg'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _amount(String value, String suffix) =>
      value == '--' ? value : '₹$value$suffix';

  Widget _columns(String purity, String perGram, String perBase,
      {bool header = false}) {
    final valueStyle = header ? LiveRatesStyles.column : LiveRatesStyles.rate;
    return Row(
      children: [
        Expanded(
            flex: 2,
            child: Text(purity,
                style: header ? valueStyle : LiveRatesStyles.purity)),
        Expanded(
          flex: 3,
          child: Text(
            perGram,
            style: valueStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            perBase,
            textAlign: TextAlign.end,
            style: valueStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

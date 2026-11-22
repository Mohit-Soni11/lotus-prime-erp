import 'package:flutter/material.dart';

import '../../../models/live_rates/live_rates_model.dart';
import '../../../models/setting/metal_rate/metal_rate_model.dart';
import '../../../theme/dashboard/live_rates/live_rates_theme.dart';

class MetalRatePanel extends StatefulWidget {
  const MetalRatePanel({
    super.key,
    required this.metal,
    required this.rows,
    required this.collapsedRowCount,
  });

  final MetalRateMetal metal;
  final List<LiveMetalRate> rows;
  final int collapsedRowCount;

  @override
  State<MetalRatePanel> createState() => _MetalRatePanelState();
}

class _MetalRatePanelState extends State<MetalRatePanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isGold = widget.metal == MetalRateMetal.gold;
    final accent = isGold ? LiveRatesColors.gold : LiveRatesColors.silver;
    final baseUnit =
        isGold ? LiveRatesStrings.perTenGrams : LiveRatesStrings.perKilogram;
    final canExpand = widget.rows.length > widget.collapsedRowCount;
    final visibleRows = _expanded || !canExpand
        ? widget.rows
        : widget.rows.take(widget.collapsedRowCount);
    return Container(
      decoration: LiveRatesStyles.panel(isGold: isGold),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      widget.metal.assetPath,
                      width: 38,
                      height: 35,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stackTrace) => SizedBox(
                        width: 38,
                        height: 35,
                        child: Icon(Icons.diamond_outlined,
                            color: accent, size: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    isGold ? LiveRatesStrings.gold : LiveRatesStrings.silver,
                    style: LiveRatesStyles.panelTitle.copyWith(color: accent),
                  ),
                  const Spacer(),
                  if (canExpand)
                    IconButton(
                      key: ValueKey('${widget.metal.name}-rates-expand'),
                      onPressed: () => setState(() => _expanded = !_expanded),
                      tooltip:
                          _expanded ? 'Show fewer rates' : 'Show all rates',
                      color: accent,
                      visualDensity: VisualDensity.compact,
                      constraints:
                          const BoxConstraints(minWidth: 30, minHeight: 30),
                      padding: EdgeInsets.zero,
                      icon: AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
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
            for (final (index, row) in visibleRows.indexed) ...[
              if (index > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 12,
                  endIndent: 12,
                  color: LiveRatesColors.divider,
                ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: _columns(
                  row.description ?? row.purity,
                  _amount(row.perGram),
                  _amount(row.perBaseUnit),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _amount(String value) => value == '--' ? value : '₹$value';

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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/reports/day_book/day_book_models.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_metal_sales_panel.dart';
import 'day_book_metal_visual.dart';

class DayBookPositionPanels extends StatelessWidget {
  const DayBookPositionPanels({
    super.key,
    required this.summary,
  });

  final DayBookSummary summary;

  @override
  Widget build(BuildContext context) {
    final flow = summary.moneyFlow;
    final gold = summary.ownedStockPosition?.gold;
    final silver = summary.ownedStockPosition?.silver;
    final goldAvailable = gold?.isConsistent ?? summary.metalPositionVerified;
    final silverAvailable =
        silver?.isConsistent ?? summary.metalPositionVerified;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _PositionSection(
        title: 'Opening Position',
        icon: Icons.inventory_2_outlined,
        date: summary.date,
        tiles: [
          _PositionTile(
              label: 'Opening Balance',
              value: _money(flow?.openingTotal ?? summary.openingCash),
              icon: Icons.account_balance_wallet_outlined,
              color: DayBookColors.positive,
              hint: 'Cash + bank'),
          _PositionTile(
              label: 'Opening Gold',
              value: goldAvailable
                  ? dayBookMetalWeight(
                      gold?.openingGrams ?? summary.openingGoldGrams)
                  : '—',
              metal: DayBookMetalVisualType.gold,
              color: DayBookColors.goldMetal,
              hint: _stockHint(
                  goldAvailable, gold?.openingGrams ?? summary.openingGoldGrams,
                  verified: summary.metalPositionVerified)),
          _PositionTile(
              label: 'Opening Silver',
              value: silverAvailable
                  ? dayBookMetalWeight(
                      silver?.openingGrams ?? summary.openingSilverGrams)
                  : '—',
              metal: DayBookMetalVisualType.silver,
              color: DayBookColors.silverMetal,
              hint: _stockHint(silverAvailable,
                  silver?.openingGrams ?? summary.openingSilverGrams,
                  verified: summary.metalPositionVerified)),
        ],
      ),
      const SizedBox(height: 10),
      DayBookMetalSalesPanel(
        gold: gold,
        silver: silver,
        customerSales: summary.customerMetalSales,
      ),
      const SizedBox(height: 10),
      _PositionSection(
        title: 'Closing Position',
        icon: Icons.assessment_outlined,
        tiles: [
          _PositionTile(
              label: 'Closing Balance',
              value: _money(flow?.closingTotal ?? summary.closingCash),
              icon: Icons.account_balance_wallet_rounded,
              color: DayBookColors.positive,
              hint: 'Cash + bank'),
          _PositionTile(
              label: 'Closing Gold',
              value:
                  goldAvailable ? dayBookMetalWeight(summary.closingGold) : '—',
              metal: DayBookMetalVisualType.gold,
              color: DayBookColors.goldMetal,
              hint: _stockHint(goldAvailable, summary.closingGold,
                  verified: summary.metalPositionVerified)),
          _PositionTile(
              label: 'Closing Silver',
              value: silverAvailable
                  ? dayBookMetalWeight(summary.closingSilver)
                  : '—',
              metal: DayBookMetalVisualType.silver,
              color: DayBookColors.silverMetal,
              hint: _stockHint(silverAvailable, summary.closingSilver,
                  verified: summary.metalPositionVerified)),
        ],
      ),
    ]);
  }
}

class _PositionTile {
  const _PositionTile({
    required this.label,
    required this.value,
    required this.color,
    required this.hint,
    this.icon,
    this.metal,
  });

  final String label;
  final String value;
  final IconData? icon;
  final DayBookMetalVisualType? metal;
  final Color color;
  final String hint;
}

class _PositionSection extends StatelessWidget {
  const _PositionSection({
    required this.title,
    required this.icon,
    required this.tiles,
    this.date,
  });

  final String title;
  final IconData icon;
  final List<_PositionTile> tiles;
  final DateTime? date;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: DayBookStyles.panel(),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            _IconBadge(icon: icon, color: DayBookColors.brandGold),
            const SizedBox(width: 9),
            Expanded(
              child: Text(title,
                  style: DayBookStyles.sectionTitle.copyWith(fontSize: 18)),
            ),
            if (date != null)
              Text(DateFormat('d MMM yyyy').format(date!),
                  style: DayBookStyles.labelStrong),
          ]),
          const SizedBox(height: 11),
          LayoutBuilder(builder: (context, constraints) {
            final inline = constraints.maxWidth >= 440;
            if (!inline) {
              return Column(children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(height: 7),
                  _PositionValueTile(tile: tiles[i]),
                ],
              ]);
            }
            return Row(children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _PositionValueTile(tile: tiles[i])),
              ],
            ]);
          }),
        ]),
      );
}

class _PositionValueTile extends StatelessWidget {
  const _PositionValueTile({required this.tile});

  final _PositionTile tile;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: DayBookStyles.softPanel(
            color: DayBookColors.bodySubtle,
            borderColor: DayBookColors.bodyBorder),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (tile.metal != null)
              DayBookMetalVisual(metal: tile.metal!, size: 30)
            else
              Icon(tile.icon, size: 21, color: tile.color),
            const SizedBox(width: 7),
            Expanded(
                child: Text(tile.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DayBookStyles.labelStrong.copyWith(fontSize: 13))),
          ]),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 26,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(tile.value,
                  style: DayBookStyles.valueLarge.copyWith(fontSize: 20)),
            ),
          ),
          Text(tile.hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DayBookStyles.label.copyWith(fontSize: 13)),
        ]),
      );
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: DayBookColors.brandGoldSoft,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 19, color: color),
      );
}

String _money(double value) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: value == value.roundToDouble() ? 0 : 2)
    .format(value);

String _stockHint(bool available, double grams, {required bool verified}) {
  if (!available) return 'Needs review';
  if (!verified) return 'Calculated net · unverified';
  return grams.abs() < 0.001 ? 'No available stock' : 'Available stock · net';
}

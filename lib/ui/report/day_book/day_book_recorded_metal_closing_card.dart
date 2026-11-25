import 'package:flutter/material.dart';

import '../../../models/reports/day_book/day_book_owned_stock_position.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_eod_sections.dart';
import 'day_book_metal_visual.dart';
import 'day_book_metal_weight.dart';

class DayBookRecordedMetalClosingCard extends StatelessWidget {
  const DayBookRecordedMetalClosingCard({
    super.key,
    required this.position,
  });

  final DayBookOwnedStockPosition? position;

  @override
  Widget build(BuildContext context) => EodPanel(
        title: 'Recorded Metal Closing',
        icon: Icons.inventory_2_outlined,
        child: position == null
            ? Text('Stock closing balances are unavailable.',
                style: DayBookStyles.labelStrong.copyWith(fontSize: 13))
            : LayoutBuilder(builder: (context, constraints) {
                final cards = [
                  _MetalBalance(
                    label: 'Closing Gold',
                    position: position!.gold,
                    metal: DayBookMetalVisualType.gold,
                  ),
                  _MetalBalance(
                    label: 'Closing Silver',
                    position: position!.silver,
                    metal: DayBookMetalVisualType.silver,
                  ),
                ];
                if (constraints.maxWidth < 440) {
                  return Column(children: [
                    cards.first,
                    const SizedBox(height: 8),
                    cards.last,
                  ]);
                }
                return Row(children: [
                  Expanded(child: cards.first),
                  const SizedBox(width: 8),
                  Expanded(child: cards.last),
                ]);
              }),
      );
}

class _MetalBalance extends StatelessWidget {
  const _MetalBalance({
    required this.label,
    required this.position,
    required this.metal,
  });

  final String label;
  final DayBookOwnedMetalPosition position;
  final DayBookMetalVisualType metal;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: DayBookStyles.softPanel(
          color: DayBookColors.bodySubtle,
          borderColor: DayBookColors.bodyBorder,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            DayBookMetalVisual(metal: metal, size: 30),
            const SizedBox(width: 7),
            Expanded(
              child: Text(label,
                  style: DayBookStyles.labelStrong.copyWith(fontSize: 13)),
            ),
          ]),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 26,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                position.isConsistent
                    ? dayBookMetalWeight(position.closingGrams)
                    : 'Review stock records',
                style: DayBookStyles.valueLarge.copyWith(
                  fontSize: 20,
                  color: position.isConsistent
                      ? DayBookColors.textPrimary
                      : DayBookColors.negative,
                ),
              ),
            ),
          ),
          Text(
            position.isConsistent ? 'Recorded net weight' : 'Needs review',
            style: DayBookStyles.label.copyWith(fontSize: 13),
          ),
        ]),
      );
}

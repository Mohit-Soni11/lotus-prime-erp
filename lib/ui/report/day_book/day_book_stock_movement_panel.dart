import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/reports/day_book/day_book_stock_movement.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookStockMovementPanel extends StatelessWidget {
  const DayBookStockMovementPanel({super.key, required this.movements});

  final List<DayBookStockMovement> movements;

  @override
  Widget build(BuildContext context) {
    final inward = movements
        .where((movement) => movement.isInward)
        .fold<double>(
            0, (total, movement) => total + movement.netWeightDelta.abs());
    final outward = movements
        .where((movement) => movement.isOutward)
        .fold<double>(
            0, (total, movement) => total + movement.netWeightDelta.abs());
    return Container(
      decoration: DayBookStyles.panel(),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text('Owned Stock Movement', style: DayBookStyles.sectionTitle),
        subtitle: Text(
          'Posted inward ${_grams(inward)} · outward ${_grams(outward)} · ${movements.length} records',
          style: DayBookStyles.sectionSubtitle,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Historical purity and opening stock require verification. These movements are not a certified closing balance.',
              style: DayBookStyles.labelStrong.copyWith(
                color: DayBookColors.warning,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (movements.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('No posted stock movement for this day.',
                  style: DayBookStyles.label),
            )
          else
            SizedBox(
              height: 360,
              child: ListView.separated(
                itemCount: movements.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final movement = movements[index];
                  final direction = movement.isInward
                      ? 'IN'
                      : movement.isOutward
                          ? 'OUT'
                          : 'ADJUST';
                  final details = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '$direction · ${movement.metal} ${movement.puritySnapshot ?? '(purity unverified)'} · ${movement.itemName}',
                          style: DayBookStyles.labelStrong),
                      Text(
                        '${movement.movementType} · ${movement.sourceType} ${movement.sourceNumber ?? movement.sourceId}${movement.sourceLineNo == null ? '' : ' line ${movement.sourceLineNo}'} · ${DateFormat('HH:mm').format(movement.occurredAt)}',
                        style: DayBookStyles.label,
                      ),
                    ],
                  );
                  final weights = Text(
                    '${movement.quantityDelta} pcs · ${_grams(movement.grossWeightDelta)} gross · ${_grams(movement.netWeightDelta)} net · ${_grams(movement.fineWeightDelta)} fine',
                    style: DayBookStyles.labelStrong,
                    textAlign: TextAlign.right,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: LayoutBuilder(builder: (context, constraints) {
                      if (constraints.maxWidth < 760) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            details,
                            const SizedBox(height: 4),
                            weights,
                          ],
                        );
                      }
                      return Row(children: [
                        Expanded(child: details),
                        const SizedBox(width: 16),
                        Flexible(child: weights),
                      ]);
                    }),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

String _grams(double value) => '${value.toStringAsFixed(3)} g';

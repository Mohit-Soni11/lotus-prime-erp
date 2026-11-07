import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/reports/day_book/day_book_owned_stock_position.dart';
import '../../../models/reports/day_book/day_book_customer_metal_sales.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_metal_visual.dart';

class DayBookMetalSalesPanel extends StatelessWidget {
  const DayBookMetalSalesPanel({
    super.key,
    required this.gold,
    required this.silver,
    this.customerSales,
  });

  final DayBookOwnedMetalPosition? gold;
  final DayBookOwnedMetalPosition? silver;
  final DayBookCustomerMetalSales? customerSales;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: DayBookStyles.softPanel(
          color: DayBookColors.brandGoldSoft,
          borderColor: DayBookColors.brandGoldBorder,
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.receipt_long_rounded,
                size: 19, color: DayBookColors.goldMetal),
            const SizedBox(width: 7),
            Expanded(
              child: Text('Metal Sold Today',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DayBookStyles.sectionTitle),
            ),
          ]),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            final inline = constraints.maxWidth >= 440;
            final cards = [
              _SoldMetalCard(
                title: 'Gold Sold',
                metal: DayBookMetalVisualType.gold,
                position: gold,
                soldGrams: customerSales?.goldGrams,
                invoiceCount: customerSales?.goldInvoices,
              ),
              _SoldMetalCard(
                title: 'Silver Sold',
                metal: DayBookMetalVisualType.silver,
                position: silver,
                soldGrams: customerSales?.silverGrams,
                invoiceCount: customerSales?.silverInvoices,
              ),
            ];
            if (!inline) {
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
        ]),
      );
}

class _SoldMetalCard extends StatelessWidget {
  const _SoldMetalCard({
    required this.title,
    required this.metal,
    required this.position,
    required this.soldGrams,
    required this.invoiceCount,
  });

  final String title;
  final DayBookMetalVisualType metal;
  final DayBookOwnedMetalPosition? position;
  final double? soldGrams;
  final int? invoiceCount;

  @override
  Widget build(BuildContext context) {
    final available = soldGrams != null;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: DayBookStyles.softPanel(
          color: DayBookColors.bodyPanel,
          borderColor: DayBookColors.bodyBorder),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          DayBookMetalVisual(metal: metal, size: 32),
          const SizedBox(width: 8),
          Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DayBookStyles.labelStrong)),
        ]),
        const SizedBox(height: 6),
        Text(available ? dayBookMetalWeight(soldGrams!) : '—',
            style: DayBookStyles.valueLarge.copyWith(
              fontSize: 18,
              color: DayBookColors.negative,
            )),
        Text(
            available
                ? '${invoiceCount ?? 0} invoices · Owned stock out ${position?.isConsistent == true ? dayBookMetalWeight(position!.soldGrams) : 'unverified'}'
                : 'Invoice weight unavailable',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DayBookStyles.label.copyWith(fontSize: 13)),
      ]),
    );
  }
}

String dayBookMetalWeight(double grams) {
  final amount = grams.abs() >= 1000 ? grams / 1000 : grams;
  final unit = grams.abs() >= 1000 ? 'kg' : 'g';
  return '${NumberFormat.decimalPatternDigits(locale: 'en_IN', decimalDigits: 3).format(amount)} $unit';
}

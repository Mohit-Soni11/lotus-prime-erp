import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_routes.dart';
import '../../../models/reports/day_book/day_book_stock_added_batch.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_metal_visual.dart';
import 'day_book_smart_format.dart';

class DayBookStockAddedRow extends StatelessWidget {
  const DayBookStockAddedRow({
    super.key,
    required this.batch,
    required this.isDemo,
  });

  final DayBookStockAddedBatch batch;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final canOpen = !isDemo && batch.canOpenInventory;
    return Material(
      color: DayBookColors.bodyPanel,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: canOpen
            ? () => context.push(Uri(
                  path: RoutePaths.stockInventory,
                  queryParameters: {
                    'metal': batch.metal,
                    'batch': batch.batchCode,
                  },
                ).toString())
            : null,
        borderRadius: BorderRadius.circular(11),
        hoverColor: DayBookColors.cardHover,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: DayBookColors.bodyBorder),
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < 1010) return _compact();
            return _wide();
          }),
        ),
      ),
    );
  }

  Widget _wide() => Row(children: [
        SizedBox(width: 140, child: _metal()),
        Expanded(flex: 23, child: _identity()),
        _divider(),
        Expanded(flex: 17, child: _metric('Net Weight', _weight)),
        _divider(),
        Expanded(flex: 16, child: _metric('Rate', _rate)),
        _divider(),
        Expanded(flex: 17, child: _metric('Making', _making)),
        _divider(),
        Expanded(flex: 19, child: _purchaseValue()),
        const Icon(Icons.chevron_right_rounded,
            size: 20, color: DayBookColors.goldMetal),
      ]);

  Widget _compact() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _metal(),
            const SizedBox(width: 12),
            Expanded(child: _identity()),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: DayBookColors.goldMetal),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 18, runSpacing: 9, children: [
            _metric('Net Weight', _weight),
            _metric('Rate', _rate),
            _metric('Making', _making),
            _purchaseValue(),
          ]),
        ],
      );

  Widget _metal() {
    final isGold = batch.metal.toLowerCase() == 'gold';
    final isSilver = batch.metal.toLowerCase() == 'silver';
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (isGold || isSilver)
        DayBookMetalVisual(
          metal: isGold
              ? DayBookMetalVisualType.gold
              : DayBookMetalVisualType.silver,
          size: 34,
        )
      else
        const Icon(Icons.inventory_2_outlined, size: 31),
      const SizedBox(width: 7),
      Text(batch.metal.toUpperCase(),
          style: DayBookStyles.labelStrong.copyWith(
            fontSize: 13,
            color: isGold
                ? DayBookColors.goldMetal
                : isSilver
                    ? DayBookColors.silverMetal
                    : DayBookColors.textPrimary,
          )),
    ]);
  }

  Widget _identity() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(batch.batchCode,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DayBookStyles.labelStrong
                  .copyWith(fontSize: 13, fontWeight: FontWeight.w800)),
          Text(
            '${DateFormat('d MMM y, h:mm a').format(batch.postedAt)}  ·  ${batch.pieces} ${batch.pieces == 1 ? 'pc' : 'pcs'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DayBookStyles.label.copyWith(fontSize: 13),
          ),
        ],
      );

  Widget _metric(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: DayBookStyles.label.copyWith(fontSize: 13)),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DayBookStyles.labelStrong.copyWith(fontSize: 13)),
        ],
      );

  Widget _purchaseValue() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: DayBookColors.brandGoldSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            _metric('Purchase Value', dayBookSmartMoney(batch.purchaseValue)),
      );

  Widget _divider() => Container(
        height: 30,
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: DayBookColors.bodyBorder,
      );

  String get _weight => '${batch.netWeightGrams.toStringAsFixed(3)} g';
  String get _rate => batch.hasMixedRates
      ? 'Multiple rates'
      : batch.ratePerGram == null
          ? '—'
          : '${dayBookSmartMoney(batch.ratePerGram!)}/g';
  String get _making =>
      batch.makingTotal == null ? '—' : dayBookSmartMoney(batch.makingTotal!);
}

// =============================================================================
// FILE        : booking_scrap_table.dart
// MODULE      : Sales / Booking & Advance
// DESCRIPTION : Metal trade-in table for advance settlements.
//               Customer gives old/scrap metal as part of advance.
//               Columns: S.NO | METAL | DESCRIPTION | GR.WT | LESS |
//                        NET WT | PURITY | FINE WT | RATE | VALUE | ACT
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import '../../../logic/booking_advance/booking_advance_controller.dart';
import '../../models/booking_advance/booking_advance/booking_advance_model.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'widgets/booking_money_text.dart';

part 'widgets/booking_scrap_row.dart';

class BookingScrapTable extends StatelessWidget {
  final BookingAdvanceController ctrl;
  const BookingScrapTable({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: BookingAdvanceColors.bodyPanelBg,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: BookingAdvanceColors.bodyBorder, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: BookingAdvanceColors.shadowLight,
                blurRadius: 10,
                offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildColumnRow(),
            ctrl.scrapItems.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ctrl.scrapItems.length,
                    itemBuilder: (_, i) => BookingScrapRow(
                        index: i, item: ctrl.scrapItems[i], ctrl: ctrl),
                  ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: BookingAdvanceColors.danger.withValues(alpha: 0.04),
        border: const Border(
            bottom:
                BorderSide(color: BookingAdvanceColors.bodyBorder, width: 1.5)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: BookingAdvanceColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color:
                        BookingAdvanceColors.danger.withValues(alpha: 0.40))),
            child: const Icon(Icons.recycling_rounded,
                color: BookingAdvanceColors.danger, size: 22)),
        const SizedBox(width: 14),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('EXCHANGE & SCRAP METAL',
                  style: BookingAdvanceStyles.highVisHeader
                      .copyWith(color: BookingAdvanceColors.danger, height: 1)),
              const SizedBox(height: 4),
              Text('Customer giving old/scrap metal as advance',
                  style: BookingAdvanceStyles.subTitleMuted),
            ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: BookingAdvanceColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: BookingAdvanceColors.danger.withValues(alpha: 0.3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: BookingAdvanceColors.danger,
                    shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('SCRAP : ${ctrl.scrapItems.length}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: BookingAdvanceColors.danger,
                    letterSpacing: 0.8)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildColumnRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
          color: BookingAdvanceColors.bodyBg,
          border: Border(
              bottom: BorderSide(
                  color: BookingAdvanceColors.bodyBorder, width: 1.5))),
      child: Row(children: [
        _h('S.NO', 1, center: true),
        const SizedBox(width: 6),
        _h('METAL', 3),
        const SizedBox(width: 6),
        _h('DESCRIPTION', 4),
        const SizedBox(width: 6),
        _h('GR. WT', 2),
        const SizedBox(width: 6),
        _h('LESS', 2),
        const SizedBox(width: 6),
        _h('NET WT', 2, center: true),
        const SizedBox(width: 6),
        _h('PURITY %', 2, center: true),
        const SizedBox(width: 6),
        _h('FINE WT', 2, center: true),
        const SizedBox(width: 6),
        _h('RATE', 3),
        const SizedBox(width: 6),
        _h('VALUE', 3, right: true),
        const SizedBox(width: 6),
        _h('ACT', 1, center: true),
      ]),
    );
  }

  Widget _h(String t, int flex, {bool right = false, bool center = false}) =>
      Expanded(
          flex: flex,
          child: Text(t,
              textAlign: right
                  ? TextAlign.right
                  : (center ? TextAlign.center : TextAlign.left),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: BookingAdvanceColors.textDark,
                  letterSpacing: 0.8)));

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: BookingAdvanceColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        BookingAdvanceColors.danger.withValues(alpha: 0.25))),
            child: const Icon(Icons.recycling_rounded,
                color: BookingAdvanceColors.danger, size: 30)),
        const SizedBox(height: 12),
        const Text('NO SCRAP/EXCHANGE METAL',
            style: TextStyle(
                color: BookingAdvanceColors.bodyTextMain,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text('Add old gold / scrap metal given by customer',
            style: BookingAdvanceStyles.subTitleMuted),
      ])),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: BookingAdvanceColors.bodyPanelBg,
        border: Border(
            top:
                BorderSide(color: BookingAdvanceColors.bodyBorder, width: 1.5)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        InkWell(
          onTap: ctrl.addScrapItem,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: BookingAdvanceColors.danger.withValues(alpha: 0.08),
              border: Border.all(
                  color: BookingAdvanceColors.danger.withValues(alpha: 0.35),
                  width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_circle_outline_rounded,
                  color: BookingAdvanceColors.danger, size: 20),
              SizedBox(width: 8),
              Text('ADD SCRAP / OLD METAL',
                  style: TextStyle(
                      color: BookingAdvanceColors.danger,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8)),
            ]),
          ),
        ),
        if (ctrl.scrapItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                color: BookingAdvanceColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: BookingAdvanceColors.danger.withValues(alpha: 0.3),
                    width: 1.5)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('SCRAP METAL VALUE',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color: BookingAdvanceColors.danger,
                      letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text(BookingMoneyText.decimal(ctrl.totalScrapVal),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: BookingAdvanceColors.danger)),
            ]),
          ),
      ]),
    );
  }
}

// =============================================================================
// SCRAP ROW
// =============================================================================

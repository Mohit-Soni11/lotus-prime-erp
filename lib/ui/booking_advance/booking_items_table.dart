// =============================================================================
// FILE        : booking_items_table.dart
// MODULE      : Sales / Booking & Advance
// DESCRIPTION : Responsive booking item grid shell.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../logic/booking_advance/booking_advance_controller.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import 'widgets/booking_item_row.dart';
import 'widgets/booking_money_text.dart';

class BookingItemsTable extends StatelessWidget {
  const BookingItemsTable({super.key, required this.ctrl});

  static const double _minimumGridWidth = 1180;

  final BookingAdvanceController ctrl;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f2): ctrl.addBookingItem,
        const SingleActivator(LogicalKeyboardKey.delete): ctrl.removeActiveItem,
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: ctrl,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              color: BookingAdvanceColors.bodyPanelBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BookingAdvanceColors.bodyBorder,
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: BookingAdvanceColors.shadowLight,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BookingItemsHeader(controller: ctrl),
                LayoutBuilder(
                  builder: (_, constraints) {
                    final gridWidth = constraints.maxWidth < _minimumGridWidth
                        ? _minimumGridWidth
                        : constraints.maxWidth;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: gridWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _BookingItemsColumnRow(),
                            ctrl.bookingItems.isEmpty
                                ? const _BookingItemsEmptyState()
                                : Column(
                                    children: List.generate(
                                      ctrl.bookingItems.length,
                                      (index) => BookingItemRow(
                                        index: index,
                                        item: ctrl.bookingItems[index],
                                        controller: ctrl,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                _BookingItemsBottomBar(controller: ctrl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingItemsHeader extends StatelessWidget {
  const _BookingItemsHeader({required this.controller});

  final BookingAdvanceController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BookingAdvanceColors.brandGold.withValues(alpha: 0.06),
        border: const Border(
          bottom: BorderSide(
            color: BookingAdvanceColors.bodyBorder,
            width: 1.5,
          ),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BookingAdvanceColors.brandGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: BookingAdvanceColors.brandGold.withValues(alpha: 0.40),
                ),
              ),
              child: const Center(
                child: Icon(
                  BookingAdvanceIcons.itemIcon,
                  color: BookingAdvanceColors.brandGold,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'BOOKING ITEMS',
                  style: BookingAdvanceStyles.highVisHeader,
                ),
                const SizedBox(height: 4),
                Text(
                  'Press F2 to add item',
                  style: BookingAdvanceStyles.subTitleMuted,
                ),
              ],
            ),
            const Spacer(),
            _ItemCountBadge(count: controller.bookingItems.length),
          ],
        ),
      ),
    );
  }
}

class _ItemCountBadge extends StatelessWidget {
  const _ItemCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: BookingAdvanceColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: BookingAdvanceColors.bodyBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: BookingAdvanceColors.brandGold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ITEMS : $count',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: BookingAdvanceColors.bodyTextMain,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingItemsColumnRow extends StatelessWidget {
  const _BookingItemsColumnRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: BookingAdvanceColors.bodyBg,
        border: Border(
          bottom: BorderSide(
            color: BookingAdvanceColors.bodyBorder,
            width: 1.5,
          ),
        ),
      ),
      child: const Row(
        children: [
          _HeaderCell('S.NO', 1, center: true),
          SizedBox(width: 6),
          _HeaderCell('METAL', 3),
          SizedBox(width: 6),
          _HeaderCell('DESCRIPTION', 4),
          SizedBox(width: 6),
          _HeaderCell('PCS', 1, center: true),
          SizedBox(width: 6),
          _HeaderCell('PURITY', 2, center: true),
          SizedBox(width: 6),
          _HeaderCell('GR. WT', 2),
          SizedBox(width: 6),
          _HeaderCell('LESS', 2),
          SizedBox(width: 6),
          _HeaderCell('NET WT', 2, center: true),
          SizedBox(width: 6),
          _HeaderCell('RATE', 3),
          SizedBox(width: 6),
          _HeaderCell('MAKING', 3),
          SizedBox(width: 6),
          _HeaderCell('TOTAL', 3, right: true),
          SizedBox(width: 6),
          _HeaderCell('DEL. DATE', 3),
          SizedBox(width: 6),
          _HeaderCell('ACT', 1, center: true),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
    this.text,
    this.flex, {
    this.right = false,
    this.center = false,
  });

  final String text;
  final int flex;
  final bool right;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: right
            ? TextAlign.right
            : center
                ? TextAlign.center
                : TextAlign.left,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: BookingAdvanceColors.textDark,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _BookingItemsEmptyState extends StatelessWidget {
  const _BookingItemsEmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: BookingItemsTable._minimumGridWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _EmptyStateIcon(),
              const SizedBox(height: 18),
              const Text(
                'BOOKING LIST IS EMPTY',
                style: TextStyle(
                  color: BookingAdvanceColors.bodyTextMain,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Press F2 or click ADD ITEM to add booking items',
                style: BookingAdvanceStyles.subTitleMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateIcon extends StatelessWidget {
  const _EmptyStateIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: BookingAdvanceColors.bodyBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: BookingAdvanceColors.bodyBorder,
          width: 2,
        ),
      ),
      child: const Icon(
        BookingAdvanceIcons.itemIcon,
        color: BookingAdvanceColors.brandGold,
        size: 36,
      ),
    );
  }
}

class _BookingItemsBottomBar extends StatelessWidget {
  const _BookingItemsBottomBar({required this.controller});

  final BookingAdvanceController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: BookingAdvanceColors.bodyPanelBg,
        border: Border(
          top: BorderSide(
            color: BookingAdvanceColors.bodyBorder,
            width: 1.5,
          ),
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _AddItemButton(onTap: controller.addBookingItem),
          if (controller.bookingItems.isNotEmpty)
            Flexible(child: _BookingItemTotals(controller: controller)),
        ],
      ),
    );
  }
}

class _AddItemButton extends StatelessWidget {
  const _AddItemButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: BookingAdvanceColors.success.withValues(alpha: 0.08),
          border: Border.all(
            color: BookingAdvanceColors.success.withValues(alpha: 0.35),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              color: BookingAdvanceColors.success,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'ADD ITEM',
              style: TextStyle(
                color: BookingAdvanceColors.success,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: BookingAdvanceColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '[F2]',
                style: TextStyle(
                  color: BookingAdvanceColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingItemTotals extends StatelessWidget {
  const _BookingItemTotals({required this.controller});

  final BookingAdvanceController controller;

  @override
  Widget build(BuildContext context) {
    final goldWeight = controller.totalBookingGoldWt;
    final silverWeight = controller.totalBookingSilverWt;
    final total = controller.totalBookingVal;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (goldWeight > 0)
            _TotalChip(
              label: 'GOLD',
              value: '${goldWeight.toStringAsFixed(3)} g',
              color: BookingAdvanceColors.metalGold,
            ),
          if (goldWeight > 0 && silverWeight > 0) const SizedBox(width: 10),
          if (silverWeight > 0)
            _TotalChip(
              label: 'SILVER',
              value: '${silverWeight.toStringAsFixed(3)} g',
              color: BookingAdvanceColors.metalSilver,
            ),
          if (total > 0) ...[
            const SizedBox(width: 10),
            _TotalChip(
              label: 'TOTAL VALUE',
              value: BookingMoneyText.whole(total),
              color: BookingAdvanceColors.brandGold,
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 10,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

part of '../booking_items_table.dart';

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

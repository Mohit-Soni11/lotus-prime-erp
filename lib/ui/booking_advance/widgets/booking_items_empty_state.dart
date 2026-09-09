part of '../booking_items_table.dart';

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

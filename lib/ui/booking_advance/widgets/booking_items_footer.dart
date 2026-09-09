part of '../booking_items_table.dart';

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

part of 'booking_invoice_command_panel.dart';

class _CommandHeader extends StatelessWidget {
  const _CommandHeader({
    required this.controller,
    required this.onBack,
  });

  final BookingInvoicePreviewController controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: BookingAdvanceColors.shellBorder),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              BookingAdvanceIcons.backArrow,
              color: BookingAdvanceColors.shellTextTitle,
              size: 20,
            ),
            tooltip: 'Back',
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BOOKING INVOICE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: BookingAdvanceColors.shellTextTitle,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  '${controller.bookingNumber} | ${controller.customerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BookingAdvanceColors.shellTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingContextSection extends StatelessWidget {
  const _BookingContextSection({required this.controller});

  final BookingInvoicePreviewController controller;

  @override
  Widget build(BuildContext context) {
    final firstOrder = controller.bookings.firstOrNull?.order;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShellSectionLabel('BOOKING CONTEXT'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BookingAdvanceColors.shellPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BookingAdvanceColors.shellBorder),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ContextChip(
                icon: Icons.bookmark_added_rounded,
                label: controller.bookingNumber,
              ),
              _ContextChip(
                icon: Icons.inventory_2_rounded,
                label: '${controller.lineCount} line(s)',
              ),
              _ContextChip(
                icon: Icons.price_change_rounded,
                label: firstOrder?.bookingType ?? 'OPEN',
              ),
              _ContextChip(
                icon: Icons.payments_rounded,
                label: BookingMoneyText.whole(controller.totalAdvance),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: BookingAdvanceColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BookingAdvanceColors.shellBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: BookingAdvanceColors.brandGold),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: BookingAdvanceColors.shellTextTitle,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

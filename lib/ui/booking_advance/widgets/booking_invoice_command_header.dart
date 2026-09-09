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

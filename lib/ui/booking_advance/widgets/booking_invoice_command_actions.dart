part of 'booking_invoice_command_panel.dart';

class _ActionFooter extends StatelessWidget {
  const _ActionFooter({
    required this.controller,
    required this.isSharing,
    required this.isExporting,
    required this.isPrinting,
    required this.isExported,
    required this.isPrinted,
    required this.onShare,
    required this.onExport,
    required this.onPrint,
  });

  final BookingInvoicePreviewController controller;
  final bool isSharing;
  final bool isExporting;
  final bool isPrinting;
  final bool isExported;
  final bool isPrinted;
  final Future<void> Function() onShare;
  final Future<void> Function() onExport;
  final Future<void> Function() onPrint;

  @override
  Widget build(BuildContext context) {
    final ready = controller.isReady;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: BookingAdvanceColors.shellPanelBg,
        border: Border(
          top: BorderSide(color: BookingAdvanceColors.shellBorder),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BookingAdvanceColors.shellBg.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrinted
                ? BookingAdvanceColors.success.withValues(alpha: 0.34)
                : BookingAdvanceColors.brandGold.withValues(alpha: 0.34),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OutputStatus(
              ready: ready,
              printed: isPrinted,
              exported: isExported,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: isSharing ? 'Sharing' : 'Share PDF',
                    icon: Icons.chat_bubble_rounded,
                    onPressed: ready && !isSharing ? onShare : null,
                    isBusy: isSharing,
                    accentColor: const Color(0xFF25D366),
                    filled: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: isExported
                        ? 'Exported'
                        : isExporting
                            ? 'Exporting'
                            : 'Export PDF',
                    icon: isExported
                        ? Icons.check_circle_rounded
                        : Icons.download_rounded,
                    onPressed: ready && !isExporting ? onExport : null,
                    isBusy: isExporting,
                    accentColor: isExported
                        ? BookingAdvanceColors.success
                        : BookingAdvanceColors.shellTextTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: isPrinting ? 'Printing' : 'Print Booking Invoice',
              icon: Icons.print_rounded,
              onPressed: ready && !isPrinting ? onPrint : null,
              isBusy: isPrinting,
              isPrimary: true,
              filled: true,
              accentColor: BookingAdvanceColors.brandGold,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.accentColor,
    this.filled = false,
    this.isPrimary = false,
    this.isBusy = false,
  });

  final String label;
  final IconData icon;
  final Future<void> Function()? onPressed;
  final Color accentColor;
  final bool filled;
  final bool isPrimary;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final height = isPrimary ? 48.0 : 42.0;
    final foreground = filled ? Colors.black : accentColor;
    final borderColor = onPressed == null
        ? BookingAdvanceColors.shellBorder
        : filled
            ? accentColor
            : accentColor.withValues(alpha: 0.45);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: _buttonIcon(foreground),
              label: _buttonLabel(foreground),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: foreground,
                disabledBackgroundColor:
                    BookingAdvanceColors.shellBorder.withValues(alpha: 0.40),
                disabledForegroundColor: BookingAdvanceColors.shellTextMuted,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: _buttonIcon(foreground),
              label: _buttonLabel(foreground),
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                disabledForegroundColor: BookingAdvanceColors.shellTextMuted,
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
    );
  }

  Widget _buttonIcon(Color color) {
    if (isBusy) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    return Icon(icon, size: isPrimary ? 19 : 16);
  }

  Widget _buttonLabel(Color color) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize: isPrimary ? 14 : 13,
        letterSpacing: 0,
      ),
    );
  }
}

class _OutputStatus extends StatelessWidget {
  const _OutputStatus({
    required this.ready,
    required this.printed,
    required this.exported,
  });

  final bool ready;
  final bool printed;
  final bool exported;

  @override
  Widget build(BuildContext context) {
    final accent = printed
        ? BookingAdvanceColors.brandGold
        : exported
            ? BookingAdvanceColors.success
            : ready
                ? BookingAdvanceColors.brandGold
                : BookingAdvanceColors.warning;
    final title = printed
        ? 'Document Printed'
        : exported
            ? 'Document Exported'
            : ready
                ? 'Ready to Print'
                : 'Preparing Document';
    final badge = printed
        ? 'Printed'
        : exported
            ? 'Exported'
            : ready
                ? 'Ready'
                : 'Preparing';

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          child: Icon(
            printed
                ? Icons.local_printshop_rounded
                : exported
                    ? Icons.download_done_rounded
                    : ready
                        ? Icons.receipt_long_rounded
                        : Icons.hourglass_top_rounded,
            color: accent,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DOCUMENT OUTPUT',
                style: TextStyle(
                  color: BookingAdvanceColors.shellTextMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: BookingAdvanceColors.shellTextTitle,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        _StatusBadge(label: badge, active: ready || printed || exported),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? BookingAdvanceColors.brandGold.withValues(alpha: 0.14)
            : BookingAdvanceColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? BookingAdvanceColors.brandGold.withValues(alpha: 0.34)
              : BookingAdvanceColors.shellBorder,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: active
              ? BookingAdvanceColors.brandGold
              : BookingAdvanceColors.shellTextMuted,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

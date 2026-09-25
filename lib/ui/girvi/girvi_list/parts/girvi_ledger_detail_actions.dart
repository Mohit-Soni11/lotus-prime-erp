part of '../girvi_list_screen.dart';

class _LedgerDetailActions extends StatelessWidget {
  final bool canCollect;
  final bool openingPdf;
  final String statusLabel;
  final VoidCallback onPreviewPdf;
  final VoidCallback onCollect;

  const _LedgerDetailActions({
    required this.canCollect,
    required this.openingPdf,
    required this.statusLabel,
    required this.onPreviewPdf,
    required this.onCollect,
  });

  @override
  Widget build(BuildContext context) {
    final pdfButton = _LedgerCommandButton(
      icon: GirviIcons.print,
      label: openingPdf ? 'Opening Preview...' : 'Preview Invoice PDF',
      color: GirviColors.info,
      onTap: openingPdf ? null : onPreviewPdf,
    );

    if (!canCollect) {
      return Column(
        children: [
          pdfButton,
          const SizedBox(height: 10),
          _ClosedTicketNotice(statusLabel: statusLabel),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 520;
        if (stacked) {
          return Column(
            children: [
              pdfButton,
              const SizedBox(height: 10),
              _LedgerCommandButton(
                icon: GirviIcons.cash,
                label: 'Collect / Settle',
                color: GirviColors.success,
                onTap: onCollect,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: pdfButton),
            const SizedBox(width: 10),
            Expanded(
              child: _LedgerCommandButton(
                icon: GirviIcons.cash,
                label: 'Collect / Settle',
                color: GirviColors.success,
                onTap: onCollect,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LedgerCommandButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _LedgerCommandButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ClosedTicketNotice extends StatelessWidget {
  final String statusLabel;

  const _ClosedTicketNotice({required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GirviColors.statusAucBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(
            GirviIcons.info,
            color: GirviColors.textMuted,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Collection is closed for $statusLabel tickets.',
              style: GoogleFonts.inter(
                color: GirviColors.textBody,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

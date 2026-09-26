part of '../girvi_list_screen.dart';

class _LedgerDetailActions extends StatelessWidget {
  final bool canCollect;
  final bool openingPdf;
  final GirviStatus status;
  final String statusLabel;
  final bool hasDueAmount;
  final VoidCallback onPreviewPdf;
  final VoidCallback onCollect;

  const _LedgerDetailActions({
    required this.canCollect,
    required this.openingPdf,
    required this.status,
    required this.statusLabel,
    required this.hasDueAmount,
    required this.onPreviewPdf,
    required this.onCollect,
  });

  @override
  Widget build(BuildContext context) {
    final pdfButton = _LedgerCommandButton(
      icon: GirviIcons.print,
      label: openingPdf ? 'Opening Invoice...' : 'View Invoice PDF',
      color: GirviColors.info,
      onTap: openingPdf ? null : onPreviewPdf,
    );
    final action = _ledgerActionFor(status, hasDueAmount: hasDueAmount);

    if (!canCollect) {
      return Column(
        children: [
          pdfButton,
          const SizedBox(height: 10),
          _ClosedTicketNotice(
            statusLabel: statusLabel,
            message: _closedActionMessage(status),
          ),
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
                icon: action.icon,
                label: action.label,
                color: action.color,
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
                icon: action.icon,
                label: action.label,
                color: action.color,
                onTap: onCollect,
              ),
            ),
          ],
        );
      },
    );
  }

  static _LedgerActionConfig _ledgerActionFor(
    GirviStatus status, {
    required bool hasDueAmount,
  }) {
    if (status == GirviStatus.readyForDelivery) {
      return const _LedgerActionConfig(
        icon: GirviIcons.markDone,
        label: 'Complete Delivery',
        color: GirviColors.success,
      );
    }

    if (status == GirviStatus.partialRelease) {
      return const _LedgerActionConfig(
        icon: GirviIcons.release,
        label: 'Complete Settlement',
        color: GirviColors.success,
      );
    }

    if (status == GirviStatus.overdue || hasDueAmount) {
      return const _LedgerActionConfig(
        icon: GirviIcons.cash,
        label: 'Collect Interest',
        color: GirviColors.danger,
      );
    }

    return const _LedgerActionConfig(
      icon: GirviIcons.cash,
      label: 'Record Collection',
      color: GirviColors.success,
    );
  }

  static String _closedActionMessage(GirviStatus status) {
    if (status == GirviStatus.released) {
      return 'This pledge has been released. Collections are closed.';
    }
    return 'Collection is closed for this account.';
  }
}

class _LedgerActionConfig {
  final IconData icon;
  final String label;
  final Color color;

  const _LedgerActionConfig({
    required this.icon,
    required this.label,
    required this.color,
  });
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
  final String message;

  const _ClosedTicketNotice({
    required this.statusLabel,
    required this.message,
  });

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
              message,
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

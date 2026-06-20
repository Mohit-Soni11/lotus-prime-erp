part of '../girvi_list_screen.dart';

extension _GirviLedgerDetailPanel on _GirviListScreenState {
  Widget _buildLedgerDetailPanel({
    required GirviLoanWithCustomer? item,
    required bool compact,
  }) {
    if (item == null) {
      return _LedgerSurface(
        child: _LedgerEmptyState(
          icon: GirviIcons.ticket,
          title: 'No Ticket Selected',
          message: 'Select a ticket from the register to view details.',
          action: widget.onNewGirvi == null
              ? null
              : _LedgerPrimaryButton(
                  icon: Icons.add_rounded,
                  label: 'New Girvi',
                  onTap: _openNewGirvi,
                ),
        ),
      );
    }

    final loan = item.loan;
    final canOpenPayment = !loan.isClosed;
    final discountTotal =
        item.principalDiscountTotal + item.interestDiscountTotal;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LedgerSectionHeader(
          icon: _loanStatusIcon(loan),
          color: loan.statusColor,
          title: 'Ticket Details',
          subtitle: 'Selected Girvi record',
          trailing: _LedgerStatusBadge(
            icon: _loanStatusIcon(loan),
            label: loan.statusLabel,
            color: loan.statusColor,
          ),
        ),
        const SizedBox(height: 16),
        _DetailTicketHeader(
          ticketNo: loan.ticketNo,
          customerName: item.customerName,
          customerMeta: _compactCustomerLocation(item),
        ),
        const SizedBox(height: 14),
        _SettlementFocusBlock(
          totalPayable: _money(item.totalPayable),
          principalDue: _money(item.principalDue),
          interestDue: _money(item.netInterestDue),
        ),
        const SizedBox(height: 14),
        _DetailSection(
          title: 'Financial Position',
          children: [
            _DetailInfoRow(
              label: 'Original Principal',
              value: _money(item.originalPrincipal),
            ),
            _DetailInfoRow(
              label: 'Principal Repaid',
              value: _money(item.principalPaidTotal),
              valueColor: GirviColors.success,
            ),
            _DetailInfoRow(
              label: 'Interest Paid',
              value: _money(item.interestPaidTotal),
              valueColor: GirviColors.success,
            ),
            _DetailInfoRow(
              label: 'Approved Discount',
              value: _money(discountTotal),
              valueColor: GirviColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DetailSection(
          title: 'Collateral',
          children: [
            _DetailInfoRow(label: 'Item', value: loan.itemDescription),
            _DetailInfoRow(
              label: 'Metal',
              value: '${loan.metalTypeEnum.displayName} | ${loan.metalPurity}',
            ),
            _DetailInfoRow(
              label: 'Net Weight',
              value: '${loan.netWeight.toStringAsFixed(2)} g',
            ),
            _DetailInfoRow(
              label: 'Item Value',
              value: _money(loan.totalValue),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DetailSection(
          title: 'Timeline',
          children: [
            _DetailInfoRow(label: 'Start Date', value: _date(loan.startDate)),
            _DetailInfoRow(
              label: 'Maturity Date',
              value: _date(loan.maturityDate),
            ),
            _DetailInfoRow(
              label: 'Last Interest Paid',
              value: _date(loan.lastInterestPaidDate),
            ),
            _DetailInfoRow(label: 'Status', value: _maturityLabel(loan)),
          ],
        ),
        const SizedBox(height: 16),
        if (canOpenPayment)
          _LedgerCommandButton(
            icon: GirviIcons.cash,
            label: 'Collect / Settle',
            color: GirviColors.success,
            onTap: () => _openInterestEntry(item),
          )
        else
          _ClosedTicketNotice(statusLabel: loan.statusLabel),
      ],
    );

    return _LedgerSurface(
      child: compact ? content : SingleChildScrollView(child: content),
    );
  }
}

class _DetailTicketHeader extends StatelessWidget {
  final String ticketNo;
  final String customerName;
  final String customerMeta;

  const _DetailTicketHeader({
    required this.ticketNo,
    required this.customerName,
    required this.customerMeta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Row(
        children: [
          const _LedgerIconBox(
            icon: GirviIcons.customer,
            color: GirviColors.info,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticketNo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GirviStyles.ticketNumber,
                ),
                const SizedBox(height: 4),
                Text(
                  customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customerMeta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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

class _SettlementFocusBlock extends StatelessWidget {
  final String totalPayable;
  final String principalDue;
  final String interestDue;

  const _SettlementFocusBlock({
    required this.totalPayable,
    required this.principalDue,
    required this.interestDue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.success.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.successBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Payable',
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              totalPayable,
              style: GoogleFonts.manrope(
                color: GirviColors.success,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniSettlementValue(
                  label: 'Principal',
                  value: principalDue,
                  color: GirviColors.textDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniSettlementValue(
                  label: 'Interest',
                  value: interestDue,
                  color: GirviColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniSettlementValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniSettlementValue({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.manrope(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailInfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                color: valueColor ?? GirviColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerCommandButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

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

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
                  label: 'New Pledge',
                  onTap: _openNewGirvi,
                ),
        ),
      );
    }

    final loan = item.loan;
    final canOpenPayment = !loan.isClosed;
    final totalPayableColor = _dueAmountColor(item.totalPayable);
    final principalDueColor = _dueAmountColor(item.principalDue);
    final interestDueColor = _dueAmountColor(item.netInterestDue);
    final timelineColor = _ticketTimelineColor(
      loan,
      hasDueAmount: item.totalPayable > 0.005,
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LedgerSectionHeader(
          icon: _loanStatusIcon(loan),
          color: loan.statusColor,
          title: 'Account Profile',
          subtitle: 'Selected pledge account',
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
          totalPayableColor: totalPayableColor,
          principalDueColor: principalDueColor,
          interestDueColor: interestDueColor,
        ),
        const SizedBox(height: 14),
        _AccountTimelinePanel(
          startDate: _date(loan.startDate),
          maturityDate: _date(loan.maturityDate),
          lastInterestPaid: _date(loan.lastInterestPaidDate),
          statusTitle: _ticketTimelineTitle(loan),
          statusValue: _ticketTimelineValue(loan),
          statusColor: timelineColor,
        ),
        const SizedBox(height: 16),
        _LedgerDetailActions(
          canCollect: canOpenPayment,
          openingPdf: _openingInvoicePdf,
          status: loan.girviStatus,
          statusLabel: loan.statusLabel,
          hasDueAmount: item.totalPayable > 0.005,
          onPreviewPdf: () => _previewGirviInvoicePdf(item),
          onCollect: () => _openInterestEntry(item),
        ),
      ],
    );

    return _LedgerSurface(
      child: compact ? content : SingleChildScrollView(child: content),
    );
  }
}

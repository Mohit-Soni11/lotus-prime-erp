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
          title: 'No Account Selected',
          message: 'Select a pledge account from the register to view details.',
          action: widget.onNewGirvi == null
              ? null
              : _LedgerPrimaryButton(
                  icon: Icons.add_rounded,
                  label: 'New Pledge Ticket',
                  onTap: _openNewGirvi,
                ),
        ),
      );
    }

    final loan = item.loan;
    final interestQuote = item.interestQuoteAt();
    final canOpenPayment = !loan.isClosed;
    final totalPayableColor = _dueAmountColor(interestQuote.totalPayable);
    final principalDueColor = _dueAmountColor(interestQuote.principalDue);
    final interestDueColor = _dueAmountColor(interestQuote.interestOutstanding);
    final timelineColor = _ticketTimelineColor(loan);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LedgerSectionHeader(
          icon: _loanStatusIcon(loan),
          color: loan.statusColor,
          title: 'Pledge Account',
          subtitle: 'Selected account summary and actions',
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
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: _LedgerStatusBadge(
            icon: GirviIcons.interestRate,
            label: '${interestQuote.interestType} Interest',
            color: interestQuote.interestType ==
                    GirviInterestCalculationType.compound
                ? GirviColors.brandGold
                : GirviColors.info,
          ),
        ),
        const SizedBox(height: 14),
        if (loan.isClosed)
          const _LedgerSurface(
            child: Text(
                'Account Closed · Open Girvi Account for the recovery record.'),
          )
        else
          _SettlementFocusBlock(
            totalPayable: _money(interestQuote.totalPayable),
            principalDue: _money(interestQuote.principalDue),
            interestDue: _money(interestQuote.interestOutstanding),
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
          hasDueAmount: canOpenPayment && interestQuote.totalPayable > 0.005,
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

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
          title: 'Pledged Item Details',
          children: [
            _DetailInfoRow(label: 'Item Name', value: loan.itemDescription),
            _DetailInfoRow(label: 'Item Count', value: '${loan.itemCount}'),
            _DetailInfoRow(
              label: 'Metal / Purity',
              value: '${loan.metalTypeEnum.displayName} | ${loan.metalPurity}',
            ),
            _DetailInfoRow(
              label: 'Gross Weight',
              value: _weight(loan.grossWeight),
            ),
            _DetailInfoRow(
              label: 'Less Weight',
              value: _weight(loan.stoneWeight),
            ),
            _DetailInfoRow(
              label: 'Net Weight',
              value: _weight(loan.netWeight),
            ),
            _DetailInfoRow(
              label: 'Rate Per Gram',
              value: _money(loan.ratePerGram, precise: true),
            ),
            _DetailInfoRow(
                label: 'Pledged Value', value: _money(loan.totalValue)),
            if ((loan.huidNumber ?? '').trim().isNotEmpty)
              _DetailInfoRow(label: 'HUID', value: loan.huidNumber!.trim()),
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
        _PaymentHistoryPanel(
          payments: _controller.selectedPaymentLoanId == loan.id
              ? _controller.selectedPayments
              : const [],
          loading: _controller.selectedPaymentLoanId == loan.id &&
              _controller.isLoadingSelectedPayments,
          money: _money,
          date: _date,
        ),
        const SizedBox(height: 16),
        _LedgerDetailActions(
          canCollect: canOpenPayment,
          openingPdf: _openingInvoicePdf,
          statusLabel: loan.statusLabel,
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

part of '../girvi_account_detail_screen.dart';

extension _GirviAccountPaymentHistory on _GirviAccountDetailScreenState {
  Widget _buildPaymentLedger(
    GirviLoanWithCustomer account,
    List<GirviPaymentModel> payments,
  ) {
    final totalReceived =
        payments.fold<double>(0, (sum, payment) => sum + payment.amount);
    final totalDiscount = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.discountAmount,
    );

    return _AccountSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccountSectionHeader(
            icon: Icons.history_rounded,
            color: GirviColors.success,
            title: 'Payment Ledger',
            subtitle:
                '${payments.length} date-wise payment record${payments.length == 1 ? '' : 's'}',
            trailing: _PaymentLedgerHeaderActions(
              receivedLabel: 'Received ${_money(totalReceived)}',
              viewing: _viewingPaymentRecord,
              printing: _printingPaymentRecord,
              onView: _viewingPaymentRecord ? null : _previewPaymentRecord,
              onPrint: _printingPaymentRecord ? null : _printPaymentRecord,
            ),
          ),
          if (totalDiscount > 0) ...[
            const SizedBox(height: 10),
            _AccountInlineNotice(
              icon: Icons.local_offer_rounded,
              color: GirviColors.warning,
              text: 'Approved discount ${_money(totalDiscount)}',
            ),
          ],
          const SizedBox(height: 14),
          if (payments.isEmpty)
            const _AccountEmptyBlock(
              icon: GirviIcons.cash,
              title: 'No Payment Recorded',
              message: 'Interest or settlement entries will appear here.',
            )
          else
            Column(
              children: [
                for (var index = 0; index < payments.length; index++)
                  _PaymentTimelineRow(
                    payment: payments[index],
                    isLast: index == payments.length - 1,
                    money: _money,
                    date: _date,
                    coverageLabel: _paymentCoverageLabel(payments[index]),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          _AccountInlineNotice(
            icon: account.totalPayable <= 0.01
                ? Icons.verified_rounded
                : Icons.pending_actions_rounded,
            color: account.totalPayable <= 0.01
                ? GirviColors.success
                : GirviColors.warning,
            text: account.totalPayable <= 0.01
                ? 'Principal and interest settlement is complete.'
                : 'Current balance ${_money(account.totalPayable)} remains payable.',
          ),
        ],
      ),
    );
  }
}

class _PaymentLedgerHeaderActions extends StatelessWidget {
  final String receivedLabel;
  final bool viewing;
  final bool printing;
  final VoidCallback? onView;
  final VoidCallback? onPrint;

  const _PaymentLedgerHeaderActions({
    required this.receivedLabel,
    required this.viewing,
    required this.printing,
    required this.onView,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AccountStatusBadge(
          label: receivedLabel,
          color: GirviColors.success,
        ),
        const SizedBox(width: 8),
        _PaymentLedgerToolButton(
          tooltip: viewing ? 'Opening preview' : 'View payment record',
          loading: viewing,
          icon: Icons.visibility_rounded,
          onPressed: onView,
          color: GirviColors.info,
        ),
        const SizedBox(width: 6),
        _PaymentLedgerToolButton(
          tooltip: printing ? 'Preparing print' : 'Print payment record',
          loading: printing,
          icon: Icons.print_rounded,
          onPressed: onPrint,
          color: GirviColors.shellBg,
        ),
      ],
    );
  }
}

class _PaymentLedgerToolButton extends StatelessWidget {
  final String tooltip;
  final bool loading;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const _PaymentLedgerToolButton({
    required this.tooltip,
    required this.loading,
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 36,
        height: 36,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: color,
            disabledBackgroundColor: color.withValues(alpha: 0.45),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.76),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: loading
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, size: 18),
        ),
      ),
    );
  }
}

class _PaymentTimelineRow extends StatelessWidget {
  final GirviPaymentModel payment;
  final bool isLast;
  final String Function(double value, {bool precise}) money;
  final String Function(DateTime? value) date;
  final String? coverageLabel;

  const _PaymentTimelineRow({
    required this.payment,
    required this.isLast,
    required this.money,
    required this.date,
    required this.coverageLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = _paymentColor(payment.type);
    final receiptNo = payment.receiptNo?.trim();
    final hasReceiptNo = receiptNo != null && receiptNo.isNotEmpty;
    final split = <_AccountInfoRowData>[
      _AccountInfoRowData('Principal', money(payment.principalComponent)),
      _AccountInfoRowData('Interest', money(payment.interestComponent)),
      if (payment.discountAmount > 0)
        _AccountInfoRowData('Discount', money(payment.discountAmount)),
      _AccountInfoRowData('Balance After', money(payment.balanceAfter)),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Column(
            children: [
              _PaymentDateBadge(
                date: date(payment.paymentDate),
                color: color,
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: 112,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  color: GirviColors.cardBorder,
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GirviColors.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.type.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              color: GirviColors.textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _PaymentMetaChip(
                                icon: _paymentModeIcon(payment.mode),
                                label: payment.mode.displayName,
                                color: color,
                              ),
                              if (hasReceiptNo)
                                _PaymentMetaChip(
                                  icon: Icons.receipt_long_rounded,
                                  label: receiptNo,
                                  color: GirviColors.info,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Received',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: GirviColors.textBody,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 132),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              money(payment.amount),
                              style: GoogleFonts.manrope(
                                color: GirviColors.success,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (coverageLabel != null) ...[
                  const SizedBox(height: 9),
                  _AccountInlineNotice(
                    icon: Icons.date_range_rounded,
                    color: GirviColors.info,
                    text: coverageLabel!,
                  ),
                ],
                const SizedBox(height: 10),
                _AccountInfoGrid(rows: split, compact: true),
                if ((payment.notes ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    payment.notes!.trim(),
                    style: GoogleFonts.inter(
                      color: GirviColors.textBody,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Color _paymentColor(GirviPaymentType type) {
    switch (type) {
      case GirviPaymentType.interest:
      case GirviPaymentType.partialInterest:
        return GirviColors.warning;
      case GirviPaymentType.partialPrincipal:
        return GirviColors.info;
      case GirviPaymentType.fullRelease:
        return GirviColors.success;
      case GirviPaymentType.penalty:
        return GirviColors.danger;
    }
  }

  static IconData _paymentModeIcon(GirviPaymentMode mode) {
    switch (mode) {
      case GirviPaymentMode.cash:
        return GirviIcons.cash;
      case GirviPaymentMode.upi:
        return GirviIcons.upi;
      case GirviPaymentMode.neft:
      case GirviPaymentMode.bankTransfer:
        return GirviIcons.bank;
      case GirviPaymentMode.cheque:
        return Icons.receipt_rounded;
    }
  }
}

class _PaymentDateBadge extends StatelessWidget {
  final String date;
  final Color color;

  const _PaymentDateBadge({
    required this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final parts = date.split(' ');
    final day = parts.isNotEmpty ? parts.first : date;
    final month = parts.length >= 2 ? parts[1].toUpperCase() : 'DATE';
    final year = parts.length >= 3 ? parts[2] : '';

    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            day,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            month,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (year.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              year,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GirviColors.textBody,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PaymentMetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

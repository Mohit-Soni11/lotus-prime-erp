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
                '${payments.length} payment record${payments.length == 1 ? '' : 's'}',
            trailing: _AccountStatusBadge(
              label: 'Received ${_money(totalReceived)}',
              color: GirviColors.success,
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
          width: 34,
          child: Column(
            children: [
              _AccountIconBox(icon: _paymentIcon(payment.type), color: color),
              if (!isLast)
                Container(
                  width: 1,
                  height: 96,
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
              color: color.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.18)),
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
                          Text(
                            'Paid on ${date(payment.paymentDate)} | ${payment.mode.displayName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: GirviColors.textBody,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            money(payment.amount),
                            style: GoogleFonts.manrope(
                              color: GirviColors.success,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
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

  static IconData _paymentIcon(GirviPaymentType type) {
    switch (type) {
      case GirviPaymentType.interest:
      case GirviPaymentType.partialInterest:
        return GirviIcons.interestRate;
      case GirviPaymentType.partialPrincipal:
        return GirviIcons.loanTerms;
      case GirviPaymentType.fullRelease:
        return GirviIcons.release;
      case GirviPaymentType.penalty:
        return GirviIcons.warning;
    }
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
}

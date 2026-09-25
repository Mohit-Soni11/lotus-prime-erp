part of '../girvi_list_screen.dart';

class _PaymentHistoryPanel extends StatelessWidget {
  final List<GirviPaymentModel> payments;
  final bool loading;
  final String Function(double value, {bool precise}) money;
  final String Function(DateTime? value) date;

  const _PaymentHistoryPanel({
    required this.payments,
    required this.loading,
    required this.money,
    required this.date,
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
          Row(
            children: [
              Text(
                'Transaction Ledger',
                style: GoogleFonts.manrope(
                  color: GirviColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (payments.isNotEmpty)
                Text(
                  '${payments.length} entr${payments.length == 1 ? 'y' : 'ies'}',
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: GirviColors.brandGold,
                  ),
                ),
              ),
            )
          else if (payments.isEmpty)
            Text(
              'No payment has been recorded for this ticket yet.',
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            ...payments.map(
              (payment) => _PaymentHistoryRow(
                payment: payment,
                money: money,
                date: date,
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentHistoryRow extends StatelessWidget {
  final GirviPaymentModel payment;
  final String Function(double value, {bool precise}) money;
  final String Function(DateTime? value) date;

  const _PaymentHistoryRow({
    required this.payment,
    required this.money,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final principal = payment.principalComponent;
    final interest = payment.interestComponent;
    final discount = payment.discountAmount;
    final coverage = _coverageLabel(payment, date);
    final parts = <String>[
      if (coverage != null) coverage,
      if (principal > 0) 'Principal ${money(principal)}',
      if (interest > 0) 'Interest ${money(interest)}',
      if (discount > 0) 'Discount ${money(discount)}',
      payment.mode.displayName,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LedgerIconBox(
            icon: _paymentIcon(payment.type),
            color: _paymentColor(payment.type),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        payment.type.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      money(payment.amount),
                      style: GoogleFonts.manrope(
                        color: GirviColors.success,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Paid on ${date(payment.paymentDate)}',
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  parts.join(' | '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textBody,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String? _coverageLabel(
    GirviPaymentModel payment,
    String Function(DateTime? value) date,
  ) {
    final from = payment.interestFromDate;
    final to = payment.interestToDate;
    if (from != null && to != null) {
      return 'Period ${date(from)} to ${date(to)}';
    }

    final monthsCovered = payment.monthsCovered ?? 0;
    if (monthsCovered > 0) {
      return '$monthsCovered month${monthsCovered == 1 ? '' : 's'} covered';
    }

    return null;
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

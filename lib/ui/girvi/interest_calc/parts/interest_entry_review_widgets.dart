part of '../interest_calc_screen.dart';

class _EntryReviewBar extends StatelessWidget {
  final double enteredAmount;
  final double discountAmount;
  final GirviPaymentType paymentType;
  final double interestDue;
  final double principalOutstanding;
  final NumberFormat moneyFmt;
  final bool isSaving;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onRecord;

  const _EntryReviewBar({
    required this.enteredAmount,
    required this.discountAmount,
    required this.paymentType,
    required this.interestDue,
    required this.principalOutstanding,
    required this.moneyFmt,
    required this.isSaving,
    required this.actionLabel,
    required this.actionIcon,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    final signal = _EntryReviewSignal.resolve(
      paymentType: paymentType,
      enteredAmount: enteredAmount,
      discountAmount: discountAmount,
      interestDue: interestDue,
      principalOutstanding: principalOutstanding,
      moneyFmt: moneyFmt,
    );
    final isFullRelease = paymentType == GirviPaymentType.fullRelease;
    final releaseInterestPayable = math.max(interestDue - discountAmount, 0.0);
    final releaseTotalPayable = principalOutstanding + releaseInterestPayable;
    final actionButton = SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : onRecord,
        style: ElevatedButton.styleFrom(
          backgroundColor: GirviColors.success,
          foregroundColor: Colors.white,
          disabledBackgroundColor: GirviColors.textHint,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(actionIcon, size: 18),
        label: Text(
          isSaving ? 'Saving...' : actionLabel,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: signal.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: signal.color.withValues(alpha: 0.28)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(signal.icon, color: signal.color, size: 20),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      signal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                signal.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: GirviColors.textDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 11),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: isFullRelease
                    ? [
                        _ReviewMetric(
                          label: 'Principal',
                          value: 'Rs ${moneyFmt.format(principalOutstanding)}',
                        ),
                        _ReviewMetric(
                          label: 'Total Interest',
                          value:
                              'Rs ${moneyFmt.format(releaseInterestPayable)}',
                        ),
                        _ReviewMetric(
                          label: 'Total Payable',
                          value: 'Rs ${moneyFmt.format(releaseTotalPayable)}',
                          valueColor: signal.color,
                        ),
                      ]
                    : [
                        _ReviewMetric(
                          label: signal.referenceLabel,
                          value: signal.referenceValue,
                        ),
                        _ReviewMetric(
                          label: 'Entry Amount',
                          value: 'Rs ${moneyFmt.format(enteredAmount)}',
                        ),
                        _ReviewMetric(
                          label: signal.balanceLabel,
                          value: signal.balanceValue,
                          valueColor: signal.color,
                        ),
                      ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                details,
                const SizedBox(height: 14),
                actionButton,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 16),
              actionButton,
            ],
          );
        },
      ),
    );
  }
}

class _EntryReviewSignal {
  final String title;
  final String message;
  final String referenceLabel;
  final String referenceValue;
  final String balanceLabel;
  final String balanceValue;
  final IconData icon;
  final Color color;

  const _EntryReviewSignal({
    required this.title,
    required this.message,
    required this.referenceLabel,
    required this.referenceValue,
    required this.balanceLabel,
    required this.balanceValue,
    required this.icon,
    required this.color,
  });

  static _EntryReviewSignal resolve({
    required GirviPaymentType paymentType,
    required double enteredAmount,
    required double discountAmount,
    required double interestDue,
    required double principalOutstanding,
    required NumberFormat moneyFmt,
  }) {
    String amount(double value) => 'Rs ${moneyFmt.format(value)}';

    if (enteredAmount + discountAmount <= 0) {
      final pending = _referenceValue(
        paymentType: paymentType,
        interestDue: interestDue,
        principalOutstanding: principalOutstanding,
      );
      return _EntryReviewSignal(
        title: 'Amount Required',
        message: 'Enter the received amount before recording this entry.',
        referenceLabel: _referenceLabel(paymentType),
        referenceValue: amount(pending),
        balanceLabel: 'Pending',
        balanceValue: amount(pending),
        icon: GirviIcons.warning,
        color: GirviColors.warning,
      );
    }

    switch (paymentType) {
      case GirviPaymentType.interest:
        final remaining = math.max(interestDue - enteredAmount, 0.0);
        final advance = math.max(enteredAmount - interestDue, 0.0);
        if (interestDue <= 0) {
          return _EntryReviewSignal(
            title: 'Advance Interest Credit',
            message:
                'This amount will be held as advance credit against future interest.',
            referenceLabel: 'Net Interest Due',
            referenceValue: amount(interestDue),
            balanceLabel: 'Advance',
            balanceValue: amount(enteredAmount),
            icon: GirviIcons.markDone,
            color: GirviColors.success,
          );
        }
        if (remaining > 0) {
          return _EntryReviewSignal(
            title: 'Interest Part Received',
            message: '${amount(remaining)} interest will remain due.',
            referenceLabel: 'Net Interest Due',
            referenceValue: amount(interestDue),
            balanceLabel: 'After Entry',
            balanceValue: amount(remaining),
            icon: GirviIcons.interestRate,
            color: GirviColors.info,
          );
        }
        return _EntryReviewSignal(
          title: advance > 0 ? 'Advance Interest Credit' : 'Interest Cleared',
          message: advance > 0
              ? '${amount(advance)} will auto-adjust against future interest.'
              : 'This entry clears the current net interest due.',
          referenceLabel: 'Net Interest Due',
          referenceValue: amount(interestDue),
          balanceLabel: advance > 0 ? 'Advance' : 'After Entry',
          balanceValue: amount(advance),
          icon: GirviIcons.markDone,
          color: advance > 0 ? GirviColors.info : GirviColors.success,
        );

      case GirviPaymentType.partialInterest:
        final remaining = math.max(interestDue - enteredAmount, 0.0);
        return _EntryReviewSignal(
          title: remaining > 0 ? 'Partial Interest' : 'Interest Cleared',
          message: remaining > 0
              ? '${amount(remaining)} interest will still remain due.'
              : 'This entry covers the current interest due.',
          referenceLabel: 'Interest Due',
          referenceValue: amount(interestDue),
          balanceLabel: 'After Entry',
          balanceValue: amount(remaining),
          icon: remaining > 0 ? GirviIcons.interestRate : GirviIcons.markDone,
          color: remaining > 0 ? GirviColors.warning : GirviColors.success,
        );

      case GirviPaymentType.partialPrincipal:
        final balance = math.max(principalOutstanding - enteredAmount, 0.0);
        return _EntryReviewSignal(
          title: balance > 0 ? 'Principal Part Payment' : 'Principal Cleared',
          message: '${amount(balance)} principal will remain after this entry.',
          referenceLabel: 'Principal Outstanding',
          referenceValue: amount(principalOutstanding),
          balanceLabel: 'After Entry',
          balanceValue: amount(balance),
          icon: GirviIcons.loanTerms,
          color: balance > 0 ? GirviColors.purple : GirviColors.success,
        );

      case GirviPaymentType.penalty:
        return _EntryReviewSignal(
          title: 'Penalty Entry Ready',
          message: 'Penalty collection will be recorded against this ticket.',
          referenceLabel: 'Interest Due',
          referenceValue: amount(interestDue),
          balanceLabel: 'Penalty',
          balanceValue: amount(enteredAmount),
          icon: GirviIcons.warning,
          color: GirviColors.danger,
        );

      case GirviPaymentType.fullRelease:
        final totalPayable = principalOutstanding + interestDue;
        final balance =
            math.max(totalPayable - enteredAmount - discountAmount, 0.0);
        return _EntryReviewSignal(
          title: balance > 0
              ? 'Settlement Balance Pending'
              : 'Settlement Complete',
          message: balance > 0
              ? '${amount(balance)} will remain after this entry.'
              : discountAmount > 0
                  ? '${amount(discountAmount)} discount applied. Ticket will move to Ready for Delivery.'
                  : 'Ticket will move to Ready for Delivery after saving.',
          referenceLabel: 'Total Payable',
          referenceValue: amount(totalPayable),
          balanceLabel: balance > 0 ? 'Balance After' : 'Balance',
          balanceValue: amount(balance),
          icon: GirviIcons.release,
          color: balance > 0 ? GirviColors.warning : GirviColors.success,
        );
    }
  }

  static String _referenceLabel(GirviPaymentType paymentType) {
    switch (paymentType) {
      case GirviPaymentType.interest:
        return 'Net Interest Due';
      case GirviPaymentType.partialInterest:
        return 'Interest Due';
      case GirviPaymentType.partialPrincipal:
        return 'Principal Outstanding';
      case GirviPaymentType.penalty:
        return 'Interest Due';
      case GirviPaymentType.fullRelease:
        return 'Total Payable';
    }
  }

  static double _referenceValue({
    required GirviPaymentType paymentType,
    required double interestDue,
    required double principalOutstanding,
  }) {
    switch (paymentType) {
      case GirviPaymentType.interest:
        return interestDue;
      case GirviPaymentType.partialInterest:
      case GirviPaymentType.penalty:
        return interestDue;
      case GirviPaymentType.partialPrincipal:
        return principalOutstanding;
      case GirviPaymentType.fullRelease:
        return principalOutstanding + interestDue;
    }
  }
}

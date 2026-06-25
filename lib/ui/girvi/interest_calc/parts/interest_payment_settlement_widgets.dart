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
                children: [
                  _ReviewMetric(
                    label: signal.referenceLabel,
                    value: signal.referenceValue,
                  ),
                  _ReviewMetric(
                    label: 'Entry Amount',
                    value: 'Rs ${moneyFmt.format(enteredAmount)}',
                  ),
                  if (paymentType == GirviPaymentType.fullRelease &&
                      discountAmount > 0)
                    _ReviewMetric(
                      label: 'Discount',
                      value: 'Rs ${moneyFmt.format(discountAmount)}',
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

class _ReleaseSettlementBalanceStrip extends StatelessWidget {
  final double principalDue;
  final double interestDue;
  final double principalCollected;
  final double interestCollected;
  final double previousDiscount;
  final double discount;
  final double cashEntered;
  final NumberFormat moneyFmt;

  const _ReleaseSettlementBalanceStrip({
    required this.principalDue,
    required this.interestDue,
    required this.principalCollected,
    required this.interestCollected,
    required this.previousDiscount,
    required this.discount,
    required this.cashEntered,
    required this.moneyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final grossDue = principalDue + interestDue;
    final netPayable = math.max(grossDue - discount, 0.0);
    final balanceAfter = math.max(netPayable - cashEntered, 0.0);
    final earlierCash = principalCollected + interestCollected;
    final hasPriorSettlement = earlierCash > 0 || previousDiscount > 0;
    final balanceColor =
        balanceAfter > 0 ? GirviColors.warning : GirviColors.success;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return _SettlementHeader(
                label: 'Net Payable',
                amount: _money(netPayable),
                helper: discount > 0
                    ? 'Amount after settlement discount'
                    : 'Principal due plus interest due',
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: GirviColors.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GirviColors.divider),
            ),
            child: Column(
              children: [
                _SettlementBreakdownRow(
                  label: 'Principal Due',
                  value: _money(principalDue),
                  color: GirviColors.purple,
                ),
                _SettlementBreakdownRow(
                  label: 'Interest Due',
                  value: _money(interestDue),
                  color: GirviColors.warning,
                ),
                const Divider(height: 18, color: GirviColors.divider),
                _SettlementBreakdownRow(
                  label: 'Gross Settlement',
                  value: _money(grossDue),
                  color: GirviColors.textDark,
                  strong: true,
                ),
                _SettlementBreakdownRow(
                  label: 'Discount / Waiver',
                  value: discount > 0 ? '- ${_money(discount)}' : _money(0),
                  color: discount > 0
                      ? GirviColors.success
                      : GirviColors.textMuted,
                ),
                _SettlementBreakdownRow(
                  label: 'Cash Entered',
                  value: _money(cashEntered),
                  color: GirviColors.success,
                ),
                const Divider(height: 18, color: GirviColors.divider),
                _SettlementBreakdownRow(
                  label: 'Balance After',
                  value: _money(balanceAfter),
                  color: balanceColor,
                  strong: true,
                ),
              ],
            ),
          ),
          if (hasPriorSettlement) ...[
            const SizedBox(height: 10),
            _PriorSettlementNote(
              earlierCash: earlierCash,
              previousDiscount: previousDiscount,
              moneyFmt: moneyFmt,
            ),
          ],
        ],
      ),
    );
  }

  String _money(double value) => 'Rs ${moneyFmt.format(value)}';
}

class _SettlementHeader extends StatelessWidget {
  final String label;
  final String amount;
  final String helper;

  const _SettlementHeader({
    required this.label,
    required this.amount,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GirviColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: GirviColors.success.withValues(alpha: 0.22),
            ),
          ),
          child: const Icon(
            Icons.verified_rounded,
            color: GirviColors.success,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: GirviColors.textDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  amount,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                helper,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: GirviColors.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettlementBreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool strong;

  const _SettlementBreakdownRow({
    required this.label,
    required this.value,
    required this.color,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GirviColors.textBody,
                fontSize: 12.5,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: color,
              fontSize: strong ? 15 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorSettlementNote extends StatelessWidget {
  final double earlierCash;
  final double previousDiscount;
  final NumberFormat moneyFmt;

  const _PriorSettlementNote({
    required this.earlierCash,
    required this.previousDiscount,
    required this.moneyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (earlierCash > 0) 'cash Rs ${moneyFmt.format(earlierCash)}',
      if (previousDiscount > 0)
        'discount Rs ${moneyFmt.format(previousDiscount)}',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: GirviColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.info.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.history_rounded,
            color: GirviColors.info,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Already settled before this entry: ${parts.join(', ')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GirviColors.textBody,
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

class _ReadyForDeliveryPanel extends StatelessWidget {
  final DateTime? expectedDeliveryDate;
  final double principalCollected;
  final double interestCollected;
  final double discountGiven;
  final NumberFormat moneyFmt;
  final DateFormat dateFmt;
  final bool isSaving;
  final VoidCallback onDeliver;

  const _ReadyForDeliveryPanel({
    required this.expectedDeliveryDate,
    required this.principalCollected,
    required this.interestCollected,
    required this.discountGiven,
    required this.moneyFmt,
    required this.dateFmt,
    required this.isSaving,
    required this.onDeliver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GirviColors.success.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GirviColors.success.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _IconBox(
                icon: GirviIcons.release,
                color: GirviColors.success,
                dark: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settlement Complete',
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Payment is complete. Item remains in shop custody until handover.',
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _FocusMetric(
                label: 'Principal Received',
                value: 'Rs ${moneyFmt.format(principalCollected)}',
                color: GirviColors.purple,
                wide: true,
              ),
              _FocusMetric(
                label: 'Interest Received',
                value: 'Rs ${moneyFmt.format(interestCollected)}',
                color: GirviColors.warning,
                wide: true,
              ),
              if (discountGiven > 0)
                _FocusMetric(
                  label: 'Discount Approved',
                  value: 'Rs ${moneyFmt.format(discountGiven)}',
                  color: GirviColors.info,
                  wide: true,
                ),
              _FocusMetric(
                label: 'Expected Pickup',
                value: expectedDeliveryDate == null
                    ? 'Not set'
                    : dateFmt.format(expectedDeliveryDate!),
                color: GirviColors.info,
                wide: true,
              ),
              const _FocusMetric(
                label: 'Custody Status',
                value: 'In Shop',
                color: GirviColors.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onDeliver,
              style: ElevatedButton.styleFrom(
                backgroundColor: GirviColors.success,
                foregroundColor: Colors.white,
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
                  : const Icon(Icons.inventory_2_rounded, size: 18),
              label: Text(
                isSaving ? 'Delivering...' : 'Confirm Item Delivered',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

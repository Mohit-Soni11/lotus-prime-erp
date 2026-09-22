part of '../interest_calc_screen.dart';

extension InterestPaymentActions on _InterestCalcScreenState {
  Future<void> _recordPayment() async {
    final selectedBeforeSave = _ctrl.selectedLoan;
    final wasReadyForDelivery = _ctrl.isReadyForDelivery;
    final isFullReleaseSettlement = _ctrl.paymentType ==
            GirviPaymentType.fullRelease &&
        !wasReadyForDelivery &&
        _ctrl.releaseSettlementValue + 0.01 >= _ctrl.releaseTotalDueForSelected;

    if (isFullReleaseSettlement) {
      final confirmed = await _confirmFullReleaseSettlement();
      if (!confirmed) return;
    }

    if (wasReadyForDelivery) {
      final confirmed = await _confirmReadyDelivery();
      if (!confirmed) return;
    }

    final ok = await _ctrl.recordPayment();
    if (!mounted || !ok) return;
    if ((isFullReleaseSettlement || wasReadyForDelivery) &&
        selectedBeforeSave != null) {
      await _showSettlementSavedDialog(
        selectedBeforeSave.loan.id,
        delivered: wasReadyForDelivery,
      );
    } else {
      AppFeedback.show(
        context,
        type: AppFeedbackType.success,
        message: _ctrl.successMessage ?? 'Payment entry recorded.',
      );
    }
  }

  Future<bool> _confirmFullReleaseSettlement() async {
    final selected = _ctrl.selectedLoan;
    if (selected == null) return false;
    final principal = _ctrl.releasePrincipalDueForSelected;
    final totalInterest = _ctrl.netInterestDueForSelected;
    final discount = _ctrl.releaseDiscount;
    final interestAfterWaiver = math.max(totalInterest - discount, 0.0);
    final totalPayable = principal + interestAfterWaiver;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: GirviColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: GirviColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      GirviIcons.release,
                      color: GirviColors.success,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Confirm Final Settlement',
                      style: GoogleFonts.manrope(
                        color: GirviColors.textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Confirm that the final receivable amount has been collected for ticket ${selected.loan.ticketNo}.',
                      style: GoogleFonts.inter(
                        color: GirviColors.textBody,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DeliveryConfirmLine(
                      label: 'Customer',
                      value: selected.customerName,
                    ),
                    _DeliveryConfirmLine(
                      label: 'Principal',
                      value: 'Rs ${_moneyFmt.format(principal)}',
                    ),
                    _DeliveryConfirmLine(
                      label: 'Total Interest',
                      value: 'Rs ${_moneyFmt.format(totalInterest)}',
                    ),
                    _DeliveryConfirmLine(
                      label: 'Interest Waiver',
                      value: discount > 0
                          ? '- Rs ${_moneyFmt.format(discount)}'
                          : 'Rs 0',
                      valueColor: discount > 0
                          ? GirviColors.success
                          : GirviColors.textMuted,
                    ),
                    _DeliveryConfirmLine(
                      label: 'Total Receivable',
                      value: 'Rs ${_moneyFmt.format(totalPayable)}',
                      valueColor: GirviColors.textDark,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GirviColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: GirviColors.success.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Text(
                        'After confirmation, this ticket will move to Ready for Delivery and settlement documents can be printed or saved.',
                        style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: GirviColors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GirviColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(GirviIcons.release, size: 18),
                  label: Text(
                    'Confirm Settlement',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _confirmReadyDelivery() async {
    final selected = _ctrl.selectedLoan;
    if (selected == null) return false;
    final loan = selected.loan;
    final expectedDate = loan.expectedDeliveryDate == null
        ? 'Not set'
        : _dateFmt.format(loan.expectedDeliveryDate!);
    final nowLabel = _dateTimeFmt.format(DateTime.now());
    final principalReceived = _ctrl.principalRepaidForSelected +
        _ctrl.releasePrincipalCollectedForSelected;
    final interestReceived = _ctrl.interestCollectedForSelected;
    final discountGiven = _ctrl.releaseDiscountForSelected;
    final receivedTotal = principalReceived + interestReceived;
    final clearedTotal = receivedTotal + discountGiven;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: GirviColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: GirviColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: GirviColors.success,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Confirm Item Delivery',
                      style: GoogleFonts.manrope(
                        color: GirviColors.textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'This will mark ticket ${loan.ticketNo} as delivered and closed.',
                      style: GoogleFonts.inter(
                        color: GirviColors.textBody,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DeliveryConfirmLine(
                      label: 'Customer',
                      value: selected.customerName,
                    ),
                    _DeliveryConfirmLine(
                      label: 'Expected Pickup',
                      value: expectedDate,
                    ),
                    _DeliveryConfirmLine(
                      label: 'Delivery Time',
                      value: nowLabel,
                    ),
                    _DeliveryConfirmLine(
                      label: 'Principal Received',
                      value: 'Rs ${_moneyFmt.format(principalReceived)}',
                    ),
                    _DeliveryConfirmLine(
                      label: 'Interest Received',
                      value: 'Rs ${_moneyFmt.format(interestReceived)}',
                    ),
                    if (discountGiven > 0)
                      _DeliveryConfirmLine(
                        label: 'Approved Waiver',
                        value: 'Rs ${_moneyFmt.format(discountGiven)}',
                        valueColor: GirviColors.info,
                      ),
                    _DeliveryConfirmLine(
                      label: 'Total Payable Cleared',
                      value: 'Rs ${_moneyFmt.format(clearedTotal)}',
                      valueColor: GirviColors.success,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GirviColors.warning.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: GirviColors.warning.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            color: GirviColors.warning,
                            size: 18,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Verify pledged item, customer identity and receipt before handover.',
                              style: GoogleFonts.inter(
                                color: GirviColors.textDark,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: GirviColors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GirviColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.inventory_2_rounded, size: 18),
                  label: Text(
                    'Confirm Delivery',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

class _DeliveryConfirmLine extends StatelessWidget {
  const _DeliveryConfirmLine({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: GirviColors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                color: valueColor ?? GirviColors.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

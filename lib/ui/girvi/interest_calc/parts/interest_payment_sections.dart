part of '../interest_calc_screen.dart';

extension InterestPaymentSections on _InterestCalcScreenState {
  Widget _buildPaymentForm(GirviLoanWithCustomer data) {
    return GirviSectionCard(
      icon: GirviIcons.cash,
      title: 'Interest Collection Entry',
      subtitle:
          'Record verified interest or release collections for this ticket',
      accent: GirviColors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Collection Type', style: GirviStyles.fieldLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _ctrl.entryPaymentTypes.map((type) {
              return _SelectablePill(
                label: _labelForPaymentType(type),
                selected: _ctrl.paymentType == type,
                icon: _iconForPaymentType(type),
                color: _colorForPaymentType(type),
                onTap: () => _ctrl.setPaymentType(type),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          if (_ctrl.isReadyForDelivery)
            _ReadyForDeliveryPanel(
              expectedDeliveryDate: data.loan.expectedDeliveryDate,
              principalCollected: _ctrl.principalRepaidForSelected +
                  _ctrl.releasePrincipalCollectedForSelected,
              interestCollected: _ctrl.interestCollectedForSelected,
              discountGiven: _ctrl.releaseDiscountForSelected,
              moneyFmt: _moneyFmt,
              dateFmt: _dateFmt,
              isSaving: _ctrl.isSaving,
              onDeliver: _recordPayment,
            )
          else ...[
            if (_ctrl.isInterestEntry)
              GirviRowTwo(
                left: GirviInputField(
                  label: 'Amount Received',
                  hint: '0',
                  icon: GirviIcons.cash,
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  prefixText: 'Rs ',
                ),
                right: GirviInputField(
                  label: 'Equivalent Months',
                  hint: '1',
                  icon: GirviIcons.dates,
                  controller: _monthsCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  suffixText: 'months',
                ),
              )
            else
              Column(
                children: [
                  GirviRowTwo(
                    left: GirviInputField(
                      label: 'Principal Due',
                      hint: '0',
                      icon: GirviIcons.loanTerms,
                      controller: _releasePrincipalCtrl,
                      enabled: false,
                      prefixText: 'Rs ',
                    ),
                    right: GirviInputField(
                      label: 'Interest Received',
                      hint: '0',
                      icon: GirviIcons.cash,
                      controller: _releaseInterestCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      prefixText: 'Rs ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  GirviInputField(
                    label: 'Interest Discount / Waiver',
                    hint: '0',
                    icon: Icons.local_offer_rounded,
                    controller: _releaseDiscountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    prefixText: 'Rs ',
                  ),
                ],
              ),
            const SizedBox(height: 10),
            if (_ctrl.isInterestEntry)
              _AmountShortcutRail(
                paymentType: _ctrl.paymentType,
                isInterestEntry: true,
                interestDue: _ctrl.netInterestDueForSelected,
                monthlyInterest: _ctrl.currentLedgerMonthlyInterestForSelected,
                principalOutstanding: data.loan.loanAmount,
                expectedInterest: _ctrl.expectedInterest,
                moneyFmt: _moneyFmt,
                onPick: _setPaymentAmount,
              )
            else
              _ReleaseSettlementBalanceStrip(
                principalDue: _ctrl.releasePrincipalDueForSelected,
                interestDue: _ctrl.netInterestDueForSelected,
                principalCollected: _ctrl.releasePrincipalCollectedForSelected,
                interestCollected: _ctrl.releaseInterestCollectedForSelected,
                previousDiscount: _ctrl.releaseDiscountForSelected,
                discount: _ctrl.releaseDiscount,
                cashEntered: _ctrl.releaseEntryTotal,
                moneyFmt: _moneyFmt,
              ),
            if (_ctrl.isInterestEntry) ...[
              const SizedBox(height: 10),
              _InterestLedgerBalanceStrip(
                grossInterest: _ctrl.grossInterestAccruedForSelected,
                interestPaid: _ctrl.interestCollectedForSelected,
                netDue: _ctrl.netInterestDueForSelected,
                equivalentMonths: _ctrl.interestMonthsCoveredByAmount,
                interestFromDate: _ctrl.interestFromDate,
                moneyFmt: _moneyFmt,
              ),
            ],
            const SizedBox(height: 14),
            if (_ctrl.isInterestEntry)
              _DateField(
                label: 'Collection Date',
                value: _dateFmt.format(_ctrl.paymentDate),
                icon: GirviIcons.dates,
                onTap: () => _pickDate(
                  initialDate: _ctrl.paymentDate,
                  onPicked: _ctrl.setPaymentDate,
                ),
              )
            else
              GirviRowTwo(
                left: _DateField(
                  label: 'Collection Date',
                  value: _dateFmt.format(_ctrl.paymentDate),
                  icon: GirviIcons.dates,
                  onTap: () => _pickDate(
                    initialDate: _ctrl.paymentDate,
                    onPicked: _ctrl.setPaymentDate,
                  ),
                ),
                right: _DateField(
                  label: 'Expected Pickup Date',
                  value: _dateFmt.format(_ctrl.expectedDeliveryDate),
                  icon: GirviIcons.dates,
                  onTap: () => _pickDate(
                    initialDate: _ctrl.expectedDeliveryDate,
                    onPicked: _ctrl.setExpectedDeliveryDate,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Text('Collection Mode', style: GirviStyles.fieldLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: GirviPaymentMode.values.map((mode) {
                return _SelectablePill(
                  label: mode.displayName,
                  selected: _ctrl.paymentMode == mode,
                  icon: _iconForPaymentMode(mode),
                  color: GirviColors.info,
                  onTap: () => _ctrl.setPaymentMode(mode),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            GirviInputField(
              label: 'Collection Notes',
              hint: 'Optional remarks for audit trail',
              icon: GirviIcons.notes,
              controller: _notesCtrl,
              minLines: 2,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 18),
            _EntryReviewBar(
              enteredAmount: _ctrl.isInterestEntry
                  ? _ctrl.amount
                  : _ctrl.releaseEntryTotal,
              discountAmount: _ctrl.isInterestEntry ? 0 : _ctrl.releaseDiscount,
              paymentType: _ctrl.paymentType,
              interestDue: _ctrl.netInterestDueForSelected,
              principalOutstanding: _ctrl.releasePrincipalDueForSelected,
              moneyFmt: _moneyFmt,
              isSaving: _ctrl.isSaving,
              actionLabel: _ctrl.isInterestEntry
                  ? 'Record Interest Collection'
                  : _ctrl.releaseSettlementValue + 0.01 >=
                          _ctrl.releaseTotalDueForSelected
                      ? 'Mark Ready for Delivery'
                      : 'Record Partial Settlement',
              actionIcon:
                  _ctrl.isInterestEntry ? GirviIcons.save : GirviIcons.release,
              onRecord: _recordPayment,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    return GirviSectionCard(
      icon: GirviIcons.list,
      title: 'Interest Ledger',
      subtitle:
          '${_ctrl.payments.length} ledger entr${_ctrl.payments.length == 1 ? 'y' : 'ies'} recorded for this ticket',
      accent: GirviColors.info,
      child: _ctrl.payments.isEmpty
          ? const _EmptyState(
              icon: GirviIcons.list,
              title: 'No Ledger Entry Recorded',
              message:
                  'The first interest collection for this ticket will appear here.',
            )
          : Column(
              children: _ctrl.payments.map((payment) {
                return _PaymentHistoryRow(
                  payment: payment,
                  moneyFmt: _moneyFmt,
                  dateFmt: _dateFmt,
                );
              }).toList(),
            ),
    );
  }

  IconData _iconForPaymentType(GirviPaymentType type) {
    switch (type) {
      case GirviPaymentType.interest:
      case GirviPaymentType.partialInterest:
        return GirviIcons.interestRate;
      case GirviPaymentType.partialPrincipal:
        return GirviIcons.loanTerms;
      case GirviPaymentType.penalty:
        return GirviIcons.warning;
      case GirviPaymentType.fullRelease:
        return GirviIcons.release;
    }
  }

  String _labelForPaymentType(GirviPaymentType type) {
    switch (type) {
      case GirviPaymentType.interest:
        return 'Interest Collection';
      case GirviPaymentType.partialInterest:
        return 'Partial Interest';
      case GirviPaymentType.partialPrincipal:
        return 'Principal Collection';
      case GirviPaymentType.penalty:
        return 'Penalty Collection';
      case GirviPaymentType.fullRelease:
        return 'Final Release';
    }
  }

  Color _colorForPaymentType(GirviPaymentType type) {
    switch (type) {
      case GirviPaymentType.interest:
        return GirviColors.success;
      case GirviPaymentType.partialInterest:
        return GirviColors.warning;
      case GirviPaymentType.partialPrincipal:
        return GirviColors.purple;
      case GirviPaymentType.penalty:
        return GirviColors.danger;
      case GirviPaymentType.fullRelease:
        return GirviColors.info;
    }
  }

  IconData _iconForPaymentMode(GirviPaymentMode mode) {
    switch (mode) {
      case GirviPaymentMode.cash:
        return GirviIcons.cash;
      case GirviPaymentMode.upi:
        return GirviIcons.upi;
      case GirviPaymentMode.neft:
      case GirviPaymentMode.bankTransfer:
      case GirviPaymentMode.cheque:
        return GirviIcons.bank;
    }
  }
}

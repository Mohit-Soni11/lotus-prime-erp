part of '../interest_calc_screen.dart';

extension InterestEntryLayout on _InterestCalcScreenState {
  Widget _buildLoanPanel() {
    return Container(
      decoration: GirviStyles.card,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                const _IconBox(
                    icon: GirviIcons.ticket, color: GirviColors.brandGold),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer Girvi Book',
                          style: GirviStyles.sectionTitle),
                      const SizedBox(height: 2),
                      Text(
                        '${_ctrl.openCustomerCount} customer${_ctrl.openCustomerCount == 1 ? '' : 's'} | ${_ctrl.openTicketCount} open ticket${_ctrl.openTicketCount == 1 ? '' : 's'}',
                        style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                _CountBadge(value: _ctrl.customerAccounts.length.toString()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: _SearchField(
              controller: _searchCtrl,
              hintText: 'Search customer, mobile, ticket or item',
            ),
          ),
          Expanded(
            child: _ctrl.customerAccounts.isEmpty
                ? _EmptyState(
                    icon: GirviIcons.search,
                    title: _ctrl.hasCustomerAccounts
                        ? 'No Matching Customer'
                        : 'No Open Girvi Customer',
                    message: _ctrl.hasCustomerAccounts
                        ? 'Adjust the search text to find the correct customer or ticket.'
                        : 'Create a girvi ticket first, then record payments here.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _ctrl.customerAccounts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final account = _ctrl.customerAccounts[index];
                      final selected =
                          account.customerId == _ctrl.selectedCustomerId;
                      return _CustomerGirviCard(
                        account: account,
                        selected: selected,
                        moneyFmt: _moneyFmt,
                        dateFmt: _dateFmt,
                        onCustomerTap: () =>
                            _ctrl.selectCustomerAccount(account),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspace({bool shrink = false}) {
    final selected = _ctrl.selectedLoan;
    final selectedCustomer = _ctrl.selectedCustomerAccount;
    final content = selectedCustomer == null
        ? [
            const _EmptyState(
              icon: GirviIcons.customer,
              title: 'Select a Customer',
              message:
                  'Choose one customer from the left to view all open Girvi bills.',
              large: true,
            ),
          ]
        : selected == null
            ? [
                _CustomerReadyPanel(
                  account: selectedCustomer,
                  moneyFmt: _moneyFmt,
                  selectedLoanId: null,
                  onLoanTap: _ctrl.selectLoan,
                ),
                const SizedBox(height: 14),
                const _EmptyState(
                  icon: GirviIcons.ticket,
                  title: 'Select a Girvi Bill',
                  message:
                      'Open the exact bill from the list above to record interest or principal collection.',
                ),
              ]
            : [
                _buildSelectedSummary(selected),
                const SizedBox(height: 14),
                if (_ctrl.errorMessage != null) ...[
                  GirviErrorBanner(message: _ctrl.errorMessage!),
                  const SizedBox(height: 12),
                ],
                if (_ctrl.successMessage != null) ...[
                  _SuccessBanner(message: _ctrl.successMessage!),
                  const SizedBox(height: 12),
                ],
                _buildPaymentForm(selected),
                const SizedBox(height: 14),
                _buildPaymentHistory(),
                const SizedBox(height: 28),
              ];

    if (shrink) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: content,
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: content,
    );
  }

  Widget _buildSelectedSummary(GirviLoanWithCustomer data) {
    final loan = data.loan;
    final principalDisbursed = _ctrl.principalDisbursedForSelected;
    final principalRepaid = _ctrl.principalRepaidForSelected +
        _ctrl.releasePrincipalCollectedForSelected;
    final interestCollected = _ctrl.interestCollectedForSelected;
    final totalCollected = _ctrl.totalCollectedForSelected;
    final grossInterestAccrued = _ctrl.grossInterestAccruedForSelected;
    final netInterestDue = _ctrl.netInterestDueForSelected;
    final advanceInterestCredit = _ctrl.advanceInterestCreditForSelected;
    final settlementComplete =
        loan.girviStatus == GirviStatus.readyForDelivery ||
            loan.girviStatus == GirviStatus.released;
    final currentMonthlyInterest =
        _ctrl.currentLedgerMonthlyInterestForSelected;
    final totalPayable = _ctrl.releasePrincipalDueForSelected + netInterestDue;
    final totalMonths = loan.monthsElapsed.ceil();
    final interestBreakdown = GirviLoanModel.calculateCompoundInterestBreakdown(
      principal: principalDisbursed,
      monthlyRatePercent: loan.interestRate,
      months: loan.monthsElapsed.ceil(),
    );
    final elapsedPeriod = GirviLoanModel.elapsedPeriodBetween(
      loan.startDate,
      loan.releaseDate ?? DateTime.now(),
    );
    final advanceMonths =
        advanceInterestCredit <= 0 || currentMonthlyInterest <= 0
            ? 0
            : (advanceInterestCredit / currentMonthlyInterest).floor();
    final principalProgress = principalDisbursed <= 0
        ? 0.0
        : (principalRepaid / principalDisbursed).clamp(0.0, 1.0).toDouble();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GirviColors.cardBg,
            GirviColors.brandGold.withValues(alpha: 0.055),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GirviColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: GirviColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compactHeader = constraints.maxWidth < 720;
              final identity = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: GirviColors.brandGold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: GirviColors.brandGold.withValues(alpha: 0.30),
                      ),
                    ),
                    child: const Icon(
                      GirviIcons.ticket,
                      color: GirviColors.brandGold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loan Overview',
                          style: GoogleFonts.inter(
                            color: GirviColors.textDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          loan.ticketNo,
                          style: GoogleFonts.robotoMono(
                            color: GirviColors.brandGold,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${data.customerName}  |  ${data.customerMobile}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: GirviColors.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            loan.itemSummary,
                            if ((data.customerCity ?? '').trim().isNotEmpty)
                              data.customerCity!.trim(),
                          ].join('  |  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: GirviColors.textDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment:
                    compactHeader ? WrapAlignment.start : WrapAlignment.end,
                children: [
                  _StatusPill(label: loan.statusLabel, color: loan.statusColor),
                  SizedBox(
                    width: 132,
                    child: _OverviewActionButton(
                      label: 'Change Bill',
                      icon: Icons.swap_horiz_rounded,
                      busy: false,
                      onTap: _ctrl.showBillSelectionForSelectedCustomer,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: _OverviewActionButton(
                      label:
                          _openingReceipt ? 'Opening...' : 'View Girvi Invoice',
                      icon: Icons.visibility_rounded,
                      busy: _openingReceipt,
                      onTap: () => _previewGirviReceipt(data),
                    ),
                  ),
                ],
              );

              if (compactHeader) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    identity,
                    const SizedBox(height: 12),
                    actions,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 330),
                    child: actions,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _CollectionFocusStrip(
            interestDue: netInterestDue,
            monthlyInterest: currentMonthlyInterest,
            totalPayable: totalPayable,
            unpaidMonths: totalMonths,
            advanceAmount: advanceInterestCredit,
            advanceMonths: advanceMonths,
            settlementComplete: settlementComplete,
            isOverdue: loan.isOverdue,
            moneyFmt: _moneyFmt,
          ),
          if (interestBreakdown.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InterestBreakdownPanel(
              lines: interestBreakdown,
              totalMonths: totalMonths,
              elapsedPeriod: elapsedPeriod,
              totalInterest: grossInterestAccrued,
              moneyFmt: _moneyFmt,
            ),
          ],
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 960;
              final principalPanel = _OverviewMoneyPanel(
                title: 'Principal',
                primaryLabel: 'Principal Amount',
                primaryValue: 'Rs ${_moneyFmt.format(principalDisbursed)}',
                secondaryLabel: 'Outstanding Balance',
                secondaryValue:
                    'Rs ${_moneyFmt.format(_ctrl.releasePrincipalDueForSelected)}',
                tertiaryLabel: principalRepaid > 0 ? 'Principal Repaid' : null,
                tertiaryValue: principalRepaid > 0
                    ? 'Rs ${_moneyFmt.format(principalRepaid)}'
                    : null,
                icon: GirviIcons.loanTerms,
                color: GirviColors.purple,
                progress: principalRepaid > 0 ? principalProgress : null,
              );

              final interestPanel = _OverviewMoneyPanel(
                title: 'Interest',
                primaryLabel: 'Due Now',
                primaryValue: 'Rs ${_moneyFmt.format(netInterestDue)}',
                secondaryLabel: advanceInterestCredit > 0
                    ? settlementComplete
                        ? 'Excess Received'
                        : 'Advance Credit'
                    : 'Gross Interest',
                secondaryValue: advanceInterestCredit > 0
                    ? 'Rs ${_moneyFmt.format(advanceInterestCredit)}'
                    : 'Rs ${_moneyFmt.format(grossInterestAccrued)}',
                tertiaryLabel: 'Interest Paid',
                tertiaryValue: 'Rs ${_moneyFmt.format(interestCollected)}',
                icon: GirviIcons.interestRate,
                color: advanceInterestCredit > 0
                    ? settlementComplete
                        ? GirviColors.danger
                        : GirviColors.success
                    : GirviColors.warning,
              );

              final termsPanel = _OverviewTermsPanel(
                tenure: '${loan.durationMonths} months',
                startDate: _dateFmt.format(loan.startDate),
                maturityDate: loan.maturityDate == null
                    ? 'Not set'
                    : _dateFmt.format(loan.maturityDate!),
                paidTill: 'Rs ${_moneyFmt.format(interestCollected)}',
                totalCollected: 'Rs ${_moneyFmt.format(totalCollected)}',
              );

              if (compact) {
                return Column(
                  children: [
                    principalPanel,
                    const SizedBox(height: 12),
                    interestPanel,
                    const SizedBox(height: 12),
                    termsPanel,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: principalPanel),
                  const SizedBox(width: 12),
                  Expanded(child: interestPanel),
                  const SizedBox(width: 12),
                  Expanded(child: termsPanel),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

part of '../new_girvi_screen.dart';

extension NewGirviLayout on _NewGirviScreenState {
  Widget _buildMainEntryColumn({bool includeKyc = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDeskStatusStrip(),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            return _animated(1, _buildPledgedItemsSection());
          },
        ),
        const SizedBox(height: 16),
        _animated(2, _buildPledgedValuationSection()),
        const SizedBox(height: 16),
        _animated(4, _buildSection4LoanTerms()),
        const SizedBox(height: 16),
        if (includeKyc) ...[
          _animated(7, _buildSection7KYC()),
          const SizedBox(height: 16),
        ],
        _animated(8, _buildSection8Notes()),
      ],
    );
  }

  Widget _buildDeskStatusStrip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: GirviColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final children = [
            _DeskMetric(
              icon: GirviIcons.customer,
              label: 'Borrower',
              value: _ctrl.hasCustomer
                  ? _ctrl.selectedCustomer!.name
                  : 'Not selected',
              color: GirviColors.accentCustomer,
            ),
            _DeskMetric(
              icon: GirviIcons.weight,
              label: 'Net Weight',
              value: _deskNetWeightLabel(),
              color: GirviColors.accentWeight,
            ),
            _DeskMetric(
              icon: GirviIcons.interestRate,
              label: 'Monthly Interest',
              value: _deskMonthlyInterestLabel(),
              color: GirviColors.accentInterest,
            ),
            _DeskMetric(
              icon: GirviIcons.loanTerms,
              label: 'Loan Amount',
              value: _deskLoanAmountLabel(),
              color: GirviColors.accentLoan,
            ),
          ];
          if (compact) {
            return Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  children[i],
                ],
              ],
            );
          }
          return Row(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: children[i]),
              ],
            ],
          );
        },
      ),
    );
  }

  String _deskNetWeightLabel() {
    if (_ctrl.netWeight <= 0) return 'Not set';
    return _formatSmartWeight(_ctrl.netWeight);
  }

  String _deskMonthlyInterestLabel() {
    final hasLoanContext =
        _ctrl.loanAmount > 0 || _loanAmtCtrl.text.trim().isNotEmpty;
    if (!hasLoanContext || _ctrl.interestRate <= 0) return 'Not set';
    return '${_formatSmartPercent(_ctrl.interestRate)} monthly';
  }

  String _deskLoanAmountLabel() {
    if (_ctrl.loanAmount <= 0) return 'Not set';
    return _formatSmartMoney(_ctrl.loanAmount);
  }

  Widget _buildTicketSummaryPanel() {
    final customer = _ctrl.selectedCustomer;
    final photoCount =
        _pledgedItems.fold<int>(0, (sum, item) => sum + item.photoCount);
    final hasItems = _pledgedItems.isNotEmpty && _ctrl.netWeight > 0;
    final disbursementReady = _ctrl.loanAmount > 0 &&
        _totalDisbursementAmount > 0 &&
        (_totalDisbursementAmount - _ctrl.loanAmount).abs() <= 0.50;
    final completedSteps = [
      _ctrl.hasCustomer,
      hasItems,
      _ctrl.loanAmount > 0,
      disbursementReady,
    ].where((complete) => complete).length;
    final invoiceReady = completedSteps == 4;
    final hasKyc =
        _ctrl.idProofType != null && _idProofNoCtrl.text.trim().isNotEmpty;
    final ltv = _ctrl.computedLtv.clamp(0.0, 999.0);
    final paymentParts = [
      for (final mode in _visibleDisbursementModes)
        if (_disbursementAmountFor(mode) > 0)
          _InvoicePaymentPart(
            label: _disbursementModeLabel(mode),
            value: _formatSmartMoney(_disbursementAmountFor(mode)),
            icon: _disbursementModeIcon(mode),
            color: _disbursementModeColor(mode),
          ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GirviColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: GirviColors.shadowMedium,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
            decoration: const BoxDecoration(
              color: GirviColors.cardBg,
              border: Border(
                bottom: BorderSide(color: GirviColors.cardBorder),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: GirviColors.brandGoldLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: GirviColors.brandGold.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: GirviColors.brandGold,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOAN INVOICE SUMMARY',
                            style: GoogleFonts.inter(
                              color: GirviColors.textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _ctrl.ticketNo.isEmpty
                                ? 'Generating invoice number...'
                                : _ctrl.ticketNo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              color: GirviColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(
                      label: invoiceReady ? 'READY' : 'DRAFT',
                      color: invoiceReady
                          ? GirviColors.success
                          : GirviColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          minHeight: 5,
                          value: completedSteps / 4,
                          backgroundColor: GirviColors.inputBgLocked,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            invoiceReady
                                ? GirviColors.success
                                : GirviColors.brandGold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$completedSteps / 4 complete',
                      style: GoogleFonts.inter(
                        color: GirviColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InvoiceCustomerCard(
                  name: customer?.name ?? 'Customer not selected',
                  mobile: customer?.mobile ??
                      'Select customer from Customer Details above',
                  ready: _ctrl.hasCustomer,
                ),
                const SizedBox(height: 12),
                _InvoiceAmountHero(
                  loanAmount: _ctrl.loanAmount > 0
                      ? _formatSmartMoney(_ctrl.loanAmount)
                      : 'Not set',
                  duration: _ctrl.durationMonths > 0
                      ? '${_ctrl.durationMonths} months'
                      : 'Not set',
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final metrics = [
                      _InvoiceMetricTile(
                        label: 'Item Value',
                        value: _ctrl.totalValue > 0
                            ? _formatSmartMoney(_ctrl.totalValue)
                            : 'Not set',
                        icon: GirviIcons.valuation,
                        color: GirviColors.success,
                      ),
                      _InvoiceMetricTile(
                        label: 'Monthly Interest',
                        value: _ctrl.monthlyInterest > 0
                            ? _formatSmartMoney(_ctrl.monthlyInterest)
                            : 'Not set',
                        icon: GirviIcons.interestRate,
                        color: GirviColors.info,
                      ),
                      _InvoiceMetricTile(
                        label: 'LTV Ratio',
                        value: ltv > 0 ? _formatSmartPercent(ltv) : 'Not set',
                        icon: Icons.pie_chart_outline_rounded,
                        color: GirviColors.purple,
                      ),
                    ];
                    if (constraints.maxWidth < 360) {
                      return Column(
                        children: [
                          for (var i = 0; i < metrics.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            metrics[i],
                          ],
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < metrics.length; i++) ...[
                          if (i > 0) const SizedBox(width: 7),
                          Expanded(child: metrics[i]),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                _InvoiceDetailSection(
                  title: 'LOAN TERMS',
                  icon: GirviIcons.loanTerms,
                  children: [
                    _InvoiceDetailRow(
                      icon: GirviIcons.interestRate,
                      label: 'Interest Rate',
                      value: _ctrl.interestRate > 0
                          ? '${_formatSmartPercent(_ctrl.interestRate)} monthly'
                          : 'Not set',
                    ),
                    _InvoiceDetailRow(
                      icon: GirviIcons.dates,
                      label: 'Maturity Date',
                      value: _ctrl.durationMonths > 0
                          ? _dateFmt.format(_ctrl.maturityDate)
                          : 'Not set',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _InvoicePaymentBreakdown(
                  parts: paymentParts,
                  totalPaid: _totalDisbursementAmount > 0
                      ? _formatSmartMoney(_totalDisbursementAmount)
                      : 'Not set',
                  loanAmount: _ctrl.loanAmount > 0
                      ? _formatSmartMoney(_ctrl.loanAmount)
                      : 'Not set',
                  differenceLabel: _remainingDisbursementAmount >= 0
                      ? 'Remaining ${_formatSmartMoney(_remainingDisbursementAmount)}'
                      : 'Excess ${_formatSmartMoney(_remainingDisbursementAmount.abs())}',
                  ready: disbursementReady,
                ),
                const SizedBox(height: 10),
                _InvoiceDetailSection(
                  title: 'PLEDGED SECURITY',
                  icon: GirviIcons.diamond,
                  children: [
                    _InvoiceDetailRow(
                      icon: GirviIcons.weight,
                      label: 'Items / Net Weight',
                      value:
                          '${_ctrl.itemCount == 1 ? '1 piece' : '${_ctrl.itemCount} pieces'}  |  ${_formatSmartWeight(_ctrl.netWeight)}',
                    ),
                    _InvoiceDetailRow(
                      icon: GirviIcons.gold,
                      label: 'Metal / Purity',
                      value:
                          '${_ctrl.metalType.displayName}  |  ${_ctrl.metalPurity.displayName}',
                    ),
                    _InvoiceDetailRow(
                      icon: Icons.verified_outlined,
                      label: 'HUID / Photos',
                      value:
                          '${_huidCtrl.text.trim().isEmpty ? 'No HUID' : _huidCtrl.text.trim()}  |  $photoCount photo${photoCount == 1 ? '' : 's'}',
                      valueColor: photoCount > 0
                          ? GirviColors.success
                          : GirviColors.textDark,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _InvoiceReadinessCard(
                  customerReady: _ctrl.hasCustomer,
                  itemsReady: hasItems,
                  amountReady: _ctrl.loanAmount > 0,
                  paymentReady: disbursementReady,
                  kycAttached: hasKyc,
                ),
                const SizedBox(height: 14),
                _TicketActionButton(
                  label: _ctrl.isEditMode
                      ? 'Update & Print Invoice'
                      : 'Create & Print Invoice',
                  icon: GirviIcons.print,
                  filled: true,
                  busy: _ctrl.isSaving,
                  onTap: _ctrl.isSaving
                      ? null
                      : () => _onSave(generateInvoice: true),
                ),
                const SizedBox(height: 10),
                _TicketActionButton(
                  label:
                      _ctrl.isEditMode ? 'Update Ticket' : 'Save Ticket Only',
                  icon: Icons.inventory_2_outlined,
                  filled: false,
                  onTap: _ctrl.isSaving
                      ? null
                      : () => _onSave(generateInvoice: false),
                ),
                if (!_ctrl.isEditMode) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: _ctrl.isSaving ? null : _resetAll,
                    style: TextButton.styleFrom(
                      foregroundColor: GirviColors.textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(GirviIcons.refresh, size: 16),
                    label: Text(
                      'Reset this entry',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

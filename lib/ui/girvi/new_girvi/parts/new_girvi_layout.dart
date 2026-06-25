part of '../new_girvi_screen.dart';

extension NewGirviLayout on _NewGirviScreenState {
  static const double _headerCardHeight = 156;

  // â”€â”€ TICKET BANNER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
              label: 'Customer',
              value: _ctrl.hasCustomer
                  ? _ctrl.selectedCustomer!.name
                  : 'Not selected',
              color: GirviColors.accentCustomer,
            ),
            _DeskMetric(
              icon: GirviIcons.weight,
              label: 'Net Weight',
              value: '${_ctrl.netWeight.toStringAsFixed(3)} g',
              color: GirviColors.accentWeight,
            ),
            _DeskMetric(
              icon: GirviIcons.interestRate,
              label: 'Interest Rate',
              value: '${_ctrl.interestRate.toStringAsFixed(2)}% / month',
              color: GirviColors.accentInterest,
            ),
            _DeskMetric(
              icon: GirviIcons.loanTerms,
              label: 'Loan Amount',
              value: 'Rs ${_fmt.format(_ctrl.loanAmount)}',
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
            value: 'Rs ${_fmt.format(_disbursementAmountFor(mode))}',
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
                  loanAmount: 'Rs ${_fmt.format(_ctrl.loanAmount)}',
                  maturityAmount: 'Rs ${_fmt.format(_ctrl.totalDueAtMaturity)}',
                  duration: '${_ctrl.durationMonths} months',
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final metrics = [
                      _InvoiceMetricTile(
                        label: 'Item Value',
                        value: 'Rs ${_fmt.format(_ctrl.totalValue)}',
                        icon: GirviIcons.valuation,
                        color: GirviColors.success,
                      ),
                      _InvoiceMetricTile(
                        label: 'Monthly Interest',
                        value: 'Rs ${_fmt.format(_ctrl.monthlyInterest)}',
                        icon: GirviIcons.interestRate,
                        color: GirviColors.warning,
                      ),
                      _InvoiceMetricTile(
                        label: 'LTV Ratio',
                        value: '${ltv.toStringAsFixed(1)}%',
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
                      value:
                          '${_ctrl.interestRate.toStringAsFixed(2)}% monthly',
                    ),
                    _InvoiceDetailRow(
                      icon: GirviIcons.dates,
                      label: 'Maturity Date',
                      value: _dateFmt.format(_ctrl.maturityDate),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _InvoicePaymentBreakdown(
                  parts: paymentParts,
                  totalPaid: 'Rs ${_fmt.format(_totalDisbursementAmount)}',
                  loanAmount: 'Rs ${_fmt.format(_ctrl.loanAmount)}',
                  differenceLabel: _remainingDisbursementAmount >= 0
                      ? 'Remaining Rs ${_fmt.format(_remainingDisbursementAmount)}'
                      : 'Excess Rs ${_fmt.format(_remainingDisbursementAmount.abs())}',
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
                          '${_ctrl.itemCount == 1 ? '1 piece' : '${_ctrl.itemCount} pieces'}  |  ${_ctrl.netWeight.toStringAsFixed(3)} g',
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

  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildHeaderDeck(),
    );
  }

  Widget _buildHeaderDeck() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1280;
        if (!wide) {
          return Column(
            children: [
              SizedBox(
                height: _headerCardHeight,
                child: _buildTicketBanner(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: _headerCardHeight,
                child: _animated(0, _buildCustomerBanner()),
              ),
            ],
          );
        }
        return Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 672,
                height: _headerCardHeight,
                child: _buildTicketBanner(),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 620,
                height: _headerCardHeight,
                child: _animated(0, _buildCustomerBanner()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomerBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: _headerCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _buildHeaderIconBox(
                icon: GirviIcons.customer,
                color: GirviColors.brandGold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CUSTOMER DETAILS',
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Borrower profile for this loan ticket',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                label: _ctrl.hasCustomer ? 'SELECTED' : 'REQUIRED',
                color: _ctrl.hasCustomer
                    ? GirviColors.success
                    : GirviColors.warning,
              ),
            ],
          ),
          Container(
            height: 1,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 16),
            color: GirviColors.cardBorder,
          ),
          Expanded(
            child: Center(
              child: _ctrl.hasCustomer
                  ? _buildSelectedCustomerHeaderTile()
                  : SizedBox(
                      height: 52,
                      child: _SelectCustomerButton(onTap: _openCustomerSearch),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCustomerHeaderTile() {
    final customer = _ctrl.selectedCustomer!;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: GirviColors.brandGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              GirviIcons.customer,
              color: GirviColors.brandGold,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    customer.mobile,
                    if ((customer.city ?? '').trim().isNotEmpty)
                      customer.city!.trim(),
                  ].join('  |  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _ctrl.clearCustomer,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GirviColors.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GirviColors.cardBorder),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: GirviColors.textMuted,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: _headerCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ticketAccentLine(20, 1.0),
                      const SizedBox(height: 3),
                      _ticketAccentLine(13, 0.45),
                      const SizedBox(height: 3),
                      _ticketAccentLine(7, 0.18),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INVOICE NUMBER',
                        style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Girvi Loan Invoice',
                        style: GoogleFonts.inter(
                          color: GirviColors.brandGold,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 40),
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: GirviColors.bodyBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GirviColors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: GirviColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'DRAFT',
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            height: 1,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 16),
            color: GirviColors.cardBorder,
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildLoanInvoiceIconBox(),
                const SizedBox(width: 16),
                _buildLoanInvoiceNumberBlock(),
                const SizedBox(width: 20),
                Container(
                  width: 1,
                  height: 34,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        GirviColors.cardBorder,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: StreamBuilder<DateCardModel>(
                      stream: _dateLogic.timeStream,
                      initialData: _dateLogic.initialData,
                      builder: (context, snapshot) {
                        final data = snapshot.data ?? _dateLogic.initialData;
                        return _buildLoanDateTimeRow(data);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _headerCardDecoration() {
    return BoxDecoration(
      color: GirviColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: GirviColors.cardBorder),
      boxShadow: const [
        BoxShadow(
          color: GirviColors.shadowLight,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
        BoxShadow(
          color: GirviColors.shadowMedium,
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  Widget _buildHeaderIconBox({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: color, size: 17),
    );
  }

  Widget _buildLoanInvoiceNumberBlock() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INVOICE NO :',
          style: GoogleFonts.inter(
            color: GirviColors.textDark,
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _ctrl.ticketNo.isEmpty ? 'Generating...' : _ctrl.ticketNo,
          style: GirviStyles.ticketNumber.copyWith(
            color: GirviColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildLoanInvoiceIconBox() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: GirviColors.brandGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: GirviColors.brandGold.withValues(alpha: 0.25)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 8,
            right: 8,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    GirviColors.brandGold.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const Center(
            child: Icon(
              Icons.receipt_long_outlined,
              color: GirviColors.brandGold,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanDateTimeRow(DateCardModel data) {
    final timeParts = data.time.split(':');
    final cleanTime =
        timeParts.length >= 2 ? '${timeParts[0]} : ${timeParts[1]}' : data.time;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLoanChip(
          icon: GirviIcons.dates,
          iconColor: GirviColors.textDark,
          subLabel: 'DATE',
          value: data.date.toUpperCase(),
          valueColor: GirviColors.textDark,
          valueFontSize: 13,
          chipBg: GirviColors.bodyBg,
          chipBorder: GirviColors.cardBorder,
        ),
        const SizedBox(width: 8),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: GirviColors.textMuted,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        _buildLoanChip(
          icon: Icons.schedule_rounded,
          iconColor: GirviColors.success,
          subLabel: 'TIME',
          value: cleanTime,
          valueColor: GirviColors.success,
          valueFontSize: 14,
          chipBg: GirviColors.success.withValues(alpha: 0.07),
          chipBorder: GirviColors.success.withValues(alpha: 0.25),
        ),
      ],
    );
  }

  Widget _buildLoanChip({
    required IconData icon,
    required Color iconColor,
    required String subLabel,
    required String value,
    required Color valueColor,
    required double valueFontSize,
    required Color chipBg,
    required Color chipBorder,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subLabel,
                style: GoogleFonts.inter(
                  color: iconColor.withValues(alpha: 0.8),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: valueColor,
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ticketAccentLine(double width, double opacity) => Container(
        width: width,
        height: 3,
        decoration: BoxDecoration(
          color: GirviColors.brandGold.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

part of '../girvi_account_detail_screen.dart';

extension _GirviAccountDetailPanels on _GirviAccountDetailScreenState {
  Widget _buildAccountHero(GirviLoanWithCustomer account) {
    final statusColor = _accountStatusColor(account);
    final actionEnabled = _canOpenSettlementAction(account);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF5),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: GirviColors.brandGold.withValues(alpha: 0.22)),
        boxShadow: const [
          BoxShadow(
            color: GirviColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          final identity = _buildAccountIdentity(account, statusColor);
          final documents = _buildAccountDocuments(account, actionEnabled);

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const Divider(height: 1, color: GirviColors.cardBorder),
                documents,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: identity),
              Container(
                width: 1,
                constraints: const BoxConstraints(minHeight: 240),
                color: GirviColors.brandGold.withValues(alpha: 0.18),
              ),
              SizedBox(width: 430, child: documents),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAccountIdentity(
    GirviLoanWithCustomer account,
    Color statusColor,
  ) {
    final loan = account.loan;
    final address = _customerAddress(account);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GirviColors.brandGold.withValues(alpha: 0.10),
            const Color(0xFFFFFCF5),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccountCustomerAvatar(
            initials: _customerInitials(account.customerName),
            statusColor: statusColor,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _AccountMetaChip(
                      icon: Icons.confirmation_number_rounded,
                      label: 'Ticket ${loan.ticketNo}',
                      color: GirviColors.brandGold,
                    ),
                    _AccountStatusBadge(
                      label: _accountStatusLabel(account),
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  account.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _AccountMetaChip(
                      icon: Icons.phone_rounded,
                      label: account.customerMobile,
                      color: GirviColors.info,
                    ),
                    _AccountMetaChip(
                      icon: Icons.location_on_rounded,
                      label: address,
                      color: GirviColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _AccountQuickFact(
                      label: 'Principal Amount',
                      value: _money(account.originalPrincipal),
                      icon: Icons.account_balance_wallet_rounded,
                      color: GirviColors.textDark,
                    ),
                    _AccountQuickFact(
                      label: 'Start Date',
                      value: _date(loan.startDate),
                      icon: GirviIcons.dates,
                      color: GirviColors.info,
                    ),
                    _AccountQuickFact(
                      label: 'Pledged Item',
                      value:
                          '${loan.itemCount} item${loan.itemCount == 1 ? '' : 's'} | ${_weight(loan.netWeight)}',
                      icon: GirviIcons.itemDetails,
                      color: GirviColors.brandGold,
                    ),
                    _AccountQuickFact(
                      label: 'Interest Rate',
                      value: '${loan.interestRate.toStringAsFixed(2)}% monthly',
                      icon: GirviIcons.interestRate,
                      color: GirviColors.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDocuments(
    GirviLoanWithCustomer account,
    bool actionEnabled,
  ) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Account Documents',
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Open one receipt preview. Double-click the preview to switch between receipt and ledger side.',
            style: GoogleFonts.inter(
              color: GirviColors.textBody,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _AccountDocumentButton(
            icon: Icons.receipt_long_rounded,
            title: 'Girvi Receipt',
            subtitle: _openingGirviReceipt
                ? 'Preparing receipt preview'
                : 'Front receipt, double-click to flip ledger side',
            color: GirviColors.brandGold,
            onTap: _openingGirviReceipt ? null : _previewGirviReceipt,
          ),
          if (actionEnabled) ...[
            const SizedBox(height: 14),
            _AccountPrimaryCommandButton(
              icon: account.loan.girviStatus == GirviStatus.readyForDelivery
                  ? GirviIcons.markDone
                  : GirviIcons.cash,
              label: _settlementActionLabel(account),
              onTap: _openInterestEntry,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialOverview(GirviLoanWithCustomer account) {
    final discountTotal =
        account.principalDiscountTotal + account.interestDiscountTotal;
    final totalReceived = account.principalPaidTotal +
        account.legacyPrincipalRepaidTotal +
        account.interestPaidTotal;
    final interestRate = account.loan.interestRate;
    final interestRateLabel = interestRate == interestRate.roundToDouble()
        ? interestRate.toStringAsFixed(0)
        : interestRate.toStringAsFixed(2);
    final principalDueVisible = account.principalDue > 0.01;
    final interestDueVisible = account.netInterestDue > 0.01;

    final metrics = [
      _AccountMetricData(
        label: 'Original Principal',
        value: _money(account.originalPrincipal),
        icon: GirviIcons.loanTerms,
        color: GirviColors.textDark,
        helper: 'Loan amount',
      ),
      _AccountMetricData(
        label: 'Total Interest',
        value: _money(account.grossInterestAccrued),
        icon: GirviIcons.interestRate,
        color: GirviColors.warning,
        helper: 'Interest rate $interestRateLabel%',
      ),
      if (principalDueVisible)
        _AccountMetricData(
          label: 'Principal Due',
          value: _money(account.principalDue),
          icon: Icons.account_balance_rounded,
          color: GirviColors.danger,
          helper: 'Outstanding principal',
        ),
      if (interestDueVisible)
        _AccountMetricData(
          label: 'Interest Due',
          value: _money(account.netInterestDue),
          icon: Icons.percent_rounded,
          color: GirviColors.warning,
          helper: 'Unpaid interest',
        ),
      _AccountMetricData(
        label: 'Total Received',
        value: _money(totalReceived),
        icon: GirviIcons.cash,
        color: GirviColors.success,
        helper: 'Principal and interest',
      ),
      _AccountMetricData(
        label: 'Net Payable',
        value: _money(account.totalPayable),
        icon: Icons.verified_rounded,
        color: account.totalPayable <= 0.01
            ? GirviColors.success
            : GirviColors.danger,
        helper: discountTotal > 0 ? 'Discount ${_money(discountTotal)}' : null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final safeWidth = maxWidth <= 0 ? 320.0 : maxWidth;
        final maxColumns = safeWidth >= 1180
            ? 6
            : safeWidth >= 760
                ? 3
                : 2;
        final columns =
            metrics.length < maxColumns ? metrics.length : maxColumns;
        const spacing = 12.0;
        final cardWidth = (safeWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: cardWidth > 0 ? cardWidth : safeWidth,
                  child: _AccountMetricCard(data: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildPledgedItemPanel(GirviLoanWithCustomer account) {
    final loan = account.loan;
    final detailedItems =
        _controller.details?.items ?? const <GirviLoanItemDetails>[];
    return _AccountSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccountSectionHeader(
            icon: GirviIcons.itemDetails,
            color: GirviColors.brandGold,
            title: 'Pledged Item Details',
            subtitle: detailedItems.isEmpty
                ? 'Summary captured at ticket creation'
                : '${detailedItems.length} item${detailedItems.length == 1 ? '' : 's'} grouped by metal',
            trailing: _AccountStatusBadge(
              label: 'Principal ${_money(account.originalPrincipal)}',
              color: GirviColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          if (detailedItems.isNotEmpty) ...[
            _buildPledgedMetalSummary(detailedItems),
            const SizedBox(height: 14),
            Column(
              children: [
                for (final itemDetails in detailedItems) ...[
                  _PledgedItemDetailRow(
                    serialNo: itemDetails.item.serialNo,
                    itemName: itemDetails.item.itemName,
                    metal: itemDetails.item.metalType,
                    purity: itemDetails.item.purity,
                    pieces: itemDetails.item.pieces,
                    grossWeight: _weight(itemDetails.item.grossWeight),
                    lessWeight: _weight(itemDetails.item.lessWeight),
                    netWeight: _weight(itemDetails.item.netWeight),
                    rate: _money(itemDetails.item.ratePerGram, precise: true),
                    value: _money(itemDetails.item.valuationAmount),
                    huid: itemDetails.item.huidNumber,
                    photoCount: itemDetails.photos.length,
                    color: _metalColor(itemDetails.item.metalType),
                  ),
                  if (itemDetails != detailedItems.last)
                    const SizedBox(height: 10),
                ],
              ],
            ),
          ] else
            _AccountInfoGrid(
              rows: [
                _AccountInfoRowData('Item Name', loan.itemDescription),
                _AccountInfoRowData('Item Count', loan.itemCount.toString()),
                _AccountInfoRowData(
                  'Metal / Purity',
                  '${loan.metalTypeEnum.displayName} / ${loan.metalPurity}',
                ),
                _AccountInfoRowData(
                    'Principal Amount', _money(account.originalPrincipal)),
                _AccountInfoRowData('Gross Weight', _weight(loan.grossWeight)),
                _AccountInfoRowData('Less Weight', _weight(loan.stoneWeight)),
                _AccountInfoRowData('Net Weight', _weight(loan.netWeight)),
                _AccountInfoRowData(
                  'Rate Per Gram',
                  _money(loan.ratePerGram, precise: true),
                ),
                _AccountInfoRowData('Pledged Value', _money(loan.totalValue)),
                if ((loan.huidNumber ?? '').trim().isNotEmpty)
                  _AccountInfoRowData('HUID', loan.huidNumber!.trim()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPledgedMetalSummary(List<GirviLoanItemDetails> items) {
    final summaries = <String, _PledgedMetalSummary>{};
    for (final itemDetails in items) {
      final item = itemDetails.item;
      final key =
          item.metalType.trim().isEmpty ? 'Other' : item.metalType.trim();
      final existing = summaries[key] ?? _PledgedMetalSummary(metal: key);
      summaries[key] = existing.add(
        pieces: item.pieces,
        grossWeight: item.grossWeight,
        netWeight: item.netWeight,
        value: item.valuationAmount,
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: summaries.values
          .map(
            (summary) => _PledgedMetalSummaryCard(
              metal: summary.metal,
              itemCount: summary.itemCount,
              pieces: summary.pieces,
              grossWeight: _weight(summary.grossWeight),
              netWeight: _weight(summary.netWeight),
              value: _money(summary.value),
              color: _metalColor(summary.metal),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLoanTermsPanel(GirviLoanWithCustomer account) {
    final loan = account.loan;
    return _AccountSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AccountSectionHeader(
            icon: GirviIcons.dates,
            color: GirviColors.info,
            title: 'Loan Terms',
            subtitle: 'Principal, interest rate and maturity timeline',
          ),
          const SizedBox(height: 14),
          _AccountInfoGrid(
            rows: [
              _AccountInfoRowData('Start Date', _date(loan.startDate)),
              _AccountInfoRowData('Maturity Date', _date(loan.maturityDate)),
              _AccountInfoRowData(
                'Duration',
                '${loan.durationMonths} month${loan.durationMonths == 1 ? '' : 's'}',
              ),
              _AccountInfoRowData(
                'Monthly Interest Rate',
                '${loan.interestRate.toStringAsFixed(2)}%',
              ),
              _AccountInfoRowData(
                'Disbursement Mode',
                loan.disbursementMode,
              ),
              _AccountInfoRowData(
                'Last Interest Paid',
                _date(loan.lastInterestPaidDate),
              ),
              _AccountInfoRowData(
                'Elapsed Period',
                loan.unpaidInterestElapsedPeriod.displayLabel,
              ),
              _AccountInfoRowData('Notes', _emptyText(loan.notes)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPanel(GirviLoanWithCustomer account) {
    final loan = account.loan;
    final settlementComplete = account.totalPayable <= 0.01 ||
        loan.girviStatus == GirviStatus.readyForDelivery ||
        loan.deliveredAt != null;
    final delivered = loan.deliveredAt != null;
    final statusColor = _accountStatusColor(account);

    return _AccountSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: _AccountSectionHeader(
              icon: GirviIcons.release,
              color: statusColor,
              title: 'Delivery and Closure',
              subtitle: _accountStatusLabel(account),
              trailing: _AccountStatusBadge(
                label: delivered ? 'Closed' : 'Live Status',
                color: statusColor,
              ),
            ),
          ),
          const Divider(height: 1, color: GirviColors.cardBorder),
          _AccountClosureHero(
            color: statusColor,
            icon: delivered
                ? Icons.inventory_2_rounded
                : settlementComplete
                    ? Icons.inventory_rounded
                    : Icons.pending_actions_rounded,
            title: delivered
                ? 'Delivered and Closed'
                : settlementComplete
                    ? 'Settlement Complete'
                    : 'Settlement Pending',
            subtitle: delivered
                ? 'Customer item delivery is completed.'
                : settlementComplete
                    ? 'Item is ready for customer pickup.'
                    : 'Principal and interest must be cleared before delivery.',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _AccountClosureStep(
                      icon: Icons.verified_rounded,
                      label: 'Settlement',
                      value: settlementComplete ? 'Complete' : 'Pending',
                      color: settlementComplete
                          ? GirviColors.success
                          : GirviColors.warning,
                    ),
                    _AccountClosureStep(
                      icon: Icons.event_available_rounded,
                      label: 'Expected Pickup',
                      value: _date(loan.expectedDeliveryDate),
                      color: GirviColors.info,
                    ),
                    _AccountClosureStep(
                      icon: Icons.handshake_rounded,
                      label: 'Delivery',
                      value: delivered ? 'Delivered' : 'Not Delivered',
                      color: delivered
                          ? GirviColors.success
                          : GirviColors.textBody,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _AccountInfoGrid(
                  rows: [
                    _AccountInfoRowData(
                        'Release Date', _date(loan.releaseDate)),
                    _AccountInfoRowData(
                        'Delivered At', _dateTime(loan.deliveredAt)),
                    _AccountInfoRowData(
                      'Processed By',
                      _emptyText(loan.releasedBy),
                    ),
                    _AccountInfoRowData(
                      'Payment Mode',
                      _emptyText(loan.releasePaymentMode),
                    ),
                    _AccountInfoRowData(
                      'Release Notes',
                      _emptyText(loan.releaseNotes),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _customerAddress(GirviLoanWithCustomer account) {
    final address = account.customerAddress.trim();
    if (address.isNotEmpty) return address;

    final city = account.customerCity?.trim();
    if (city != null && city.isNotEmpty) return city;
    return 'Address not available';
  }

  String _customerInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'NA';
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first
        .substring(0, parts.first.length >= 2 ? 2 : 1)
        .toUpperCase();
  }

  Color _metalColor(String metal) {
    switch (metal.trim().toLowerCase()) {
      case 'gold':
        return GirviColors.brandGold;
      case 'silver':
        return const Color(0xFF64748B);
      case 'diamond':
        return GirviColors.info;
      case 'platinum':
        return const Color(0xFF0F766E);
      default:
        return GirviColors.textDark;
    }
  }

  String _emptyText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'Not set';
    return trimmed;
  }
}

class _PledgedMetalSummary {
  final String metal;
  final int itemCount;
  final int pieces;
  final double grossWeight;
  final double netWeight;
  final double value;

  const _PledgedMetalSummary({
    required this.metal,
    this.itemCount = 0,
    this.pieces = 0,
    this.grossWeight = 0,
    this.netWeight = 0,
    this.value = 0,
  });

  _PledgedMetalSummary add({
    required int pieces,
    required double grossWeight,
    required double netWeight,
    required double value,
  }) {
    return _PledgedMetalSummary(
      metal: metal,
      itemCount: itemCount + 1,
      pieces: this.pieces + pieces,
      grossWeight: this.grossWeight + grossWeight,
      netWeight: this.netWeight + netWeight,
      value: this.value + value,
    );
  }
}

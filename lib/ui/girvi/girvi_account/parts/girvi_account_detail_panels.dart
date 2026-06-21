part of '../girvi_account_detail_screen.dart';

extension _GirviAccountDetailPanels on _GirviAccountDetailScreenState {
  Widget _buildAccountHero(GirviLoanWithCustomer account) {
    final statusColor = _accountStatusColor(account);
    final actionEnabled = _canOpenSettlementAction(account);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
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
                color: GirviColors.cardBorder,
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
            GirviColors.brandGold.withValues(alpha: 0.075),
            GirviColors.cardBg,
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
                    const _AccountStatusBadge(
                      label: 'Girvi Invoice / Ticket',
                      color: GirviColors.brandGold,
                    ),
                    _AccountStatusBadge(
                      label: _accountStatusLabel(account),
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  loan.ticketNo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  account.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: GirviColors.textDark,
                    fontSize: 18,
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
            'Print the original invoice or the complete settlement statement.',
            style: GoogleFonts.inter(
              color: GirviColors.textBody,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _AccountDocumentButton(
            icon: GirviIcons.print,
            title: 'Original Invoice',
            subtitle: _openingOriginalInvoice
                ? 'Opening invoice preview'
                : 'Girvi creation time PDF',
            color: GirviColors.info,
            onTap: _openingOriginalInvoice ? null : _previewOriginalInvoice,
          ),
          const SizedBox(height: 10),
          _AccountDocumentButton(
            icon: Icons.receipt_long_rounded,
            title: 'Settlement Statement',
            subtitle: _openingSettlementStatement
                ? 'Preparing statement'
                : 'Full payment and delivery ledger',
            color: GirviColors.brandGold,
            onTap: _openingSettlementStatement
                ? null
                : _previewSettlementStatement,
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

    final metrics = [
      _AccountMetricData(
        label: 'Original Principal',
        value: _money(account.originalPrincipal),
        icon: GirviIcons.loanTerms,
        color: GirviColors.textDark,
      ),
      _AccountMetricData(
        label: 'Total Interest',
        value: _money(account.grossInterestAccrued),
        icon: GirviIcons.interestRate,
        color: GirviColors.warning,
      ),
      _AccountMetricData(
        label: 'Principal Due',
        value: _money(account.principalDue),
        icon: Icons.account_balance_rounded,
        color: account.principalDue <= 0.01
            ? GirviColors.success
            : GirviColors.textDark,
      ),
      _AccountMetricData(
        label: 'Interest Due',
        value: _money(account.netInterestDue),
        icon: Icons.percent_rounded,
        color: account.netInterestDue <= 0.01
            ? GirviColors.success
            : GirviColors.warning,
      ),
      _AccountMetricData(
        label: 'Total Received',
        value: _money(totalReceived),
        icon: GirviIcons.cash,
        color: GirviColors.success,
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
        final columns = safeWidth >= 1180
            ? 6
            : safeWidth >= 760
                ? 3
                : 2;
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
    return _AccountSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AccountSectionHeader(
            icon: GirviIcons.itemDetails,
            color: GirviColors.brandGold,
            title: 'Pledged Item Details',
            subtitle: 'Item and valuation captured at ticket creation',
          ),
          const SizedBox(height: 14),
          _AccountInfoGrid(
            rows: [
              _AccountInfoRowData('Item Name', loan.itemDescription),
              _AccountInfoRowData('Item Count', loan.itemCount.toString()),
              _AccountInfoRowData(
                'Metal / Purity',
                '${loan.metalTypeEnum.displayName} / ${loan.metalPurity}',
              ),
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

  String _emptyText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'Not set';
    return trimmed;
  }
}

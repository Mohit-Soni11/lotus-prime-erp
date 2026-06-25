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
        border: Border.all(color: const Color(0xFFE8E3DA)),
        boxShadow: const [
          BoxShadow(
            color: GirviColors.shadowLight,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
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
                    constraints: const BoxConstraints(minHeight: 246),
                    color: const Color(0xFFE8E3DA),
                  ),
                  SizedBox(width: 390, child: documents),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountIdentity(
    GirviLoanWithCustomer account,
    Color statusColor,
  ) {
    final loan = account.loan;
    final address = _customerAddress(account);
    final principalLabel = _money(account.originalPrincipal);
    final itemLabel =
        '${loan.itemCount} item${loan.itemCount == 1 ? '' : 's'} | ${_weight(loan.netWeight)}';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                    Text(
                      account.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: GirviColors.textDark,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _AccountMetaChip(
                          icon: Icons.phone_rounded,
                          label: account.customerMobile,
                          color: GirviColors.info,
                        ),
                        _AccountMetaChip(
                          icon: Icons.location_on_rounded,
                          label: address,
                          color: GirviColors.textHint,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AccountQuickFact(
                label: 'Principal Amount',
                value: principalLabel,
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
                value: itemLabel,
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
          const SizedBox(height: 14),
          _buildAccountLifecycleOverview(account),
        ],
      ),
    );
  }

  Widget _buildAccountLifecycleOverview(GirviLoanWithCustomer account) {
    final summary = GirviAccountLifecycleSummary.fromAccount(
      account,
      dateLabel: _date,
      dateTimeLabel: _dateTime,
      moneyLabel: _money,
    );

    return _AccountLifecycleRail(
      items: [
        _lifecycleItem(summary.period),
        _lifecycleItem(summary.settlement),
        _lifecycleItem(summary.delivery),
      ],
    );
  }

  _AccountLifecycleItem _lifecycleItem(GirviLifecycleTile tile) {
    return _AccountLifecycleItem(
      icon: _lifecycleIcon(tile.kind),
      title: tile.title,
      value: tile.value,
      subtitle: tile.subtitle,
      color: _lifecycleColor(tile.kind),
    );
  }

  IconData _lifecycleIcon(GirviLifecycleTileKind kind) {
    switch (kind) {
      case GirviLifecycleTileKind.runningPeriod:
      case GirviLifecycleTileKind.closedPeriod:
        return Icons.schedule_rounded;
      case GirviLifecycleTileKind.settlementComplete:
        return Icons.verified_rounded;
      case GirviLifecycleTileKind.settlementPending:
        return Icons.pending_actions_rounded;
      case GirviLifecycleTileKind.deliveryDelivered:
        return Icons.inventory_2_rounded;
      case GirviLifecycleTileKind.deliveryReady:
        return Icons.event_available_rounded;
      case GirviLifecycleTileKind.deliveryPending:
        return Icons.lock_clock_rounded;
    }
  }

  Color _lifecycleColor(GirviLifecycleTileKind kind) {
    switch (kind) {
      case GirviLifecycleTileKind.runningPeriod:
      case GirviLifecycleTileKind.closedPeriod:
      case GirviLifecycleTileKind.deliveryReady:
        return GirviColors.info;
      case GirviLifecycleTileKind.settlementComplete:
      case GirviLifecycleTileKind.deliveryDelivered:
        return GirviColors.success;
      case GirviLifecycleTileKind.settlementPending:
        return GirviColors.warning;
      case GirviLifecycleTileKind.deliveryPending:
        return GirviColors.textBody;
    }
  }

  Widget _buildAccountDocuments(
    GirviLoanWithCustomer account,
    bool actionEnabled,
  ) {
    final balanceCleared =
        GirviAccountLifecycleSummary.isSettlementComplete(account);
    final balanceColor =
        balanceCleared ? GirviColors.success : GirviColors.danger;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _AccountIconBox(
                icon: Icons.folder_copy_rounded,
                color: GirviColors.brandGold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Actions',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: GirviColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Invoice, ledger side and settlement workflow',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textBody,
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: balanceColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: balanceColor.withValues(alpha: 0.16)),
            ),
            child: Row(
              children: [
                Icon(
                  balanceCleared
                      ? Icons.verified_rounded
                      : Icons.pending_actions_rounded,
                  color: balanceColor,
                  size: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    balanceCleared
                        ? 'No payable balance on this account'
                        : 'Net payable ${_money(account.totalPayable)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: GirviColors.textDark,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _AccountDocumentButton(
            icon: Icons.visibility_rounded,
            title: 'View Girvi Invoice',
            subtitle: _openingGirviInvoice
                ? 'Opening...'
                : 'Invoice preview with ledger flip side',
            color: GirviColors.brandGold,
            onTap: _openingGirviInvoice ? null : _previewGirviInvoice,
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
    final totalAmount =
        account.originalPrincipal + account.grossInterestAccrued;
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
                : '${detailedItems.length} pledged item${detailedItems.length == 1 ? '' : 's'} with smart details',
            trailing: _AccountStatusBadge(
              label: 'Principal ${_money(account.originalPrincipal)}',
              color: GirviColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          _PledgedFinancialSummary(
            principal: _money(account.originalPrincipal),
            interest: _money(account.grossInterestAccrued),
            totalAmount: _money(totalAmount),
            itemCount:
                '${loan.itemCount} item${loan.itemCount == 1 ? '' : 's'}',
            netWeight: _weight(loan.netWeight),
          ),
          const SizedBox(height: 14),
          if (detailedItems.isNotEmpty)
            _buildStructuredPledgedItemCards(detailedItems)
          else
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

  Widget _buildStructuredPledgedItemCards(List<GirviLoanItemDetails> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final safeWidth = constraints.maxWidth <= 0
            ? MediaQuery.sizeOf(context).width
            : constraints.maxWidth;
        final useTwoColumns = items.length > 1 && safeWidth >= 940;
        const spacing = 12.0;
        final cardWidth = useTwoColumns ? (safeWidth - spacing) / 2 : safeWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final itemDetails in items)
              SizedBox(
                width: cardWidth,
                child: _PledgedItemDetailRow(
                  serialNo: itemDetails.item.serialNo,
                  itemName: itemDetails.item.itemName,
                  metal: itemDetails.item.metalType,
                  purity: itemDetails.item.purity,
                  pieces: itemDetails.item.pieces,
                  grossWeight: _weight(itemDetails.item.grossWeight),
                  lessWeight: itemDetails.item.lessWeight > 0.001
                      ? _weight(itemDetails.item.lessWeight)
                      : null,
                  netWeight: _weight(itemDetails.item.netWeight),
                  rate: _money(itemDetails.item.ratePerGram, precise: true),
                  value: _money(itemDetails.item.valuationAmount),
                  huid: itemDetails.item.huidNumber,
                  photoPaths: itemDetails.photos
                      .map((photo) => photo.filePath)
                      .toList(growable: false),
                  color: _metalColor(itemDetails.item.metalType),
                ),
              ),
          ],
        );
      },
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

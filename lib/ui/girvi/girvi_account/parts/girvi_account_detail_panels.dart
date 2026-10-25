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
                    constraints: const BoxConstraints(minHeight: 190),
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
          const SizedBox(height: 14),
          _buildAccountStatusOverview(account),
        ],
      ),
    );
  }

  Widget _buildAccountStatusOverview(GirviLoanWithCustomer account) {
    final loan = account.loan;
    if (loan.girviStatus == GirviStatus.auctioned) {
      return _AccountStatusBadge(
        label: switch (_controller.recoveryClosure?.disposition) {
          'MELTED' => 'MELTED · ACCOUNT CLOSED',
          'SOLD' => 'SOLD · ACCOUNT CLOSED',
          _ => 'RECOVERY · ACCOUNT CLOSED',
        },
        color: GirviColors.danger,
      );
    }
    if (loan.girviStatus == GirviStatus.released || loan.deliveredAt != null) {
      return _AccountStatusBadge(
        label: loan.deliveredAt != null
            ? 'DELIVERED · ACCOUNT CLOSED'
            : 'RELEASED · ACCOUNT CLOSED',
        color: GirviColors.statusReleased,
      );
    }

    final settled = GirviAccountLifecycleSummary.isSettlementComplete(account);
    final delivered =
        loan.deliveredAt != null || loan.girviStatus == GirviStatus.released;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _AccountStatusBadge(
          label: settled ? 'Settlement Complete' : 'Payment Pending',
          color: settled ? GirviColors.success : GirviColors.warning,
        ),
        _AccountStatusBadge(
          label: delivered
              ? 'Item Delivered'
              : settled
                  ? 'Ready for Pickup'
                  : 'Delivery Pending',
          color: delivered
              ? GirviColors.success
              : settled
                  ? GirviColors.info
                  : GirviColors.textBody,
        ),
      ],
    );
  }

  Widget _buildFinancialOverview(GirviLoanWithCustomer account) {
    final closure = _controller.recoveryClosure;
    if (account.loan.girviStatus == GirviStatus.auctioned && closure != null) {
      return _buildRecoveryClosureOverview(account, closure);
    }
    final interestQuote = account.interestQuoteAt();
    final principalReceived =
        account.principalPaidTotal + account.legacyPrincipalRepaidTotal;
    final totalReceived = principalReceived + account.interestPaidTotal;
    final totalDiscount =
        account.principalDiscountTotal + account.interestDiscountTotal;
    final amountToCollect = interestQuote.totalPayable;
    final grossTotal = account.originalPrincipal + interestQuote.grossInterest;
    final principalCard = _AccountBalanceCard(
      title: 'Original Principal',
      amount: _money(account.originalPrincipal),
      icon: Icons.account_balance_rounded,
      color: GirviColors.info,
      compact: true,
      note: 'Loan amount at pledge',
    );
    final interestCard = _AccountBalanceCard(
      title: 'Total Interest Accrued',
      amount: _money(interestQuote.grossInterest),
      icon: GirviIcons.interestRate,
      color: GirviColors.warning,
      compact: true,
      note:
          '${interestQuote.interestType} · ${interestQuote.chargeableMonths} chargeable months',
    );
    final grossCard = _AccountBalanceCard(
      title: 'Gross Total',
      amount: _money(grossTotal),
      icon: Icons.calculate_rounded,
      color: GirviColors.textDark,
      compact: true,
      note: 'Principal + interest before payments and discounts',
    );
    final balanceCard = _AccountBalanceCard(
      title: amountToCollect <= 0.01 ? 'Account Settled' : 'Amount to Collect',
      amount: _money(amountToCollect),
      icon: amountToCollect <= 0.01
          ? Icons.verified_rounded
          : Icons.request_quote_rounded,
      color: amountToCollect <= 0.01 ? GirviColors.success : GirviColors.danger,
      note: amountToCollect <= 0.01 ? 'No remaining balance' : null,
      lines: [
        if (interestQuote.principalDue > 0.01)
          _AccountBalanceLine(
              'Principal Due', _money(interestQuote.principalDue)),
        if (interestQuote.interestOutstanding > 0.01)
          _AccountBalanceLine(
            'Interest Due',
            _money(interestQuote.interestOutstanding),
          ),
      ],
    );
    final receivedCard = _AccountBalanceCard(
      title: 'Total Received',
      amount: _money(totalReceived),
      icon: GirviIcons.cash,
      color: GirviColors.success,
      lines: [
        if (account.interestPaidTotal > 0.01)
          _AccountBalanceLine(
            'Interest Received',
            _money(account.interestPaidTotal),
            color: GirviColors.success,
          )
        else if (interestQuote.interestOutstanding > 0.01)
          _AccountBalanceLine(
            'Interest Due',
            _money(interestQuote.interestOutstanding),
            color: GirviColors.danger,
          ),
        if (principalReceived > 0.01)
          _AccountBalanceLine(
            'Principal Received',
            _money(principalReceived),
            color: GirviColors.success,
          )
        else if (interestQuote.principalDue > 0.01)
          _AccountBalanceLine(
            'Principal Due',
            _money(interestQuote.principalDue),
            color: GirviColors.danger,
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final safeWidth = maxWidth <= 0 ? 320.0 : maxWidth;
        final columns = safeWidth >= 960
            ? 3
            : safeWidth >= 680
                ? 2
                : 1;
        const spacing = 12.0;
        final cardWidth = (safeWidth - (columns - 1) * spacing) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 10),
              child: Text(
                'Financial Overview',
                style: GirviStyles.sectionTitle,
              ),
            ),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final card in [principalCard, interestCard, grossCard])
                  SizedBox(width: cardWidth, child: card),
              ],
            ),
            const SizedBox(height: spacing),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final card in [receivedCard, balanceCard])
                  SizedBox(
                    width: (safeWidth - (safeWidth >= 680 ? spacing : 0)) /
                        (safeWidth >= 680 ? 2 : 1),
                    child: card,
                  ),
              ],
            ),
            if (totalDiscount > 0.01 ||
                interestQuote.advanceInterestCredit > 0.01) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (totalDiscount > 0.01)
                    _AccountMetaChip(
                      icon: Icons.local_offer_rounded,
                      label: 'Discount applied ${_money(totalDiscount)}',
                      color: GirviColors.warning,
                    ),
                  if (interestQuote.advanceInterestCredit > 0.01)
                    _AccountMetaChip(
                      icon: Icons.savings_rounded,
                      label:
                          'Advance interest credit ${_money(interestQuote.advanceInterestCredit)}',
                      color: GirviColors.info,
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPledgedItemPanel(GirviLoanWithCustomer account) {
    final loan = account.loan;
    final detailedItems =
        _controller.details?.items ?? const <GirviLoanItemDetails>[];
    final itemCount =
        detailedItems.isEmpty ? loan.itemCount : detailedItems.length;
    return _AccountSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccountSectionHeader(
            icon: GirviIcons.itemDetails,
            color: GirviColors.brandGold,
            title: 'Pledged Item Details',
            subtitle: itemCount > 1 ? '$itemCount pledged items' : null,
          ),
          const SizedBox(height: 14),
          if (detailedItems.isNotEmpty)
            _buildStructuredPledgedItemCards(detailedItems)
          else
            _AccountInfoGrid(
              rows: [
                _AccountInfoRowData('Item Name', loan.itemDescription),
                if (loan.itemCount > 1)
                  _AccountInfoRowData('Item Count', loan.itemCount.toString()),
                _AccountInfoRowData(
                  'Metal / Purity',
                  '${loan.metalTypeEnum.displayName} / ${loan.metalPurity}',
                ),
                if (loan.stoneWeight > 0.001 ||
                    (loan.grossWeight - loan.netWeight).abs() > 0.001)
                  _AccountInfoRowData(
                    'Gross Weight',
                    _weight(loan.grossWeight),
                  ),
                if (loan.stoneWeight > 0.001)
                  _AccountInfoRowData('Less Weight', _weight(loan.stoneWeight)),
                _AccountInfoRowData('Net Weight', _weight(loan.netWeight)),
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
                  showSerial: items.length > 1,
                  serialNo: itemDetails.item.serialNo,
                  itemName: itemDetails.item.itemName,
                  metal: itemDetails.item.metalType,
                  purity: itemDetails.item.purity,
                  pieceLabel: itemDetails.item.pieces > 1
                      ? '${itemDetails.item.pieces} pieces'
                      : null,
                  grossWeight: itemDetails.item.lessWeight > 0.001 ||
                          (itemDetails.item.grossWeight -
                                      itemDetails.item.netWeight)
                                  .abs() >
                              0.001
                      ? _weight(itemDetails.item.grossWeight)
                      : null,
                  lessWeight: itemDetails.item.lessWeight > 0.001
                      ? _weight(itemDetails.item.lessWeight)
                      : null,
                  netWeight: _weight(itemDetails.item.netWeight),
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
    final disbursements =
        _controller.details?.disbursements ?? const <GirviDisbursement>[];
    final closure = _controller.recoveryClosure;
    final loanEnd = closure?.closedAt ?? loan.releaseDate ?? DateTime.now();
    final periodEnd =
        loanEnd.isBefore(loan.startDate) ? loan.startDate : loanEnd;
    final currentPeriod =
        GirviLoanModel.elapsedPeriodBetween(loan.startDate, periodEnd);
    final chargeableMonths =
        GirviLoanModel.chargeableMonthsBetween(loan.startDate, periodEnd);
    final singleDisbursement =
        disbursements.length == 1 ? disbursements.single : null;
    final disbursementLabel = singleDisbursement == null
        ? '${_money(account.originalPrincipal)} via ${loan.disbursementMode.trim().isEmpty ? 'Mode not recorded' : loan.disbursementMode.trim()}'
        : '${_money(singleDisbursement.amount)} via ${singleDisbursement.displayLabel}';
    return _AccountSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AccountSectionHeader(
            icon: GirviIcons.dates,
            color: GirviColors.info,
            title: 'Loan Terms',
            subtitle: 'Amount, dates, interest and disbursement',
          ),
          const SizedBox(height: 14),
          _AccountInfoGrid(
            rows: [
              _AccountInfoRowData(
                'Original Principal',
                _money(account.originalPrincipal),
              ),
              _AccountInfoRowData(
                'Monthly Interest Rate',
                '${loan.interestRate.toStringAsFixed(2)}%',
              ),
              _AccountInfoRowData('Pledge Date', _date(loan.startDate)),
              _AccountInfoRowData('Maturity Date', _date(loan.maturityDate)),
              _AccountInfoRowData(
                'Original Loan Period',
                '${loan.durationMonths} month${loan.durationMonths == 1 ? '' : 's'}',
              ),
              _AccountInfoRowData(
                closure == null && loan.releaseDate == null
                    ? 'Current Loan Period'
                    : 'Loan Period at Settlement',
                currentPeriod.displayLabel,
              ),
              _AccountInfoRowData('Chargeable Months', '$chargeableMonths'),
              if (closure == null && account.netInterestDue > 0.01)
                _AccountInfoRowData(
                  'Unpaid Interest Period',
                  loan.unpaidInterestElapsedPeriod.displayLabel,
                ),
              if (loan.lastInterestPaidDate != null)
                _AccountInfoRowData(
                  'Interest Paid Through',
                  _date(loan.lastInterestPaidDate),
                ),
              if (disbursements.length <= 1)
                _AccountInfoRowData('Disbursed', disbursementLabel),
              if (singleDisbursement?.referenceNo?.trim().isNotEmpty ?? false)
                _AccountInfoRowData(
                  'Disbursement Reference',
                  singleDisbursement!.referenceNo!.trim(),
                ),
              if (loan.deliveredAt != null)
                _AccountInfoRowData(
                    'Delivered On', _dateTime(loan.deliveredAt)),
              if (loan.deliveredAt == null && loan.expectedDeliveryDate != null)
                _AccountInfoRowData(
                  'Expected Pickup Date',
                  _date(loan.expectedDeliveryDate),
                ),
              if ((loan.notes ?? '').trim().isNotEmpty)
                _AccountInfoRowData('Notes', loan.notes!.trim()),
            ],
          ),
          if (disbursements.length > 1) ...[
            const SizedBox(height: 16),
            _buildDisbursementBreakdown(disbursements),
          ],
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
}

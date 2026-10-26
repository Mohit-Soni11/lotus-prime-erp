part of 'customer_profile_screen.dart';

extension _ProfileOverviewSections on _CustomerProfileScreenState {
  Widget _buildHeroCard(CustomerProfileModel p) {
    final isFemale = p.isFemale;
    final Color avatarBg =
        isFemale ? const Color(0xFFFCE4EC) : CustomerProfileColors.brandGoldBg;
    final Color avatarBorder =
        isFemale ? const Color(0xFFF48FB1) : CustomerProfileColors.brandGold;
    final Color initialsColor =
        isFemale ? const Color(0xFFE91E63) : CustomerProfileColors.brandGold;
    final Color genderIconColor =
        isFemale ? const Color(0xFFE91E63) : const Color(0xFF1565C0);
    final IconData genderIcon =
        isFemale ? Icons.female_rounded : Icons.male_rounded;

    return Container(
      decoration: CustomerProfileStyles.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: avatarBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: avatarBorder, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: avatarBorder.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  p.initials,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: initialsColor,
                  ),
                ),
              ),
              if (p.gender == CustomerGender.male ||
                  p.gender == CustomerGender.female)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: genderIconColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(genderIcon, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.name,
                        style: CustomerProfileStyles.customerName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTypeBadge(p),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(CustomerProfileIcons.phone,
                        size: 13, color: CustomerProfileColors.bodyTextMuted),
                    const SizedBox(width: 4),
                    Text(p.mobile, style: CustomerProfileStyles.customerMobile),
                    const SizedBox(width: 12),
                    if (p.city.isNotEmpty) ...[
                      const Icon(CustomerProfileIcons.city,
                          size: 13, color: CustomerProfileColors.bodyTextMuted),
                      const SizedBox(width: 4),
                      Text(p.city, style: CustomerProfileStyles.customerMobile),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildAccountStatusBadge(p.accountStatus),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF81C784)),
                      ),
                      child: Text(
                        "Since ${p.formattedMemberSince}",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
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

  // 2. ACTION BUTTONS
  Widget _buildActionButtons(CustomerProfileModel p) {
    return Row(
      children: [
        Expanded(
          child: CustomerProfileActionBtn(
            icon: CustomerProfileIcons.newSale,
            label: CustomerProfileStrings.btnNewSale,
            bg: CustomerProfileColors.newSaleBg,
            fg: CustomerProfileColors.newSaleText,
            border: CustomerProfileColors.newSaleBg,
            filled: true,
            onTap: () => widget.onNewSale?.call(p.id),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomerProfileActionBtn(
            icon: CustomerProfileIcons.edit,
            label: CustomerProfileStrings.btnEdit,
            bg: CustomerProfileColors.editBg,
            fg: CustomerProfileColors.editText,
            border: CustomerProfileColors.editBorder,
            onTap: () => _openCustomerEditor(p),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomerProfileActionBtn(
            icon: CustomerProfileIcons.billHistory,
            label: CustomerProfileStrings.btnHistory,
            bg: CustomerProfileColors.historyBg,
            fg: CustomerProfileColors.historyText,
            border: CustomerProfileColors.historyBorder,
            onTap: () {
              _scrollCtrl.animateTo(
                _scrollCtrl.position.maxScrollExtent,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
              );
              _tabCtrl.animateTo(0);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomerProfileActionBtn(
            icon: CustomerProfileIcons.delete,
            label: CustomerProfileStrings.btnDelete,
            bg: CustomerProfileColors.deleteBg,
            fg: CustomerProfileColors.deleteText,
            border: CustomerProfileColors.deleteBorder,
            onTap: () => _showDeleteDialog(p),
          ),
        ),
      ],
    );
  }

  // 3. STATS OVERVIEW
  Widget _buildStatsOverview(CustomerProfileModel p) {
    return Container(
      decoration: CustomerProfileStyles.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.analytics_rounded,
            title: "Customer Portfolio Overview",
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomerProfileStatBox(
                  label: "Sales Bills",
                  value: p.totalBills.toString(),
                  icon: CustomerProfileIcons.invoice,
                  color: CustomerProfileColors.brandGold,
                  sub: "Total \u20B9${_fmt(p.totalBillAmount)}",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomerProfileStatBox(
                  label: "Settled Bills",
                  value: p.paidBillsCount.toString(),
                  icon: CustomerProfileIcons.clear,
                  color: const Color(0xFF10B981),
                  sub: "Paid \u20B9${_fmt(p.totalPaidAmount)}",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomerProfileStatBox(
                  label: "Due Bills",
                  value: p.unpaidBillsCount.toString(),
                  icon: CustomerProfileIcons.dueBills,
                  color: const Color(0xFFF59E0B),
                  sub: "Due \u20B9${_fmt(p.totalDueAmount)}",
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CustomerProfileStatBox(
                  label: "Girvi Tickets",
                  value: p.totalLoans.toString(),
                  icon: Icons.lock_outline_rounded,
                  color: const Color(0xFF7C3AED),
                  sub: "Principal \u20B9${_fmt(p.totalLoanAmount)}",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomerProfileStatBox(
                  label: "Active Girvi",
                  value: p.activeLoans.toString(),
                  icon: Icons.lock_rounded,
                  color: const Color(0xFFEF4444),
                  sub: "Balance \u20B9${_fmt(p.totalActiveLoanAmount)}",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomerProfileStatBox(
                  label: "Advance Orders",
                  value: p.activeAdvanceCount.toString(),
                  icon: CustomerProfileIcons.advanceOrder,
                  color: CustomerProfileColors.advanceAccent,
                  sub: "Advance \u20B9${_fmt(p.totalAdvancePaid)}",
                ),
              ),
            ],
          ),
          if (p.accountCreditBalance > 0.005) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  width: 1.4,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 20,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Customer Account Credit",
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    "\u20B9${_fmt(p.accountCreditBalance)}",
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactCard(CustomerProfileModel p) {
    return Container(
      decoration: CustomerProfileStyles.cardDecoration,
      padding: CustomerProfileStyles.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: CustomerProfileIcons.phone,
            title: CustomerProfileStrings.secContact,
            color: CustomerProfileColors.brandGold,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _infoRow(
                    CustomerProfileIcons.phone,
                    CustomerProfileStrings.lblMobile,
                    p.mobile.isEmpty ? CustomerProfileStrings.lblNa : p.mobile),
              ),
              Expanded(
                child: _infoRow(
                    CustomerProfileIcons.city,
                    CustomerProfileStrings.lblCity,
                    p.city.isEmpty ? CustomerProfileStrings.lblNa : p.city),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoRow(CustomerProfileIcons.calendar,
                    CustomerProfileStrings.lblSince, p.formattedMemberSince),
              ),
              Expanded(
                child: _infoRow(CustomerProfileIcons.type,
                    CustomerProfileStrings.lblType, p.type),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSnapshotCard(CustomerProfileModel p) {
    return Container(
      decoration: CustomerProfileStyles.cardDecoration,
      padding: CustomerProfileStyles.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionHeader(
                  icon: Icons.account_balance_wallet_rounded,
                  title: CustomerProfileStrings.secAccountSnapshot,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              GestureDetector(
                onTap: _logic.editingDueLimit
                    ? _logic.cancelEditDueLimit
                    : _logic.startEditDueLimit,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CustomerProfileColors.brandGoldBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CustomerProfileColors.brandGold
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _logic.editingDueLimit
                            ? Icons.close_rounded
                            : CustomerProfileIcons.editLimit,
                        color: CustomerProfileColors.brandGold,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _logic.editingDueLimit ? "Cancel" : "Update Due Limit",
                        style: const TextStyle(
                          color: CustomerProfileColors.brandGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_logic.editingDueLimit) ...[
            _buildDueLimitEdit(p),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _ledgerSummaryBox(
                  title: "Due Ledger",
                  primaryLabel: CustomerProfileStrings.lblDueTotal,
                  primaryValue: "\u20B9${_fmt(p.totalDueAmount)}",
                  secondaryLabel: CustomerProfileStrings.lblDueBillValue,
                  secondaryValue: "\u20B9${_fmt(p.totalDueBillAmount)}",
                  tertiaryLabel: CustomerProfileStrings.lblDueLimit,
                  tertiaryValue: "\u20B9${_fmt(p.dueLimit)}",
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFFEA580C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ledgerSummaryBox(
                  title: "Girvi Ledger",
                  primaryLabel: CustomerProfileStrings.lblGirviBalance,
                  primaryValue: "\u20B9${_fmt(p.totalActiveLoanAmount)}",
                  secondaryLabel: CustomerProfileStrings.lblGirviTotal,
                  secondaryValue: "\u20B9${_fmt(p.totalLoanAmount)}",
                  tertiaryLabel: "Active Tickets",
                  tertiaryValue: p.activeLoans.toString(),
                  icon: Icons.lock_rounded,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ledgerSummaryBox(
                  title: "Interest Ledger",
                  primaryLabel: CustomerProfileStrings.lblInterestAccrued,
                  primaryValue: "\u20B9${_fmt(p.totalInterestAccrued)}",
                  secondaryLabel: CustomerProfileStrings.lblInterestBase,
                  secondaryValue: "\u20B9${_fmt(p.totalActiveLoanAmount)}",
                  tertiaryLabel: CustomerProfileStrings.lblGirviReceivable,
                  tertiaryValue: "\u20B9${_fmt(p.totalGirviReceivable)}",
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF0F766E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

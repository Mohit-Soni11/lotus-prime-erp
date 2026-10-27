part of 'customer_profile_screen.dart';

extension _ProfileOverviewSections on _CustomerProfileScreenState {
  Widget _buildHeroCard(CustomerProfileModel profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: CustomerProfileStyles.cardDecoration,
      child: Wrap(
        spacing: 16,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CustomerProfileColors.brandGoldBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CustomerProfileColors.brandGold),
            ),
            child: Text(profile.initials,
                style: CustomerProfileStyles.customerName),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(spacing: 10, runSpacing: 7, children: [
                Text(profile.name, style: CustomerProfileStyles.customerName),
                _buildTypeBadge(profile),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 15, runSpacing: 6, children: [
                Text(
                    profile.mobile.isEmpty
                        ? 'Mobile not added'
                        : profile.mobile,
                    style: CustomerProfileStyles.customerMobile),
                Text('Customer since ${profile.formattedMemberSince}',
                    style: CustomerProfileStyles.customerMobile),
                if (profile.formattedAddress != null)
                  Text(profile.formattedAddress!,
                      style: CustomerProfileStyles.customerMobile),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CustomerProfileModel profile) {
    final actions = <Widget>[
      CustomerProfileActionBtn(
        icon: CustomerProfileIcons.newSale,
        label: CustomerProfileStrings.btnNewSale,
        bg: CustomerProfileColors.newSaleBg,
        fg: CustomerProfileColors.newSaleText,
        border: CustomerProfileColors.newSaleBg,
        filled: true,
        onTap: () => widget.onNewSale?.call(profile.id),
      ),
      CustomerProfileActionBtn(
        icon: CustomerProfileIcons.edit,
        label: CustomerProfileStrings.btnEdit,
        bg: CustomerProfileColors.editBg,
        fg: CustomerProfileColors.bodyTextMain,
        border: CustomerProfileColors.editBorder,
        onTap: () => _openCustomerEditor(profile),
      ),
      CustomerProfileActionBtn(
        icon: CustomerProfileIcons.billHistory,
        label: CustomerProfileStrings.btnHistory,
        bg: CustomerProfileColors.historyBg,
        fg: CustomerProfileColors.bodyTextMain,
        border: CustomerProfileColors.historyBorder,
        onTap: () {
          final historyContext = _historyKey.currentContext;
          if (historyContext == null) return;
          Scrollable.ensureVisible(historyContext,
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              alignment: 0.06);
          _tabCtrl.animateTo(0);
        },
      ),
      CustomerProfileActionBtn(
        icon: CustomerProfileIcons.delete,
        label: CustomerProfileStrings.btnDelete,
        bg: CustomerProfileColors.deleteBg,
        fg: CustomerProfileColors.bodyTextMain,
        border: CustomerProfileColors.deleteBorder,
        onTap: () => _showDeleteDialog(profile),
      ),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 740
          ? 4
          : constraints.maxWidth >= 420
              ? 2
              : 1;
      final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
      return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: actions
              .map((action) => SizedBox(width: width, child: action))
              .toList());
    });
  }

  Widget _buildStatsOverview(CustomerProfileModel profile) {
    final cards = <Widget>[
      CustomerProfileMetricCard(
        label: 'Total Sales Bills',
        value: '${profile.totalBills}',
        icon: CustomerProfileIcons.invoice,
        accent: const Color(0xFF2563EB),
        detail: 'Sales value ₹${_fmt(profile.totalBillAmount)}',
      ),
      if (profile.dueInvoiceCount > 0)
        CustomerProfileMetricCard(
          label: 'Due Invoices',
          value: '${profile.dueInvoiceCount}',
          icon: CustomerProfileIcons.dueBills,
          accent: const Color(0xFFDC2626),
          detail: 'Outstanding ₹${_fmt(profile.totalDueAmount)}',
        ),
      if (profile.totalLoans > 0)
        CustomerProfileMetricCard(
          label: 'Girvi Tickets',
          value: '${profile.totalLoans}',
          icon: Icons.lock_outline_rounded,
          accent: const Color(0xFF7C3AED),
          detail: 'Capital given ₹${_fmt(profile.totalLoanAmount)}',
        ),
      if (profile.activeLoans > 0)
        CustomerProfileMetricCard(
          label: 'Active Girvi',
          value: '${profile.activeLoans}',
          icon: Icons.lock_rounded,
          accent: const Color(0xFF7C3AED),
          detail: 'Active capital ₹${_fmt(profile.totalActiveLoanAmount)}',
        ),
      if (profile.activeAdvanceCount > 0)
        CustomerProfileMetricCard(
          label: 'Open Advance Orders',
          value: '${profile.activeAdvanceCount}',
          icon: CustomerProfileIcons.advanceOrder,
          accent: CustomerProfileColors.advanceAccent,
          detail: 'Advance paid ₹${_fmt(profile.totalAdvancePaid)}',
        ),
    ];
    return _buildSectionCard(
      icon: Icons.analytics_outlined,
      title: 'Customer Portfolio',
      child: _responsiveCards(cards, minWidth: 220),
    );
  }

  Widget _buildContactCard(CustomerProfileModel profile) {
    final address = profile.formattedAddress;
    return _buildSectionCard(
      icon: Icons.contact_phone_outlined,
      title: CustomerProfileStrings.secContact,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _infoRow(CustomerProfileIcons.phone, 'Mobile',
            profile.mobile.isEmpty ? 'Not added' : profile.mobile),
        if (profile.whatsapp.trim().isNotEmpty)
          _infoRow(CustomerProfileIcons.phone, 'WhatsApp', profile.whatsapp),
        _infoRow(Icons.location_on_outlined, 'Full Address',
            address ?? 'Address not added'),
        _infoRow(CustomerProfileIcons.calendar, 'Customer Since',
            profile.formattedMemberSince),
        _infoRow(CustomerProfileIcons.type, 'Customer Category',
            '${profile.customerTier.displayLabel} Customer'),
      ]),
    );
  }

  Widget _buildAccountSnapshotCard(CustomerProfileModel profile) {
    final cards = <Widget>[
      if (profile.totalDueAmount > 0)
        CustomerProfileLedgerCard(
          title: 'Due Ledger',
          icon: Icons.receipt_long_outlined,
          accent: const Color(0xFFDC2626),
          metrics: [
            ('Total Due Amount', '₹${_fmt(profile.totalDueAmount)}'),
            ('Due Invoices', '${profile.dues.length}'),
            ('Due Invoice Value', '₹${_fmt(profile.totalDueBillAmount)}'),
          ],
        ),
      if (profile.totalLoans > 0)
        CustomerProfileLedgerCard(
          title: 'Girvi Ledger',
          icon: Icons.lock_outline_rounded,
          accent: const Color(0xFF7C3AED),
          metrics: [
            ('Total Capital Given', '₹${_fmt(profile.totalLoanAmount)}'),
            ('Active Capital', '₹${_fmt(profile.totalActiveLoanAmount)}'),
            ('Girvi Tickets', '${profile.totalLoans}'),
            ('Active Tickets', '${profile.activeLoans}'),
          ],
        ),
      if (profile.activeLoans > 0)
        CustomerProfileLedgerCard(
          title: 'Interest Ledger',
          icon: Icons.trending_up_rounded,
          accent: const Color(0xFF0F766E),
          metrics: [
            ('Active Interest Due', '₹${_fmt(profile.totalInterestAccrued)}'),
            ('Active Girvi Invoices', '${profile.activeLoans}'),
            ('Capital + Interest', '₹${_fmt(profile.totalGirviReceivable)}'),
          ],
        ),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();
    return _buildSectionCard(
      icon: Icons.account_balance_wallet_outlined,
      title: CustomerProfileStrings.secAccountSnapshot,
      child: _responsiveCards(cards, minWidth: 270),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: CustomerProfileStyles.cardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(
            icon: icon, title: title, color: CustomerProfileColors.brandGold),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }

  Widget _responsiveCards(List<Widget> cards, {required double minWidth}) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = ((constraints.maxWidth + 12) / (minWidth + 12))
          .floor()
          .clamp(1, cards.length);
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList());
    });
  }
}

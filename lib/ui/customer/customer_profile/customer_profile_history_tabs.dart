part of 'customer_profile_screen.dart';

enum _CustomerHistorySection { sales, due, girvi, advances }

extension _ProfileHistoryTabs on _CustomerProfileScreenState {
  List<_CustomerHistorySection> _visibleHistorySections(
    CustomerProfileModel profile,
  ) =>
      [
        if (profile.bills.isNotEmpty) _CustomerHistorySection.sales,
        if (profile.dues.isNotEmpty) _CustomerHistorySection.due,
        if (profile.loans.any((loan) => loan.isActive))
          _CustomerHistorySection.girvi,
        if (profile.advanceOrders
            .any((order) => order.isPending || order.isReady))
          _CustomerHistorySection.advances,
      ];

  void _selectFirstHistoryTab() {
    final historyContext = _historyKey.currentContext;
    if (historyContext == null) return;
    DefaultTabController.maybeOf(historyContext)?.animateTo(0);
  }

  Widget _buildHistoryTabs(CustomerProfileModel profile) {
    final sections = _visibleHistorySections(profile);
    final content = Container(
      key: _historyKey,
      decoration: CustomerProfileStyles.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Text(
              'Invoice History',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: CustomerProfileColors.bodyTextMain,
              ),
            ),
          ),
          if (sections.isEmpty)
            SizedBox(
              height: 220,
              child: _emptyState(
                icon: CustomerProfileIcons.emptyBills,
                title: 'No account activity yet',
                sub: 'Sales, Girvi and advance records will appear here.',
              ),
            )
          else ...[
            Container(
              color: CustomerProfileColors.bodyPanelBg,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                labelColor: CustomerProfileColors.bodyTextMain,
                unselectedLabelColor: CustomerProfileColors.bodyTextMain,
                indicatorColor: CustomerProfileColors.brandGold,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                tabs: sections
                    .map((section) => _historyTab(section, profile))
                    .toList(growable: false),
              ),
            ),
            SizedBox(
              height: 480,
              child: TabBarView(
                children: sections
                    .map((section) => switch (section) {
                          _CustomerHistorySection.sales =>
                            _buildBillsList(profile),
                          _CustomerHistorySection.due =>
                            _buildBillsList(profile, dueOnly: true),
                          _CustomerHistorySection.girvi =>
                            _buildGirviList(profile),
                          _CustomerHistorySection.advances =>
                            _buildAdvanceList(profile),
                        })
                    .toList(growable: false),
              ),
            ),
          ],
        ],
      ),
    );
    if (sections.isEmpty) return content;
    return DefaultTabController(
      key: ValueKey(sections.map((section) => section.name).join('|')),
      length: sections.length,
      child: content,
    );
  }

  Widget _historyTab(
    _CustomerHistorySection section,
    CustomerProfileModel profile,
  ) {
    final (icon, title, count, accent) = switch (section) {
      _CustomerHistorySection.sales => (
          CustomerProfileIcons.invoice,
          'Sales Bills',
          profile.bills.length,
          const Color(0xFF2563EB),
        ),
      _CustomerHistorySection.due => (
          CustomerProfileIcons.dueBills,
          'Due Bills',
          profile.dues.length,
          const Color(0xFFDC2626),
        ),
      _CustomerHistorySection.girvi => (
          Icons.lock_rounded,
          'Active Girvi',
          profile.loans.where((loan) => loan.isActive).length,
          const Color(0xFF7C3AED),
        ),
      _CustomerHistorySection.advances => (
          CustomerProfileIcons.advanceOrder,
          'Active Advances',
          profile.advanceOrders
              .where((order) => order.isPending || order.isReady)
              .length,
          CustomerProfileColors.advanceAccent,
        ),
    };
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: const TextStyle(
              color: CustomerProfileColors.bodyTextMain,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

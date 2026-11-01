part of 'supplier_profile_screen.dart';

extension _SupplierProfileHistorySections on _SupplierProfileScreenState {
  Widget _buildHistoryTabs(SupplierProfileModel profile) {
    return Container(
      decoration: SupplierProfileStyles.cardDecoration,
      padding: SupplierProfileStyles.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Stock Batches & Purchases',
            'Supplier batches and their purchase records',
            SupplierProfileIcons.purchases,
            SupplierProfileColors.info,
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: SupplierProfileColors.bodyBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SupplierProfileColors.bodyBorder),
              ),
              child: TabBar(
                controller: _tabCtrl,
                onTap: _logic.setTab,
                isScrollable: false,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: SupplierProfileColors.brandGoldBg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: SupplierProfileColors.brandGold),
                ),
                indicatorPadding: const EdgeInsets.all(4),
                dividerColor: Colors.transparent,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black,
                labelStyle: SupplierProfileStyles.chipText,
                unselectedLabelStyle: SupplierProfileStyles.chipText,
                tabs: const [
                  Tab(text: 'Stock Batches'),
                  Tab(text: 'Purchase Bills'),
                  Tab(text: SupplierProfileStrings.secDocuments),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (_logic.activeTab) {
              1 => _buildPurchaseList(profile),
              2 => _buildDocumentsList(profile),
              _ => _buildBatchList(profile),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseList(SupplierProfileModel profile) {
    return _buildPurchaseListFor(
      items: profile.purchases,
      emptyTitle: SupplierProfileStrings.noPurchases,
      emptySubtitle: SupplierProfileStrings.noPurchasesSub,
      keyValue: 'purchase-list',
    );
  }

  Widget _buildPurchaseListFor({
    required List<SupplierProfilePurchaseModel> items,
    required String emptyTitle,
    required String emptySubtitle,
    required String keyValue,
  }) {
    if (items.isEmpty) {
      return _EmptyState(
        key: ValueKey('$keyValue-empty'),
        icon: SupplierProfileIcons.empty,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    return Column(
      key: ValueKey(keyValue),
      children: [
        for (final item in items) ...[
          _PurchaseHistoryCard(item: item),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildBatchList(SupplierProfileModel profile) {
    if (profile.batches.isEmpty) {
      return const _EmptyState(
        key: ValueKey('batch-empty'),
        icon: SupplierProfileIcons.inventory,
        title: 'No stock batches yet',
        subtitle: 'Saved supplier stock batches will appear here.',
      );
    }
    return Column(
      key: const ValueKey('batch-list'),
      children: [
        for (final batch in profile.batches) ...[
          _SupplierBatchCard(batch: batch),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildDocumentsList(SupplierProfileModel profile) {
    final items = profile.billDocuments;
    if (items.isEmpty) {
      return const _EmptyState(
        key: ValueKey('docs-empty'),
        icon: SupplierProfileIcons.photo,
        title: SupplierProfileStrings.noDocuments,
        subtitle: SupplierProfileStrings.noDocumentsSub,
      );
    }
    return Column(
      key: const ValueKey('docs-list'),
      children: [
        for (final item in items) ...[
          _BillDocumentCard(item: item),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

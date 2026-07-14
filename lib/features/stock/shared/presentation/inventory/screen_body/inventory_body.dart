part of '../inventory_screen.dart';

extension _InventoryBody on _InventoryScreenState {
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: InvColors.brandGold,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          Text('Loading inventory data...', style: InvStyles.pageSubtitle),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final showLedger = _selectedMetal != null;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // â”€â”€ Page Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _animated(0, _buildPageHeader()),
                const SizedBox(height: 24),
                _animated(
                  1,
                  InventoryMetalSummaryGrid(
                    stats: _ctrl.stats,
                    selectedMetal: _selectedMetal,
                    onMetalSelected: _openMetalLedger,
                  ),
                ),
                if (showLedger) ...[
                  const SizedBox(height: 24),

                  // â”€â”€ Summary Cards Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  _animated(1, _buildSummaryCards()),
                  const SizedBox(height: 20),

                  // â”€â”€ Metal Holdings Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  _animated(2, _buildMetalHoldingsCard()),
                  const SizedBox(height: 24),
                  _animated(3, _buildMovementLedgerPanel()),
                  const SizedBox(height: 24),

                  // â”€â”€ Section Label + Filter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  _animated(4, _buildSectionHeader()),
                  const SizedBox(height: 12),
                  _animated(4, _buildCategoryFilter()),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),

        // â”€â”€ Stock Items List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (showLedger)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            sliver: SliverToBoxAdapter(child: _animated(5, _buildStockList())),
          )
        else
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 32),
          ),
      ],
    );
  }
}

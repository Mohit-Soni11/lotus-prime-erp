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
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _animated(0, _buildPageHeader()),
                const SizedBox(height: 24),
                _animated(
                  1,
                  InventoryMetalSummaryGrid(
                    stats: _ctrl.stats,
                    selectedMetal: null,
                    onMetalSelected: _openMetalLedger,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }
}

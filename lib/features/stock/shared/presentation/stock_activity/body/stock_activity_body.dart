part of '../stock_activity_screen.dart';

class _StockActivityBody extends StatefulWidget {
  final StockActivityController controller;

  const _StockActivityBody({required this.controller});

  @override
  State<_StockActivityBody> createState() => _StockActivityBodyState();
}

class _StockActivityBodyState extends State<_StockActivityBody> {
  late final TextEditingController _searchController;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 320), () {
      widget.controller.setSearchText(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StockActivityHero(summary: controller.summary),
              const SizedBox(height: 18),
              _SummaryGrid(summary: controller.summary),
              const SizedBox(height: 18),
              _MetalMovementSnapshot(metals: controller.metalSummaries),
              const SizedBox(height: 18),
              _FilterPanel(
                controller: controller,
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
              ),
              const SizedBox(height: 18),
              _ActivityPanel(
                records: controller.records,
                isLoading: controller.isLoading,
                errorMessage: controller.errorMessage,
              ),
            ],
          ),
        ),
        if (controller.isLoading && controller.records.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: InvColors.bodyBg.withValues(alpha: 0.35),
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 12),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StockActivityHero extends StatelessWidget {
  final StockActivitySummary summary;

  const _StockActivityHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFFF2B8), Color(0xFFD8B12E)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: InvColors.brandGold.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
            ),
            child: const Icon(
              Icons.timeline_rounded,
              color: Color(0xFF7A5400),
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock Activity Ledger',
                  style: GoogleFonts.manrope(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2B1F05),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Track every stock add, POS sale, restore and source document movement in one professional ledger.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4C3A12),
                  ),
                ),
              ],
            ),
          ),
          _HeroMetric(
            label: 'Movements',
            value: summary.totalMovements.toString(),
          ),
          const SizedBox(width: 12),
          _HeroMetric(
            label: 'Sold',
            value: '${summary.stockSold} pcs',
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final StockActivitySummary summary;

  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _ActivityMetricCard(
          title: 'Stock Added',
          value: '${summary.stockAdded} pcs',
          subtitle: '${_weight(summary.addedWeight)} weight',
          icon: Icons.add_business_rounded,
          accent: InvColors.success,
          background: InvColors.successBg,
        ),
        _ActivityMetricCard(
          title: 'Stock Sold',
          value: '${summary.stockSold} pcs',
          subtitle: '${_weight(summary.soldWeight)} weight',
          icon: Icons.point_of_sale_rounded,
          accent: InvColors.danger,
          background: InvColors.dangerBg,
        ),
        _ActivityMetricCard(
          title: 'Stock Restored',
          value: '${summary.stockRestored} pcs',
          subtitle: 'Sale return or restore',
          icon: Icons.restore_rounded,
          accent: const Color(0xFF2563EB),
          background: const Color(0x142563EB),
        ),
        _ActivityMetricCard(
          title: 'Ledger Records',
          value: summary.totalMovements.toString(),
          subtitle: 'Filtered activity rows',
          icon: Icons.receipt_long_rounded,
          accent: InvColors.brandGold,
          background: InvColors.brandGoldLight,
        ),
      ],
    );
  }
}

class _MetalMovementSnapshot extends StatelessWidget {
  final List<StockMetalActivitySummary> metals;

  const _MetalMovementSnapshot({required this.metals});

  @override
  Widget build(BuildContext context) {
    return _ActivitySurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _SectionIcon(
                  Icons.account_tree_rounded, InvColors.brandGold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Metal Movement Snapshot', style: _titleText(18)),
                    const SizedBox(height: 2),
                    Text(
                      'Metal-wise inward, outward and restored stock movement.',
                      style: _mutedText(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (metals.isEmpty)
            const _EmptyMetalMovementState()
          else
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: metals
                  .map((metal) => _MetalMovementCard(summary: metal))
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final StockActivityController controller;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const _FilterPanel({
    required this.controller,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ActivitySurface(
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _SearchField(
              controller: searchController,
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: _DropdownFilter(
              label: 'Movement',
              value: controller.movementFilter,
              values: StockActivityController.movementFilters,
              onChanged: controller.setMovementFilter,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: _DropdownFilter(
              label: 'Metal',
              value: controller.metalFilter,
              values: StockActivityController.metalFilters,
              onChanged: controller.setMetalFilter,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  final List<StockActivityRecord> records;
  final bool isLoading;
  final String? errorMessage;

  const _ActivityPanel({
    required this.records,
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return _ActivitySurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              children: [
                const _SectionIcon(Icons.timeline_rounded, InvColors.brandGold),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Movement Timeline', style: _titleText(18)),
                      const SizedBox(height: 2),
                      Text(
                        'Latest purchase, sale and restore activity from stock movements.',
                        style: _mutedText(),
                      ),
                    ],
                  ),
                ),
                _SoftBadge('${records.length} records'),
              ],
            ),
          ),
          const Divider(height: 1, color: InvColors.divider),
          if (isLoading && records.isEmpty)
            const _LoadingPanel()
          else if (errorMessage != null)
            _EmptyPanel(
              icon: Icons.error_outline_rounded,
              title: 'Activity could not be loaded',
              subtitle: errorMessage!,
            )
          else if (records.isEmpty)
            const _EmptyPanel(
              icon: Icons.inventory_2_outlined,
              title: 'No Stock Activity Yet',
              subtitle:
                  'Stock movements will appear here after purchase, sale or restore actions.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                return _ActivityRecordCard(record: records[index]);
              },
            ),
        ],
      ),
    );
  }
}

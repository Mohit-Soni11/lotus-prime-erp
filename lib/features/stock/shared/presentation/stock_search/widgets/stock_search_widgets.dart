part of '../stock_search_screen.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: 'Rs ',
  decimalDigits: 0,
);

final _dateFormat = DateFormat('dd MMM yyyy');
final _timeFormat = DateFormat('hh:mm a');

class _SearchHero extends StatelessWidget {
  final StockSearchSummary summary;

  const _SearchHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFFF4C4), Color(0xFFD8B12C)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: InvColors.shadowLight,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const _HeroIcon(icon: Icons.manage_search_rounded),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock Search Center',
                  style: GoogleFonts.manrope(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2B2106),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Search HUID, unit code, batch, item, supplier, invoice or weight from one professional inventory desk.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5D4A15),
                  ),
                ),
              ],
            ),
          ),
          _HeroMetric(
              label: 'Available', value: '${summary.availableUnits} pcs'),
          const SizedBox(width: 12),
          _HeroMetric(label: 'Total Weight', value: _grams(summary.netWeight)),
          const SizedBox(width: 12),
          _HeroMetric(
            label: 'Available Weight',
            value: _grams(summary.availableWeight),
          ),
          const SizedBox(width: 12),
          _HeroMetric(
            label: 'Sold Weight',
            value: _grams(summary.soldWeight),
          ),
        ],
      ),
    );
  }
}

class _SearchFilterPanel extends StatelessWidget {
  final StockSearchController controller;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const _SearchFilterPanel({
    required this.controller,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: InvStyles.cardDecoration,
      child: LayoutBuilder(builder: (context, constraints) {
        final searchField = TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: InvColors.textDark,
          ),
          decoration: _inputDecoration(
            icon: Icons.search_rounded,
            hint: 'Search HUID, item, batch, weight, supplier or invoice',
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            searchField,
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _FilterDropdown(
                  value: controller.statusFilter,
                  values: StockSearchController.statusFilters,
                  labelFor: StockSearchController.statusFilterLabel,
                  width: 170,
                  onChanged: controller.setStatusFilter,
                ),
                _FilterDropdown(
                  value: controller.metalFilter,
                  values: StockSearchController.metalFilters,
                  labelFor: StockSearchController.metalFilterLabel,
                  width: 160,
                  onChanged: controller.setMetalFilter,
                ),
                _FilterDropdown(
                  value: controller.trackingFilter,
                  values: StockSearchController.trackingFilters,
                  labelFor: StockSearchController.trackingFilterLabel,
                  width: 190,
                  onChanged: controller.setTrackingFilter,
                ),
                _FilterDropdown(
                  value: controller.sortMode,
                  values: StockSearchController.sortModes,
                  labelFor: (value) => value,
                  width: 170,
                  onChanged: controller.setSortMode,
                ),
                _ClearSearchButton(
                  enabled: controller.hasActiveFilters,
                  onTap: controller.clearFilters,
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _SearchResultsPanel extends StatelessWidget {
  final StockSearchController controller;

  const _SearchResultsPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: InvStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                const _SectionIcon(icon: Icons.inventory_2_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Search Results',
                          style: InvStyles.sectionTitle.copyWith(fontSize: 17)),
                      const SizedBox(height: 2),
                      Text(
                        'Live stock units with batch, supplier, value and tracking status.',
                        style: InvStyles.pageSubtitle
                            .copyWith(color: InvColors.textBody),
                      ),
                    ],
                  ),
                ),
                _ResultCount(count: controller.results.length),
              ],
            ),
          ),
          const Divider(height: 1, color: InvColors.divider),
          if (controller.isLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.errorMessage != null)
            _EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Search Failed',
              message: controller.errorMessage!,
            )
          else if (controller.results.isEmpty)
            const _EmptyState(
              icon: Icons.manage_search_rounded,
              title: 'No Stock Found',
              message:
                  'Try another HUID, batch, item name, supplier, invoice or weight.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: controller.results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = controller.results[index];
                return _StockSearchCard(
                  item: item,
                  onTap: () => _showStockDetail(
                    context,
                    item,
                    onChanged: controller.load,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StockSearchCard extends StatefulWidget {
  final StockSearchResult item;
  final VoidCallback onTap;

  const _StockSearchCard({
    required this.item,
    required this.onTap,
  });

  @override
  State<_StockSearchCard> createState() => _StockSearchCardState();
}

class _StockSearchCardState extends State<_StockSearchCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isSold = item.isSold;
    final cardAccent = isSold ? InvColors.danger : InvColors.brandGold;
    final cardBg = isSold
        ? const Color(0xFFFFF7F7)
        : _hovered
            ? const Color(0xFFFFFBEB)
            : Colors.white;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered || isSold ? cardAccent : InvColors.cardBorder,
              width: _hovered || isSold ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _MetalAvatar(metal: item.metalType),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: InvStyles.itemName.copyWith(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(status: item.status),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${_clean(item.itemType)} • ${_clean(item.segment)} • ${item.trackingLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          InvStyles.itemSku.copyWith(color: InvColors.textBody),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SmallPill(
                            label: item.hasHuid ? 'HUID' : 'Unit Code',
                            value: item.hasHuid ? item.huid : item.unitCode),
                        _SmallPill(
                          label: 'Batch',
                          value: item.inventoryBatchCode,
                        ),
                        _SmallPill(
                            label: 'Supplier',
                            value: _clean(item.supplierName)),
                        if (item.isSold && item.soldBillNo.trim().isNotEmpty)
                          _SmallPill(
                              label: 'Sale Invoice',
                              value: item.soldBillNo.trim()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ResultMetric(
                  label: 'Net Weight',
                  value: _grams(item.netWeight),
                  accent: InvColors.success),
              _ResultMetric(
                  label: 'Purity',
                  value: _percent(item.purityPercent),
                  accent: InvColors.brandGold),
              _ResultMetric(
                  label: 'Actual Fine',
                  value: _grams(item.actualFineWeight),
                  accent: InvColors.success),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded,
                  color: InvColors.brandGold, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

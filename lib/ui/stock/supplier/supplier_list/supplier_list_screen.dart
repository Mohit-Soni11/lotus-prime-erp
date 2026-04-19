// -----------------------------------------------------------------------------
// FILE: supplier_list_screen.dart
// MODULE: Supplier → Supplier List
// DESCRIPTION: Full Supplier List screen — identical structure to CustomerListScreen.
//              ListenableBuilder + stats strip + search + filter chips.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../../../theme/stock/supplier/supplier_list/supplier_list_theme.dart';
import '../../../../logic/stock/supplier_list_logic.dart';
import '../../../../models/stock/supplier_model/supplier_enums.dart';
import 'supplier_list_app_bar.dart';
import 'supplier_list_card.dart';

class SupplierListScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onAddSupplier;
  final Function(int supplierId)? onSupplierTap;

  const SupplierListScreen({
    super.key,
    this.onBack,
    this.onAddSupplier,
    this.onSupplierTap,
  });

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  late final SupplierListLogic _logic;
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _logic = SupplierListLogic();
  }

  @override
  void dispose() {
    _logic.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: SupplierListColors.bodyBg,
        appBar: SupplierListAppBar(onBack: widget.onBack ?? () {}),
        body: ListenableBuilder(
          listenable: _logic,
          builder: (context, _) => Column(
            children: [
              _buildStatsDashboard(),
              _buildSearchAndFilter(),
              _buildResultCount(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  // ── STATS DASHBOARD ──────────────────────────────────────────────────────
  Widget _buildStatsDashboard() {
    final stats = _logic.stats;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          // Total Suppliers
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: SupplierListStyles.statsCardDecoration,
              child: Row(
                children: [
                  SizedBox(
                    width: 50, height: 50,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: 0.82,
                          strokeWidth: 5,
                          backgroundColor: SupplierListColors.bodyBorder,
                          valueColor: const AlwaysStoppedAnimation(SupplierListColors.brandGold),
                          strokeCap: StrokeCap.round,
                        ),
                        const Center(child: Text('82%',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: SupplierListColors.brandGold))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(stats.isLoading ? '--' : stats.total.toString(), style: SupplierListStyles.statsValue),
                      const SizedBox(height: 2),
                      Text(SupplierListStrings.totalSuppliers, style: SupplierListStyles.statsLabel),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // New Today
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: SupplierListStyles.statsCardDecoration,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: SupplierListColors.successBg, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(SupplierListIcons.todayNew, size: 14, color: SupplierListColors.success),
                  ),
                  const Spacer(),
                  Text(stats.isLoading ? '--' : stats.todayCount.toString(), style: SupplierListStyles.statsValue),
                ]),
                const SizedBox(height: 12),
                Text(SupplierListStrings.todayNew, style: SupplierListStyles.statsLabel),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          // Manufacturers
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: SupplierListStyles.statsCardDecoration,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: SupplierListColors.manufacturerBg, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(SupplierListIcons.manufacturer, size: 14, color: SupplierListColors.manufacturerText),
                  ),
                  const Spacer(),
                  Text(stats.isLoading ? '--' : stats.manufacturerCount.toString(), style: SupplierListStyles.statsValue),
                ]),
                const SizedBox(height: 12),
                Text(SupplierListStrings.manufacturerCount, style: SupplierListStyles.statsLabel),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── SEARCH + FILTER ──────────────────────────────────────────────────────
  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Column(
        children: [
          Container(
            decoration: SupplierListStyles.searchDecoration,
            child: TextField(
              controller: _searchCtrl,
              onChanged: _logic.onSearchChanged,
              style: SupplierListStyles.searchText,
              decoration: InputDecoration(
                hintText: SupplierListStrings.searchHint,
                hintStyle: SupplierListStyles.searchHint,
                prefixIcon: const Icon(SupplierListIcons.search, color: SupplierListColors.bodyTextMuted, size: 22),
                suffixIcon: _logic.isSearching
                    ? IconButton(
                        icon: const Icon(SupplierListIcons.clearSearch, color: SupplierListColors.bodyTextMuted, size: 20),
                        onPressed: () { _searchCtrl.clear(); _logic.clearSearch(); })
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: SupplierListStyles.filterBarHeight,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: SupplierFilter.values.map((filter) {
                final isActive = _logic.activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => _logic.setFilter(filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: SupplierListStyles.chipPadding,
                      decoration: BoxDecoration(
                        color: isActive ? SupplierListColors.chipActiveBg : SupplierListColors.chipInactiveBg,
                        borderRadius: BorderRadius.circular(SupplierListStyles.chipBorderRadius),
                        border: Border.all(color: isActive ? SupplierListColors.chipActive : Colors.transparent),
                      ),
                      child: Text(filter.label,
                          style: isActive ? SupplierListStyles.chipActive : SupplierListStyles.chipInactive),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCount() {
    if (_logic.state == SupplierListState.loading) return const SizedBox.shrink();
    final count = _logic.suppliers.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      alignment: Alignment.centerLeft,
      child: Text('$count Supplier${count == 1 ? '' : 's'} found',
          style: SupplierListStyles.supplierDetail),
    );
  }

  Widget _buildBody() {
    switch (_logic.state) {
      case SupplierListState.loading:
      case SupplierListState.searching:
        return const Center(child: CircularProgressIndicator(color: SupplierListColors.brandGold));
      case SupplierListState.empty:
        return _buildEmptyState();
      case SupplierListState.error:
        return _buildErrorState();
      case SupplierListState.loaded:
        return ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: _logic.suppliers.length,
          itemBuilder: (context, index) {
            final s = _logic.suppliers[index];
            return SupplierListCard(
              supplier: s,
              onTap: () { if (widget.onSupplierTap != null) widget.onSupplierTap!(s.id); },
            );
          },
        );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_logic.isSearching ? SupplierListIcons.noResult : SupplierListIcons.emptyState,
              size: 64, color: SupplierListColors.bodyTextMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(_logic.isSearching ? SupplierListStrings.noResultTitle : SupplierListStrings.emptyTitle,
              style: SupplierListStyles.emptyTitle),
          const SizedBox(height: 8),
          Text(_logic.isSearching ? SupplierListStrings.noResultSub : SupplierListStrings.emptySubtitle,
              style: SupplierListStyles.emptySubtitle),
          if (!_logic.isSearching) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onAddSupplier,
              style: ElevatedButton.styleFrom(
                backgroundColor: SupplierListColors.brandGold, foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(SupplierListIcons.addSupplier, size: 18),
              label: const Text(SupplierListStrings.addFirst, style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _logic.refresh,
        style: ElevatedButton.styleFrom(backgroundColor: SupplierListColors.brandGold, foregroundColor: Colors.black),
        icon: const Icon(SupplierListIcons.refresh, size: 18),
        label: const Text(SupplierListStrings.btnRefresh),
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: widget.onAddSupplier,
      backgroundColor: SupplierListColors.brandGold,
      foregroundColor: Colors.black,
      icon: const Icon(SupplierListIcons.addSupplier),
      label: const Text(SupplierListStrings.btnAddNew, style: TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
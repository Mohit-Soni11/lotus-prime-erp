// -----------------------------------------------------------------------------
// FILE: customer_list_screen.dart
// MODULE: Customer -> Customer List
// DESCRIPTION: Production-ready customer directory body.
// -----------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../logic/customer/customer_list_logic.dart';
import '../../../models/customer/customer_enums/customer_list_enums.dart';
import '../../../theme/customer/customer_list/customer_list_theme.dart';
import 'customer_list_app_bar.dart';
import 'customer_list_card.dart';
import 'customer_list_controls.dart';
import 'customer_list_stats_dashboard.dart';

class CustomerListScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onAddCustomer;
  final Function(int customerId)? onCustomerTap;

  const CustomerListScreen({
    super.key,
    this.onBack,
    this.onAddCustomer,
    this.onCustomerTap,
  });

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  late final CustomerListLogic _logic;
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _logic = CustomerListLogic();
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
        backgroundColor: CustomerListColors.bodyBg,
        appBar: CustomerListAppBar(onBack: widget.onBack ?? () {}),
        body: ListenableBuilder(
          listenable: _logic,
          builder: (context, _) {
            return RefreshIndicator(
              color: CustomerListColors.brandGold,
              onRefresh: _logic.refresh,
              child: CustomScrollView(
                controller: _scrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildPageHeader()),
                  SliverToBoxAdapter(
                      child: CustomerListStatsDashboard(stats: _logic.stats)),
                  SliverToBoxAdapter(child: _buildCommandCenter()),
                  SliverToBoxAdapter(child: _buildResultSummary()),
                  _buildBodySliver(),
                ],
              ),
            );
          },
        ),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(CustomerListStrings.pageTitle,
                    style: CustomerListStyles.pageTitle),
                const SizedBox(height: 5),
                Text(
                  CustomerListStrings.pageSubtitle,
                  style: CustomerListStyles.pageSubtitle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          CustomerListToolbarButton(
            icon: CustomerListIcons.refresh,
            label: CustomerListStrings.btnRefresh,
            onTap: _logic.refresh,
          ),
        ],
      ),
    );
  }

  Widget _buildCommandCenter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CustomerListColors.bodyPanelBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CustomerListColors.bodyBorder),
          boxShadow: const [
            BoxShadow(
              color: CustomerListColors.shadowLight,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 980;
            final search = _buildSearchField();
            final filters = _buildFilterChips();
            final sort = _buildSortMenu();

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  search,
                  const SizedBox(height: 12),
                  filters,
                  const SizedBox(height: 12),
                  sort,
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 4, child: search),
                const SizedBox(width: 12),
                Expanded(flex: 5, child: filters),
                const SizedBox(width: 12),
                sort,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: CustomerListStyles.searchBarHeight,
      decoration: CustomerListStyles.searchDecoration,
      child: TextField(
        controller: _searchCtrl,
        onChanged: _logic.onSearchChanged,
        style: CustomerListStyles.searchText,
        decoration: InputDecoration(
          hintText: CustomerListStrings.searchHint,
          hintStyle: CustomerListStyles.searchHint,
          prefixIcon: const Icon(
            CustomerListIcons.search,
            color: CustomerListColors.bodyTextMuted,
            size: 21,
          ),
          suffixIcon: _logic.isSearching
              ? IconButton(
                  tooltip: "Clear search",
                  icon: const Icon(
                    CustomerListIcons.clearSearch,
                    color: CustomerListColors.bodyTextMuted,
                    size: 19,
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    _logic.clearSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: CustomerFilter.values.map((filter) {
        final isActive = _logic.activeFilter == filter;
        return CustomerListFilterChipButton(
          label: filter.label,
          isActive: isActive,
          onTap: () {
            _searchCtrl.clear();
            _logic.setFilter(filter);
          },
        );
      }).toList(),
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<CustomerSort>(
      tooltip: "Sort customers",
      onSelected: _logic.setSort,
      itemBuilder: (context) {
        return CustomerSort.values.map((sort) {
          final active = _logic.activeSort == sort;
          return PopupMenuItem<CustomerSort>(
            value: sort,
            child: Row(
              children: [
                Icon(
                  active ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 16,
                  color: active
                      ? CustomerListColors.brandGold
                      : CustomerListColors.bodyTextMuted,
                ),
                const SizedBox(width: 10),
                Text(sort.label),
              ],
            ),
          );
        }).toList();
      },
      child: CustomerListToolbarButton(
        icon: CustomerListIcons.sort,
        label: _logic.activeSort.label,
      ),
    );
  }

  Widget _buildResultSummary() {
    if (_logic.isLoading) return const SizedBox.shrink();

    final visible = _logic.customers.length;
    final loaded = _logic.totalLoadedCount;
    final scope = _logic.activeFilter == CustomerFilter.all
        ? "all customers"
        : _logic.activeFilter.label.toLowerCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Column(
                key: ValueKey("$visible-$loaded-${_logic.searchQuery}"),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$visible customer${visible == 1 ? '' : 's'} visible",
                    style: CustomerListStyles.resultTitle,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Showing $scope - sorted by ${_logic.activeSort.label.toLowerCase()}",
                    style: CustomerListStyles.resultMeta,
                  ),
                ],
              ),
            ),
          ),
          if (_logic.isSearching)
            CustomerListResultPill(
              icon: CustomerListIcons.search,
              label: _logic.searchQuery,
            ),
        ],
      ),
    );
  }

  Widget _buildBodySliver() {
    switch (_logic.state) {
      case CustomerListState.loading:
      case CustomerListState.searching:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
              color: CustomerListColors.brandGold,
            ),
          ),
        );
      case CustomerListState.empty:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(),
        );
      case CustomerListState.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _buildErrorState(),
        );
      case CustomerListState.loaded:
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 100),
          sliver: SliverList.builder(
            itemCount: _logic.customers.length,
            itemBuilder: (context, index) {
              final customer = _logic.customers[index];
              return TweenAnimationBuilder<double>(
                key: ValueKey(customer.id),
                tween: Tween(begin: 0, end: 1),
                duration: Duration(
                  milliseconds: 220 + math.min(index * 16, 180),
                ),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 10),
                      child: child,
                    ),
                  );
                },
                child: CustomerListCard(
                  customer: customer,
                  onTap: () => widget.onCustomerTap?.call(customer.id),
                ),
              );
            },
          ),
        );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: CustomerListColors.brandGoldBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              _logic.isSearching
                  ? CustomerListIcons.noResult
                  : CustomerListIcons.emptyState,
              size: 42,
              color: CustomerListColors.brandGoldDark,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _logic.isSearching
                ? CustomerListStrings.noResultTitle
                : CustomerListStrings.emptyTitle,
            style: CustomerListStyles.emptyTitle,
          ),
          const SizedBox(height: 8),
          Text(
            _logic.isSearching
                ? CustomerListStrings.noResultSub
                : CustomerListStrings.emptySubtitle,
            style: CustomerListStyles.emptySubtitle,
          ),
          if (!_logic.isSearching) ...[
            const SizedBox(height: 22),
            CustomerListToolbarButton(
              icon: CustomerListIcons.addCustomer,
              label: CustomerListStrings.addFirst,
              onTap: widget.onAddCustomer,
              filled: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 46,
            color: CustomerListColors.danger,
          ),
          const SizedBox(height: 12),
          Text(
            _logic.errorMessage ?? CustomerListStrings.loadError,
            style: CustomerListStyles.emptySubtitle,
          ),
          const SizedBox(height: 18),
          CustomerListToolbarButton(
            icon: CustomerListIcons.refresh,
            label: CustomerListStrings.btnRefresh,
            onTap: _logic.refresh,
            filled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: widget.onAddCustomer,
      backgroundColor: CustomerListColors.brandGold,
      foregroundColor: Colors.black,
      elevation: 8,
      icon: const Icon(CustomerListIcons.addCustomer),
      label: const Text(
        CustomerListStrings.btnAddNew,
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

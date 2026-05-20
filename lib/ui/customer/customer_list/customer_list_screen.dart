// -----------------------------------------------------------------------------
// FILE: customer_list_screen.dart
// MODULE: Customer â†’ Customer List
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../../theme/customer/customer_list/customer_list_theme.dart';
import '../../../logic/customer/customer_list_logic.dart';
import '../../../models/customer/customer_enums/customer_list_enums.dart';
import 'customer_list_app_bar.dart';
import 'customer_list_card.dart';

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
        appBar: CustomerListAppBar(
          onBack: widget.onBack ?? () {},
        ),
        body: ListenableBuilder(
          listenable: _logic,
          builder: (context, _) {
            return Column(
              children: [
                _buildStatsDashboard(),
                _buildSearchAndFilter(),
                _buildResultCount(),
                Expanded(child: _buildBody()),
              ],
            );
          },
        ),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  // â”€â”€ PREMIUM STATS DASHBOARD WITH GRAPH â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildStatsDashboard() {
    final stats = _logic.stats;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          // 1. Total Clients with Circular Graph
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: CustomerListStyles.statsCardDecoration,
              child: Row(
                children: [
                  // Circular Progress Chart (Simulating 85% Active users)
                  const SizedBox(
                    width: 50,
                    height: 50,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: 0.85,
                          strokeWidth: 5,
                          backgroundColor: CustomerListColors.bodyBorder,
                          valueColor: AlwaysStoppedAnimation(
                              CustomerListColors.brandGold),
                          strokeCap: StrokeCap.round,
                        ),
                        Center(
                          child: Text(
                            "85%",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: CustomerListColors.brandGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.isLoading ? "--" : stats.totalCount.toString(),
                          style: CustomerListStyles.statsValue,
                        ),
                        const SizedBox(height: 2),
                        Text(CustomerListStrings.totalCustomers,
                            style: CustomerListStyles.statsLabel),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Today's New Enrollments
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: CustomerListStyles.statsCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: CustomerListColors.successBg,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(CustomerListIcons.systemOnline,
                            size: 14, color: CustomerListColors.success),
                      ),
                      const Spacer(),
                      Text(
                        stats.isLoading ? "--" : stats.todayCount.toString(),
                        style: CustomerListStyles.statsValue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(CustomerListStrings.todayNew,
                      style: CustomerListStyles.statsLabel),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 3. VIP / Elite Members
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: CustomerListStyles.statsCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: CustomerListColors.vipBadgeBg,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(CustomerListIcons.vipBadge,
                            size: 14, color: CustomerListColors.vipBadgeText),
                      ),
                      const Spacer(),
                      Text(
                        stats.isLoading ? "--" : stats.vipCount.toString(),
                        style: CustomerListStyles.statsValue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(CustomerListStrings.vipCount,
                      style: CustomerListStyles.statsLabel),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ SEARCH + FILTER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Column(
        children: [
          Container(
            decoration: CustomerListStyles.searchDecoration,
            child: TextField(
              controller: _searchCtrl,
              onChanged: _logic.onSearchChanged,
              style: CustomerListStyles.searchText,
              decoration: InputDecoration(
                hintText: CustomerListStrings.searchHint,
                hintStyle: CustomerListStyles.searchHint,
                prefixIcon: const Icon(CustomerListIcons.search,
                    color: CustomerListColors.bodyTextMuted, size: 22),
                suffixIcon: _logic.isSearching
                    ? IconButton(
                        icon: const Icon(CustomerListIcons.clearSearch,
                            color: CustomerListColors.bodyTextMuted, size: 20),
                        onPressed: () {
                          _searchCtrl.clear();
                          _logic.clearSearch();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: CustomerListStyles.filterBarHeight,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: CustomerFilter.values.map((filter) {
                final isActive = _logic.activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => _logic.setFilter(filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: CustomerListStyles.chipPadding,
                      decoration: BoxDecoration(
                        color: isActive
                            ? CustomerListColors.chipActiveBg
                            : CustomerListColors.chipInactiveBg,
                        borderRadius: BorderRadius.circular(
                            CustomerListStyles.chipBorderRadius),
                        border: Border.all(
                            color: isActive
                                ? CustomerListColors.chipActive
                                : Colors.transparent),
                      ),
                      child: Text(
                        filter.label == "VIP"
                            ? "Elite"
                            : filter.label == "Regular"
                                ? "Standard"
                                : filter.label,
                        style: isActive
                            ? CustomerListStyles.chipActive
                            : CustomerListStyles.chipInactive,
                      ),
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
    if (_logic.isLoading) return const SizedBox.shrink();
    final count = _logic.customers.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      alignment: Alignment.centerLeft,
      child: Text("$count Client${count == 1 ? '' : 's'} found",
          style: CustomerListStyles.customerDetail),
    );
  }

  Widget _buildBody() {
    switch (_logic.state) {
      case CustomerListState.loading:
      case CustomerListState.searching:
        return const Center(
            child:
                CircularProgressIndicator(color: CustomerListColors.brandGold));
      case CustomerListState.empty:
        return _buildEmptyState();
      case CustomerListState.error:
        return _buildErrorState();
      case CustomerListState.loaded:
        return ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: _logic.customers.length,
          itemBuilder: (context, index) {
            final customer = _logic.customers[index];
            return CustomerListCard(
              customer: customer,
              onTap: () {
                if (widget.onCustomerTap != null) {
                  widget.onCustomerTap!(customer.id);
                }
              },
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
          Icon(
              _logic.isSearching
                  ? CustomerListIcons.noResult
                  : CustomerListIcons.emptyState,
              size: 64,
              color: CustomerListColors.bodyTextMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
              _logic.isSearching
                  ? CustomerListStrings.noResultTitle
                  : CustomerListStrings.emptyTitle,
              style: CustomerListStyles.emptyTitle),
          const SizedBox(height: 8),
          Text(
              _logic.isSearching
                  ? CustomerListStrings.noResultSub
                  : CustomerListStrings.emptySubtitle,
              style: CustomerListStyles.emptySubtitle),
          if (!_logic.isSearching) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onAddCustomer,
              style: ElevatedButton.styleFrom(
                  backgroundColor: CustomerListColors.brandGold,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              icon: const Icon(CustomerListIcons.addCustomer, size: 18),
              label: const Text(CustomerListStrings.addFirst,
                  style: TextStyle(fontWeight: FontWeight.w800)),
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
        style: ElevatedButton.styleFrom(
            backgroundColor: CustomerListColors.brandGold,
            foregroundColor: Colors.black),
        icon: const Icon(CustomerListIcons.refresh, size: 18),
        label: const Text(CustomerListStrings.btnRefresh),
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: widget.onAddCustomer,
      backgroundColor: CustomerListColors.brandGold,
      foregroundColor: Colors.black,
      icon: const Icon(CustomerListIcons.addCustomer),
      label: const Text(CustomerListStrings.btnAddNew,
          style: TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

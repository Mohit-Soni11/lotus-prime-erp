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
import 'customer_list_result_header.dart';
import 'customer_list_stats_dashboard.dart';
import 'customer_list_toolbar.dart';
import '../../shared/system_status_badge.dart';

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

class _CustomerListScreenState extends State<CustomerListScreen>
    with WidgetsBindingObserver {
  late final CustomerListLogic _logic;
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _logic = CustomerListLogic();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _logic.refresh(showLoading: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(CustomerListStyles.appBarHeight),
          child: ListenableBuilder(
            listenable: _logic,
            builder: (context, _) => CustomerListAppBar(
              onBack: widget.onBack ?? () {},
              status: _logic.errorMessage != null
                  ? SystemStatus.unavailable
                  : _logic.isLoading
                      ? SystemStatus.loading
                      : SystemStatus.online,
            ),
          ),
        ),
        body: ListenableBuilder(
          listenable: _logic,
          builder: (context, _) {
            return CustomScrollView(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildPageHeader()),
                SliverToBoxAdapter(
                    child: CustomerListStatsDashboard(stats: _logic.stats)),
                SliverToBoxAdapter(
                  child: CustomerListToolbar(
                    logic: _logic,
                    searchController: _searchCtrl,
                  ),
                ),
                if (!_logic.isLoading)
                  SliverToBoxAdapter(
                    child: CustomerListResultHeader(
                      visibleCount: _logic.customers.length,
                      filter: _logic.activeFilter,
                      sort: _logic.activeSort,
                      searchQuery: _logic.searchQuery,
                    ),
                  ),
                _buildBodySliver(),
              ],
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
            label: CustomerListStrings.btnRetry,
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

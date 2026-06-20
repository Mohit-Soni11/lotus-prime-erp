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
                  SliverToBoxAdapter(child: _buildStatsDashboard()),
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
          _ToolbarButton(
            icon: CustomerListIcons.refresh,
            label: CustomerListStrings.btnRefresh,
            onTap: _logic.refresh,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsDashboard() {
    final stats = _logic.stats;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 12.0;
          final columns = constraints.maxWidth >= 1260
              ? 4
              : constraints.maxWidth >= 760
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              SizedBox(
                width: width,
                child: _StatCard(
                  icon: CustomerListIcons.clients,
                  title: CustomerListStrings.totalCustomers,
                  value:
                      stats.isLoading ? "--" : _formatCount(stats.totalCount),
                  caption: stats.isLoading
                      ? "Calculating active rate"
                      : "${stats.activePercentage}% active accounts",
                  accent: CustomerListColors.brandGold,
                  background: CustomerListColors.brandGoldBg,
                  trailing: _ActiveRing(
                    value: stats.isLoading ? 0 : stats.activeRatio,
                    label:
                        stats.isLoading ? "--" : "${stats.activePercentage}%",
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: _StatCard(
                  icon: CustomerListIcons.active,
                  title: CustomerListStrings.activeAccounts,
                  value:
                      stats.isLoading ? "--" : _formatCount(stats.activeCount),
                  caption: stats.isLoading
                      ? "Reading live accounts"
                      : "${stats.totalBillCount} invoices recorded",
                  accent: CustomerListColors.success,
                  background: CustomerListColors.successBg,
                  progress: stats.isLoading ? 0 : stats.activeRatio,
                ),
              ),
              SizedBox(
                width: width,
                child: _StatCard(
                  icon: CustomerListIcons.month,
                  title: CustomerListStrings.newThisMonth,
                  value:
                      stats.isLoading ? "--" : _formatCount(stats.monthCount),
                  caption: stats.isLoading
                      ? "Checking enrollments"
                      : "${stats.todayCount} added today",
                  accent: CustomerListColors.info,
                  background: CustomerListColors.infoBg,
                  progress: stats.totalCount == 0 || stats.isLoading
                      ? 0
                      : stats.monthCount / stats.totalCount,
                ),
              ),
              SizedBox(
                width: width,
                child: _StatCard(
                  icon: CustomerListIcons.due,
                  title: CustomerListStrings.dueExposure,
                  value: stats.isLoading
                      ? "--"
                      : _formatMoney(stats.totalDueAmount),
                  caption: stats.isLoading
                      ? "Auditing customer dues"
                      : "${stats.dueCustomerCount} clients with pending due",
                  accent: stats.totalDueAmount > 0
                      ? CustomerListColors.danger
                      : CustomerListColors.teal,
                  background: stats.totalDueAmount > 0
                      ? CustomerListColors.dangerBg
                      : CustomerListColors.tealBg,
                ),
              ),
            ],
          );
        },
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
        return _FilterChipButton(
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
      tooltip: "Sort clients",
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
      child: _ToolbarButton(
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
        ? "all clients"
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
                    "$visible client${visible == 1 ? '' : 's'} visible",
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
            _ResultPill(
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
            _ToolbarButton(
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
          _ToolbarButton(
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

  static String _formatCount(int value) {
    if (value >= 1000000) return "${(value / 1000000).toStringAsFixed(1)}M";
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(1)}K";
    return value.toString();
  }

  static String _formatMoney(double value) {
    if (value <= 0.01) return "Rs 0";
    if (value >= 10000000) {
      return "Rs ${(value / 10000000).toStringAsFixed(1)}Cr";
    }
    if (value >= 100000) return "Rs ${(value / 100000).toStringAsFixed(1)}L";
    if (value >= 1000) return "Rs ${(value / 1000).toStringAsFixed(1)}K";
    return "Rs ${value.toStringAsFixed(0)}";
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String caption;
  final Color accent;
  final Color background;
  final double? progress;
  final Widget? trailing;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
    required this.accent,
    required this.background,
    this.progress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = (progress ?? 0).clamp(0.0, 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(15),
      decoration: CustomerListStyles.statsCardDecoration,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 21, color: accent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: CustomerListStyles.statsLabel),
                const SizedBox(height: 6),
                Text(value, style: CustomerListStyles.statsValue),
                const SizedBox(height: 5),
                Text(
                  caption,
                  style: CustomerListStyles.statsCaption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (progress != null) ...[
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: clampedProgress),
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 5,
                          backgroundColor: CustomerListColors.bodyBorder
                              .withValues(alpha: 0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _ActiveRing extends StatelessWidget {
  final double value;
  final String label;

  const _ActiveRing({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return SizedBox(
          width: 58,
          height: 58,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: animatedValue,
                strokeWidth: 6,
                backgroundColor: CustomerListColors.bodyBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  CustomerListColors.brandGold,
                ),
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Text(
                  label,
                  style: CustomerListStyles.statsCaption.copyWith(
                    color: CustomerListColors.brandGoldDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CustomerListStyles.chipBorderRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: CustomerListStyles.chipPadding,
        decoration: BoxDecoration(
          color: isActive
              ? CustomerListColors.chipActiveBg
              : CustomerListColors.chipInactiveBg,
          borderRadius:
              BorderRadius.circular(CustomerListStyles.chipBorderRadius),
          border: Border.all(
            color: isActive
                ? CustomerListColors.chipActive
                : CustomerListColors.bodyBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              const Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: CustomerListColors.brandGoldDark,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: isActive
                  ? CustomerListStyles.chipActive
                  : CustomerListStyles.chipInactive,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        filled ? CustomerListColors.brandGold : CustomerListColors.bodyPanelBg;
    final border =
        filled ? CustomerListColors.brandGold : CustomerListColors.bodyBorder;
    final foreground = filled ? Colors.black : CustomerListColors.bodyTextMain;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: CustomerListStyles.toolbarButton.copyWith(
                  color: foreground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ResultPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: CustomerListColors.infoBg,
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: CustomerListColors.info.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CustomerListColors.info),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: CustomerListStyles.resultMeta.copyWith(
                color: CustomerListColors.info,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

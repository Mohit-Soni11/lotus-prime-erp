import 'package:flutter/material.dart';

import '../../../logic/customer/customer_list_logic.dart';
import '../../../models/customer/customer_enums/customer_list_enums.dart';
import '../../../theme/customer/customer_list/customer_list_theme.dart';
import 'customer_list_controls.dart';

class CustomerListToolbar extends StatelessWidget {
  const CustomerListToolbar({
    super.key,
    required this.logic,
    required this.searchController,
  });

  final CustomerListLogic logic;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
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
        controller: searchController,
        onChanged: logic.onSearchChanged,
        style: CustomerListStyles.searchText,
        decoration: InputDecoration(
          hintText: CustomerListStrings.searchHint,
          hintStyle: CustomerListStyles.searchHint,
          prefixIcon: const Icon(
            CustomerListIcons.search,
            color: CustomerListColors.bodyTextMain,
            size: 21,
          ),
          suffixIcon: logic.isSearching
              ? IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(
                    CustomerListIcons.clearSearch,
                    color: CustomerListColors.bodyTextMain,
                    size: 19,
                  ),
                  onPressed: () {
                    searchController.clear();
                    logic.clearSearch();
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
        final isActive = logic.activeFilter == filter;
        return CustomerListFilterChipButton(
          label: filter.label,
          isActive: isActive,
          onTap: () {
            searchController.clear();
            logic.setFilter(filter);
          },
        );
      }).toList(),
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<CustomerSort>(
      tooltip: 'Sort customers',
      onSelected: logic.setSort,
      itemBuilder: (context) => CustomerSort.values.map((sort) {
        final active = logic.activeSort == sort;
        return PopupMenuItem<CustomerSort>(
          value: sort,
          child: Row(
            children: [
              Icon(
                active ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 16,
                color: active
                    ? CustomerListColors.brandGold
                    : CustomerListColors.bodyTextMain,
              ),
              const SizedBox(width: 10),
              Text(sort.label, style: CustomerListStyles.toolbarButton),
            ],
          ),
        );
      }).toList(),
      child: CustomerListToolbarButton(
        icon: CustomerListIcons.sort,
        label: logic.activeSort.label,
      ),
    );
  }
}

// ==========================================
// FILE: defaulter_filter_bar.dart
// MODULE: Customer → Defaulter List
// DESCRIPTION: Search box + risk filter chips + sort dropdown.
//              Communicates user actions back to DefaulterLogic.
// ==========================================

import 'package:flutter/material.dart';

import '../../../models/customer/defaulter_model.dart';
import '../../../theme/customer/defaulter/defaulter_theme.dart';

class DefaulterFilterBar extends StatefulWidget {
  final DefaulterFilterBy activeFilter;
  final DefaulterSortBy activeSort;
  final String searchQuery;
  final ValueChanged<DefaulterFilterBy> onFilterChanged;
  final ValueChanged<DefaulterSortBy> onSortChanged;
  final ValueChanged<String> onSearchChanged;

  const DefaulterFilterBar({
    super.key,
    required this.activeFilter,
    required this.activeSort,
    required this.searchQuery,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onSearchChanged,
  });

  @override
  State<DefaulterFilterBar> createState() => _DefaulterFilterBarState();
}

class _DefaulterFilterBarState extends State<DefaulterFilterBar> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.searchQuery);
    _searchCtrl.addListener(_handleSearchTextChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_handleSearchTextChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleSearchTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        children: [
          // --- ROW 1: Search + Sort ---
          Row(
            children: [
              // Search Bar
              Expanded(
                  child: _SearchBar(
                controller: _searchCtrl,
                onChanged: widget.onSearchChanged,
              )),

              const SizedBox(width: 12),

              // Sort Dropdown
              _SortDropdown(
                activeSort: widget.activeSort,
                onSortChanged: widget.onSortChanged,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // --- ROW 2: Filter Chips ---
          _FilterChips(
            activeFilter: widget.activeFilter,
            onFilterChanged: widget.onFilterChanged,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// SEARCH BAR
// ─────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: DefaulterStyles.searchBarDecoration,
      child: TextField(
        controller: controller,
        style: DefaulterStyles.searchInputText,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: DefaulterStrings.searchHint,
          hintStyle: DefaulterStyles.searchInputText.copyWith(
            color: DefaulterColors.bodyTextHint,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            DefaulterIcons.search,
            color: DefaulterColors.bodyTextHint,
            size: 18,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    DefaulterIcons.clearFilter,
                    color: DefaulterColors.bodyTextHint,
                    size: 16,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          isDense: true,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SORT DROPDOWN
// ─────────────────────────────────────────

class _SortDropdown extends StatelessWidget {
  final DefaulterSortBy activeSort;
  final ValueChanged<DefaulterSortBy> onSortChanged;

  const _SortDropdown({
    required this.activeSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: DefaulterColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DefaulterColors.bodyBorder, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DefaulterSortBy>(
          value: activeSort,
          icon: const Icon(
            DefaulterIcons.filter,
            color: DefaulterColors.bodyTextMuted,
            size: 16,
          ),
          style: DefaulterStyles.filterChipText.copyWith(
            color: DefaulterColors.bodyTextMain,
          ),
          dropdownColor: DefaulterColors.bodyPanelBg,
          items: [
            _sortItem(
                DefaulterSortBy.daysOverdue, DefaulterStrings.sortOverdue),
            _sortItem(DefaulterSortBy.amountDue, DefaulterStrings.sortAmount),
            _sortItem(DefaulterSortBy.customerName, DefaulterStrings.sortName),
            _sortItem(
                DefaulterSortBy.lastActivity, DefaulterStrings.sortRecent),
          ],
          onChanged: (val) {
            if (val != null) onSortChanged(val);
          },
        ),
      ),
    );
  }

  DropdownMenuItem<DefaulterSortBy> _sortItem(
    DefaulterSortBy value,
    String label,
  ) {
    return DropdownMenuItem<DefaulterSortBy>(
      value: value,
      child: Text(label),
    );
  }
}

// ─────────────────────────────────────────
// FILTER CHIPS ROW
// ─────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final DefaulterFilterBy activeFilter;
  final ValueChanged<DefaulterFilterBy> onFilterChanged;

  const _FilterChips({
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final chips = [
      (DefaulterFilterBy.all, DefaulterStrings.filterAll, null),
      (
        DefaulterFilterBy.overdue,
        DefaulterStrings.filterOverdue,
        DefaulterColors.riskCriticalText
      ),
      (
        DefaulterFilterBy.critical,
        DefaulterStrings.filterCritical,
        DefaulterColors.riskCriticalText
      ),
      (
        DefaulterFilterBy.high,
        DefaulterStrings.filterHigh,
        DefaulterColors.riskHighText
      ),
      (
        DefaulterFilterBy.medium,
        DefaulterStrings.filterMedium,
        DefaulterColors.riskMediumText
      ),
      (
        DefaulterFilterBy.low,
        DefaulterStrings.filterLow,
        DefaulterColors.riskLowText
      ),
      (
        DefaulterFilterBy.settlementPending,
        DefaulterStrings.filterSettlement,
        DefaulterColors.riskHighText
      ),
    ];

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (filter, label, color) = chips[i];
          final isActive = activeFilter == filter;

          return GestureDetector(
            onTap: () => onFilterChanged(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? DefaulterColors.filterChipActive
                    : DefaulterColors.filterChipBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? DefaulterColors.filterChipActive
                      : DefaulterColors.bodyBorder,
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: DefaulterStyles.filterChipText.copyWith(
                  color: isActive
                      ? DefaulterColors.filterChipActiveText
                      : (color ?? DefaulterColors.bodyTextMuted),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

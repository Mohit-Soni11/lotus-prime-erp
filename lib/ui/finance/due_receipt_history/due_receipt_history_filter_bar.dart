import 'package:flutter/material.dart';

import '../../../logic/finance/due_receipt_history/due_receipt_history_controller.dart';
import '../../../models/finance/due_receipt_history/due_receipt_history_model.dart';
import '../../../theme/finance/due_receipt_history/due_receipt_history_theme.dart';

class DueReceiptHistoryFilterBar extends StatelessWidget {
  final DueReceiptHistoryController ctrl;

  const DueReceiptHistoryFilterBar({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DueReceiptHistoryStyles.panel(
          color: DueReceiptHistoryColors.panelSoft),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SearchBox(ctrl: ctrl),
                const SizedBox(height: 10),
                _DateFilters(ctrl: ctrl),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _ModeDropdown(ctrl: ctrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _SortDropdown(ctrl: ctrl)),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 4, child: _SearchBox(ctrl: ctrl)),
              const SizedBox(width: 12),
              Expanded(flex: 5, child: _DateFilters(ctrl: ctrl)),
              const SizedBox(width: 12),
              SizedBox(width: 160, child: _ModeDropdown(ctrl: ctrl)),
              const SizedBox(width: 10),
              SizedBox(width: 170, child: _SortDropdown(ctrl: ctrl)),
            ],
          );
        },
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final DueReceiptHistoryController ctrl;

  const _SearchBox({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: DueReceiptHistoryStyles.flatPanel(),
      child: TextField(
        controller: ctrl.searchCtrl,
        style: DueReceiptHistoryStyles.rowTitle,
        decoration: InputDecoration(
          prefixIcon: const Icon(DueReceiptHistoryIcons.search,
              size: 18, color: DueReceiptHistoryColors.textMuted),
          suffixIcon: ctrl.searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(DueReceiptHistoryIcons.clear, size: 17),
                  color: DueReceiptHistoryColors.textMuted,
                  onPressed: ctrl.clearSearch,
                ),
          hintText: DueReceiptHistoryStrings.searchHint,
          hintStyle: DueReceiptHistoryStyles.muted,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }
}

class _DateFilters extends StatelessWidget {
  final DueReceiptHistoryController ctrl;

  const _DateFilters({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: DueReceiptDateFilter.values.map((filter) {
            final selected = ctrl.dateFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => ctrl.setDateFilter(filter),
                borderRadius: BorderRadius.circular(30),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? DueReceiptHistoryColors.goldSoft
                        : DueReceiptHistoryColors.panelBg,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: selected
                          ? DueReceiptHistoryColors.gold
                          : DueReceiptHistoryColors.border,
                    ),
                  ),
                  child: Text(
                    filter.label,
                    style: DueReceiptHistoryStyles.label.copyWith(
                      color: selected
                          ? DueReceiptHistoryColors.gold
                          : DueReceiptHistoryColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ModeDropdown extends StatelessWidget {
  final DueReceiptHistoryController ctrl;

  const _ModeDropdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _DropdownShell(
      icon: DueReceiptHistoryIcons.filter,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DueReceiptModeFilter>(
          value: ctrl.modeFilter,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          items: DueReceiptModeFilter.values
              .map((value) =>
                  DropdownMenuItem(value: value, child: Text(value.label)))
              .toList(),
          onChanged: (value) {
            if (value != null) ctrl.setModeFilter(value);
          },
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final DueReceiptHistoryController ctrl;

  const _SortDropdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _DropdownShell(
      icon: DueReceiptHistoryIcons.sort,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DueReceiptSort>(
          value: ctrl.sort,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          items: DueReceiptSort.values
              .map((value) =>
                  DropdownMenuItem(value: value, child: Text(value.label)))
              .toList(),
          onChanged: (value) {
            if (value != null) ctrl.setSort(value);
          },
        ),
      ),
    );
  }
}

class _DropdownShell extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _DropdownShell({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.only(left: 11, right: 8),
      decoration: DueReceiptHistoryStyles.flatPanel(),
      child: Row(
        children: [
          Icon(icon, size: 17, color: DueReceiptHistoryColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: DefaultTextStyle(
              style: DueReceiptHistoryStyles.label
                  .copyWith(color: DueReceiptHistoryColors.textPrimary),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../domain/invoice_center_models.dart';
import '../invoice_center_style.dart';

class InvoiceCenterFilters extends StatelessWidget {
  const InvoiceCenterFilters({
    super.key,
    required this.searchController,
    required this.month,
    required this.usesMonth,
    required this.metals,
    required this.selectedMetal,
    required this.selectedStatus,
    required this.tab,
    required this.onSearch,
    required this.onMonthChange,
    required this.onMetalChange,
    required this.onStatusChange,
    required this.onMoreFilters,
    required this.onRefresh,
    required this.hasAmountFilter,
  });

  final TextEditingController searchController;
  final DateTime month;
  final bool usesMonth;
  final List<String> metals;
  final String selectedMetal;
  final String selectedStatus;
  final InvoiceCenterTab tab;
  final ValueChanged<String> onSearch;
  final ValueChanged<int> onMonthChange;
  final ValueChanged<String> onMetalChange;
  final ValueChanged<String> onStatusChange;
  final VoidCallback onMoreFilters;
  final VoidCallback onRefresh;
  final bool hasAmountFilter;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1100;
          final searchWidth = wide
              ? constraints.maxWidth - 238 - 174 - 174 - 156 - 48 - 5 * 10
              : constraints.maxWidth < 600
                  ? constraints.maxWidth
                  : constraints.maxWidth - 250;
          final controls = <Widget>[
            SizedBox(width: 238, child: _monthControl()),
            SizedBox(width: searchWidth, child: _searchControl()),
            SizedBox(
              width: 174,
              child: _dropdown(
                value: selectedMetal,
                values: metals,
                allLabel: 'All Metal',
                onChanged: onMetalChange,
              ),
            ),
            SizedBox(
              width: 174,
              child: _dropdown(
                value: selectedStatus,
                values: _statusesFor(tab),
                allLabel: 'All Status',
                onChanged: onStatusChange,
              ),
            ),
            SizedBox(
              width: 156,
              child: OutlinedButton.icon(
                onPressed: onMoreFilters,
                icon: Icon(
                  Icons.filter_alt_outlined,
                  size: 19,
                  color: hasAmountFilter
                      ? InvoiceCenterStyle.gold
                      : InvoiceCenterStyle.ink,
                ),
                label: Text(hasAmountFilter ? 'Filters On' : 'More Filters'),
                style: _buttonStyle(),
              ),
            ),
            IconButton.outlined(
              onPressed: onRefresh,
              tooltip: 'Refresh invoices',
              icon: const Icon(Icons.refresh_rounded),
              style: IconButton.styleFrom(
                foregroundColor: InvoiceCenterStyle.ink,
                backgroundColor: Colors.white,
                side: const BorderSide(color: InvoiceCenterStyle.border),
                minimumSize: const Size(44, 44),
              ),
            ),
          ];
          return wide
              ? Row(
                  children: [
                    for (var index = 0; index < controls.length; index++) ...[
                      if (index > 0) const SizedBox(width: 10),
                      controls[index],
                    ],
                  ],
                )
              : Wrap(spacing: 10, runSpacing: 10, children: controls);
        },
      );

  Widget _monthControl() => Container(
        height: 48,
        decoration: InvoiceCenterStyle.panel(radius: 10),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.calendar_month_outlined,
                size: 20, color: InvoiceCenterStyle.ink),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                usesMonth ? InvoiceCenterFormat.month(month) : 'All dates',
                style: const TextStyle(
                  color: InvoiceCenterStyle.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: InvoiceCenterStyle.bodyTextSize,
                ),
              ),
            ),
            IconButton(
              onPressed: usesMonth ? () => onMonthChange(-1) : null,
              tooltip: 'Previous month',
              icon: const Icon(Icons.chevron_left_rounded),
              iconSize: 19,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: usesMonth ? () => onMonthChange(1) : null,
              tooltip: 'Next month',
              icon: const Icon(Icons.chevron_right_rounded),
              iconSize: 19,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );

  Widget _searchControl() => Container(
        height: 48,
        decoration: InvoiceCenterStyle.panel(radius: 10),
        child: TextField(
          controller: searchController,
          onChanged: onSearch,
          style: const TextStyle(
            color: InvoiceCenterStyle.ink,
            fontSize: InvoiceCenterStyle.bodyTextSize,
            fontWeight: InvoiceCenterStyle.bodyTextWeight,
          ),
          decoration: const InputDecoration(
            hintText: 'Search by invoice no., customer, mobile...',
            hintStyle: TextStyle(
              color: InvoiceCenterStyle.muted,
              fontSize: InvoiceCenterStyle.bodyTextSize,
              fontWeight: InvoiceCenterStyle.bodyTextWeight,
            ),
            prefixIcon: Icon(Icons.search_rounded,
                color: InvoiceCenterStyle.muted, size: 21),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      );

  Widget _dropdown({
    required String value,
    required List<String> values,
    required String allLabel,
    required ValueChanged<String> onChanged,
  }) {
    final options = <String>['', ...values];
    if (value.isNotEmpty && !options.contains(value)) options.add(value);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: InvoiceCenterStyle.panel(radius: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: const TextStyle(
            color: InvoiceCenterStyle.ink,
            fontWeight: InvoiceCenterStyle.bodyTextWeight,
            fontSize: InvoiceCenterStyle.bodyTextSize,
          ),
          dropdownColor: Colors.white,
          items: [
            for (final option in options)
              DropdownMenuItem(
                value: option,
                child: Text(option.isEmpty ? allLabel : option,
                    overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (option) {
            if (option != null) onChanged(option);
          },
        ),
      ),
    );
  }

  List<String> _statusesFor(InvoiceCenterTab tab) => switch (tab) {
        InvoiceCenterTab.due => ['DUE', 'PARTIALLY_RETURNED', 'RETURNED'],
        InvoiceCenterTab.advance => ['ADVANCE'],
        InvoiceCenterTab.cancelled => ['CANCELLED'],
        InvoiceCenterTab.regular || InvoiceCenterTab.gst => [
            'DUE',
            'SETTLED',
            'PARTIALLY_RETURNED',
            'RETURNED'
          ],
        InvoiceCenterTab.all => [
            'DUE',
            'SETTLED',
            'ADVANCE',
            'DELIVERED',
            'CANCELLED',
            'PARTIALLY_RETURNED',
            'RETURNED',
          ],
      };

  ButtonStyle _buttonStyle() => OutlinedButton.styleFrom(
        foregroundColor: InvoiceCenterStyle.ink,
        backgroundColor: Colors.white,
        side: const BorderSide(color: InvoiceCenterStyle.border),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontSize: InvoiceCenterStyle.bodyTextSize,
          fontWeight: InvoiceCenterStyle.bodyTextWeight,
        ),
      );
}

import 'package:flutter/material.dart';

import '../../../logic/finance/due_report/due_report_controller.dart';
import '../../../models/finance/due_report/due_report_model.dart';
import '../../../theme/finance/due_report/due_report_theme.dart';
import 'due_report_filter_chip.dart';

class DueReportFilterBar extends StatelessWidget {
  const DueReportFilterBar({
    super.key,
    required this.ctrl,
    required this.onPrint,
    required this.onExport,
  });

  final DueReportController ctrl;
  final VoidCallback onPrint;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: DueReportStyles.panel(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                _SearchBox(ctrl: ctrl),
                if (ctrl.allDueBillCount > 0) ...[
                  const SizedBox(height: 10),
                  _ToolsRow(
                    ctrl: ctrl,
                    onPrint: onPrint,
                    onExport: onExport,
                  ),
                ],
              ] else
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: _SearchBox(ctrl: ctrl),
                        ),
                      ),
                    ),
                    if (ctrl.allDueBillCount > 0) ...[
                      const SizedBox(width: 12),
                      _ToolsRow(
                        ctrl: ctrl,
                        onPrint: onPrint,
                        onExport: onExport,
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final filter in ctrl.availableFilters)
                    DueReportFilterChip(
                      filter: filter,
                      count: ctrl.filterCount(filter),
                      selected: ctrl.filter == filter,
                      onSelected: () => ctrl.setFilter(filter),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.ctrl});

  final DueReportController ctrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: ctrl.searchCtrl,
        style: DueReportStyles.label.copyWith(fontSize: 14),
        decoration: InputDecoration(
          hintText: DueReportStrings.searchHint,
          hintStyle: DueReportStyles.label.copyWith(fontSize: 14),
          prefixIcon: const Icon(
            DueReportIcons.search,
            color: DueReportColors.textPrimary,
            size: 20,
          ),
          suffixIcon: ctrl.searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(DueReportIcons.clear, size: 18),
                  onPressed: ctrl.clearSearch,
                ),
          filled: true,
          fillColor: DueReportColors.panelBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          border: _border(DueReportColors.border),
          enabledBorder: _border(DueReportColors.border),
          focusedBorder: _border(DueReportColors.gold),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color),
      );
}

class _ToolsRow extends StatelessWidget {
  const _ToolsRow({
    required this.ctrl,
    required this.onPrint,
    required this.onExport,
  });

  final DueReportController ctrl;
  final VoidCallback onPrint;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(width: 180, child: _SortMenu(ctrl: ctrl)),
        if (ctrl.visibleGroups.isNotEmpty) ...[
          _ActionButton(
            icon: DueReportIcons.print,
            label: 'Print',
            onPressed: onPrint,
          ),
          _ActionButton(
            icon: DueReportIcons.export,
            label: 'Export',
            onPressed: onExport,
          ),
        ],
      ],
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.ctrl});

  final DueReportController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: DueReportColors.panelBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DueReportColors.border),
      ),
      child: Row(
        children: [
          const Icon(DueReportIcons.sort,
              size: 18, color: DueReportColors.textPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DueReportSort>(
                value: ctrl.sort,
                isExpanded: true,
                borderRadius: BorderRadius.circular(10),
                dropdownColor: DueReportColors.panelBg,
                iconEnabledColor: DueReportColors.textPrimary,
                style: DueReportStyles.label.copyWith(fontSize: 14),
                onChanged: (value) {
                  if (value != null) ctrl.setSort(value);
                },
                items: [
                  for (final sort in DueReportSort.values)
                    DropdownMenuItem(
                      value: sort,
                      child: Text(sort.label,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: DueReportColors.textPrimary,
          backgroundColor: DueReportColors.panelBg,
          side: const BorderSide(color: DueReportColors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: DueReportStyles.label.copyWith(fontSize: 14),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

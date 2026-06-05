import 'package:flutter/material.dart';

import '../../../logic/finance/due_report/due_report_controller.dart';
import '../../../models/finance/due_report/due_report_model.dart';
import '../../../theme/finance/due_report/due_report_theme.dart';

class DueReportFilterBar extends StatelessWidget {
  final DueReportController ctrl;
  final VoidCallback onPrint;
  final VoidCallback onExport;

  const DueReportFilterBar({
    super.key,
    required this.ctrl,
    required this.onPrint,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DueReportStyles.flatPanel(),
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SearchBox(ctrl: ctrl),
                    const SizedBox(height: 10),
                    _FilterChips(ctrl: ctrl),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _SortMenu(ctrl: ctrl)),
                        const SizedBox(width: 10),
                        _ActionButton(
                          icon: DueReportIcons.print,
                          label: 'Print',
                          onTap: onPrint,
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          icon: DueReportIcons.export,
                          label: 'Export',
                          onTap: onExport,
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(width: 340, child: _SearchBox(ctrl: ctrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _FilterChips(ctrl: ctrl)),
                    const SizedBox(width: 12),
                    SizedBox(width: 190, child: _SortMenu(ctrl: ctrl)),
                    const SizedBox(width: 10),
                    _ActionButton(
                      icon: DueReportIcons.print,
                      label: 'Print',
                      onTap: onPrint,
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: DueReportIcons.export,
                      label: 'Export',
                      onTap: onExport,
                    ),
                  ],
                );
        },
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final DueReportController ctrl;
  const _SearchBox({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: ctrl.searchCtrl,
        style: DueReportStyles.rowTitle.copyWith(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: DueReportStrings.searchHint,
          hintStyle: DueReportStyles.muted,
          prefixIcon: const Icon(
            DueReportIcons.search,
            color: DueReportColors.textMuted,
            size: 18,
          ),
          suffixIcon: ctrl.searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(DueReportIcons.clear, size: 16),
                  onPressed: ctrl.clearSearch,
                ),
          filled: true,
          fillColor: DueReportColors.panelSoft,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: DueReportColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: DueReportColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: DueReportColors.gold),
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final DueReportController ctrl;
  const _FilterChips({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: DueReportFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final filter = DueReportFilter.values[index];
          final active = ctrl.filter == filter;
          return InkWell(
            onTap: () => ctrl.setFilter(filter),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: active
                    ? DueReportColors.appBarBg
                    : DueReportColors.panelSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: active ? DueReportColors.gold : DueReportColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  filter.label,
                  style: DueReportStyles.label.copyWith(
                    color: active
                        ? DueReportColors.textLight
                        : DueReportColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  final DueReportController ctrl;
  const _SortMenu({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: DueReportColors.panelSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DueReportColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            DueReportIcons.sort,
            size: 17,
            color: DueReportColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DueReportSort>(
                value: ctrl.sort,
                isExpanded: true,
                iconSize: 18,
                style: DueReportStyles.label,
                onChanged: (value) {
                  if (value != null) ctrl.setSort(value);
                },
                items: DueReportSort.values
                    .map(
                      (sort) => DropdownMenuItem(
                        value: sort,
                        child: Text(
                          sort.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted || _hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color:
                _hovered ? DueReportColors.goldSoft : DueReportColors.panelSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered ? DueReportColors.gold : DueReportColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 17, color: DueReportColors.gold),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: DueReportStyles.label.copyWith(
                  color: DueReportColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

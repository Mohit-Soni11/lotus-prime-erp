import 'package:flutter/material.dart';
import 'package:lotus_erp/features/stock/shared/application/supplier_list_logic.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_enums.dart';
import 'package:lotus_erp/theme/stock/supplier/supplier_list/supplier_list_theme.dart';

class SupplierListToolbar extends StatelessWidget {
  const SupplierListToolbar({
    super.key,
    required this.logic,
    required this.controller,
  });

  final SupplierListLogic logic;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: SupplierListStyles.statsCardDecoration,
          child: LayoutBuilder(builder: (context, constraints) {
            final search = TextField(
              controller: controller,
              onChanged: logic.onSearchChanged,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Search name, mobile, contact person, or GST',
                hintStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: Colors.black),
                suffixIcon: logic.isSearching
                    ? IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          controller.clear();
                          logic.clearSearch();
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            );
            final filters = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SupplierFilter.values.map((filter) {
                final selected = filter == logic.activeFilter;
                return SupplierFilterButton(
                  filter: filter,
                  selected: selected,
                  onPressed: () => logic.setFilter(filter),
                );
              }).toList(),
            );
            if (constraints.maxWidth < 850) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [search, const SizedBox(height: 12), filters]);
            }
            return Row(children: [
              Expanded(flex: 4, child: search),
              const SizedBox(width: 12),
              Expanded(flex: 5, child: filters),
            ]);
          }),
        ),
      );
}

class SupplierFilterButton extends StatelessWidget {
  const SupplierFilterButton({
    super.key,
    required this.filter,
    required this.selected,
    required this.onPressed,
  });

  final SupplierFilter filter;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: selected
              ? const Icon(Icons.check_circle_rounded, size: 16)
              : const SizedBox.shrink(),
          label: Text(filter.label),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: selected
                ? SupplierListColors.brandGold.withValues(alpha: 0.2)
                : SupplierListColors.chipInactiveBg,
            side: BorderSide(
              color: selected
                  ? SupplierListColors.brandGold
                  : SupplierListColors.bodyBorder,
            ),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );
}

import 'package:flutter/material.dart';

import 'package:lotus_erp/features/stock/shared/application/stock_transfer_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_transfer/stock_transfer_models.dart';
import 'package:lotus_erp/features/stock/shared/presentation/stock_transfer/widgets/stock_transfer_shared_widgets.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class StockTransferAvailablePanel extends StatelessWidget {
  final StockTransferController controller;
  final TextEditingController searchController;

  const StockTransferAvailablePanel({
    super.key,
    required this.controller,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return TransferPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TransferSectionHeader(
            icon: Icons.inventory_2_outlined,
            title: 'Available Stock',
            subtitle: 'Select HUID or weight-tracked units for transfer.',
            trailing: Text(
              '${controller.availableUnits.length} shown',
              style: InvStyles.cardNote,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: searchController,
            onChanged: controller.setSearchText,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Search SKU, HUID, item, supplier or batch',
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: InvColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: InvColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: InvColors.brandGold, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final metal in const [
                'All',
                'Gold',
                'Silver',
                'Platinum',
                'Diamond',
              ])
                TransferChip(
                  label: metal,
                  selected: controller.metalFilter == metal,
                  onTap: () => controller.setMetalFilter(metal),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (controller.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 34),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.availableUnits.isEmpty)
            const _TransferEmptyState(
              title: 'No Available Stock Found',
              subtitle: 'Try another metal, HUID, item name or batch code.',
            )
          else
            ...controller.availableUnits.map(
              (unit) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TransferUnitCard(
                  unit: unit,
                  selected: controller.isSelected(unit.id),
                  onTap: () => controller.toggleUnit(unit),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TransferUnitCard extends StatelessWidget {
  final StockTransferUnit unit;
  final bool selected;
  final VoidCallback onTap;

  const _TransferUnitCard({
    required this.unit,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _metalColor(unit.metalType);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.1)
              : const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? accent : InvColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                selected ? Icons.check_rounded : Icons.add_rounded,
                color: accent,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.displayName,
                    style: InvStyles.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${unit.metalType} | ${unit.trackingCode} | ${unit.currentLocation}',
                    style: InvStyles.itemSku,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _TinyMetric(label: 'Net', value: transferWeight(unit.netWeight)),
            const SizedBox(width: 10),
            _TinyMetric(label: 'Cost', value: transferMoney(unit.unitCost)),
          ],
        ),
      ),
    );
  }
}

class _TinyMetric extends StatelessWidget {
  final String label;
  final String value;

  const _TinyMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: InvStyles.itemFieldLabel),
          const SizedBox(height: 2),
          Text(
            value,
            style: InvStyles.itemFieldValue.copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TransferEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TransferEmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InvColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: InvColors.textHint,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(title, style: InvStyles.sectionTitle),
          const SizedBox(height: 4),
          Text(subtitle,
              style: InvStyles.cardNote, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

Color _metalColor(String metal) {
  switch (metal.trim().toLowerCase()) {
    case 'gold':
      return const Color(0xFFD97706);
    case 'silver':
      return const Color(0xFF64748B);
    case 'platinum':
      return const Color(0xFF7C3AED);
    case 'diamond':
      return const Color(0xFF0891B2);
    default:
      return InvColors.brandGold;
  }
}

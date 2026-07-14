part of '../inventory_screen.dart';

class _InventorySubCategoryGroup {
  final String subCategory;
  final List<StockItem> items;
  final int totalQuantity;
  final double totalNetWeight;
  final double totalFineGold;
  final double totalValue;
  final List<String> purityTags;

  const _InventorySubCategoryGroup({
    required this.subCategory,
    required this.items,
    required this.totalQuantity,
    required this.totalNetWeight,
    required this.totalFineGold,
    required this.totalValue,
    required this.purityTags,
  });
}

class _GoldInventoryGroupCard extends StatelessWidget {
  final _InventorySubCategoryGroup group;
  final NumberFormat rupeeFormat;
  final NumberFormat wtFormat;

  const _GoldInventoryGroupCard({
    required this.group,
    required this.rupeeFormat,
    required this.wtFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: InvStyles.cardDecoration.copyWith(
        border: Border.all(
          color: InvColors.brandGold.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: InvColors.brandGold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: InvColors.brandGold.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    InvIcons.catGold,
                    color: InvColors.brandGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.subCategory.toUpperCase(),
                        style: InvStyles.sectionTitle.copyWith(
                          color: InvColors.textDark,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.items.length} stock line${group.items.length == 1 ? '' : 's'} combined in one gold ledger card.',
                        style: InvStyles.cardNote,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: InvColors.brandGoldLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: InvColors.brandGold.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'COMBINED VALUE',
                        style: InvStyles.cardNote.copyWith(
                          color: InvColors.brandGold,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        rupeeFormat.format(group.totalValue),
                        style: InvStyles.cardSubValue.copyWith(
                          color: InvColors.brandGold,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _groupMetric(
                  'Pieces',
                  '${group.totalQuantity} pcs',
                  InvColors.brandGold,
                ),
                _groupMetric(
                  'Net Weight',
                  '${wtFormat.format(group.totalNetWeight)} g',
                  InvColors.closingAccent,
                ),
                _groupMetric(
                  'Fine Gold',
                  '${wtFormat.format(group.totalFineGold)} g',
                  InvColors.openingAccent,
                ),
                if (group.purityTags.isNotEmpty)
                  _groupMetric(
                    'Purity Mix',
                    group.purityTags.join(' â€¢ '),
                    InvColors.textMuted,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                for (int index = 0; index < group.items.length; index++) ...[
                  _GoldInventoryMiniRow(
                    item: group.items[index],
                    rupeeFormat: rupeeFormat,
                    wtFormat: wtFormat,
                  ),
                  if (index < group.items.length - 1)
                    const Divider(height: 18, color: InvColors.cardBorder),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupMetric(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: InvStyles.cardNote.copyWith(fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            value,
            style: InvStyles.cardSubValue.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldInventoryMiniRow extends StatelessWidget {
  final StockItem item;
  final NumberFormat rupeeFormat;
  final NumberFormat wtFormat;

  const _GoldInventoryMiniRow({
    required this.item,
    required this.rupeeFormat,
    required this.wtFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.itemName,
                style: InvStyles.itemName.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  'SKU ${item.sku}',
                  if ((item.purity ?? '').isNotEmpty) item.purity!,
                  if ((item.huid ?? '').isNotEmpty) 'HUID ${item.huid}',
                ].join('  â€¢  '),
                style: InvStyles.itemSku,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${wtFormat.format(item.netWeight)} g',
          style: InvStyles.itemFieldValue,
        ),
        const SizedBox(width: 16),
        Text(
          rupeeFormat.format(item.mrp > 0 ? item.mrp : item.purchasePrice),
          style: InvStyles.itemMrp.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}

// =============================================================================
// SUMMARY CARD WIDGET
// =============================================================================

part of 'supplier_profile_screen.dart';

class _SupplierBatchCard extends StatelessWidget {
  const _SupplierBatchCard({required this.batch});

  final SupplierStockBatch batch;

  @override
  Widget build(BuildContext context) {
    final color = batch.isActive
        ? SupplierProfileColors.success
        : SupplierProfileColors.bodyTextMuted;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: SupplierProfileStyles.softPanelDecoration,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: SupplierProfileStyles.tintedPanel(color),
            child: Icon(SupplierProfileIcons.inventory, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(batch.code, style: SupplierProfileStyles.historyTitle),
                const SizedBox(height: 4),
                Text(
                  [batch.metalTypes, batch.itemNames]
                      .where((value) => value.trim().isNotEmpty)
                      .join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SupplierProfileStyles.historyMeta,
                ),
                const SizedBox(height: 4),
                Text(
                  '${batch.availableUnits} of ${batch.totalUnits} stock units available',
                  style: SupplierProfileStyles.historyMeta,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _MiniBadge(batch.statusLabel, color),
        ],
      ),
    );
  }
}

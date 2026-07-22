part of 'gold_purity_step.dart';

class _StockGroupRow extends StatelessWidget {
  final _StockGroup group;

  const _StockGroupRow({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: group.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: group.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _IconBadge(icon: group.icon, color: group.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.label, style: _titleStyle(13)),
                const SizedBox(height: 2),
                Text(group.description, style: _bodyStyle(11)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${group.fineWeight.toStringAsFixed(3)} g',
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: group.color,
                    ),
                  ),
                ),
                Text('Total Fine', style: _bodyStyle(10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStockState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GoldStockColors.brandGoldLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GoldStockColors.brandGold.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_outlined,
            size: 28,
            color: GoldStockColors.brandGold.withValues(alpha: 0.70),
          ),
          const SizedBox(height: 8),
          Text(
            'No gold stock recorded yet.',
            textAlign: TextAlign.center,
            style: _titleStyle(13),
          ),
          const SizedBox(height: 4),
          Text(
            'Saved batches will appear here by business grade.',
            textAlign: TextAlign.center,
            style: _bodyStyle(11),
          ),
        ],
      ),
    );
  }
}

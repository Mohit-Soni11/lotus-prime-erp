part of 'silver_purity_step.dart';

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
                Text(
                  group.label,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: SilverStockColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  group.description,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: SilverStockColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${group.fineWeight.toStringAsFixed(3)} g',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: group.color,
                ),
              ),
              Text(
                'Total Fine',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: SilverStockColors.textMuted,
                ),
              ),
            ],
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
        color: SilverStockColors.brandSilverLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SilverStockColors.brandSilver.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_outlined,
            size: 28,
            color: SilverStockColors.brandSilver.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 8),
          Text(
            'No silver stock recorded yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: SilverStockColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Saved batches will appear here by business grade.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              height: 1.5,
              color: SilverStockColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

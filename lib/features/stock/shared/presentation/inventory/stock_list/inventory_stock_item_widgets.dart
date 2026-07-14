part of '../inventory_screen.dart';

class _StockItemCard extends StatefulWidget {
  final StockItem item;
  final NumberFormat rupeeFormat;
  final NumberFormat wtFormat;
  const _StockItemCard({
    required this.item,
    required this.rupeeFormat,
    required this.wtFormat,
  });

  @override
  State<_StockItemCard> createState() => _StockItemCardState();
}

class _StockItemCardState extends State<_StockItemCard> {
  bool _hovered = false;

  (Color, Color, Color) _statusColors(String status) {
    if (status == StockStatus.available.label) {
      return (
        InvColors.statusAvailBg,
        InvColors.statusAvailText,
        InvColors.closingAccent,
      );
    }
    if (status == StockStatus.sold.label) {
      return (
        InvColors.statusSoldBg,
        InvColors.statusSoldText,
        InvColors.danger,
      );
    }
    if (status == StockStatus.onOrder.label) {
      return (
        InvColors.statusOrderBg,
        InvColors.statusOrderText,
        InvColors.warning,
      );
    }
    return (
      InvColors.statusKarigarBg,
      InvColors.statusKarigarText,
      InvColors.openingAccent,
    );
  }

  Color _categoryAccent(String cat) {
    if (cat == StockCategory.gold.label) return InvColors.brandGold;
    if (cat == StockCategory.silver.label) return const Color(0xFF94A3B8);
    if (cat == StockCategory.diamond.label) return const Color(0xFF3B82F6);
    if (cat == StockCategory.platinum.label) return const Color(0xFF8B5CF6);
    return InvColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final (statusBg, statusText, _) = _statusColors(item.status);
    final accent = _categoryAccent(item.category);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _hovered ? InvColors.cardBg : InvColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                _hovered ? accent.withValues(alpha: 0.5) : InvColors.cardBorder,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? accent.withValues(alpha: 0.10)
                  : InvColors.shadowLight,
              blurRadius: _hovered ? 20 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.2)),
                ),
                child: Icon(
                  _categoryIcon(item.category),
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),

              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.itemName,
                            style: InvStyles.itemName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(
                          label: item.status,
                          bg: statusBg,
                          textColor: statusText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // SKU + category
                    Row(
                      children: [
                        Text(
                          '${InvStrings.lblSku}: ${item.sku}',
                          style: InvStyles.itemSku,
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.category,
                            style: InvStyles.itemSku.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (item.purity != null &&
                            (item.purity ?? '').isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text('â€¢ ${item.purity}', style: InvStyles.itemSku),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Stats row
                    Row(
                      children: [
                        _StatChip(
                          label: 'Gross',
                          value: '${widget.wtFormat.format(item.grossWeight)}g',
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: 'Net',
                          value: '${widget.wtFormat.format(item.netWeight)}g',
                        ),
                        const SizedBox(width: 8),
                        _StatChip(label: 'Qty', value: '${item.quantity} pcs'),
                        const Spacer(),
                        // MRP
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('MRP', style: InvStyles.itemFieldLabel),
                            Text(
                              widget.rupeeFormat.format(item.mrp),
                              style: InvStyles.itemMrp,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    if (cat == StockCategory.gold.label) return InvIcons.catGold;
    if (cat == StockCategory.silver.label) return InvIcons.catSilver;
    if (cat == StockCategory.diamond.label) return InvIcons.catDiamond;
    if (cat == StockCategory.platinum.label) return InvIcons.catPlatinum;
    if (cat == StockCategory.antique.label) return InvIcons.catAntique;
    return InvIcons.catDefault;
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: InvStyles.itemFieldLabel),
        Text(value, style: InvStyles.itemFieldValue),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  const _StatusBadge({
    required this.label,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: InvStyles.statusBadge(bg, textColor),
      child: Text(label, style: InvStyles.statusBadgeText(textColor)),
    );
  }
}

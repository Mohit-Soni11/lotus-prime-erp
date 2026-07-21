part of '../inventory_screen.dart';

class _InventoryItemSummaryAccumulator {
  final String itemType;
  final Map<String, _InventoryItemNameSummaryAccumulator> variants =
      <String, _InventoryItemNameSummaryAccumulator>{};
  int totalPieces = 0;
  int availablePieces = 0;
  int soldPieces = 0;
  double grossWeight = 0;
  double totalWeight = 0;
  double availableWeight = 0;
  double soldWeight = 0;

  _InventoryItemSummaryAccumulator(this.itemType);

  void add(_InventoryGradeUnit unit) {
    final itemName = unit.itemName.trim().isNotEmpty
        ? _titleCase(unit.itemName)
        : 'Unnamed ${itemType.trim()}';
    variants
        .putIfAbsent(
          itemName.toLowerCase(),
          () => _InventoryItemNameSummaryAccumulator(itemName),
        )
        .add(unit);
    totalPieces += unit.totalPieces;
    availablePieces += unit.availablePieces;
    soldPieces += unit.soldPieces;
    grossWeight += unit.totalGrossWeight;
    totalWeight += unit.totalNetWeight;
    availableWeight += unit.availableNetWeight;
    soldWeight += unit.soldNetWeight;
  }

  _InventoryItemSummary toSummary() {
    final itemNames = variants.values.map((entry) => entry.toSummary()).toList()
      ..sort((a, b) {
        final status = a.statusRank.compareTo(b.statusRank);
        if (status != 0) return status;
        return a.itemName.compareTo(b.itemName);
      });

    return _InventoryItemSummary(
      itemType: itemType,
      itemNames: itemNames,
      totalPieces: totalPieces,
      availablePieces: availablePieces,
      soldPieces: soldPieces,
      grossWeight: grossWeight,
      totalWeight: totalWeight,
      availableWeight: availableWeight,
      soldWeight: soldWeight,
    );
  }
}

class _InventoryItemNameSummaryAccumulator {
  final String itemName;
  int totalPieces = 0;
  int availablePieces = 0;
  int soldPieces = 0;
  double totalWeight = 0;
  double availableWeight = 0;
  double soldWeight = 0;

  _InventoryItemNameSummaryAccumulator(this.itemName);

  void add(_InventoryGradeUnit unit) {
    totalPieces += unit.totalPieces;
    availablePieces += unit.availablePieces;
    soldPieces += unit.soldPieces;
    totalWeight += unit.totalNetWeight;
    availableWeight += unit.availableNetWeight;
    soldWeight += unit.soldNetWeight;
  }

  _InventoryItemNameSummary toSummary() {
    return _InventoryItemNameSummary(
      itemName: itemName,
      totalPieces: totalPieces,
      availablePieces: availablePieces,
      soldPieces: soldPieces,
      totalWeight: totalWeight,
      availableWeight: availableWeight,
      soldWeight: soldWeight,
    );
  }
}

class _InventoryItemSummary {
  final String itemType;
  final List<_InventoryItemNameSummary> itemNames;
  final int totalPieces;
  final int availablePieces;
  final int soldPieces;
  final double grossWeight;
  final double totalWeight;
  final double availableWeight;
  final double soldWeight;

  const _InventoryItemSummary({
    required this.itemType,
    required this.itemNames,
    required this.totalPieces,
    required this.availablePieces,
    required this.soldPieces,
    required this.grossWeight,
    required this.totalWeight,
    required this.availableWeight,
    required this.soldWeight,
  });

  bool get isSoldOut => totalPieces > 0 && availablePieces <= 0;
  bool get isPartiallySold => availablePieces > 0 && soldPieces > 0;
  int get itemNameCount => itemNames.length;

  String get itemNamePreview {
    if (itemNames.isEmpty) return 'No item names recorded';
    final preview = itemNames.map((item) => item.itemName).take(3).join(', ');
    if (itemNames.length <= 3) return preview;
    return '$preview +${itemNames.length - 3} more';
  }

  String get statusLabel {
    if (isSoldOut) return 'Sold Out';
    if (isPartiallySold) return 'Partially Sold';
    return 'Ready Stock';
  }

  int get statusRank {
    if (availablePieces > 0) return 0;
    if (isSoldOut) return 2;
    return 1;
  }
}

class _InventoryItemNameSummary {
  final String itemName;
  final int totalPieces;
  final int availablePieces;
  final int soldPieces;
  final double totalWeight;
  final double availableWeight;
  final double soldWeight;

  const _InventoryItemNameSummary({
    required this.itemName,
    required this.totalPieces,
    required this.availablePieces,
    required this.soldPieces,
    required this.totalWeight,
    required this.availableWeight,
    required this.soldWeight,
  });

  bool get isSoldOut => totalPieces > 0 && availablePieces <= 0;
  int get statusRank {
    if (availablePieces > 0) return 0;
    if (isSoldOut) return 2;
    return 1;
  }
}

class _GradeItemSummaryCard extends StatefulWidget {
  final _InventoryItemSummary item;
  final StockMetalUiData ui;
  final String Function(double value) weightFormatter;

  const _GradeItemSummaryCard({
    required this.item,
    required this.ui,
    required this.weightFormatter,
  });

  @override
  State<_GradeItemSummaryCard> createState() => _GradeItemSummaryCardState();
}

class _GradeItemSummaryCardState extends State<_GradeItemSummaryCard> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final ui = widget.ui;
    final statusColor = item.isSoldOut
        ? const Color(0xFFEF4444)
        : item.isPartiallySold
            ? const Color(0xFFD97706)
            : const Color(0xFF10B981);

    return InkWell(
      onTap: () => setState(() => _showDetails = !_showDetails),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _showDetails ? ui.accent : ui.accent.withValues(alpha: 0.24),
            width: _showDetails ? 1.4 : 1,
          ),
          boxShadow: [
            if (_showDetails)
              BoxShadow(
                color: ui.accent.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.985, end: 1).animate(animation),
                child: child,
              ),
            );
          },
          child: _showDetails
              ? _buildBack(item, ui)
              : _buildFront(item, ui, statusColor),
        ),
      ),
    );
  }

  Widget _buildFront(
    _InventoryItemSummary item,
    StockMetalUiData ui,
    Color statusColor,
  ) {
    return Column(
      key: const ValueKey('front'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ui.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(ui.icon, color: ui.accent, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: InvColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.itemNamePreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: InvColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                item.statusLabel,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _GradeItemMetric(
                label: 'Available Pcs',
                value: '${item.availablePieces} pcs',
                accent: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GradeItemMetric(
                label: 'Item Names',
                value: '${item.itemNameCount}',
                accent: ui.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GradeItemMetric(
                label: 'Sold',
                value: '${item.soldPieces} pcs',
                accent: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _GradeItemMetric(
                label: 'Total Weight',
                value: '${widget.weightFormatter(item.totalWeight)} g',
                accent: ui.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GradeItemMetric(
                label: 'Available Weight',
                value: '${widget.weightFormatter(item.availableWeight)} g',
                accent: const Color(0xFF0F766E),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GradeItemMetric(
                label: 'Sold Weight',
                value: '${widget.weightFormatter(item.soldWeight)} g',
                accent: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _FlipHint(accent: ui.accent, label: 'Click to view item-name breakup'),
      ],
    );
  }

  Widget _buildBack(_InventoryItemSummary item, StockMetalUiData ui) {
    final visibleNames = item.itemNames.take(5).toList(growable: false);
    return Column(
      key: const ValueKey('back'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ui.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.category_rounded, color: ui.accent, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.itemType} Breakup',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: InvColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.itemNameCount} item names • ${item.availablePieces} available pcs',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: InvColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.flip_to_front_rounded, color: ui.accent, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        for (final variant in visibleNames) ...[
          _ItemNameBreakupRow(
            variant: variant,
            accent: ui.accent,
            weightFormatter: widget.weightFormatter,
          ),
          if (variant != visibleNames.last) const SizedBox(height: 8),
        ],
        if (item.itemNames.length > visibleNames.length) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: ui.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${item.itemNames.length - visibleNames.length} more item names in this family',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: ui.accent,
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        _FlipHint(accent: ui.accent, label: 'Click to return to summary'),
      ],
    );
  }
}

class _ItemNameBreakupRow extends StatelessWidget {
  final _InventoryItemNameSummary variant;
  final Color accent;
  final String Function(double value) weightFormatter;

  const _ItemNameBreakupRow({
    required this.variant,
    required this.accent,
    required this.weightFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
        variant.isSoldOut ? InvColors.danger : InvColors.success;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  variant.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: InvColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${variant.availablePieces} pcs',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _BreakupMiniMetric(
                  label: 'Available',
                  value: '${weightFormatter(variant.availableWeight)} g',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BreakupMiniMetric(
                  label: 'Total',
                  value: '${weightFormatter(variant.totalWeight)} g',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BreakupMiniMetric(
                  label: 'Sold',
                  value:
                      '${variant.soldPieces} pcs • ${weightFormatter(variant.soldWeight)} g',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakupMiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _BreakupMiniMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            color: InvColors.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            color: InvColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _FlipHint extends StatelessWidget {
  final Color accent;
  final String label;

  const _FlipHint({
    required this.accent,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_rounded, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeItemMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _GradeItemMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: InvColors.textMuted,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: InvColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

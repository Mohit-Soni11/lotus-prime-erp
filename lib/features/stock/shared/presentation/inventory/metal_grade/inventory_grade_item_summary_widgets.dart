part of '../inventory_screen.dart';

class _InventoryItemSummaryAccumulator {
  final String itemType;
  final String quantityUnitLabel;
  final Map<String, _InventoryItemNameSummaryAccumulator> variants =
      <String, _InventoryItemNameSummaryAccumulator>{};
  final Set<String> companyNames = <String>{};
  int totalPieces = 0;
  int availablePieces = 0;
  int soldPieces = 0;
  double totalDisplayUnits = 0;
  double availableDisplayUnits = 0;
  double soldDisplayUnits = 0;
  double grossWeight = 0;
  double totalWeight = 0;
  double availableWeight = 0;
  double soldWeight = 0;

  _InventoryItemSummaryAccumulator(this.itemType, this.quantityUnitLabel);

  void add(_InventoryGradeUnit unit) {
    final itemName = unit.itemName.trim().isNotEmpty
        ? _titleCase(unit.itemName)
        : 'Unnamed ${itemType.trim()}';
    final companyName = unit.companyName.trim();
    if (companyName.isNotEmpty) {
      companyNames.add(_titleCase(companyName));
    } else {
      companyNames.add('Unbranded Silver');
    }
    totalDisplayUnits += _inventoryTotalDisplayUnits(unit);
    availableDisplayUnits += _inventoryAvailableDisplayUnits(unit);
    soldDisplayUnits += _inventorySoldDisplayUnits(unit);
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
    final companies = companyNames.toList()..sort();

    return _InventoryItemSummary(
      itemType: itemType,
      itemNames: itemNames,
      companyNames: companies,
      quantityUnitLabel: quantityUnitLabel,
      totalPieces: totalPieces,
      availablePieces: availablePieces,
      soldPieces: soldPieces,
      totalDisplayUnits: totalDisplayUnits,
      availableDisplayUnits: availableDisplayUnits,
      soldDisplayUnits: soldDisplayUnits,
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
  final List<String> companyNames;
  final String quantityUnitLabel;
  final int totalPieces;
  final int availablePieces;
  final int soldPieces;
  final double totalDisplayUnits;
  final double availableDisplayUnits;
  final double soldDisplayUnits;
  final double grossWeight;
  final double totalWeight;
  final double availableWeight;
  final double soldWeight;

  const _InventoryItemSummary({
    required this.itemType,
    required this.itemNames,
    required this.companyNames,
    required this.quantityUnitLabel,
    required this.totalPieces,
    required this.availablePieces,
    required this.soldPieces,
    required this.totalDisplayUnits,
    required this.availableDisplayUnits,
    required this.soldDisplayUnits,
    required this.grossWeight,
    required this.totalWeight,
    required this.availableWeight,
    required this.soldWeight,
  });

  bool get isSoldOut => totalPieces > 0 && availablePieces <= 0;
  bool get isPartiallySold => availablePieces > 0 && soldPieces > 0;
  int get itemNameCount => itemNames.length;
  int get companyCount => companyNames.length;

  String get itemNamePreview {
    if (itemNames.isEmpty) return 'No item names recorded';
    final preview = itemNames.map((item) => item.itemName).take(3).join(', ');
    if (itemNames.length <= 3) return preview;
    return '$preview +${itemNames.length - 3} more';
  }

  String get companyPreview {
    if (companyNames.isEmpty) return 'No company tagged';
    final preview = companyNames.take(3).join(', ');
    if (companyNames.length <= 3) return preview;
    return '$preview +${companyNames.length - 3} more';
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

String _inventoryQuantityUnitLabel(_InventoryGradeUnit unit) {
  final mode = unit.quantityMode.trim().toLowerCase();
  if (mode == 'packet' || mode == 'pack') return 'packet';
  if (mode == 'pair') return 'pair';
  if (mode == 'set') return 'set';
  if (mode == 'lot' || mode == 'bulk') return 'lot';

  final item = '${unit.itemType} ${unit.itemName}'.toLowerCase();
  if (item.contains('packet') || item.contains('pack')) return 'packet';
  if (item.contains('payal') ||
      item.contains('anklet') ||
      item.contains('jhumka') ||
      item.contains('earring') ||
      item.contains('tops') ||
      item.contains('bali') ||
      item.contains('kundal') ||
      item.contains('bichhiya') ||
      item.contains('toe ring')) {
    return 'pair';
  }
  if (item.contains('set') ||
      item.contains('necklace') ||
      item.contains('haar') ||
      item.contains('har') ||
      item.contains('chudi')) {
    return 'set';
  }
  return 'pcs';
}

String _inventoryAggregateUnitLabel(Set<String> unitLabels) {
  final labels = unitLabels
      .map((label) => label.trim().toLowerCase())
      .where((label) => label.isNotEmpty)
      .toSet();
  if (labels.length == 1) return labels.single;
  return 'mixed';
}

double _inventoryTotalDisplayUnits(_InventoryGradeUnit unit) {
  final label = _inventoryQuantityUnitLabel(unit);
  if (label == 'packet') {
    if (unit.packetCount > 0) return unit.packetCount.toDouble();
    return _inventoryPieceDisplayUnits(unit.totalPieces, unit);
  }
  return _inventoryPieceDisplayUnits(unit.totalPieces, unit);
}

double _inventoryAvailableDisplayUnits(_InventoryGradeUnit unit) {
  final label = _inventoryQuantityUnitLabel(unit);
  if (label == 'packet') {
    if (unit.packetCount > 0) {
      return (unit.packetCount - unit.soldQuantity)
          .clamp(0, unit.packetCount)
          .toDouble();
    }
    if (unit.soldQuantity > 0) {
      final total = _inventoryTotalDisplayUnits(unit);
      return (total - unit.soldQuantity).clamp(0.0, total).toDouble();
    }
  }
  return _inventoryPieceDisplayUnits(unit.availablePieces, unit);
}

double _inventorySoldDisplayUnits(_InventoryGradeUnit unit) {
  final label = _inventoryQuantityUnitLabel(unit);
  if (label == 'packet') {
    if (unit.packetCount > 0) {
      return unit.soldQuantity.clamp(0, unit.packetCount).toDouble();
    }
    if (unit.soldQuantity > 0) return unit.soldQuantity.toDouble();
  }
  return _inventoryPieceDisplayUnits(unit.soldPieces, unit);
}

double _inventoryPieceDisplayUnits(int pieces, _InventoryGradeUnit unit) {
  final label = _inventoryQuantityUnitLabel(unit);
  final divisor = switch (label) {
    'packet' => unit.piecesPerPacket <= 0 ? 1 : unit.piecesPerPacket,
    'pair' => 2,
    _ => 1,
  };
  return pieces / divisor;
}

String _inventoryQuantityUnitName(String label, {required bool plural}) {
  final normalized = label.trim().toLowerCase();
  return switch (normalized) {
    'packet' => plural ? 'Packets' : 'Packet',
    'pair' => plural ? 'Pairs' : 'Pair',
    'set' => plural ? 'Sets' : 'Set',
    'lot' => plural ? 'Lots' : 'Lot',
    'mixed' => plural ? 'Units' : 'Unit',
    _ => 'Pcs',
  };
}

String _inventoryDisplayQuantityText(double value, String label) {
  final rounded = value.roundToDouble();
  final quantity = (value - rounded).abs() < 0.001
      ? rounded.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  final unit = _inventoryQuantityUnitName(
    label,
    plural: (value - 1).abs() > 0.001,
  ).toLowerCase();
  return '$quantity $unit';
}

class _GradeItemSummaryCard extends StatefulWidget {
  final _InventoryItemSummary item;
  final StockMetalUiData ui;
  final String Function(double value) weightFormatter;
  final VoidCallback? onValuationProfileRequested;

  const _GradeItemSummaryCard({
    required this.item,
    required this.ui,
    required this.weightFormatter,
    this.onValuationProfileRequested,
  });

  @override
  State<_GradeItemSummaryCard> createState() => _GradeItemSummaryCardState();
}

class _GradeItemSummaryCardState extends State<_GradeItemSummaryCard> {
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
      onTap: widget.onValuationProfileRequested,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: ui.accent.withValues(alpha: 0.24),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: _buildFront(item, ui, statusColor),
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
                    item.companyPreview,
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
                label:
                    'Available ${_inventoryQuantityUnitName(item.quantityUnitLabel, plural: true)}',
                value: _inventoryDisplayQuantityText(
                  item.availableDisplayUnits,
                  item.quantityUnitLabel,
                ),
                accent: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GradeItemMetric(
                label: 'Companies',
                value: '${item.companyCount}',
                accent: ui.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GradeItemMetric(
                label: 'Sold',
                value: _inventoryDisplayQuantityText(
                  item.soldDisplayUnits,
                  item.quantityUnitLabel,
                ),
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
        if (widget.onValuationProfileRequested != null) ...[
          const SizedBox(height: 10),
          _FlipHint(
            accent: ui.accent,
            label: 'Open company valuation profile',
          ),
        ],
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

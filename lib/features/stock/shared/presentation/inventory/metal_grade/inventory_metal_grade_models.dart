part of '../inventory_screen.dart';

class _InventoryGradeSummary {
  final String gradeLabel;
  final int totalUnits;
  final int availableUnits;
  final int soldUnits;
  final int totalPieces;
  final int availablePieces;
  final int soldPieces;
  final int totalSets;
  final int availableSets;
  final String quantityUnitLabel;
  final double totalDisplayUnits;
  final double availableDisplayUnits;
  final double soldDisplayUnits;
  final int companyCount;
  final int purityGroupCount;
  final double grossWeight;
  final double netWeight;
  final double soldWeight;
  final double actualFine;
  final double valuationFine;
  final double stockValue;
  final List<_InventoryGradeAvailableInfo> availableInfo;

  const _InventoryGradeSummary({
    required this.gradeLabel,
    required this.totalUnits,
    required this.availableUnits,
    required this.soldUnits,
    required this.totalPieces,
    required this.availablePieces,
    required this.soldPieces,
    required this.totalSets,
    required this.availableSets,
    required this.quantityUnitLabel,
    required this.totalDisplayUnits,
    required this.availableDisplayUnits,
    required this.soldDisplayUnits,
    required this.companyCount,
    required this.purityGroupCount,
    required this.grossWeight,
    required this.netWeight,
    required this.soldWeight,
    required this.actualFine,
    required this.valuationFine,
    required this.stockValue,
    required this.availableInfo,
  });

  bool get isSoldOut =>
      totalDisplayQuantity > 0 && availableDisplayQuantity <= 0.0001;
  bool get isPartiallySold => !isSoldOut && soldDisplayQuantity > 0.0001;

  double get totalDisplayQuantity {
    if (totalDisplayUnits > 0) return totalDisplayUnits;
    if (quantityUnitLabel == 'packet' && totalSets > 0) {
      return totalSets.toDouble();
    }
    return _inventoryGradeDisplayQuantity(totalPieces, quantityUnitLabel);
  }

  double get availableDisplayQuantity {
    if (totalDisplayUnits > 0) return availableDisplayUnits;
    if (quantityUnitLabel == 'packet' && totalSets > 0) {
      return availableSets.clamp(0, totalSets).toDouble();
    }
    return _inventoryGradeDisplayQuantity(availablePieces, quantityUnitLabel);
  }

  double get soldDisplayQuantity {
    if (totalDisplayUnits > 0) return soldDisplayUnits;
    return (totalDisplayQuantity - availableDisplayQuantity)
        .clamp(0.0, totalDisplayQuantity)
        .toDouble();
  }

  String get totalQuantityLabel =>
      _inventoryDisplayQuantityText(totalDisplayQuantity, quantityUnitLabel);

  String get availableQuantityLabel => _inventoryDisplayQuantityText(
      availableDisplayQuantity, quantityUnitLabel);

  String get soldQuantityLabel =>
      _inventoryDisplayQuantityText(soldDisplayQuantity, quantityUnitLabel);

  String get unitBalanceLabel =>
      '${_quantityNumber(availableDisplayQuantity)}/${_quantityNumber(totalDisplayQuantity)} ${_inventoryQuantityUnitName(quantityUnitLabel, plural: true).toLowerCase()}';

  String get statusLabel {
    if (isSoldOut) return 'Sold Out';
    if (isPartiallySold) return 'Partially Sold';
    return 'Ready Stock';
  }
}

class _InventoryGradeAvailableInfo {
  final String itemType;
  final String segment;
  final String itemName;
  final int pieces;
  final double grossWeight;
  final double netWeight;

  const _InventoryGradeAvailableInfo({
    required this.itemType,
    required this.segment,
    required this.itemName,
    required this.pieces,
    required this.grossWeight,
    required this.netWeight,
  });
}

enum _InventoryGroupKind { grade, company, item }

String _inventoryPrimaryGroupExpression(StockCategory metal) {
  if (metal == StockCategory.gold) {
    return '''
      CASE
        WHEN u.purity_percent > 0 THEN
          CASE CAST(ROUND(u.purity_percent * 24.0 / 100.0) AS INTEGER)
            WHEN 24 THEN '24KT (99.9%)'
            WHEN 22 THEN '22KT (91.6%)'
            WHEN 18 THEN '18KT (75%)'
            WHEN 14 THEN '14KT (58.5%)'
            WHEN 9 THEN '9KT (37.5%)'
            ELSE CAST(CAST(ROUND(u.purity_percent * 24.0 / 100.0) AS INTEGER) AS TEXT) || 'KT (' || printf('%.1f', u.purity_percent) || '%)'
          END
        ELSE COALESCE(NULLIF(TRIM(s.purity), ''), 'Custom Grade')
      END
    ''';
  }

  if (metal == StockCategory.silver) {
    return '''
      CASE
        WHEN NULLIF(TRIM(COALESCE(u.item_type, s.sub_category, '')), '') IS NOT NULL THEN
          'item|GROUP|' || lower(TRIM(COALESCE(u.item_type, s.sub_category, ''))) || '|UNIT|' || ($_inventorySummaryUnitLabelExpression)
        WHEN NULLIF(TRIM(COALESCE(u.item_name, s.item_name, '')), '') IS NOT NULL THEN
          'item|GROUP|' || lower(TRIM(COALESCE(u.item_name, s.item_name, ''))) || '|UNIT|' || ($_inventorySummaryUnitLabelExpression)
        ELSE 'item|GROUP|Silver Item|UNIT|' || ($_inventorySummaryUnitLabelExpression)
      END
    ''';
  }

  return '''
    COALESCE(
      NULLIF(TRIM(s.purity), ''),
      CASE
        WHEN u.purity_percent > 0 THEN printf('%.2f%%', u.purity_percent)
        ELSE 'Custom Grade'
      END
    )
  ''';
}

String _inventoryFallbackGroupLabel(StockCategory metal) {
  if (metal == StockCategory.gold) return 'Custom Gold Grade';
  if (metal == StockCategory.silver) return 'Silver Item';
  return 'Custom Grade';
}

String _inventoryGradeTitle(StockCategory metal, String gradeLabel) {
  final ui = stockMetalUiFor(metal);
  final parts = _inventoryGroupParts(gradeLabel);
  final label = parts.label.trim();
  if (label.isEmpty || label.toLowerCase() == 'custom grade') {
    return 'Custom ${ui.title} Stock';
  }
  if (metal == StockCategory.gold) {
    return '${_inventoryGoldGradeText(parts.label)} Gold Stock';
  }
  if (metal == StockCategory.silver) {
    final unitLabel = _inventoryGroupUnitLabel(gradeLabel);
    final unitText = unitLabel == null
        ? ''
        : ' ${_inventoryQuantityUnitName(unitLabel, plural: false)}';
    return '${_titleCase(label)}$unitText Silver Stock';
  }
  return '$label ${ui.title} Stock';
}

String _inventoryGradeSubtitle(StockCategory metal, String gradeLabel,
    int availableUnits, int totalUnits, int companyCount, int purityGroupCount,
    [String? availableQuantityLabel]) {
  final ui = stockMetalUiFor(metal);
  final parts = _inventoryGroupParts(gradeLabel);
  if (metal == StockCategory.gold) {
    final gradeText = _inventoryGoldGradeText(parts.label);
    return '$gradeText gold - ${availableQuantityLabel ?? '$availableUnits pcs'} available';
  }
  if (metal == StockCategory.silver) {
    final companyText =
        companyCount <= 1 ? '$companyCount company' : '$companyCount companies';
    final gradeText = purityGroupCount <= 1
        ? '$purityGroupCount grade'
        : '$purityGroupCount grades';
    return '${availableQuantityLabel ?? '$availableUnits pcs'} available - $companyText - $gradeText';
  }
  final purity = _inventoryGradePurityPercent(parts.label);
  final purityText = purity == null
      ? parts.label
      : '${_formatInventoryPercent(purity)}% ${ui.title.toLowerCase()} purity';
  return '$purityText - $availableUnits available items';
}

double _inventoryGradeDisplayQuantity(int pieces, String unitLabel) {
  final quantity = pieces.toDouble();
  return switch (unitLabel) {
    'pair' => quantity,
    _ => quantity,
  };
}

({String label, _InventoryGroupKind kind}) _inventoryGroupParts(String value) {
  final parts = value.split('|GROUP|');
  if (parts.length < 2) {
    final label = _inventoryGroupBaseLabel(value);
    return (label: label, kind: _InventoryGroupKind.grade);
  }
  final type = parts.first.trim().toLowerCase();
  final label = _inventoryGroupBaseLabel(parts.sublist(1).join('|GROUP|'));
  return (
    label: label,
    kind: type == 'company'
        ? _InventoryGroupKind.company
        : type == 'item'
            ? _InventoryGroupKind.item
            : _InventoryGroupKind.grade,
  );
}

String _inventoryGroupBaseLabel(String value) {
  return value
      .replaceFirst(RegExp(r'\|UNIT\|[^|]+$', caseSensitive: false), '')
      .trim();
}

String? _inventoryGroupUnitLabel(String value) {
  final match = RegExp(r'\|UNIT\|([^|]+)$', caseSensitive: false)
      .firstMatch(value.trim());
  final label = match?.group(1)?.trim().toLowerCase();
  return label == null || label.isEmpty ? null : label;
}

String _inventoryGoldGradeText(String gradeLabel) {
  final raw = gradeLabel.trim();
  if (raw.isEmpty) return 'Custom Gold Grade';
  if (RegExp(r'\b\d+(?:\.\d+)?\s*KT\b', caseSensitive: false).hasMatch(raw)) {
    return raw.replaceAll(RegExp(r'\s+'), ' ').replaceAllMapped(
          RegExp(r'\bkt\b', caseSensitive: false),
          (_) => 'KT',
        );
  }
  final purity = _inventoryGradePurityPercent(raw);
  if (purity == null) return _titleCase(raw);
  final karat = (purity * 24 / 100).round();
  return '${karat}KT (${_formatInventoryPercent(_standardGoldPurity(karat, purity))}%)';
}

double _standardGoldPurity(int karat, double fallback) {
  switch (karat) {
    case 24:
      return 99.9;
    case 22:
      return 91.6;
    case 18:
      return 75;
    case 14:
      return 58.5;
    case 9:
      return 37.5;
    default:
      return fallback;
  }
}

double? _inventoryGradePurityPercent(String gradeLabel) {
  final raw = gradeLabel.trim();
  final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
  if (match == null) return null;
  final value = double.tryParse(match.group(1) ?? '');
  if (value == null || value <= 0) return null;
  if (value > 100 && value <= 1000) return value / 10;
  return value;
}

String _formatInventoryPercent(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.001) return rounded.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

String _titleCase(String value) {
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) {
    final lower = part.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }).join(' ');
}

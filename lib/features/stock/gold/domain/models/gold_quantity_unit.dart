enum GoldQuantityUnit {
  pieces('PIECES', 'PCS', 'Pieces', 1),
  pair('PAIR', 'PAIR', 'Pair', 2),
  set('SET', 'SET', 'Set', 1),
  bulk('BULK', 'BULK', 'Bulk / Lot', 1);

  final String modeCode;
  final String shortCode;
  final String label;
  final int stockPiecesPerUnit;

  const GoldQuantityUnit(
    this.modeCode,
    this.shortCode,
    this.label,
    this.stockPiecesPerUnit,
  );

  static GoldQuantityUnit infer({
    required String category,
    required String itemName,
  }) {
    final text = '${category.trim()} ${itemName.trim()}'.toLowerCase();
    if (_containsAny(text, const [
      'jhumka',
      'earring',
      'ear ring',
      'tops',
      'bali',
      'kundal',
      'payal',
      'anklet',
      'bichhiya',
      'toe ring',
    ])) {
      return GoldQuantityUnit.pair;
    }
    if (_containsAny(text, const [
      'necklace set',
      'bridal set',
      'jewellery set',
      'jewelry set',
      'haar',
      'har',
      'chudi set',
    ])) {
      return GoldQuantityUnit.set;
    }
    if (_containsAny(text, const [
      'bar',
      'bullion',
      'scrap',
      'lot',
      'bulk',
    ])) {
      return GoldQuantityUnit.bulk;
    }
    return GoldQuantityUnit.pieces;
  }
}

bool _containsAny(String text, List<String> keywords) {
  return keywords.any(text.contains);
}

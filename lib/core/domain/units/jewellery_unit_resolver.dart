enum JewelleryUnit { pieces, pair, set, packet, lot }

extension JewelleryUnitStorage on JewelleryUnit {
  String get storageCode => switch (this) {
        JewelleryUnit.pieces => 'PIECES',
        JewelleryUnit.pair => 'PAIR',
        JewelleryUnit.set => 'SET',
        JewelleryUnit.packet => 'PACKET',
        JewelleryUnit.lot => 'LOT',
      };

  String get label => switch (this) {
        JewelleryUnit.pieces => 'Pieces',
        JewelleryUnit.pair => 'Pair',
        JewelleryUnit.set => 'Set',
        JewelleryUnit.packet => 'Packet',
        JewelleryUnit.lot => 'Lot',
      };

  static JewelleryUnit fromStorage(String value) =>
      JewelleryUnit.values.firstWhere(
        (unit) => unit.storageCode == value.trim().toUpperCase(),
        orElse: () => JewelleryUnit.pieces,
      );
}

/// Suggests a saleable unit from the item being entered. A saved stock unit or
/// a user selection always takes precedence over this suggestion.
final class JewelleryUnitResolver {
  const JewelleryUnitResolver._();

  static JewelleryUnit infer({
    required String itemName,
    String category = '',
  }) {
    final name = _normalize(itemName);
    if (name.isNotEmpty) {
      if (_matches(name, _packetWords)) return JewelleryUnit.packet;
      if (_matches(name, _lotWords)) return JewelleryUnit.lot;
      if (_matches(name, _singleWords)) return JewelleryUnit.pieces;
      if (_matches(name, _setWords)) return JewelleryUnit.set;
      if (_matches(name, _pairWords)) return JewelleryUnit.pair;
      if (_matches(name, _pairedItems)) return JewelleryUnit.pair;
      if (_matches(name, _singleItems)) return JewelleryUnit.pieces;
      final type = _normalize(category);
      if (_matches(type, _pairedItems)) return JewelleryUnit.pair;
      return JewelleryUnit.pieces;
    }

    final type = _normalize(category);
    if (_matches(type, _pairedItems)) return JewelleryUnit.pair;
    return JewelleryUnit.pieces;
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  static bool _matches(String value, List<String> phrases) => phrases.any(
        (phrase) => RegExp('(?:^| )${RegExp.escape(phrase)}(?: |\$)')
            .hasMatch(value),
      );

  static const _packetWords = ['packet', 'pack', 'pkt', 'pouch'];
  static const _lotWords = ['lot', 'bulk', 'scrap'];
  static const _singleWords = ['single', 'one piece', 'one pc'];
  static const _setWords = ['set', 'combo', 'matching set'];
  static const _pairWords = ['pair', 'jodi', 'jora'];
  static const _pairedItems = [
    'payal', 'anklet', 'bichhiya', 'bichia', 'bichiya', 'toe ring',
    'jhumka', 'jumka', 'jhumki', 'earring', 'ear ring', 'earrings',
    'ear tops', 'tops', 'bali', 'kundal', 'ear stud', 'ear studs',
  ];
  static const _singleItems = [
    'ring', 'chain', 'bracelet', 'pendant', 'locket', 'mangalsutra',
    'bangle', 'chudi', 'kada', 'necklace', 'haar', 'har', 'nose pin',
    'nath', 'nose ring', 'coin', 'bar', 'bullion', 'idol', 'murti',
    'utensil', 'gift item',
  ];
}

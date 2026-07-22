import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';

enum PosItemUnitCode {
  pieces,
  pair,
  set,
  packet,
  lot,
}

class PosItemUnitProfile {
  final PosItemUnitCode code;
  final String displayName;
  final String shortName;
  final int defaultPieceCount;
  final int stockPiecesPerUnit;
  final bool usesPieceWiseHuid;

  const PosItemUnitProfile._({
    required this.code,
    required this.displayName,
    required this.shortName,
    required this.defaultPieceCount,
    required this.stockPiecesPerUnit,
    required this.usesPieceWiseHuid,
  });

  static const pieces = PosItemUnitProfile._(
    code: PosItemUnitCode.pieces,
    displayName: 'Pieces',
    shortName: 'PCS',
    defaultPieceCount: 1,
    stockPiecesPerUnit: 1,
    usesPieceWiseHuid: true,
  );

  static const pair = PosItemUnitProfile._(
    code: PosItemUnitCode.pair,
    displayName: 'Pair',
    shortName: 'PAIR',
    defaultPieceCount: 1,
    stockPiecesPerUnit: 2,
    usesPieceWiseHuid: true,
  );

  static const set = PosItemUnitProfile._(
    code: PosItemUnitCode.set,
    displayName: 'Set',
    shortName: 'SET',
    defaultPieceCount: 1,
    stockPiecesPerUnit: 1,
    usesPieceWiseHuid: true,
  );

  static const packet = PosItemUnitProfile._(
    code: PosItemUnitCode.packet,
    displayName: 'Packet',
    shortName: 'PACK',
    defaultPieceCount: 1,
    stockPiecesPerUnit: 1,
    usesPieceWiseHuid: false,
  );

  static const lot = PosItemUnitProfile._(
    code: PosItemUnitCode.lot,
    displayName: 'Lot',
    shortName: 'LOT',
    defaultPieceCount: 1,
    stockPiecesPerUnit: 1,
    usesPieceWiseHuid: false,
  );

  static const values = [pieces, pair, set, packet, lot];

  static List<PosItemUnitProfile> invoiceOptionsForMetal(MetalType metal) {
    return switch (metal) {
      MetalType.silver => const [pieces, packet, pair, set],
      MetalType.gold => const [pieces, pair, set],
      MetalType.platinum || MetalType.diamond => const [pieces, set],
    };
  }

  static PosItemUnitProfile infer({
    required MetalType metal,
    required String itemName,
  }) {
    final text = _normalize(itemName);
    if (text.isEmpty) return pieces;

    if (_containsAny(text, _pairKeywords)) {
      return pair;
    }
    if (_containsAny(text, _setKeywords)) {
      return set;
    }
    if (metal == MetalType.silver && _containsAny(text, _packetKeywords)) {
      return packet;
    }
    if (_containsAny(text, _lotKeywords)) {
      return lot;
    }
    return pieces;
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool _containsAny(String value, List<String> keywords) {
    return keywords.any(value.contains);
  }

  static const _pairKeywords = [
    'jhumka',
    'jumka',
    'jhumki',
    'earring',
    'ear ring',
    'tops',
    'bali',
    'kundal',
    'payal',
    'anklet',
    'bichhiya',
    'bichia',
    'toe ring',
    'toe-ring',
    'kada pair',
  ];

  static const _setKeywords = [
    'necklace set',
    'bridal set',
    'jewellery set',
    'jewelry set',
    'chudi set',
    'bangle set',
    'haar set',
    'har set',
    'set',
  ];

  static const _packetKeywords = [
    'packet',
    'pkt',
    'pack',
    'pouch',
  ];

  static const _lotKeywords = [
    'bulk',
    'lot',
    'scrap',
    'bar',
    'bullion',
    'casting',
  ];
}

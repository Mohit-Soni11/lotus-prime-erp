import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../core/domain/units/jewellery_unit_resolver.dart';

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

  static PosItemUnitProfile? fromStorageValue(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }
    for (final unit in values) {
      if (unit.shortName == normalized ||
          unit.code.name.toUpperCase() == normalized) {
        return unit;
      }
    }
    return null;
  }

  static List<PosItemUnitProfile> invoiceOptionsForMetal(MetalType metal) {
    return values;
  }

  static PosItemUnitProfile infer({
    required MetalType metal,
    required String itemName,
  }) {
    final inferred = JewelleryUnitResolver.infer(itemName: itemName);
    final profile = switch (inferred) {
      JewelleryUnit.pieces => pieces,
      JewelleryUnit.pair => pair,
      JewelleryUnit.set => set,
      JewelleryUnit.packet => packet,
      JewelleryUnit.lot => lot,
    };
    return profile;
  }
}

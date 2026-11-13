import 'package:lotus_erp/core/domain/units/jewellery_unit_resolver.dart';

enum GoldQuantityUnit {
  pieces('PIECES', 'PCS', 'Pieces', 1),
  pair('PAIR', 'PAIR', 'Pair', 2),
  set('SET', 'SET', 'Set', 1),
  packet('PACKET', 'PACK', 'Packet', 1),
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
    return switch (JewelleryUnitResolver.infer(
      category: category,
      itemName: itemName,
    )) {
      JewelleryUnit.pair => GoldQuantityUnit.pair,
      JewelleryUnit.set => GoldQuantityUnit.set,
      JewelleryUnit.packet => GoldQuantityUnit.packet,
      JewelleryUnit.lot => GoldQuantityUnit.bulk,
      JewelleryUnit.pieces => GoldQuantityUnit.pieces,
    };
  }
}

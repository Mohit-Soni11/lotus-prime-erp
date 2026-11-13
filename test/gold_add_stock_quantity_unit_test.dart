import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/stock/gold/domain/models/gold_item_model.dart';
import 'package:lotus_erp/features/stock/gold/domain/models/gold_quantity_unit.dart';

void main() {
  test('gold item entry infers pair unit and HUID slots for jhumka', () {
    final item = GoldItemModel(id: 'gold-row-1');
    addTearDown(item.disposeAll);

    item.categoryCtrl.text = 'Earring / Jhumka';
    item.itemNameCtrl.text = 'Antique Jhumka';
    item.piecesCtrl.text = '1';
    item.setHuidTrackingEnabled(true);

    expect(item.quantityUnit, GoldQuantityUnit.pair);
    expect(item.enteredQuantity, 1);
    expect(item.stockPieces, 2);
    expect(item.quantityModeCode, 'PAIR');
    expect(item.packetCount, 1);
    expect(item.piecesPerPacket, 2);
    expect(item.huidControllers.length, 2);
  });

  test('gold item entry allows manual unit override', () {
    final item = GoldItemModel(id: 'gold-row-2');
    addTearDown(item.disposeAll);

    item.categoryCtrl.text = 'Earring / Jhumka';
    item.setQuantityUnit(GoldQuantityUnit.pieces);
    item.itemNameCtrl.text = 'Jhumka single repair piece';
    item.setHuidTrackingEnabled(true);

    expect(item.quantityUnit, GoldQuantityUnit.pieces);
    expect(item.stockPieces, 1);
    expect(item.huidControllers.length, 1);
  });

  test('gold packet name asks for its physical pieces per packet', () {
    final item = GoldItemModel(id: 'gold-packet');
    addTearDown(item.disposeAll);

    item.itemNameCtrl.text = 'Gold Earring Packet';
    item.piecesCtrl.text = '3';
    expect(item.quantityUnit, GoldQuantityUnit.packet);
    expect(item.stockPieces, 0);

    item.piecesPerPacketCtrl.text = '2';
    expect(item.stockPieces, 6);
    expect(item.quantityModeCode, 'PACKET');
  });
}

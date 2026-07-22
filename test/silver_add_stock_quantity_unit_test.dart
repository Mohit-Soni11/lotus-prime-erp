import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/stock/silver/domain/models/silver_item_model.dart';

void main() {
  test('silver item entry infers pair unit and HUID slots for payal', () {
    final item = SilverItemModel(id: 'silver-row-1');
    addTearDown(item.disposeAll);

    item.categoryCtrl.text = 'Anklet / Payal';
    item.itemNameCtrl.text = 'Dulhan Payal';
    item.piecesCtrl.text = '1';
    item.setHuidTrackingEnabled(true);

    expect(item.quantityMode, SilverQuantityMode.pair);
    expect(item.enteredQuantity, 1);
    expect(item.pieces, 2);
    expect(item.quantityModeCode, 'PAIR');
    expect(item.packetCount, 1);
    expect(item.piecesPerPacket, 2);
    expect(item.huidControllers.length, 2);
  });

  test('silver item entry keeps packet mode for packet stock', () {
    final item = SilverItemModel(id: 'silver-row-2');
    addTearDown(item.disposeAll);

    item.setQuantityMode(SilverQuantityMode.packet);
    item.piecesCtrl.text = '3';
    item.piecesPerPacketCtrl.text = '4';

    expect(item.quantityMode, SilverQuantityMode.packet);
    expect(item.enteredQuantity, 3);
    expect(item.pieces, 12);
    expect(item.quantityModeCode, 'PACKET');
    expect(item.packetCount, 3);
    expect(item.piecesPerPacket, 4);
  });

  test('silver item entry allows manual unit override', () {
    final item = SilverItemModel(id: 'silver-row-3');
    addTearDown(item.disposeAll);

    item.categoryCtrl.text = 'Earring / Jhumka';
    item.setQuantityMode(SilverQuantityMode.pieces);
    item.itemNameCtrl.text = 'Single jhumka repair piece';
    item.setHuidTrackingEnabled(true);

    expect(item.quantityMode, SilverQuantityMode.pieces);
    expect(item.pieces, 1);
    expect(item.huidControllers.length, 1);
  });
}

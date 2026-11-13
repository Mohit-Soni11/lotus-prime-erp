import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/core/domain/units/jewellery_unit_resolver.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_item_unit_profile.dart';
import 'package:lotus_erp/features/sales_pos/application/pdf/pos_invoice_quantity_text.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';

void main() {
  test('explicit packaging and single words outrank jewellery defaults', () {
    expect(
      JewelleryUnitResolver.infer(itemName: 'Silver Payal Packet'),
      JewelleryUnit.packet,
    );
    expect(
      JewelleryUnitResolver.infer(itemName: 'Single Jhumka'),
      JewelleryUnit.pieces,
    );
    expect(
      JewelleryUnitResolver.infer(itemName: 'Earring Set'),
      JewelleryUnit.set,
    );
    expect(
      JewelleryUnitResolver.infer(itemName: 'Gold Bar'),
      JewelleryUnit.pieces,
    );
    expect(
      JewelleryUnitResolver.infer(itemName: 'Bulk scrap lot'),
      JewelleryUnit.lot,
    );
  });

  test('category is only used when item name is empty', () {
    expect(
      JewelleryUnitResolver.infer(
        itemName: 'Chain',
        category: 'Anklet / Payal',
      ),
      JewelleryUnit.pieces,
    );
    expect(
      JewelleryUnitResolver.infer(
        itemName: '',
        category: 'Earring / Jhumka',
      ),
      JewelleryUnit.pair,
    );
    expect(
      JewelleryUnitResolver.infer(
        itemName: 'Fancy Design',
        category: 'Anklet / Payal',
      ),
      JewelleryUnit.pair,
    );
  });

  test('invoice name does not change the saved stock unit', () {
    final item = SaleItemModel(metal: MetalType.silver);
    addTearDown(item.dispose);
    item.setStoredUnitProfile(PosItemUnitProfile.packet);
    item.descCtrl.text = 'Payal Packet';
    item.setInvoiceUnitLabel('Special Bundle');

    expect(item.unitShortName, 'PACK');
    expect(item.invoiceUnitLabel, 'Special Bundle');
    expect(item.huidSlotCount, 1);
    expect(PosInvoiceQuantityText.format(item), '1 Special Bundle');
    expect(PosInvoiceQuantityText.showInDescription(item, false), isTrue);
  });
}

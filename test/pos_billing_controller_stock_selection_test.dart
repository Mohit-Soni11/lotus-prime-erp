import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/sales_orders/sales_pos/pos_billing_controller.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_stock_lookup_model.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stock selection replaces selected purity with stock purity', () {
    final controller = PosBillingController();
    final item = SaleItemModel(metal: MetalType.gold);
    item.purityCtrl.text = '24KT';
    controller.saleItems.add(item);

    controller.applyStockSuggestionToRow(
      rowIndex: 0,
      suggestion: const PosStockLookupModel(
        stockItemId: 1,
        stockUnitId: 10,
        sku: 'PUR-GOLD-001-U001',
        itemName: 'Casting Tops',
        description: '',
        huid: 'BXZ01A',
        purity: '75',
        metal: MetalType.gold,
        categoryLabel: 'Tops',
        grossWeight: 0.680,
        lessWeight: 0,
        netWeight: 0.680,
        quantity: 1,
        status: 'Available',
      ),
    );

    expect(item.purityCtrl.text, '18KT');
    expect(item.descCtrl.text, 'Casting Tops');
    expect(item.grossCtrl.text, '0.68');

    controller.dispose();
  });
}

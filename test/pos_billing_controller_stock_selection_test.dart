import 'dart:io';

import 'package:flutter/services.dart';
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      },
    );
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
        availableQuantity: 1,
        quantityUnitLabel: 'pcs',
        status: 'Available',
      ),
    );

    expect(item.purityCtrl.text, '18KT');
    expect(item.descCtrl.text, 'Casting Tops');
    expect(item.grossCtrl.text, '0.68');

    controller.dispose();
  });

  test('stock selection fills sale row with net weight basis', () {
    final controller = PosBillingController();
    final item = SaleItemModel(metal: MetalType.silver);
    controller.saleItems.add(item);

    controller.applyStockSuggestionToRow(
      rowIndex: 0,
      suggestion: const PosStockLookupModel(
        stockItemId: 1,
        stockUnitId: 10,
        sku: 'PUR-SILVER-001-U001',
        itemName: 'Fancy Chain',
        description: '',
        huid: '',
        purity: '49',
        metal: MetalType.silver,
        categoryLabel: 'Chain',
        grossWeight: 19.600,
        lessWeight: 1.650,
        netWeight: 17.950,
        quantity: 2,
        availableQuantity: 2,
        quantityUnitLabel: 'pcs',
        status: 'Available',
      ),
    );

    expect(item.descCtrl.text, 'Fancy Chain');
    expect(item.grossCtrl.text, '17.95');
    expect(item.lessCtrl.text, isEmpty);
    expect(item.netWt, 17.95);
    expect(item.linkedStockItemId, 1);
    expect(item.linkedStockUnitId, 10);

    controller.dispose();
  });

  test('draft invoice preview can be parked after returning to new sales', () {
    final controller = PosBillingController();
    final item = SaleItemModel(metal: MetalType.gold);
    item.descCtrl.text = 'Casting Ring';
    controller.saleItems.add(item);

    expect(controller.canHoldCurrentBill, isTrue);

    controller.markCurrentSaleCommitted('INV-AJ-2026-0001');
    expect(controller.canHoldCurrentBill, isFalse);

    controller.releaseUncommittedInvoicePreview();
    expect(controller.canHoldCurrentBill, isTrue);

    controller.dispose();
  });
}

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/logic/sales_orders/sales_pos/pos_billing_controller.dart';
import 'package:lotus_erp/logic/sales_orders/sales_pos/pos_invoice_controller.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
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

  test('selected PDF template stays active when switching invoice metal',
      () async {
    final billing = PosBillingController();
    final controller = PosInvoiceController(billing: billing);

    billing.saleItems.addAll([
      SaleItemModel(metal: MetalType.gold),
      SaleItemModel(metal: MetalType.silver),
    ]);

    await controller
        .selectPrintTemplate(PrintTemplateRegistry.lotusSignature.id);
    await controller.setActivePrintMetal(MetalType.gold);
    await controller.setActivePrintMetal(MetalType.silver);

    expect(
      controller.selectedTemplateId,
      PrintTemplateRegistry.lotusSignature.id,
    );

    await controller.selectPrintTemplate(PrintTemplateRegistry.lotusEconomy.id);
    await controller.setActivePrintMetal(MetalType.gold);

    expect(
      controller.selectedTemplateId,
      PrintTemplateRegistry.lotusEconomy.id,
    );

    controller.dispose();
    billing.dispose();
  });
}

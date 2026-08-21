import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/logic/sales_orders/sales_pos/pos_billing_controller.dart';
import 'package:lotus_erp/logic/sales_orders/sales_pos/pos_invoice_controller.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';
import 'package:lotus_erp/models/setting/billing_setup/sales_billing_model.dart';
import 'package:lotus_erp/repositories/setting/billing_setup/sales_billing_repo.dart';
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

  test('PDF preview refreshes policy copy from saved Billing Setup', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = SalesBillingRepo(db: db);
    final staleSettings =
        SalesBillingModel.defaultFor(BillingMetal.gold).copyWith(
      termsAndConditions:
          'Gold items once sold will not be taken back or exchanged.\n'
          'सोने की वस्तु बिकरी के बाद वापस या एक्सचेंज नहीं की जाएगी.',
    );
    await repo.saveForMetal(staleSettings);

    final billing = PosBillingController();
    final controller = PosInvoiceController(
      billing: billing,
      salesBillingRepo: repo,
    );
    final item = SaleItemModel(metal: MetalType.gold);
    item.descCtrl.text = 'Gold Ring';
    item.purityCtrl.text = '22KT';
    item.grossCtrl.text = '1';
    item.lessCtrl.text = '0';
    item.rateCtrl.text = '1000';
    item.makingCtrl.text = '0';
    billing.saleItems.add(item);

    try {
      await controller.generateInvoice();
      expect(
        controller.metalPrintSettings[MetalType.gold]?.termsAndConditions,
        contains('बिकरी'),
      );

      final correctedSettings = staleSettings.copyWith(
        termsAndConditions:
            'Gold items once sold will not be taken back or exchanged.\n'
            'सोने की वस्तु बिक्री के बाद वापस या एक्सचेंज नहीं की जाएगी.',
      );
      await repo.saveForMetal(correctedSettings);

      await controller
          .selectPrintTemplate(PrintTemplateRegistry.lotusSignature.id);

      final refreshed =
          controller.metalPrintSettings[MetalType.gold]?.termsAndConditions;
      expect(refreshed, contains('बिक्री'));
      expect(refreshed, isNot(contains('बिकरी')));
    } finally {
      controller.dispose();
      billing.dispose();
      await db.close();
    }
  });
}

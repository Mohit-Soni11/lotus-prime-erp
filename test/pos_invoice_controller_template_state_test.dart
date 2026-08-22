import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/logic/sales_orders/sales_pos/pos_billing_controller.dart';
import 'package:lotus_erp/logic/sales_orders/sales_pos/pos_invoice_controller.dart';
import 'package:lotus_erp/models/customer/customer_enums/customer_list_enums.dart';
import 'package:lotus_erp/models/customer/customer_list/customer_list_ui_model.dart';
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

  test('invoice snapshot prints the richer selected customer address',
      () async {
    final billing = PosBillingController();
    final controller = PosInvoiceController(billing: billing);
    const selectedAddress =
        'EAST LAKSHMI NAGAR, KHEMNICHAK, PATNA, Bihar, 800027';

    billing.selectCustomer(
      CustomerListItemModel(
        id: 1,
        name: 'REYANSH SONI',
        mobile: '+91 93044 79436',
        city: selectedAddress,
        state: 'Bihar',
        type: CustomerType.standard,
        billCount: 0,
        createdAt: DateTime(2026, 8, 22),
        initials: 'RS',
      ),
    );
    billing.cityCtrl.text = 'EAST LAKSHMI NAGAR';

    final item = SaleItemModel(metal: MetalType.silver);
    item.descCtrl.text = 'PAYAL';
    item.purityCtrl.text = '92.5';
    item.grossCtrl.text = '10';
    item.lessCtrl.text = '0';
    item.rateCtrl.text = '100';
    item.makingCtrl.text = '0';
    billing.saleItems.add(item);

    try {
      await controller.generateInvoice();

      expect(controller.invoice?.customerCity, selectedAddress);
    } finally {
      controller.dispose();
      billing.dispose();
    }
  });

  test('export PDF bytes can target one metal or all metals', () async {
    final billing = PosBillingController();
    final controller = PosInvoiceController(billing: billing);
    final gold = SaleItemModel(metal: MetalType.gold);
    gold.descCtrl.text = 'Gold Ring';
    gold.purityCtrl.text = '22KT';
    gold.grossCtrl.text = '1';
    gold.lessCtrl.text = '0';
    gold.rateCtrl.text = '1000';
    gold.makingCtrl.text = '0';

    final silver = SaleItemModel(metal: MetalType.silver);
    silver.descCtrl.text = 'Silver Payal';
    silver.purityCtrl.text = '925';
    silver.grossCtrl.text = '10';
    silver.lessCtrl.text = '0';
    silver.rateCtrl.text = '100';
    silver.makingCtrl.text = '0';
    billing.saleItems.addAll([gold, silver]);

    try {
      await controller.generateInvoice();
      billing.markCurrentSaleCommitted(controller.invoice!.invoiceNumber);

      final goldBytes = await controller.buildExportPdfBytes(
        metal: MetalType.gold,
      );
      final allBytes = await controller.buildExportPdfBytes(
        includeAllMetals: true,
      );

      expect(goldBytes, isNotNull);
      expect(allBytes, isNotNull);
      expect(String.fromCharCodes(goldBytes!.take(4)), '%PDF');
      expect(String.fromCharCodes(allBytes!.take(4)), '%PDF');
      expect(allBytes.length, greaterThan(goldBytes.length));
    } finally {
      controller.dispose();
      billing.dispose();
    }
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

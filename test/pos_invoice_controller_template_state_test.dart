import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/core/documents/issued_invoice_archive.dart';
import 'package:lotus_erp/core/pdf/lotus_pdf_page_counter.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/logic/sales_orders/sales_pos/pos_billing_controller.dart';
import 'package:lotus_erp/logic/sales_orders/sales_pos/pos_invoice_controller.dart';
import 'package:lotus_erp/models/customer/customer_enums/customer_list_enums.dart';
import 'package:lotus_erp/models/customer/customer_list/customer_list_ui_model.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';
import 'package:lotus_erp/models/setting/billing_setup/sales_billing_model.dart';
import 'package:lotus_erp/repositories/sales_orders/pos/pos_checkout_repository.dart';
import 'package:lotus_erp/repositories/setting/billing_setup/sales_billing_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

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
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final billing = PosBillingController();
    final controller = _invoiceControllerForTest(billing, db);

    try {
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

      await controller
          .selectPrintTemplate(PrintTemplateRegistry.lotusEconomy.id);
      await controller.setActivePrintMetal(MetalType.gold);

      expect(
        controller.selectedTemplateId,
        PrintTemplateRegistry.lotusEconomy.id,
      );
    } finally {
      controller.dispose();
      billing.dispose();
      await db.close();
    }
  });

  test('invoice snapshot prints the richer selected customer address',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final billing = PosBillingController();
    final controller = _invoiceControllerForTest(billing, db);
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
      await db.close();
    }
  });

  test('metal settings show one metal while the full invoice keeps both',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final billing = PosBillingController();
    final controller = _invoiceControllerForTest(billing, db);
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
      final goldPreview = controller.pdfBytes;
      expect(goldPreview, isNotNull);
      expect(String.fromCharCodes(goldPreview!.take(4)), '%PDF');
      final goldPages = LotusPdfPageCounter.tryCountPages(goldPreview)!;
      expect(goldPages, greaterThan(0));
      await controller.setActivePrintMetal(MetalType.silver);
      expect(controller.effectiveActiveMetal, MetalType.silver);
      final silverPreview = controller.pdfBytes;
      expect(silverPreview, isNotNull);
      final silverPages = LotusPdfPageCounter.tryCountPages(silverPreview!)!;
      expect(silverPages, greaterThan(0));
      await controller.setActivePrintMetal(MetalType.gold);
      expect(identical(controller.pdfBytes, goldPreview), isTrue);
      final completeInvoice = await controller.generatePreviewPdfBytes();
      expect(completeInvoice, isNotNull);
      expect(LotusPdfPageCounter.tryCountPages(completeInvoice!),
          goldPages + silverPages);
      await controller.updatePrintOptions(
        copies: 1,
        duplicate: false,
        useDriverSettings: false,
      );
      expect(controller.usePrinterDriverSettings, isFalse);
    } finally {
      controller.dispose();
      billing.dispose();
      await db.close();
    }
  });

  test('finalizing from SILVER preview archives both metal pages', () async {
    final root = await Directory.systemTemp.createTemp('pos_two_metal_pdf_');
    final archive = IssuedInvoiceArchive(directoryProvider: () async => root);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final billing = PosBillingController();
    final controller = PosInvoiceController(
      billing: billing,
      database: db,
      salesBillingRepo: SalesBillingRepo(db: db),
      checkoutRepository: PosCheckoutRepository(db: db),
      issuedInvoiceArchive: archive,
    );
    addTearDown(() async {
      controller.dispose();
      billing.dispose();
      await db.close();
      await root.delete(recursive: true);
    });

    for (final metal in [MetalType.gold, MetalType.silver]) {
      billing.saleItems.add(SaleItemModel(metal: metal)
        ..descCtrl.text = '${metal.displayName} item'
        ..grossCtrl.text = '1'
        ..rateCtrl.text = '1000');
    }
    await controller.generateInvoice();
    await controller.setActivePrintMetal(MetalType.silver);
    final silverPreviewPages =
        LotusPdfPageCounter.tryCountPages(controller.pdfBytes!)!;

    await controller.finalizeInvoiceIfNeeded();

    final saved = await archive.read(
      IssuedInvoiceKind.sales,
      controller.savedBillDbId!,
      controller.invoice!.invoiceNumber,
    );
    expect(saved, isNotNull);
    expect(LotusPdfPageCounter.tryCountPages(saved!),
        greaterThan(silverPreviewPages));
    expect(await controller.buildExportPdfBytes(), orderedEquals(saved));
  });

  test('issued all-metals export reuses the archived PDF bytes', () async {
    final root = await Directory.systemTemp.createTemp('pos_issued_pdf_');
    final archive = IssuedInvoiceArchive(directoryProvider: () async => root);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final billing = PosBillingController();
    final controller = PosInvoiceController(
      billing: billing,
      database: db,
      salesBillingRepo: SalesBillingRepo(db: db),
      checkoutRepository: PosCheckoutRepository(db: db),
      issuedInvoiceArchive: archive,
    );
    addTearDown(() async {
      controller.dispose();
      billing.dispose();
      await db.close();
      await root.delete(recursive: true);
    });

    billing.saleItems.add(SaleItemModel(metal: MetalType.gold));
    await controller.generateInvoice();
    final issuedInvoice = controller.invoice!;
    controller.savedBillDbId = 777;
    controller.isSavedToDb = true;
    final issuedBytes = await (pw.Document()
          ..addPage(pw.Page(build: (_) => pw.Text('Issued PDF'))))
        .save();
    await archive.saveIfAbsent(
      IssuedInvoiceKind.sales,
      777,
      issuedInvoice.invoiceNumber,
      issuedBytes,
    );

    final exported = await controller.buildExportPdfBytes();
    final printed = await controller.buildPrintPdfBytes(
      controller.selectedFormat,
    );
    expect(exported, orderedEquals(issuedBytes));
    expect(printed, orderedEquals(issuedBytes));
    expect(controller.pdfBytes, orderedEquals(issuedBytes));
  });

  test('finalizing a sale stores the displayed PDF bytes', () async {
    final root = await Directory.systemTemp.createTemp('pos_finalize_pdf_');
    var failArchive = true;
    final archive = IssuedInvoiceArchive(directoryProvider: () async {
      if (failArchive) throw const FileSystemException('Archive unavailable');
      return root;
    });
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final billing = PosBillingController();
    final controller = PosInvoiceController(
      billing: billing,
      database: db,
      salesBillingRepo: SalesBillingRepo(db: db),
      checkoutRepository: PosCheckoutRepository(db: db),
      issuedInvoiceArchive: archive,
    );
    addTearDown(() async {
      controller.dispose();
      billing.dispose();
      await db.close();
      await root.delete(recursive: true);
    });

    final item = SaleItemModel(metal: MetalType.gold);
    item.descCtrl.text = 'Gold Ring';
    item.purityCtrl.text = '22KT';
    item.grossCtrl.text = '1';
    item.lessCtrl.text = '0';
    item.rateCtrl.text = '1000';
    item.makingCtrl.text = '0';
    billing.saleItems.add(item);

    await controller.generateInvoice();
    await expectLater(
      controller.finalizeInvoiceIfNeeded(),
      throwsA(isA<FileSystemException>()),
    );
    expect(controller.isSavedToDb, isTrue);
    expect(controller.isIssuedPdfSaved, isFalse);
    expect(controller.genState, InvoiceGenState.ready);

    failArchive = false;
    await controller.finalizeInvoiceIfNeeded();

    expect(controller.savedBillDbId, isNotNull);
    expect(controller.isIssuedPdfSaved, isTrue);
    expect(await db.select(db.bills).get(), hasLength(1));
    final saved = await archive.read(
      IssuedInvoiceKind.sales,
      controller.savedBillDbId!,
      controller.invoice!.invoiceNumber,
    );
    expect(saved, isNotNull);
    expect(saved, orderedEquals(controller.pdfBytes!));
    expect(await controller.buildExportPdfBytes(), orderedEquals(saved!));
    expect(
      await controller.buildPrintPdfBytes(controller.selectedFormat),
      orderedEquals(saved),
    );

    final reopened = PosInvoiceController(
      billing: billing,
      database: db,
      salesBillingRepo: SalesBillingRepo(db: db),
      checkoutRepository: PosCheckoutRepository(db: db),
      issuedInvoiceArchive: archive,
    );
    addTearDown(reopened.dispose);
    await reopened.generateInvoice();
    expect(reopened.genState, InvoiceGenState.ready);
    expect(reopened.isIssuedPdfSaved, isTrue);
    expect(reopened.pdfBytes, orderedEquals(saved));
  });

  for (final template in PrintTemplateRegistry.forDocument(
    PrintTemplateDocumentType.salesInvoice,
  )) {
    test('${template.shortName} is preserved in the issued sales PDF',
        () async {
      final root = await Directory.systemTemp.createTemp('pos_template_pdf_');
      final archive = IssuedInvoiceArchive(directoryProvider: () async => root);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final billing = PosBillingController();
      final controller = PosInvoiceController(
        billing: billing,
        database: db,
        salesBillingRepo: SalesBillingRepo(db: db),
        checkoutRepository: PosCheckoutRepository(db: db),
        issuedInvoiceArchive: archive,
      );
      addTearDown(() async {
        controller.dispose();
        billing.dispose();
        await db.close();
        await root.delete(recursive: true);
      });

      final item = SaleItemModel(metal: MetalType.gold);
      item.descCtrl.text = 'Gold Ring';
      item.purityCtrl.text = '22KT';
      item.grossCtrl.text = '1';
      item.lessCtrl.text = '0';
      item.rateCtrl.text = '1000';
      item.makingCtrl.text = '0';
      billing.saleItems.add(item);

      await controller.selectPrintTemplate(template.id);
      await controller.generateInvoice();
      expect(controller.selectedTemplateId, template.id);
      await controller.finalizeInvoiceIfNeeded();

      final archived = await archive.read(
        IssuedInvoiceKind.sales,
        controller.savedBillDbId!,
        controller.invoice!.invoiceNumber,
      );
      expect(archived, isNotNull);
      expect(archived, orderedEquals(controller.pdfBytes!));
      expect(await controller.buildExportPdfBytes(), orderedEquals(archived!));
    });
  }

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
      database: db,
      salesBillingRepo: repo,
      checkoutRepository: PosCheckoutRepository(db: db),
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

PosInvoiceController _invoiceControllerForTest(
  PosBillingController billing,
  AppDatabase db,
) {
  return PosInvoiceController(
    billing: billing,
    database: db,
    salesBillingRepo: SalesBillingRepo(db: db),
    checkoutRepository: PosCheckoutRepository(db: db),
  );
}

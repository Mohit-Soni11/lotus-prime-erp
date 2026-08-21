import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/features/settings/billing_setup/sales/application/sales_billing_controller.dart';
import 'package:lotus_erp/features/settings/billing_setup/sales/data/sales_billing_settings_repository.dart';
import 'package:lotus_erp/features/settings/billing_setup/sales/domain/sales_billing_metal_profile.dart';
import 'package:lotus_erp/models/setting/billing_setup/sales_billing_model.dart';
import 'package:lotus_erp/repositories/setting/billing_setup/sales_billing_repo.dart';

void main() {
  late AppDatabase db;
  late SalesBillingRepo repo;
  late SalesBillingController controller;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SalesBillingRepo(db: db);
    controller = SalesBillingController(
      repository: SalesBillingSettingsRepository(repo: repo),
    );
  });

  tearDown(() async {
    controller.dispose();
    await db.close();
  });

  test('Sales Billing loads independent settings for all four metals',
      () async {
    await controller.load();

    expect(controller.state.isLoading, isFalse);
    expect(
        controller.state.settingsByMetal.keys, containsAll(BillingMetal.all));
    expect(controller.state.inputsByMetal.keys, containsAll(BillingMetal.all));

    controller.selectMetal(BillingMetal.diamond);

    expect(controller.state.selectedMetal, BillingMetal.diamond);
    expect(controller.state.currentSettings?.metal, BillingMetal.diamond);
    expect(
      SalesBillingMetalProfiles.activeFieldCount(
        controller.state.currentSettings!,
      ),
      greaterThan(0),
    );

    final gold = controller.state.settingsByMetal[BillingMetal.gold]!;
    expect(gold.printTermsAndConditions, isTrue);
    expect(gold.printReturnPolicy, isTrue);
    expect(gold.printBuybackPolicy, isTrue);
  });

  test('Sales Billing saves only the selected metal settings', () async {
    await controller.load();

    final input = controller.state.currentInput!;
    controller
      ..toggleField(SalesBillingFieldKey.huid, false)
      ..updateCurrentInput(
        input.copyWith(
          returnWindowDays: '14',
          buybackRatePercent: '92.5',
        ),
      );

    expect(controller.state.isCurrentDirty, isTrue);
    expect(await controller.saveCurrent(), isTrue);

    final gold = await repo.fetchForMetal(BillingMetal.gold);
    final silver = await repo.fetchForMetal(BillingMetal.silver);

    expect(gold.showHuid, isFalse);
    expect(gold.returnWindowDays, 14);
    expect(gold.buybackRatePercent, 92.5);
    expect(
        silver.returnWindowDays,
        SalesBillingModel.defaultFor(
          BillingMetal.silver,
        ).returnWindowDays);
  });

  test('Sales Billing preserves exact bilingual policy copy when saving',
      () async {
    await controller.load();

    final input = controller.state.currentInput!;
    const exactTerms =
        'Gold items once sold will not be taken back or exchanged.\n'
        'सोने की वस्तु बिक्री के बाद वापस या एक्सचेंज नहीं की जाएगी.\n'
        '\n'
        'Store-added English line.';
    const exactReturnPolicy =
        'Gold jewellery is eligible for exchange within 7 days.\n'
        'सोने की ज्वेलरी मूल बिल के साथ 7 दिनों के अंदर मान्य है.';
    const exactBuybackPolicy =
        'Buyback is calculated after purity verification.\n'
        'बायबैक शुद्धता जांच के बाद calculated होगा.';
    const exactFooter = 'Thank you for shopping with us! Visit us again.\n'
        'खरीदारी के लिए धन्यवाद! फिर पधारें.';

    controller.updateCurrentInput(
      input.copyWith(
        termsAndConditions: exactTerms,
        returnPolicyText: exactReturnPolicy,
        buybackPolicyText: exactBuybackPolicy,
        footerMessage: exactFooter,
      ),
    );

    expect(await controller.saveCurrent(), isTrue);

    final saved = await repo.fetchForMetal(BillingMetal.gold);
    expect(saved.termsAndConditions, exactTerms);
    expect(saved.returnPolicyText, exactReturnPolicy);
    expect(saved.buybackPolicyText, exactBuybackPolicy);
    expect(saved.footerMessage, exactFooter);
  });

  test('Sales Billing saves the selected print template for the metal',
      () async {
    await controller.load();

    controller.updateSelectedTemplate(PrintTemplateRegistry.lotusSignature.id);

    expect(controller.state.isCurrentDirty, isTrue);
    expect(await controller.saveCurrent(), isTrue);

    final gold = await repo.fetchForMetal(BillingMetal.gold);
    expect(gold.selectedTemplate, PrintTemplateRegistry.lotusSignature.id);
  });

  test('Sales Billing stores print preferences in dedicated columns', () async {
    final model = SalesBillingModel.defaultFor(BillingMetal.gold).copyWith(
      selectedTemplate: PrintTemplateRegistry.lotusClassic.id,
      printTermsAndConditions: true,
      printReturnPolicy: true,
      printBuybackPolicy: false,
      printFooterMessage: false,
    );

    expect(await repo.saveForMetal(model), isTrue);

    final row = await (db.select(db.salesBillingSettings)
          ..where((table) => table.metal.equals(BillingMetal.gold)))
        .getSingle();

    expect(row.selectedTemplate, PrintTemplateRegistry.lotusClassic.id);
    expect(row.printTermsAndConditions, isTrue);
    expect(row.printReturnPolicy, isTrue);
    expect(row.printBuybackPolicy, isFalse);
    expect(row.printFooterMessage, isFalse);
  });

  test('Sales Billing migrates legacy encoded print preferences', () async {
    await db.ensureBillingSetupSchema();
    await db.customStatement(
      '''
      INSERT INTO "sales_billing_settings" (
        "metal",
        "selected_template"
      ) VALUES (?, ?)
      ''',
      [
        BillingMetal.gold,
        '${PrintTemplateRegistry.lotusSignature.id}|print:terms=1,return=1,buyback=1,footer=0',
      ],
    );

    final loaded = await repo.fetchForMetal(BillingMetal.gold);
    expect(loaded.selectedTemplate, PrintTemplateRegistry.lotusSignature.id);
    expect(loaded.printTermsAndConditions, isTrue);
    expect(loaded.printReturnPolicy, isTrue);
    expect(loaded.printBuybackPolicy, isTrue);
    expect(loaded.printFooterMessage, isFalse);

    final row = await (db.select(db.salesBillingSettings)
          ..where((table) => table.metal.equals(BillingMetal.gold)))
        .getSingle();
    expect(row.selectedTemplate, PrintTemplateRegistry.lotusSignature.id);
    expect(row.printTermsAndConditions, isTrue);
    expect(row.printReturnPolicy, isTrue);
    expect(row.printBuybackPolicy, isTrue);
    expect(row.printFooterMessage, isFalse);
  });

  test('Sales Billing ignores unknown print template ids', () async {
    await controller.load();

    controller.updateSelectedTemplate('unknown-template');

    expect(controller.state.currentSettings?.selectedTemplate,
        PrintTemplateRegistry.defaultTemplateId);
    expect(controller.state.isCurrentDirty, isFalse);
  });

  test('Sales Billing blocks invalid policy values before saving', () async {
    await controller.load();

    final input = controller.state.currentInput!;
    controller.updateCurrentInput(
      input.copyWith(
        returnWindowDays: '400',
        buybackRatePercent: '120',
      ),
    );

    expect(await controller.saveCurrent(), isFalse);
    expect(controller.state.validationMessages, isNotEmpty);

    final gold = await repo.fetchForMetal(BillingMetal.gold);
    expect(
        gold.returnWindowDays,
        SalesBillingModel.defaultFor(
          BillingMetal.gold,
        ).returnWindowDays);
  });
}

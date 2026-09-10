import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/settings/billing_setup/purchase/application/purchase_billing_controller.dart';
import 'package:lotus_erp/features/settings/billing_setup/purchase/data/purchase_billing_settings_repository.dart';
import 'package:lotus_erp/features/settings/billing_setup/purchase/domain/purchase_billing_metal_profile.dart';
import 'package:lotus_erp/models/setting/billing_setup/purchase_billing_model.dart';
import 'package:lotus_erp/models/setting/billing_setup/sales_billing_model.dart';
import 'package:lotus_erp/repositories/setting/billing_setup/purchase_billing_repo.dart';

void main() {
  late AppDatabase db;
  late PurchaseBillingRepo repo;
  late PurchaseBillingController controller;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PurchaseBillingRepo(db: db);
    controller = PurchaseBillingController(
      repository: PurchaseBillingSettingsRepository(repo: repo),
    );
  });

  tearDown(() async {
    controller.dispose();
    await db.close();
  });

  test('Purchase Billing loads independent settings for all four metals',
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
      PurchaseBillingMetalProfiles.activeFieldCount(
        controller.state.currentSettings!,
      ),
      greaterThan(0),
    );
  });

  test('Purchase Billing saves only the selected metal settings', () async {
    await controller.load();

    final input = controller.state.currentInput!;
    controller
      ..toggleField(PurchaseBillingFieldKey.huid, false)
      ..updatePrintTerms(false)
      ..updatePrintSellerDeclaration(false)
      ..updatePrintReturnPolicy(false)
      ..updatePrintBuybackPolicy(false)
      ..updatePrintFooter(false)
      ..updateCurrentInput(
        input.copyWith(
          returnWindowDays: '1',
          lateReclaimPenaltyAmount: '2500',
          highValueReclaimThreshold: '100000',
          highValueReclaimPenaltyPercent: '12',
          sellerDeclarationText:
              'Seller accepts full ownership responsibility.',
        ),
      );

    expect(controller.state.isCurrentDirty, isTrue);
    expect(await controller.saveCurrent(), isTrue);

    final gold = await repo.fetchForMetal(BillingMetal.gold);
    final silver = await repo.fetchForMetal(BillingMetal.silver);

    expect(gold.showHuid, isFalse);
    expect(gold.returnWindowDays, 1);
    expect(gold.lateReclaimPenaltyAmount, 2500);
    expect(gold.highValueReclaimThreshold, 100000);
    expect(gold.highValueReclaimPenaltyPercent, 12);
    expect(gold.printTermsAndConditions, isFalse);
    expect(gold.printSellerDeclaration, isFalse);
    expect(gold.printReturnPolicy, isFalse);
    expect(gold.printBuybackPolicy, isFalse);
    expect(gold.printFooterMessage, isFalse);
    expect(
      gold.sellerDeclarationText,
      'Seller accepts full ownership responsibility.',
    );
    expect(
      silver.returnWindowDays,
      PurchaseBillingModel.defaultFor(BillingMetal.silver).returnWindowDays,
    );
  });

  test('Purchase Billing preserves exact bilingual policy copy when saving',
      () async {
    await controller.load();

    final input = controller.state.currentInput!;
    const exactTerms = 'Seller confirms clean ownership.\n'
        'विक्रेता साफ स्वामित्व की पुष्टि करता है।\n'
        '\n'
        'Store note remains unchanged.';
    const exactSellerDeclaration = 'Seller accepts valuation before payout.\n'
        'विक्रेता भुगतान से पहले मूल्यांकन स्वीकार करता है।';
    const exactReturnPolicy =
        'Seller reclaim is allowed only with the original voucher.\n'
        'मूल वाउचर के साथ ही रिक्लेम मान्य होगा।';
    const exactBuybackPolicy = 'Payout follows purity verification.\n'
        'भुगतान शुद्धता जांच के अनुसार होगा।';
    const exactFooter =
        'Purchase voucher generated from saved Billing Setup copy.\n'
        'खरीद वाउचर सेव की गई बिलिंग सेटअप कॉपी से बनेगा।';

    controller.updateCurrentInput(
      input.copyWith(
        termsAndConditions: exactTerms,
        sellerDeclarationText: exactSellerDeclaration,
        returnPolicyText: exactReturnPolicy,
        buybackPolicyText: exactBuybackPolicy,
        footerMessage: exactFooter,
      ),
    );

    expect(await controller.saveCurrent(), isTrue);

    final saved = await repo.fetchForMetal(BillingMetal.gold);
    expect(saved.termsAndConditions, exactTerms);
    expect(saved.sellerDeclarationText, exactSellerDeclaration);
    expect(saved.returnPolicyText, exactReturnPolicy);
    expect(saved.buybackPolicyText, exactBuybackPolicy);
    expect(saved.footerMessage, exactFooter);
  });

  test('Purchase Billing blocks invalid policy values before saving', () async {
    await controller.load();

    final input = controller.state.currentInput!;
    controller.updateCurrentInput(
      input.copyWith(
        returnWindowDays: '400',
        lateReclaimPenaltyAmount: '-1',
        highValueReclaimThreshold: '-100',
        highValueReclaimPenaltyPercent: '120',
      ),
    );

    expect(await controller.saveCurrent(), isFalse);
    expect(controller.state.validationMessages, isNotEmpty);

    final gold = await repo.fetchForMetal(BillingMetal.gold);
    expect(
      gold.returnWindowDays,
      PurchaseBillingModel.defaultFor(BillingMetal.gold).returnWindowDays,
    );
  });

  test('legacy purchase billing table is upgraded with print visibility flags',
      () async {
    controller.dispose();
    await db.close();

    db = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (rawDb) {
          rawDb
            ..execute('PRAGMA user_version = 50')
            ..execute('''
              CREATE TABLE purchase_billing_settings (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                created_at INTEGER NOT NULL DEFAULT 0,
                updated_at INTEGER,
                metal TEXT NOT NULL,
                show_gross_weight INTEGER NOT NULL DEFAULT 1,
                show_less_weight INTEGER NOT NULL DEFAULT 1,
                show_net_weight INTEGER NOT NULL DEFAULT 1,
                show_purity INTEGER NOT NULL DEFAULT 1,
                show_rate INTEGER NOT NULL DEFAULT 1,
                show_fine_weight INTEGER NOT NULL DEFAULT 1,
                show_total_value INTEGER NOT NULL DEFAULT 1,
                show_stone_details INTEGER NOT NULL DEFAULT 0,
                show_stone_value INTEGER NOT NULL DEFAULT 0,
                show_huid INTEGER NOT NULL DEFAULT 0,
                show_supplier_details INTEGER NOT NULL DEFAULT 1,
                show_pan_number INTEGER NOT NULL DEFAULT 1,
                show_diamond_carats INTEGER NOT NULL DEFAULT 1,
                show_diamond_clarity INTEGER NOT NULL DEFAULT 1,
                show_certification_no INTEGER NOT NULL DEFAULT 0,
                show_gst_breakup INTEGER NOT NULL DEFAULT 0,
                show_hsn_code INTEGER NOT NULL DEFAULT 0,
                return_window_days INTEGER NOT NULL DEFAULT 1,
                return_mode TEXT NOT NULL DEFAULT 'Cash Refund',
                purity_deduct_percent REAL NOT NULL DEFAULT 2.0,
                late_reclaim_penalty_amount REAL NOT NULL DEFAULT 2000.0,
                high_value_reclaim_threshold REAL NOT NULL DEFAULT 50000.0,
                high_value_reclaim_penalty_percent REAL NOT NULL DEFAULT 12.0,
                terms_and_conditions TEXT NOT NULL DEFAULT '',
                seller_declaration_text TEXT NOT NULL DEFAULT '',
                return_policy_text TEXT NOT NULL DEFAULT '',
                buyback_policy_text TEXT NOT NULL DEFAULT '',
                footer_message TEXT NOT NULL DEFAULT '',
                selected_template TEXT NOT NULL DEFAULT 'default'
              )
            ''')
            ..execute(
              '''
              INSERT INTO purchase_billing_settings (metal, selected_template)
              VALUES ('gold', 'lotus_signature')
              ''',
            );
        },
      ),
    );

    final legacyRepo = PurchaseBillingRepo(db: db);
    controller = PurchaseBillingController(
      repository: PurchaseBillingSettingsRepository(repo: legacyRepo),
    );
    final gold = await legacyRepo.fetchForMetal(BillingMetal.gold);

    expect(gold.selectedTemplate, 'lotus_signature');
    expect(gold.printTermsAndConditions, isTrue);
    expect(gold.printSellerDeclaration, isTrue);
    expect(gold.printReturnPolicy, isTrue);
    expect(gold.printBuybackPolicy, isTrue);
    expect(gold.printFooterMessage, isTrue);
  });
}

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
}

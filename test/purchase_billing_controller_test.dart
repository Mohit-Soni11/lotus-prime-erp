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
      ..updateCurrentInput(
        input.copyWith(
          returnWindowDays: '12',
          purityDeductPercent: '4.5',
        ),
      );

    expect(controller.state.isCurrentDirty, isTrue);
    expect(await controller.saveCurrent(), isTrue);

    final gold = await repo.fetchForMetal(BillingMetal.gold);
    final silver = await repo.fetchForMetal(BillingMetal.silver);

    expect(gold.showHuid, isFalse);
    expect(gold.returnWindowDays, 12);
    expect(gold.purityDeductPercent, 4.5);
    expect(
      silver.returnWindowDays,
      PurchaseBillingModel.defaultFor(BillingMetal.silver).returnWindowDays,
    );
  });

  test('Purchase Billing blocks invalid policy values before saving', () async {
    await controller.load();

    final input = controller.state.currentInput!;
    controller.updateCurrentInput(
      input.copyWith(
        returnWindowDays: '400',
        purityDeductPercent: '120',
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

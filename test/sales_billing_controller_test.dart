import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
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

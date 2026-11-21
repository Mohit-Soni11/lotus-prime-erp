import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/setting/metal_rate/metal_rate_controller.dart';
import 'package:lotus_erp/models/live_rates/live_rates_model.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_price_unit.dart';
import 'package:lotus_erp/repositories/live_rates/live_rates_repository.dart';
import 'package:lotus_erp/repositories/setting/metal_rate/metal_rate_quote_service.dart';
import 'package:lotus_erp/repositories/setting/metal_rate/metal_rate_repository.dart';
import 'package:lotus_erp/ui/settings/metal_rate/metal_rate_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('local silver update persists to counter, billing and rate history',
      () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = MetalRateRepository(db: database);
    final base = await repository.loadProfile(MetalRateMetal.silver);
    await repository.saveProfile(base.copyWith(
      physicalMarketRatePer10g: 175000,
      oldMetalPurchaseRatePer10g: 12000,
      purityPlans: [
        for (final plan in base.purityPlans)
          plan.copyWith(
              manualDisplayRatePer10g: switch (plan.label) {
            '999' => 175000,
            '925' => 165000,
            '800' => 140000,
            _ => 110000,
          }),
      ],
    ));
    final controller = MetalRateController(repo: repository);
    addTearDown(controller.dispose);
    await controller.load();
    controller.updatePhysicalRate(MetalRateMetal.silver, 180000);
    await controller.saveProfile(controller.profileFor(MetalRateMetal.silver));
    expect(controller.state, MetalRateLoadState.loaded);
    final saved = await repository.loadProfile(MetalRateMetal.silver);
    expect(saved.purityPlans.map((plan) => plan.manualDisplayRatePer10g),
        [180000, 165000, 144000, 110000]);
    expect(saved.primaryBuyRatePer10g, 12000);
    final quote = await MetalRateQuoteService(repository: repository)
        .sellingQuote(metal: MetalRateMetal.silver, purityLabel: '999');
    expect(quote?.marketRate, 180000);
    expect(quote?.billingRate, 180);
    final history = controller.historyFor(MetalRateMetal.silver);
    expect(history.first.profile.primaryShopRatePer10g, 180000);
    expect(history.first.revision, greaterThan(history.last.revision!));
    final live = await LiveRatesRepository(repository: repository)
        .watchRates()
        .firstWhere((rates) => rates.state != LiveRateState.loading);
    expect(live.silverRates.first.perBaseUnit, '1,80,000');
    expect(live.silverRates.first.perGram, '180');
  });

  test('saved silver kg values are unchanged and billing uses grams', () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = MetalRateRepository(db: database);
    final base = await repository.loadProfile(MetalRateMetal.silver);
    final saved = base.copyWith(
      physicalMarketRatePer10g: 175000,
      marketRatePer10g: 175000,
      oldMetalPurchaseRatePer10g: 12000,
      purityPlans: [
        for (final plan in base.purityPlans)
          plan.copyWith(
              manualDisplayRatePer10g: switch (plan.label) {
            '999' => 175000,
            '925' => 165000,
            '800' => 150000,
            '700' => 110000,
            _ => 0,
          }),
      ],
    );
    await repository.saveProfile(saved);
    final reloaded = await repository.loadProfile(MetalRateMetal.silver);
    final quotes = MetalRateQuoteService(repository: repository);
    final fine = await quotes.sellingQuote(
      metal: MetalRateMetal.silver,
      purityLabel: '999',
    );
    final jewellery = await quotes.sellingQuote(
      metal: MetalRateMetal.silver,
      purityLabel: '700',
    );
    final buy = await quotes.buyingQuote(
      metal: MetalRateMetal.silver,
      purityLabel: '925',
    );

    expect(reloaded.marketBaseRatePer10g, 175000);
    expect(MetalRatePriceUnit.forMetal(MetalRateMetal.silver).toMarket(175000),
        175000);
    expect(fine?.marketRate, 175000);
    expect(fine?.billingRate, 175);
    expect(jewellery?.marketRate, 110000);
    expect(jewellery?.billingRate, 110);
    expect(buy?.billingRate, 12);

    final dashboard = await LiveRatesRepository(repository: repository)
        .watchRates()
        .firstWhere((rates) => rates.state != LiveRateState.loading);
    expect(dashboard.silverRates, hasLength(4));
    expect(dashboard.silverRates.first.perBaseUnit, '1,75,000');
    expect(dashboard.silverRates.first.perGram, '175');
    expect(dashboard.silverRates[1].perBaseUnit, '1,65,000');
    expect(dashboard.silverRates.last.perBaseUnit, '1,10,000');
    expect(dashboard.oldSilverBuy, '12,000');
  });

  test('jewellery requires an entered rate and never matches a 75% item',
      () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = MetalRateRepository(db: database);
    final base = await repository.loadProfile(MetalRateMetal.silver);
    await repository.saveProfile(base.copyWith(
      physicalMarketRatePer10g: 175000,
      marketRatePer10g: 175000,
    ));
    final quotes = MetalRateQuoteService(repository: repository);
    expect(
        await quotes.sellingQuote(
          metal: MetalRateMetal.silver,
          purityLabel: '700',
        ),
        isNull);
    expect(
        await quotes.sellingQuote(
          metal: MetalRateMetal.silver,
          purityLabel: '750',
        ),
        isNull);
  });

  test('older silver profiles gain only the 70% jewellery rate', () {
    final original = MetalRateProfile.defaultFor(MetalRateMetal.silver);
    final payload = original
        .copyWith(
          purityPlans: original.purityPlans
              .where((plan) => plan.label != '700')
              .map((plan) => plan.label == '925'
                  ? plan.copyWith(manualDisplayRatePer10g: 165000)
                  : plan)
              .toList(),
        )
        .toJson();
    final loaded = MetalRateProfile.fromJson(payload);
    expect(loaded.purityPlans.map((plan) => plan.label),
        containsAll(['999', '925', '800', '700']));
    expect(loaded.purityPlans.any((plan) => plan.label == '750'), isFalse);
    expect(
      loaded.purityPlans
          .firstWhere((plan) => plan.label == '925')
          .manualDisplayRatePer10g,
      165000,
    );
  });

  test('legacy 750 plan retains non-selling data during profile upgrade', () {
    final original = MetalRateProfile.defaultFor(MetalRateMetal.silver);
    final payload = original.copyWith(purityPlans: [
      ...original.purityPlans.where((plan) => plan.label != '700'),
      const MetalRatePurityPlan(
        label: '750',
        purityPercent: 75,
        supplierPremiumPercent: 0,
        targetMarginPercent: 0,
        buyRatePer10g: 90000,
      ),
    ]).toJson();

    final loaded = MetalRateProfile.fromJson(payload);
    expect(loaded.purityPlans.map((plan) => plan.label), contains('700'));
    expect(
        loaded.purityPlans
            .firstWhere((plan) => plan.label == '750')
            .buyRatePer10g,
        90000);
  });

  testWidgets('silver jewellery uses the same counter row as other purities',
      (tester) async {
    late AppDatabase database;
    late MetalRateController controller;
    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = MetalRateRepository(db: database);
      final base = await repository.loadProfile(MetalRateMetal.silver);
      await repository.saveProfile(base.copyWith(
        physicalMarketRatePer10g: 175000,
        marketRatePer10g: 175000,
        purityPlans: [
          for (final plan in base.purityPlans)
            plan.copyWith(
                manualDisplayRatePer10g: switch (plan.label) {
              '999' => 175000,
              '925' => 165000,
              '800' => 150000,
              _ => 0,
            }),
        ],
      ));
      controller = MetalRateController(repo: repository);
      await controller.load();
      controller.updateShopRate(
          metal: MetalRateMetal.silver, index: 1, value: 0);
    });
    addTearDown(() async {
      controller.dispose();
      await tester.runAsync(() => database.close());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final width in [1650.0, 800.0, 500.0]) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(MaterialApp(
          home: MetalRateDetailScreen(
        metal: MetalRateMetal.silver,
        controller: controller,
      )));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Counter Rate Control'), findsOneWidget);
      expect(find.text('70% purity · Local Jewellery'), findsOneWidget);
      expect(
          find.descendant(
            of: find.byKey(const ValueKey('silver-sell-1')),
            matching: find.text('₹ 1,61,875'),
          ),
          findsOneWidget);
      expect(find.textContaining('Auto'), findsOneWidget);
      expect(find.text('700'), findsWidgets);
      expect(
          find.byKey(const ValueKey('silver-jewellery-rate')), findsOneWidget);
      expect(find.byKey(const ValueKey('silver-jewellery-card')), findsNothing);
      expect(find.text('Silver Utensils & Tableware'), findsNothing);
      expect(find.text('₹ 1,75,000 / kg'), findsWidgets);
      expect(find.text('₹ 1,75,00,000'), findsNothing);
      expect(tester.takeException(), isNull, reason: 'Width $width');
    }

    final puritySelector = find.byKey(const ValueKey('history-purity-700'));
    await tester.ensureVisible(puritySelector);
    await tester.tap(puritySelector);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('No saved rate for this period'), findsOneWidget);

    await tester.ensureVisible(find.text('LIVE RATE'));
    await tester.tap(find.text('LIVE RATE'));
    await tester.pump();
    final local = find.descendant(
      of: find.byKey(const ValueKey('Local Physical Market')),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(local);
    await tester.enterText(local, '180000');
    await tester.pump();
    expect(controller.profileFor(MetalRateMetal.silver).marketBaseRatePer10g,
        180000);
    expect(controller.profileFor(MetalRateMetal.silver).primaryShopRatePer10g,
        180000);
    final selling = find.descendant(
      of: find.byKey(const ValueKey('silver-sell-0')),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(selling).controller!.text, '180000');
    final automatic925 = find.descendant(
      of: find.byKey(const ValueKey('silver-sell-1')),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(automatic925).controller!.text, '166500');

    final jewellery = find.descendant(
      of: find.byKey(const ValueKey('silver-jewellery-rate')),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(jewellery);
    await tester.enterText(jewellery, '120000');
    await tester.pump();
    expect(
      controller
          .profileFor(MetalRateMetal.silver)
          .purityPlans
          .firstWhere((plan) => plan.label == '700')
          .manualDisplayRatePer10g,
      120000,
    );
    expect(tester.takeException(), isNull);
  });
}

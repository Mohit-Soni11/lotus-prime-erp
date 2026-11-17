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
    expect(dashboard.silverRateKg, '1,75,000');
    expect(dashboard.silver999PerGram, '175');
    expect(dashboard.silver925RateKg, '1,65,000');
    expect(dashboard.silverJewellery, '1,10,000');
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
      expect(find.text('700'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('silver-jewellery-rate')), findsOneWidget);
      expect(find.byKey(const ValueKey('silver-jewellery-card')), findsNothing);
      expect(find.text('Silver Utensils & Tableware'), findsNothing);
      expect(find.text('₹ 1,75,000 / kg'), findsWidgets);
      expect(find.text('₹ 1,75,00,000'), findsNothing);
      expect(tester.takeException(), isNull, reason: 'Width $width');
    }

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

import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/setting/metal_rate/metal_rate_controller.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'package:lotus_erp/repositories/setting/metal_rate/metal_rate_repository.dart';
import 'package:lotus_erp/ui/settings/metal_rate/metal_rate_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gold rate detail matches the compact layout at desktop and narrow widths',
      (tester) async {
    late AppDatabase database;
    late MetalRateController controller;
    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = MetalRateRepository(db: database);
      final base = await repository.loadProfile(MetalRateMetal.gold);
      final plans = [
        for (final plan in base.purityPlans)
          plan.copyWith(
            manualDisplayRatePer10g: plan.label == '24K' ? 152000 : 0,
            buyRatePer10g: plan.label == '24K' ? 150000 : 0,
          ),
      ];
      await repository.saveProfile(base.copyWith(
        mcxRatePer10g: 162500,
        physicalMarketRatePer10g: 152000,
        purityPlans: plans,
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

    for (final width in [1650.0, 1200.0, 800.0, 500.0]) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(MaterialApp(
        home: MetalRateDetailScreen(
          metal: MetalRateMetal.gold,
          controller: controller,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('24K Sell'), findsOneWidget);
      expect(find.text('Market Reference'), findsOneWidget);
      expect(find.text('Counter Rate Control'), findsOneWidget);
      expect(find.text('Old Metal Purchase Rate'), findsOneWidget);
      expect(find.text('Rate History'), findsOneWidget);
      expect(find.text('LIVE RATE'), findsOneWidget);
      expect(find.text('LIVE RATES'), findsNothing);
      expect(find.text('Read only · Click Edit Rates to update'), findsNothing);
      expect(find.text('COMPARISON ONLY'), findsNothing);
      expect(find.text('PRIMARY RATE BASE'), findsNothing);
      expect(find.text('FROM 24K GOLD LOCAL RATE'), findsOneWidget);
      expect(find.text('24K · Local base'), findsNothing);
      expect(find.text('22K · 91.6%'), findsNothing);
      expect(find.text('₹ 1,52,000'), findsWidgets);
      expect(find.textContaining('Trading Spread'), findsNothing);
      final mcxCard =
          find.byKey(const ValueKey('market-reference-MCX 24K Reference'));
      final localCard =
          find.byKey(const ValueKey('market-reference-Local Physical Market'));
      final purityCard = find.byKey(const ValueKey('market-reference-purity'));
      expect(tester.getSize(mcxCard).height, tester.getSize(localCard).height);
      expect(
          tester.getSize(purityCard).height, tester.getSize(localCard).height);
      expect(
        tester
            .getTopLeft(
                find.byKey(const ValueKey('header-metric-24K Local Base')))
            .dx,
        lessThan(width * 0.4),
      );
      expect(tester.takeException(), isNull, reason: 'Viewport width: $width');
    }

    for (final period in ['month', 'year', 'current']) {
      final filter = find.byKey(ValueKey('history-$period'));
      await tester.ensureVisible(filter);
      await tester.tap(filter);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'History $period filter');
    }

    await Scrollable.ensureVisible(
      tester.element(find.text('Rate Changes')),
      alignment: 0.4,
    );
    await tester.pump();
    final page = tester.state<ScrollableState>(find.byType(Scrollable).first);
    final pageOffset = page.position.pixels;
    await tester.sendEventToBinding(PointerScrollEvent(
      position: tester.getCenter(find.text('Rate Changes')),
      scrollDelta: const Offset(0, -120),
    ));
    await tester.pump();
    expect(page.position.pixels, pageOffset);

    await tester.ensureVisible(find.text('LIVE RATE'));
    await tester.tap(find.text('LIVE RATE'));
    await tester.pump();
    expect(find.text('LIVE RATE'), findsNothing);
    expect(find.text('Save Rates'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('market-reference-purity')))
          .height,
      tester
          .getSize(find
              .byKey(const ValueKey('market-reference-Local Physical Market')))
          .height,
    );

    final mcxField = find.descendant(
      of: find.byKey(const ValueKey('MCX 24K Reference')),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(mcxField);
    await tester.enterText(mcxField, '200000');
    await tester.pump();
    expect(find.text('₹ 1,52,000'), findsWidgets);

    final localField = find.descendant(
      of: find.byKey(const ValueKey('Local Physical Market')),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(localField);
    await tester.enterText(localField, '160000');
    await tester.pump();
    expect(find.text('₹ 1,60,000'), findsWidgets);
    expect(find.text('₹ 1,46,560'), findsWidgets);

    final purchaseField = find.descendant(
      of: find.byKey(const ValueKey('old-metal-purchase-rate')),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(purchaseField);
    await tester.enterText(purchaseField, '124000');
    await tester.pump();
    expect(controller.profileFor(MetalRateMetal.gold).primaryBuyRatePer10g,
        124000);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rate Changes wheel scroll stays inside a long revision list',
      (tester) async {
    late AppDatabase database;
    late MetalRateController controller;
    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = MetalRateRepository(db: database);
      final profile = await repository.loadProfile(MetalRateMetal.gold);
      for (var index = 0; index < 12; index++) {
        await repository.saveProfile(profile.copyWith(
          purityPlans: [
            profile.purityPlans.first.copyWith(
              manualDisplayRatePer10g: 120000 + index * 100,
            ),
          ],
        ));
      }
      controller = MetalRateController(repo: repository);
      await controller.load();
    });
    addTearDown(() async {
      controller.dispose();
      await tester.runAsync(() => database.close());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(MaterialApp(
      home: MetalRateDetailScreen(
        metal: MetalRateMetal.gold,
        controller: controller,
      ),
    ));
    await tester.pump();
    await Scrollable.ensureVisible(
      tester.element(find.text('Rate Changes')),
      alignment: 0.25,
    );
    await tester.pump();

    final page = tester.state<ScrollableState>(find.byType(Scrollable).first);
    final inner = tester.state<ScrollableState>(find.descendant(
      of: find.byType(Scrollbar),
      matching: find.byType(Scrollable),
    ));
    expect(inner.position.maxScrollExtent, greaterThan(0));
    final pageOffset = page.position.pixels;
    final wheelPosition = tester.getCenter(find.byType(Scrollbar));
    await tester.sendEventToBinding(PointerScrollEvent(
      position: wheelPosition,
      scrollDelta: const Offset(0, 160),
    ));
    await tester.pump();
    expect(inner.position.pixels, greaterThan(0));
    expect(page.position.pixels, pageOffset);

    await tester.sendEventToBinding(PointerScrollEvent(
      position: wheelPosition,
      scrollDelta: const Offset(0, 10000),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(inner.position.extentAfter, 0);
    expect(page.position.pixels, pageOffset);
    await tester.sendEventToBinding(PointerScrollEvent(
      position: wheelPosition,
      scrollDelta: const Offset(0, 120),
    ));
    await tester.pump();
    expect(page.position.pixels, pageOffset);
  });
}

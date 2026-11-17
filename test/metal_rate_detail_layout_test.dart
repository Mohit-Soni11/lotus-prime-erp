import 'package:drift/native.dart';
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
      expect(find.text('Rate History'), findsOneWidget);
      expect(find.text('Edit Rates'), findsOneWidget);
      expect(find.text('₹ 1,51,848'), findsWidgets);
      expect(tester.takeException(), isNull, reason: 'Viewport width: $width');
    }

    await tester.tap(find.text('Edit Rates'));
    await tester.pump();
    expect(find.text('Save Rates'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

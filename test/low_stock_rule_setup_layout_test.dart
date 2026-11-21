import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/low_stock_alert_controller.dart';
import 'package:lotus_erp/features/stock/shared/data/repositories/low_stock_alert_repository.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_alert_rules_panel.dart';

void main() {
  for (final size in [
    const Size(1920, 1080),
    const Size(900, 800),
    const Size(390, 800)
  ]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
          'rule setup stats fit at ${size.width} pixels and $scale text scale',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final controller = LowStockAlertController(LowStockAlertRepository(db));
        addTearDown(controller.dispose);
        addTearDown(db.close);
        await tester.pumpWidget(MaterialApp(
            builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
            home: Scaffold(
                body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: LowStockAlertRulesPanel(controller: controller),
            ))));
        await tester.pump();
        expect(find.text('RULE CARDS'), findsOneWidget);
        expect(find.text('METALS'), findsOneWidget);
        expect(find.text('Open Setup'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/low_stock_alert_controller.dart';
import 'package:lotus_erp/features/stock/shared/data/repositories/low_stock_alert_repository.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/body/low_stock_item_alerts_body.dart';
import 'helpers/stock_alert_fixtures.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets(
      'metal drill-down shows affected items, clean purity and current availability',
      (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _StockRepository(db)
      ..cards = [
        stockAlertCard(),
        stockAlertCard(item: 'Chain', grade: '22KT (91.6%)', available: 2),
        stockAlertCard(item: 'Healthy item', available: 10),
        stockAlertCard(
            metal: 'Silver', item: 'Silver bracelet', grade: '925 (92.5%)'),
      ];
    final controller = LowStockAlertController(repo);
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: AnimatedBuilder(
          animation: controller,
          builder: (_, __) => LowStockItemAlertsBody(
              controller: controller, metalType: 'Gold')),
    )));
    expect(find.text('Ring'), findsOneWidget);
    expect(find.text('Chain'), findsOneWidget);
    expect(find.text('Gold · 18KT · 75%'), findsOneWidget);
    expect(find.text('0 pieces available'), findsOneWidget);
    expect(find.text('2 pieces available'), findsOneWidget);
    expect(find.text('Silver bracelet'), findsNothing);
    expect(find.text('Healthy item'), findsNothing);
    expect(tester.takeException(), isNull);
    repo.cards = [];
    await controller.load();
    await tester.pump();
    expect(find.textContaining('No active Gold stock alerts.'), findsOneWidget);
    expect(find.text('Ring'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test(
      'closing an in-flight stock detail load does not notify a disposed controller',
      () async {
    final repo = _StockRepository(db)
      ..pending = Completer<LowStockAlertDashboard>();
    final controller = LowStockAlertController(repo);
    final load = controller.load();
    controller.dispose();
    repo.pending!.complete(LowStockAlertDashboard.empty());
    await expectLater(load, completes);
  });
}

class _StockRepository extends LowStockAlertRepository {
  _StockRepository(super.db);
  List<LowStockStockCard> cards = [];
  Completer<LowStockAlertDashboard>? pending;

  @override
  Future<LowStockAlertDashboard> loadDashboard() async => pending != null
      ? await pending!.future
      : LowStockAlertDashboard(
          summary: LowStockAlertSummary.empty(),
          riskCards: const [],
          metalCards: const [],
          gradeCards: const [],
          itemGroupCards: const [],
          itemTypeCards: cards,
          rules: const []);
}

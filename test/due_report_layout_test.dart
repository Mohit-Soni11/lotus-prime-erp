import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/finance/due_report/due_report_controller.dart';
import 'package:lotus_erp/models/finance/due_report/due_report_model.dart';
import 'package:lotus_erp/repositories/finance/due_report_repository.dart';
import 'package:lotus_erp/ui/finance/due_report/due_report_body.dart';
import 'package:lotus_erp/ui/finance/due_report/due_report_filter_chip.dart';

class _ReportFixture extends DueReportRepository {
  _ReportFixture(AppDatabase db, this.bills) : super(db: db);

  final List<DueBillModel> bills;

  @override
  Stream<List<DueBillModel>> watchDueBills() => Stream.value(bills);

  @override
  Future<List<DueBillModel>> fetchDueBills() async => bills;
}

void main() {
  testWidgets('empty report shows one clear state and useful controls',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = DueReportController(repository: _ReportFixture(db, []));
    addTearDown(() async {
      controller.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: controller,
            builder: (_, __) => DueReportBody(
              ctrl: controller,
              onPrint: () {},
              onExport: () {},
              onCollectDue: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('All customer balances are clear'), findsOneWidget);
    expect(find.byType(DueReportFilterChip), findsOneWidget);
    expect(find.text('Print'), findsNothing);
    expect(find.text('Export'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('due report filters and panels fit desktop and narrow windows',
      (tester) async {
    final today = DueReportDate.only(DateTime.now());
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = DueReportController(
      repository: _ReportFixture(db, [
        _bill(
          id: 1,
          name: 'First Customer',
          billDate: today.subtract(const Duration(days: 2)),
          paidAmount: 0,
          dueAmount: 100,
          promiseDate: null,
        ),
        _bill(
          id: 2,
          name: 'Second Customer',
          billDate: today,
          paidAmount: 40,
          dueAmount: 60,
          promiseDate: today,
        ),
      ]),
    );
    addTearDown(() async {
      controller.dispose();
      await db.close();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.devicePixelRatio = 1;
    for (final size in [
      const Size(1920, 1080),
      const Size(850, 750),
      const Size(360, 700),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (_, __) => DueReportBody(
                ctrl: controller,
                onPrint: () {},
                onExport: () {},
                onCollectDue: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'Overflow at $size');
    }

    expect(controller.availableFilters, hasLength(6));
    expect(controller.filterCount(DueReportFilter.overdue), 1);
    expect(controller.filterCount(DueReportFilter.dueToday), 1);
    expect(controller.filterCount(DueReportFilter.partial), 1);
    expect(controller.filterCount(DueReportFilter.unpaid), 1);
    expect(controller.filterCount(DueReportFilter.noPromise), 1);

    controller.setFilter(DueReportFilter.overdue);
    controller.searchCtrl.text = 'missing';
    await tester.pump();
    expect(controller.availableFilters,
        [DueReportFilter.all, DueReportFilter.overdue]);
    controller.clearFilters();
    await tester.pump();
    expect(controller.filter, DueReportFilter.all);
    expect(controller.groups, hasLength(2));
    expect(tester.takeException(), isNull);
  });
}

DueBillModel _bill({
  required int id,
  required String name,
  required DateTime billDate,
  required double paidAmount,
  required double dueAmount,
  required DateTime? promiseDate,
}) {
  return DueBillModel(
    id: id,
    billNo: 'DUE-00$id',
    customerId: id,
    customerName: name,
    mobile: '900000000$id',
    city: 'Patna',
    address: 'Patna, Bihar',
    billDate: billDate,
    promiseDate: promiseDate,
    finalAmount: paidAmount + dueAmount,
    paidAmount: paidAmount,
    dueAmount: dueAmount,
    paymentStatus: paidAmount == 0 ? 'DUE' : 'PARTIAL',
    billingMode: 'RETAIL',
    billType: 'NORMAL',
  );
}

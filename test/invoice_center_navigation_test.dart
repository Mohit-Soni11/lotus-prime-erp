import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/features/invoice_center/application/invoice_center_controller.dart';
import 'package:lotus_erp/features/invoice_center/data/invoice_center_repository.dart';
import 'package:lotus_erp/features/invoice_center/domain/invoice_center_models.dart';
import 'package:lotus_erp/features/invoice_center/presentation/invoice_center_screen.dart';
import 'package:lotus_erp/features/invoice_center/presentation/invoice_center_style.dart';
import 'package:lotus_erp/features/invoice_center/presentation/widgets/invoice_center_table.dart';

class _TestRepository implements InvoiceCenterRepository {
  @override
  Future<InvoiceCenterSnapshot> load(InvoiceCenterQuery query) async =>
      InvoiceCenterSnapshot(
        summary: const InvoiceCenterSummary({
          InvoiceCenterTab.regular: InvoiceCenterMetric(count: 1, amount: 100),
        }),
        rows: [
          InvoiceCenterRow(
            kind: InvoiceCenterDocumentKind.sales,
            id: 1,
            number: 'INV-REAL-001',
            issuedAt: DateTime(2026, 11, 24),
            customerName: 'Amit Kumar',
            mobile: '9123456780',
            customerId: null,
            metals: 'GOLD',
            category: InvoiceCenterTab.regular,
            status: 'SETTLED',
            total: 100,
            paid: 100,
            due: 0,
          ),
        ],
        totalRows: 1,
        metals: const ['GOLD'],
      );

  @override
  Future<List<InvoiceCenterRow>> exportRows(InvoiceCenterQuery query) async =>
      (await load(query)).rows;
}

void main() {
  test('Invoice Center sidebar destination has a dedicated workspace path', () {
    expect(
      RouteMapper.toPath(AppRoutes.invoiceCenterRoute),
      RoutePaths.salesInvoiceCenter,
    );
    expect(
      RouteMapper.toRouteId(RoutePaths.salesInvoiceCenter),
      AppRoutes.invoiceCenterRoute,
    );
  });

  testWidgets('Invoice Center opens with its app bar and back action',
      (tester) async {
    var backCount = 0;
    final controller = InvoiceCenterController(
      repository: _TestRepository(),
      initialMonth: DateTime(2026, 11),
      pageSize: 8,
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(1366, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: InvoiceCenterScreen(
          onBack: () => backCount++,
          controller: controller,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('INVOICE CENTER'), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
    expect(find.text('S. No.'), findsOneWidget);
    expect(find.text('INV-REAL-001'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();

    expect(backCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invoice Center remains usable in a compact workspace',
      (tester) async {
    final controller = InvoiceCenterController(
      repository: _TestRepository(),
      initialMonth: DateTime(2026, 11),
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(640, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: InvoiceCenterScreen(onBack: () {}, controller: controller),
    ));
    await tester.pump();

    expect(find.text('INV-REAL-001'), findsOneWidget);
    expect(find.text('More Filters'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invoice rows fill a wide workspace with readable type',
      (tester) async {
    final controller = InvoiceCenterController(
      repository: _TestRepository(),
      initialMonth: DateTime(2026, 11),
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(1920, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: InvoiceCenterScreen(onBack: () {}, controller: controller),
    ));
    await tester.pump();

    final tableWidth = tester.getSize(find.byType(DataTable)).width;
    final panelWidth = tester.getSize(find.byType(InvoiceCenterTable)).width;
    expect(tableWidth, greaterThanOrEqualTo(panelWidth - 2));
    final panelRight = tester.getRect(find.byType(InvoiceCenterTable)).right;
    final actionRight = tester.getRect(find.text('Action')).right;
    expect(panelRight - actionRight, lessThan(190));
    final table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.dataTextStyle?.fontSize, InvoiceCenterStyle.bodyTextSize);
    expect(table.dataTextStyle?.fontWeight, FontWeight.w700);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      InvoiceCenterStyle.background,
    );
    expect(tester.takeException(), isNull);
  });
}

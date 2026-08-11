import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/report/sales_report/sales_report_export_service.dart';
import 'package:lotus_erp/theme/reports/sales_report/sales_report_theme.dart';
import 'package:lotus_erp/ui/report/sales_report/sales_report_app_bar.dart';

void main() {
  testWidgets('sales report app bar renders core module identity',
      (tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var wentBack = false;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SalesReportStyles.theme,
        home: Scaffold(
          appBar: SalesReportAppBar(onBack: () => wentBack = true),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text(SalesReportStrings.moduleTitle), findsOneWidget);
    expect(find.text(SalesReportStrings.moduleSubtitle), findsOneWidget);
    expect(find.text(SalesReportStrings.systemOnline), findsOneWidget);
    expect(find.byIcon(SalesReportIcons.back), findsOneWidget);
    expect(find.byIcon(SalesReportIcons.module), findsOneWidget);

    await tester.tap(find.byIcon(SalesReportIcons.back));
    await tester.pump();

    expect(wentBack, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sales report app bar opens the screen-specific download menu',
      (tester) async {
    SalesReportExportAction? selectedAction;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SalesReportStyles.theme,
        home: Scaffold(
          appBar: SalesReportAppBar(
            onBack: () {},
            onExportSelected: (action) => selectedAction = action,
            exportItems: const [
              SalesReportExportMenuItem(
                action: SalesReportExportAction.completePdf,
                label: 'Complete Sales Report PDF',
                icon: Icons.picture_as_pdf_outlined,
              ),
              SalesReportExportMenuItem(
                action: SalesReportExportAction.gstLiabilityPdf,
                label: 'GST Liability Report PDF',
                icon: Icons.account_balance_outlined,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(SalesReportIcons.export));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Complete Sales Report PDF'), findsOneWidget);
    expect(find.text('GST Liability Report PDF'), findsOneWidget);

    await tester.tap(find.text('GST Liability Report PDF'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(selectedAction, SalesReportExportAction.gstLiabilityPdf);
    expect(tester.takeException(), isNull);
  });
}

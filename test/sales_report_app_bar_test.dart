import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}

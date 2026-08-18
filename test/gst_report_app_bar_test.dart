import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/reports/gst_report/presentation/exports/gst_report_export_service.dart';
import 'package:lotus_erp/features/reports/gst_report/presentation/theme/gst_report_theme.dart';
import 'package:lotus_erp/features/reports/gst_report/presentation/widgets/gst_report_app_bar.dart';

void main() {
  testWidgets('GST report app bar renders module identity', (tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var wentBack = false;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: GstReportStyles.theme,
        home: Scaffold(
          appBar: GstReportAppBar(onBack: () => wentBack = true),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text(GstReportStrings.moduleTitle), findsOneWidget);
    expect(find.text(GstReportStrings.moduleSubtitle), findsOneWidget);
    expect(find.text(GstReportStrings.systemOnline), findsOneWidget);
    expect(find.byIcon(GstReportIcons.back), findsOneWidget);
    expect(find.byIcon(GstReportIcons.module), findsOneWidget);

    await tester.tap(find.byIcon(GstReportIcons.back));
    await tester.pump();

    expect(wentBack, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GST report app bar opens export menu', (tester) async {
    GstReportExportAction? selectedAction;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: GstReportStyles.theme,
        home: Scaffold(
          appBar: GstReportAppBar(
            onBack: () {},
            onExportSelected: (action) => selectedAction = action,
            exportItems: const [
              GstReportExportMenuItem(
                section: 'Recommended',
                action: GstReportExportAction.summaryPdf,
                label: 'GST Summary PDF',
                subtitle: 'Readable filing review',
                icon: Icons.picture_as_pdf_outlined,
              ),
              GstReportExportMenuItem(
                section: 'GSTR-1',
                action: GstReportExportAction.gstr1Csv,
                label: 'GSTR-1 CSV',
                icon: Icons.table_chart_outlined,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(GstReportIcons.export));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('GST Summary PDF'), findsOneWidget);
    expect(find.text('Readable filing review'), findsOneWidget);
    expect(find.text('GSTR-1 CSV'), findsOneWidget);
    expect(find.text('RECOMMENDED'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('gst-report-export-gstr1Csv')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(selectedAction, GstReportExportAction.gstr1Csv);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GST report app bar hides manual refresh control',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: GstReportStyles.theme,
        home: Scaffold(
          appBar: GstReportAppBar(onBack: () {}),
        ),
      ),
    );

    expect(find.byIcon(GstReportIcons.refresh), findsNothing);
    expect(find.text(GstReportStrings.systemOnline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

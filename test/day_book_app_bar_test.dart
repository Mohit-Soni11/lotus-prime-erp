import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/report/day_book/day_book_controller.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_app_bar.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_top_section.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_export_button.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_overview_panel.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_workspace_header.dart';

void main() {
  for (final width in [320.0, 1200.0]) {
    testWidgets('Day Book header and report actions work at ${width.toInt()}px',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = _HeaderController();
      addTearDown(controller.dispose);
      var backCount = 0;
      var exportCount = 0;
      var reconcileCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: DayBookAppBar(
              ctrl: controller,
              onBack: () => backCount++,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => DayBookTopSection(
                  ctrl: controller,
                  summary: controller.summary,
                  onReconcile: () => reconcileCount++,
                  onViewPdf: () => exportCount++,
                  onExportCsv: () {},
                  onSharePdf: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('DAY BOOK'), findsOneWidget);
      expect(find.text('Day Book'), findsOneWidget);
      expect(find.text('Daily Overview'), findsOneWidget);
      expect(find.byType(DayBookWorkspaceHeader), findsOneWidget);
      expect(find.byType(DayBookOverviewPanel), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(DayBookOverviewPanel)).dy,
        greaterThan(
            tester.getBottomLeft(find.byType(DayBookWorkspaceHeader)).dy),
      );
      expect(find.text('Daily business register for the selected date.'),
          findsOneWidget);
      expect(find.byType(DayBookExportButton), findsOneWidget);
      for (final title in [
        'Total Sales',
        'Girvi Given',
        'Advance Received',
        'Return & Cancellation',
        'Customer Metal Purchase',
        "Today's Dues",
        "Today's Receipts",
        'Expenses',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.textContaining('DEMO PREVIEW'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Reconcile Cash'));
      await tester.tap(find.text('Reconcile Cash'));
      expect(reconcileCount, 1);

      await tester.tap(find.byTooltip('Back'));
      expect(backCount, 1);

      await tester.ensureVisible(find.byTooltip('Previous day'));
      await tester.tap(find.byTooltip('Previous day'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(controller.isToday, isFalse);
      expect(find.byTooltip('Return to today'), findsOneWidget);

      await tester.tap(find.byTooltip('Return to today'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(controller.isToday, isTrue);

      await tester.tap(find.byTooltip('Day Book export options'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('Export CSV'), findsOneWidget);
      await tester.tap(find.text('View PDF'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(exportCount, 1);
      expect(tester.takeException(), isNull);
    });
  }
}

class _HeaderController extends ChangeNotifier implements DayBookController {
  DateTime _date = DateTime.now();

  @override
  DateTime get selectedDate => _date;

  @override
  bool get isToday {
    final now = DateTime.now();
    return _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
  }

  @override
  bool get canGoNext => !isToday;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  DayBookSummary get summary => DayBookSummary(date: _date);

  @override
  void goToPreviousDay() {
    _date = _date.subtract(const Duration(days: 1));
    notifyListeners();
  }

  @override
  void goToToday() {
    _date = DateTime.now();
    notifyListeners();
  }

  @override
  void goToNextDay() {
    if (!canGoNext) return;
    _date = _date.add(const Duration(days: 1));
    notifyListeners();
  }

  @override
  Future<void> selectDate(BuildContext context) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

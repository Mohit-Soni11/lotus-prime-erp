import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/report/day_book/day_book_controller.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_app_bar.dart';

void main() {
  for (final width in [320.0, 1200.0]) {
    testWidgets(
        'Day Book header keeps navigation and exports at ${width.toInt()}px',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = _HeaderController();
      addTearDown(controller.dispose);
      var backCount = 0;
      var exportCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: DayBookAppBar(
              compact: width < 760,
              ctrl: controller,
              onBack: () => backCount++,
              onRefresh: () {},
              onExportPdf: () => exportCount++,
              onExportCsv: () {},
              onSharePdf: () {},
            ),
          ),
        ),
      );

      expect(find.text('Day Book'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Back to previous screen'));
      expect(backCount, 1);

      await tester.tap(find.byTooltip('Previous day'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(controller.isToday, isFalse);
      expect(find.byTooltip('Return to today'), findsOneWidget);

      await tester.tap(find.byTooltip('Return to today'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(controller.isToday, isTrue);

      await tester.tap(find.byTooltip('Export Day Book'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Export table as CSV'), findsOneWidget);
      await tester.tap(find.text('Preview PDF'));
      await tester.pumpAndSettle();
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

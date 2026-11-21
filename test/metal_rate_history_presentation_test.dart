import 'dart:io';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/setting/metal_rate/metal_rate_controller.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'package:lotus_erp/ui/settings/metal_rate/metal_rate_detail_screen.dart';

void main() {
  for (final metal in [MetalRateMetal.gold, MetalRateMetal.silver]) {
    for (final width in [500.0, 1600.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('${metal.name} history at $width px and $scale text scale',
            (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 1000));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final controller = _HistoryController(metal);
          addTearDown(controller.dispose);
          final previewKey = GlobalKey();
          await tester.pumpWidget(MaterialApp(
            home: RepaintBoundary(
              key: previewKey,
              child: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1000),
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child:
                    MetalRateDetailScreen(metal: metal, controller: controller),
              ),
            ),
          ));
          await _pumpHistory(tester);
          final chartFinder =
              find.byKey(const ValueKey('metal-rate-history-chart'));
          await tester.ensureVisible(chartFinder);
          await _pumpHistory(tester);
          final data = tester.widget<LineChart>(chartFinder).data;
          expect(data.minY, lessThan(controller.initialRate));
          expect(data.maxY, greaterThan(controller.lastRate));
          expect(data.lineBarsData.single.spots.last.y, controller.lastRate);
          expect(data.lineBarsData.single.lineChartStepData.stepDirection,
              LineChartStepData.stepDirectionForward);
          expect(data.lineTouchData.touchTooltipData.fitInsideHorizontally,
              isTrue);
          expect(
              data.lineTouchData.touchTooltipData.fitInsideVertically, isTrue);

          final changes =
              find.byKey(const ValueKey('metal-rate-history-changes'));
          await tester.ensureVisible(changes);
          await _pumpHistory(tester);
          final labels = find
              .descendant(of: changes, matching: find.byType(Text))
              .evaluate()
              .map((element) => (element.widget as Text).data ?? '')
              .toList();
          expect(
              labels,
              contains(
                  '${metal == MetalRateMetal.gold ? '24K' : '999'} Selling Rate'));
          expect(labels, contains('Old Metal Purchase'));
          expect(
              labels.any((label) =>
                  label.contains('22K') ||
                  label.contains('925') ||
                  label.contains('Local market') ||
                  label.contains('Market reference')),
              isFalse);
          expect(tester.takeException(), isNull);

          const previewDir = String.fromEnvironment('LOTUS_RATE_PREVIEW_DIR');
          if (previewDir.isNotEmpty && width == 1600 && scale == 1) {
            await tester.ensureVisible(find.text('Rate History'));
            await _pumpHistory(tester);
            await tester.runAsync(() async {
              final boundary = previewKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
              final image = await boundary.toImage();
              final data =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              final file = File('$previewDir/${metal.name}.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }
        });
      }
    }
  }
}

Future<void> _pumpHistory(WidgetTester tester) async {
  // The app bar has a continuous online-status animation.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

class _HistoryController extends ChangeNotifier implements MetalRateController {
  _HistoryController(this.metal) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final elapsed = now.difference(start).inMicroseconds;
    final base = MetalRateProfile.defaultFor(metal);
    _history = [
      for (var index = 0; index < 4; index++)
        MetalRateHistoryEntry(
          revision: index + 1,
          source: 'Manual',
          changedAt: start.add(Duration(microseconds: elapsed * index ~/ 4)),
          profile: base.copyWith(
            mcxRatePer10g: 200000 + index * 1000,
            physicalMarketRatePer10g: initialRate + index * 1000,
            oldMetalPurchaseRatePer10g: 100000 + index * 500,
            purityPlans: [
              for (final plan in base.purityPlans)
                plan.copyWith(
                    manualDisplayRatePer10g: initialRate + index * 1000),
            ],
          ),
        ),
    ];
  }

  final MetalRateMetal metal;
  late final List<MetalRateHistoryEntry> _history;
  double get initialRate => metal == MetalRateMetal.gold ? 140000 : 170000;
  double get lastRate => initialRate + 3000;
  @override
  MetalRateLoadState get state => MetalRateLoadState.loaded;
  @override
  MetalRateProfile profileFor(MetalRateMetal metal) => _history.last.profile;
  @override
  List<MetalRateHistoryEntry> historyFor(MetalRateMetal metal) =>
      _history.reversed.toList();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

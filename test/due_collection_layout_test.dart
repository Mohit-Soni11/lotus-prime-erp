import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/finance/due_collection_entry/due_collection_entry_model.dart';
import 'package:lotus_erp/ui/finance/due_collection_entry/due_collection_app_bar.dart';
import 'package:lotus_erp/ui/finance/due_collection_entry/due_collection_empty_state.dart';
import 'package:lotus_erp/ui/finance/due_collection_entry/due_collection_summary.dart';
import 'package:lotus_erp/ui/shared/system_status_badge.dart';

void main() {
  testWidgets('collection header and summary fit desktop and narrow windows',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;

    for (final size in [
      const Size(1920, 1080),
      const Size(850, 750),
      const Size(360, 700)
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: DueCollectionAppBar(
            onBack: () {},
            onReset: () {},
            status: SystemStatus.online,
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(14),
            child: Column(
              children: [
                DueCollectionSummary(
                  stats: DueCollectionStatsModel(
                    billCount: 3,
                    customerCount: 2,
                    totalDue: 124500.25,
                    overdueDue: 5400,
                    selectedDue: 0,
                  ),
                  isLoading: false,
                ),
                SizedBox(height: 16),
                DueCollectionEmptyState(isLoading: false),
              ],
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull, reason: 'Overflow at $size');
      expect(find.text('DUE COLLECTION ENTRY'), findsOneWidget);
      expect(find.text('All due bills are clear'), findsOneWidget);
      expect(find.text('Due Bills'), findsOneWidget);
    }
  });
}

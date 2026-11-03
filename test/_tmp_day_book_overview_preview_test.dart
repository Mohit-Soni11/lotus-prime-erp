import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_document.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_overview_cards.dart';

void main() {
  testWidgets('preview', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(1280, 700);
    tester.view.devicePixelRatio = 1;
    final date = DateTime(2026, 11, 3);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFF9F6F0),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: RepaintBoundary(
            key: const ValueKey('preview'),
            child: DayBookOverviewCards(
              summary: DayBookSummary(
                date: date,
                openingCash: 404610,
                moneyFlow: DayBookMoneyFlow(
                  openingCash: 404610,
                  openingBank: 0,
                  entries: [
                    DayBookMoneyEntry(
                      date: date,
                      amount: 3500,
                      incoming: true,
                      isCash: true,
                      category: 'DUE_COLLECTION',
                      paymentMode: 'CASH',
                      transactionId: 'DUE-1',
                    ),
                  ],
                ),
                documents: [
                  DayBookDocument(
                    kind: DayBookDocumentKind.regularInvoice,
                    sourceId: '1',
                    number: 'INV-1',
                    date: date,
                    amount: 54000,
                    collection: 30000,
                    status: 'ACTIVE',
                  ),
                  DayBookDocument(
                    kind: DayBookDocumentKind.gstInvoice,
                    sourceId: '2',
                    number: 'TAX-2',
                    date: date,
                    amount: 88500,
                    tax: 13500,
                    collection: 50000,
                    status: 'ACTIVE',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('preview')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('build/day_book_overview_preview.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    });
  });
}

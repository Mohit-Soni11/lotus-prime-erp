import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/core/documents/issued_pdf_preview_dialog.dart';

void main() {
  testWidgets('opens immediately while an issued PDF is loading', (
    tester,
  ) async {
    final pendingPdf = Completer<Uint8List?>();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showIssuedPdfPreview(
                context: context,
                pdfBytesFuture: pendingPdf.future,
              ),
              child: const Text('View PDF'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('View PDF'));
    await tester.pump();
    expect(find.text('Opening issued invoice PDF...'), findsOneWidget);

    pendingPdf.complete(null);
    await tester.pumpAndSettle();
    expect(
        find.text('Issued invoice PDF could not be opened.'), findsOneWidget);
    expect(find.byTooltip('Close preview'), findsOneWidget);
  });
}

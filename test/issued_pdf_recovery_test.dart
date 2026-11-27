import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/core/documents/issued_pdf_recovery.dart';

void main() {
  testWidgets('missing original explains recovery without generating a PDF',
      (tester) async {
    var attachCalls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => requestMissingIssuedPdf(
              context: context,
              documentNumber: 'AJ-26-004',
              attachOriginal: (Uint8List _) async {
                attachCalls++;
                return null;
              },
            ),
            child: const Text('View'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(find.text('Original PDF not archived'), findsOneWidget);
    expect(find.textContaining('AJ-26-004'), findsOneWidget);
    expect(find.text('Attach original PDF'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(attachCalls, 0);
    expect(tester.takeException(), isNull);
  });
}

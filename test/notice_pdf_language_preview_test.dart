import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_action_model.dart';
import 'package:lotus_erp/ui/girvi/contact_recovery/widgets/notice_pdf_language_preview.dart';

void main() {
  testWidgets(
      'language buttons request matching PDF and reuse cached generation',
      (tester) async {
    final requested = <GirviNoticeLanguage>[];
    await tester.pumpWidget(MaterialApp(
        home: NoticePdfLanguagePreview(
      title: 'First Notice PDF',
      ticketNo: 'GRV-0012',
      initialLanguage: GirviNoticeLanguage.hindi,
      availableLanguages: GirviNoticeLanguage.values.toSet(),
      buildPdf: (language) {
        requested.add(language);
        return Completer<Uint8List>().future;
      },
    )));
    expect(requested, [GirviNoticeLanguage.hindi]);
    await tester.tap(find.byKey(const ValueKey('notice-language-english')));
    await tester.pump();
    expect(requested, [GirviNoticeLanguage.hindi, GirviNoticeLanguage.english]);
    expect(find.text('First Notice PDF | GRV-0012 · English'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('notice-language-hindi')));
    await tester.pump();
    expect(requested, hasLength(2));
    expect(find.text('First Notice PDF | GRV-0012 · Hindi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy unavailable language is disabled and clearly explained',
      (tester) async {
    final requested = <GirviNoticeLanguage>[];
    await tester.pumpWidget(MaterialApp(
        home: NoticePdfLanguagePreview(
      title: 'First Notice PDF',
      ticketNo: 'GRV-0012',
      initialLanguage: GirviNoticeLanguage.hindi,
      availableLanguages: const {GirviNoticeLanguage.hindi},
      buildPdf: (language) {
        requested.add(language);
        return Completer<Uint8List>().future;
      },
    )));
    final english = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('notice-language-english')));
    expect(english.onSelected, isNull);
    await tester.tap(find.byKey(const ValueKey('notice-language-english')));
    await tester.pump();
    expect(requested, [GirviNoticeLanguage.hindi]);
    expect(find.textContaining('Only the saved language'), findsOneWidget);
  });

  testWidgets('generation failure can be retried in the selected language',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(
        home: NoticePdfLanguagePreview(
      title: 'Final Notice PDF',
      ticketNo: 'GRV-0012',
      initialLanguage: GirviNoticeLanguage.english,
      availableLanguages: GirviNoticeLanguage.values.toSet(),
      buildPdf: (_) async {
        attempts++;
        throw StateError('Test generation failure');
      },
    )));
    await tester.pumpAndSettle();
    expect(find.text('English PDF could not be loaded.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });
}

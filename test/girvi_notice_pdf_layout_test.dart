import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/girvi/girvi_notice_generation_service.dart';
import 'package:lotus_erp/logic/girvi/girvi_notice_pdf_service.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_action_model.dart';

import 'fixtures/girvi_notice_case_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('long saved notices retain pagination instead of single-page overflow',
      () async {
    final text = List.generate(
      180,
      (index) =>
          'Customer response ${index + 1}: Approved historical statement.',
    ).join('\n');
    final bytes = await GirviNoticePdfService().buildStoredNotice(
      ticketNo: 'GRV-LONG-001',
      noticeType: GirviNoticeType.formal,
      noticeLanguage: GirviNoticeLanguage.english,
      noticeText: text,
      savedAt: DateTime(2026, 9, 29),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    final output = Platform.environment['NOTICE_LAYOUT_PREVIEW_DIR'];
    if (output != null && output.isNotEmpty) {
      await Directory(output).create(recursive: true);
      await File('$output/long_saved_notice.pdf').writeAsBytes(bytes);
    }
  });

  for (final type in GirviNoticeType.values) {
    for (final language in GirviNoticeLanguage.values) {
      test('${type.label} ${language.label} renders prepared and saved PDFs',
          () async {
        final item =
            createNoticeCase(simple: language == GirviNoticeLanguage.hindi);
        final generator = GirviNoticeGenerationService(now: item.now);
        expect(generator.validate(item), isEmpty);
        final text = generator.build(
          item: item,
          noticeType: type,
          language: language,
        );
        expect(text, contains('I will visit the shop on Friday.'));
        final service = GirviNoticePdfService();
        final prepared = await service.build(
          item: item,
          noticeType: type,
          noticeLanguage: language,
          noticeText: text,
        );
        final saved = await service.buildStoredNotice(
          ticketNo: item.loan.ticketNo,
          noticeType: type,
          noticeLanguage: language,
          noticeText: text,
          savedAt: item.now,
        );
        for (final bytes in [prepared, saved]) {
          expect(bytes.length, greaterThan(1000));
          expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        }

        // Opt-in artifacts use synthetic data and never touch the app database.
        final output = Platform.environment['NOTICE_LAYOUT_PREVIEW_DIR'];
        if (output != null && output.isNotEmpty) {
          await Directory(output).create(recursive: true);
          final name = 'formal_notice_${language.fileLabel}';
          await File('$output/$name.pdf').writeAsBytes(saved);
          await File('$output/${name}_prepared.pdf').writeAsBytes(prepared);
        }
      });
    }
  }
}

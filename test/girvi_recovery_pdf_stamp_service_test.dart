import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';
import 'package:lotus_erp/logic/girvi/girvi_recovery_pdf_stamp_service.dart';
import 'package:lotus_erp/models/girvi/girvi_recovery_disposition.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stamped copy has all source pages and keeps source bytes untouched',
      () async {
    final original = Uint8List.fromList([1, 2, 3]);
    final service = GirviRecoveryPdfStampService(
      rasterPages: (bytes, dpi) async* {
        expect(identical(bytes, original), isTrue);
        expect(dpi, 300);
        for (var i = 0; i < 2; i++) {
          final pixels = Uint8List(300 * 420 * 4);
          for (var offset = 0; offset < pixels.length; offset += 4) {
            pixels[offset] = 255;
            pixels[offset + 1] = 255;
            pixels[offset + 2] = 255;
            pixels[offset + 3] = 255;
          }
          yield PdfRaster(300, 420, pixels);
        }
      },
    );

    final stamped = await service.stamp(
      original,
      GirviRecoveryDisposition.sold,
    );
    expect(String.fromCharCodes(stamped.take(5)), '%PDF-');
    expect(original, [1, 2, 3]);
    expect(
        RegExp(r'/Type\s*/Page\b')
            .allMatches(String.fromCharCodes(stamped))
            .length,
        2);
    final previewPath = Platform.environment['GIRVI_RECOVERY_STAMP_PREVIEW'];
    if (previewPath != null && previewPath.isNotEmpty) {
      await File(previewPath).writeAsBytes(stamped);
    }
  });

  test('release stamp uses the same source pages for preview and print',
      () async {
    final original = Uint8List.fromList([9, 8, 7]);
    final service = GirviRecoveryPdfStampService(
      rasterPages: (bytes, dpi) async* {
        expect(identical(bytes, original), isTrue);
        expect(dpi, 300);
        for (var i = 0; i < 2; i++) {
          final pixels = Uint8List(300 * 420 * 4);
          for (var offset = 0; offset < pixels.length; offset += 4) {
            pixels[offset] = 255;
            pixels[offset + 1] = 255;
            pixels[offset + 2] = 255;
            pixels[offset + 3] = 255;
          }
          yield PdfRaster(300, 420, pixels);
        }
      },
    );

    final stamped = await service.stampReleased(original, delivered: true);
    expect(String.fromCharCodes(stamped.take(5)), '%PDF-');
    expect(original, [9, 8, 7]);
    expect(
      RegExp(r'/Type\s*/Page\b')
          .allMatches(String.fromCharCodes(stamped))
          .length,
      2,
    );
  });
}

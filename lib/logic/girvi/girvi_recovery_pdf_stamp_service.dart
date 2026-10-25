import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/pdf/girvi_recovery_watermark.dart';
import '../../core/pdf/girvi_release_watermark.dart';
import '../../core/pdf/lotus_pdf_theme.dart';
import '../../models/girvi/girvi_recovery_disposition.dart';

/// Creates a stamped viewing/printing copy without changing the issued PDF.
class GirviRecoveryPdfStampService {
  const GirviRecoveryPdfStampService({this.rasterPages});

  final Stream<PdfRaster> Function(Uint8List, double)? rasterPages;

  Future<Uint8List> stamp(
    Uint8List original,
    GirviRecoveryDisposition disposition,
  ) =>
      _stamp(original, () => girviRecoveryWatermark(disposition));

  Future<Uint8List> stampReleased(
    Uint8List original, {
    required bool delivered,
  }) =>
      _stamp(original, () => girviReleaseWatermark(delivered: delivered));

  Future<Uint8List> _stamp(
    Uint8List original,
    pw.Widget Function() watermark,
  ) async {
    const dpi = 300.0;
    final document = pw.Document(theme: await LotusPdfTheme.reportTheme());
    var pageCount = 0;
    await for (final page in rasterPages?.call(original, dpi) ??
        Printing.raster(original, dpi: dpi)) {
      final image = pw.MemoryImage(await page.toPng());
      final width = page.width * PdfPageFormat.inch / dpi;
      final height = page.height * PdfPageFormat.inch / dpi;
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(width, height),
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Image(image, fit: pw.BoxFit.fill),
              ),
              pw.Positioned.fill(
                child: watermark(),
              ),
            ],
          ),
        ),
      );
      pageCount++;
    }
    if (pageCount == 0) {
      throw StateError('The issued invoice PDF has no printable pages.');
    }
    return document.save();
  }
}

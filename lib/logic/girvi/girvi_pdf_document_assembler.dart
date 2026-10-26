import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/pdf/girvi_recovery_watermark.dart';
import '../../core/pdf/girvi_release_watermark.dart';
import '../../core/pdf/lotus_pdf_theme.dart';
import '../../models/girvi/girvi_invoice_draft.dart';

/// Keeps the saved issued invoice pages and adds the current receipt pages.
class GirviPdfDocumentAssembler {
  const GirviPdfDocumentAssembler({this.rasterPages});

  final Stream<PdfRaster> Function(Uint8List, double)? rasterPages;

  Future<Uint8List> assemble({
    required Uint8List issuedInvoice,
    Uint8List? appendix,
    required GirviInvoiceDraft draft,
  }) async {
    const dpi = 300.0;
    final output = pw.Document(theme: await LotusPdfTheme.reportTheme());
    var originalPages = 0;
    await for (final page in rasterPages?.call(issuedInvoice, dpi) ??
        Printing.raster(issuedInvoice, dpi: dpi)) {
      await _addPage(output, page, dpi: dpi, watermark: _watermark(draft));
      originalPages++;
    }
    if (originalPages == 0) {
      throw StateError('The saved original invoice has no printable pages.');
    }
    if (appendix != null) {
      await for (final page in rasterPages?.call(appendix, dpi) ??
          Printing.raster(appendix, dpi: dpi)) {
        await _addPage(output, page, dpi: dpi);
      }
    }
    return output.save();
  }

  pw.Widget Function()? _watermark(GirviInvoiceDraft draft) {
    final disposition = draft.recoveryDisposition;
    if (disposition != null) return () => girviRecoveryWatermark(disposition);
    if (draft.isReleaseReceipt || draft.deliveredAt != null) {
      return () => girviReleaseWatermark(delivered: draft.deliveredAt != null);
    }
    return null;
  }

  Future<void> _addPage(
    pw.Document output,
    PdfRaster raster, {
    required double dpi,
    pw.Widget Function()? watermark,
  }) async {
    final image = pw.MemoryImage(await raster.toPng());
    final width = raster.width * PdfPageFormat.inch / dpi;
    final height = raster.height * PdfPageFormat.inch / dpi;
    output.addPage(pw.Page(
      pageFormat: PdfPageFormat(width, height),
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Stack(children: [
        pw.Positioned.fill(child: pw.Image(image, fit: pw.BoxFit.fill)),
        if (watermark != null) pw.Positioned.fill(child: watermark()),
      ]),
    ));
  }
}

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../girvi/girvi_closure_palette.dart';

/// A single closure stamp for every page of a settled Girvi document.
pw.Widget girviReleaseWatermark({required bool delivered}) {
  const color = PdfColor.fromInt(GirviClosurePalette.released);
  return pw.Center(
    child: pw.Opacity(
      opacity: 0.32,
      child: pw.Transform.rotate(
        angle: -0.45,
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: color, width: 4),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                delivered ? 'DELIVERED' : 'RELEASED',
                style: pw.TextStyle(
                  color: color,
                  fontSize: 70,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(height: 2, width: 230, color: color),
              pw.SizedBox(height: 5),
              pw.Text(
                delivered ? 'ITEM HANDOVER COMPLETE' : 'SETTLEMENT COMPLETE',
                style: pw.TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/girvi/girvi_recovery_disposition.dart';

pw.Widget girviRecoveryWatermark(GirviRecoveryDisposition disposition) {
  const color = PdfColor.fromInt(0xFFC1121F);
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
                disposition.dbValue,
                style: pw.TextStyle(
                  color: color,
                  fontSize: 76,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(height: 2, width: 230, color: color),
              pw.SizedBox(height: 5),
              pw.Text(
                'ACCOUNT CLOSED',
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

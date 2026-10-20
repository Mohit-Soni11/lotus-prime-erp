part of 'girvi_invoice_pdf_service.dart';

pw.Widget _girviStatusWatermark({
  required String label,
  required String subtitle,
  required PdfColor color,
  double opacity = 0.14,
}) {
  final text = label.trim().toUpperCase();
  final fontSize = text.length > 14 ? 34.0 : 76.0;
  return pw.Center(
    child: pw.Opacity(
      opacity: opacity,
      child: pw.Transform.rotate(
        angle: -0.45,
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: color, width: 3),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                text,
                style: pw.TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(height: 2, width: 230, color: color),
              pw.SizedBox(height: 5),
              pw.Text(
                subtitle.toUpperCase(),
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

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CustomerPdfElements {
  pw.Widget pdfHeader(String title, String number) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF0B1E33),
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            height: 42,
            width: 42,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFD59A2B),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              'L',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  number,
                  style: const pw.TextStyle(
                    color: PdfColor.fromInt(0xFFF7C66A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            'LOTUS PRIME ERP',
            style: const pw.TextStyle(
              color: PdfColor.fromInt(0xFFF7C66A),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget pdfInfoGrid(List<List<String>> rows) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: rows.map((row) {
        return pw.Container(
          width: 248,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: const PdfColor.fromInt(0xFFE1E7F0)),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                row[0].toUpperCase(),
                style: const pw.TextStyle(
                  color: PdfColor.fromInt(0xFF637083),
                  fontSize: 7,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                row[1],
                style: pw.TextStyle(
                  color: const PdfColor.fromInt(0xFF111827),
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget pdfSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF7F3EA),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5B04C)),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          color: const PdfColor.fromInt(0xFF8A5D0A),
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  String formatRupees(double value) => 'Rs ${formatAmount(value)}';

  String formatAmount(double value) {
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

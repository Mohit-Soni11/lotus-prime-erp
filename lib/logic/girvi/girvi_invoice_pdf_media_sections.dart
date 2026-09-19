part of 'girvi_invoice_pdf_service.dart';

extension _GirviInvoicePdfMediaSections on GirviInvoicePdfService {
  pw.Widget _buildPhotoSection(
    List<_GirviPhoto> photos,
    bool compact, {
    required String sectionNumber,
  }) {
    const columns = 3;
    final rows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionHeading(
                number: sectionNumber,
                title: 'PLEDGED ITEM PHOTOS',
                subtitle: 'Visual reference attached with this receipt',
                compact: compact,
              ),
              pw.SizedBox(height: compact ? 7 : 9),
            ],
          ),
        ],
      ),
    ];
    for (var start = 0; start < photos.length; start += columns) {
      final end =
          (start + columns < photos.length) ? start + columns : photos.length;
      final rowPhotos = photos.sublist(start, end);
      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.only(
                bottom: start + columns < photos.length ? (compact ? 7 : 9) : 0,
              ),
              child: _buildPhotoRow(rowPhotos, columns, compact),
            ),
          ],
        ),
      );
    }
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(),
      },
      children: rows,
    );
  }

  pw.Widget _buildPhotoRow(
    List<_GirviPhoto> photos,
    int columns,
    bool compact,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < columns; index++) ...[
          if (index > 0) pw.SizedBox(width: compact ? 7 : 9),
          pw.Expanded(
            child: index < photos.length
                ? _buildPhotoCard(photos[index], compact)
                : pw.SizedBox(),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildPhotoCard(
    _GirviPhoto photo,
    bool compact,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(compact ? 4 : 5),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: GirviInvoicePdfService._line, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            height: compact ? 70 : 94,
            width: double.infinity,
            padding: const pw.EdgeInsets.all(3),
            decoration: const pw.BoxDecoration(
              color: GirviInvoicePdfService._surface,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Image(
              photo.image,
              fit: pw.BoxFit.contain,
            ),
          ),
          pw.SizedBox(height: compact ? 4 : 5),
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: const pw.BoxDecoration(
                  color: GirviInvoicePdfService._goldLight,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(
                  '#${photo.serialNo}',
                  style: pw.TextStyle(
                    color: GirviInvoicePdfService._gold,
                    fontSize: compact ? 7 : 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 5),
              pw.Expanded(
                child: pw.Text(
                  photo.title,
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    color: GirviInvoicePdfService._ink,
                    fontSize: compact ? 7 : 8.2,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPageFooter(
    pw.Context context,
    GirviInvoiceDraft draft,
    bool compact,
  ) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        '${draft.ticketNo}  |  Page ${context.pageNumber}',
        style: pw.TextStyle(
          color: GirviInvoicePdfService._muted,
          fontSize: compact ? 6.5 : 7.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildDocumentSignoff(
    bool compact,
    GirviBillingModel settings,
  ) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        if (settings.printFooterMessage &&
            settings.footerMessage.trim().isNotEmpty) ...[
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.symmetric(
              horizontal: compact ? 7 : 9,
              vertical: compact ? 5 : 6,
            ),
            decoration: const pw.BoxDecoration(
              color: GirviInvoicePdfService._goldLight,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              settings.footerMessage.trim(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: GirviInvoicePdfService._ink,
                fontSize: compact ? 7 : 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: compact ? 8 : 11),
        ],
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildSignature('Customer Signature', compact),
            _buildSignature('Authorized Signature / Stamp', compact),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSignature(String label, bool compact) {
    return pw.SizedBox(
      width: compact ? 128 : 165,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(height: compact ? 21 : 30),
          pw.Container(height: 0.7, color: GirviInvoicePdfService._muted),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              color: GirviInvoicePdfService._muted,
              fontSize: compact ? 7.5 : 8.5,
            ),
          ),
        ],
      ),
    );
  }
}

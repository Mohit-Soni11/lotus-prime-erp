part of 'girvi_invoice_pdf_service.dart';

extension _GirviInvoicePdfDetailSections on GirviInvoicePdfService {
  List<_GirviPhoto> _loadPhotos(
    GirviInvoiceDraft draft,
    GirviBillingModel settings,
  ) {
    final photos = <_GirviPhoto>[];
    for (final item in draft.items) {
      if (!settings.settingsForMetal(item.metal).showItemPhotos) continue;
      for (final path in item.photoPaths) {
        final normalizedPath =
            GirviInvoicePdfService._existingLocalImagePath(path);
        if (normalizedPath.isEmpty) continue;
        final file = File(normalizedPath);
        if (!file.existsSync()) continue;
        try {
          photos.add(
            _GirviPhoto(
              serialNo: item.serialNo,
              title: item.description,
              image: pw.MemoryImage(file.readAsBytesSync()),
            ),
          );
        } catch (_) {
          // A damaged image should not stop the customer invoice.
        }
      }
    }
    return photos;
  }

  pw.Widget? _buildPaymentStrip(
    GirviInvoiceDraft draft,
    GirviBillingModel settings,
    bool compact,
  ) {
    if (!settings.showDisbursementDetails) return null;
    final value = draft.payments.isNotEmpty
        ? draft.payments
            .map((payment) => '${payment.label} ${_amount(payment.amount)}')
            .join('  |  ')
        : draft.disbursementSummary.trim();
    if (value.isEmpty) return null;

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: pw.BoxDecoration(
        color: GirviInvoicePdfService._surface,
        border: pw.Border.all(color: GirviInvoicePdfService._line, width: 0.65),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            'DISBURSEMENT',
            style: pw.TextStyle(
              color: GirviInvoicePdfService._muted,
              fontSize: compact ? 6 : 7,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(width: compact ? 8 : 11),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                color: GirviInvoicePdfService._ink,
                fontSize: compact ? 7.2 : 8.3,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget? _buildCompactLoanMetrics(
    GirviInvoiceDraft draft,
    GirviBillingModel settings,
    bool compact,
  ) {
    final entries = <_GirviDetailEntry>[
      if (settings.showTotalInterest)
        _GirviDetailEntry(
          label: draft.isReleaseReceipt
              ? 'Interest Settled'
              : 'Total Interest at Maturity',
          value: _amount(
            draft.isReleaseReceipt
                ? (draft.releaseInterest ?? draft.totalInterest)
                : draft.totalInterest,
          ),
        ),
      if (draft.isReleaseReceipt && (draft.releasePenalty ?? 0) > 0)
        _GirviDetailEntry(
          label: 'Penalty / Charges',
          value: _amount(draft.releasePenalty!),
        ),
      if (settings.showTotalDue && draft.isReleaseReceipt)
        _GirviDetailEntry(
          label: 'Total Received',
          value: _amount(
            draft.releaseTotalAmount ?? draft.totalDue,
          ),
          strong: true,
        ),
      if (settings.showTotalValue)
        _GirviDetailEntry(
          label: 'Total Pledged Valuation',
          value: _amount(draft.totalValue),
          strong: true,
        ),
    ];
    if (entries.isEmpty) return null;
    return pw.Row(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          if (index > 0) pw.SizedBox(width: compact ? 5 : 7),
          pw.Expanded(child: _buildDetailCard(entries[index], compact)),
        ],
      ],
    );
  }

  pw.Widget? _buildLifecycleStrip(
    GirviInvoiceDraft draft,
    bool compact,
  ) {
    final entries = <_GirviDetailEntry>[
      if (draft.lastInterestPaidDate != null)
        _GirviDetailEntry(
          label: 'Interest Paid Till',
          value: GirviInvoicePdfService._dateFormat
              .format(draft.lastInterestPaidDate!),
        ),
      if (draft.releaseDate != null)
        _GirviDetailEntry(
          label: 'Release Date',
          value: GirviInvoicePdfService._dateFormat.format(draft.releaseDate!),
          strong: true,
        ),
      if (draft.expectedDeliveryDate != null)
        _GirviDetailEntry(
          label: 'Expected Delivery',
          value: GirviInvoicePdfService._dateFormat
              .format(draft.expectedDeliveryDate!),
        ),
      if (draft.deliveredAt != null)
        _GirviDetailEntry(
          label: 'Delivered At',
          value: GirviInvoicePdfService._dateFormat.format(draft.deliveredAt!),
        ),
    ];
    if (entries.isEmpty) return null;

    return pw.Wrap(
      spacing: compact ? 5 : 7,
      runSpacing: compact ? 5 : 7,
      children: [
        for (final entry in entries)
          pw.SizedBox(
            width: compact ? 122 : 154,
            child: _buildDetailCard(entry, compact),
          ),
      ],
    );
  }

  pw.Widget _buildDetailCard(_GirviDetailEntry entry, bool compact) {
    return pw.Container(
      padding: pw.EdgeInsets.all(compact ? 7 : 9),
      decoration: pw.BoxDecoration(
        color: entry.strong
            ? GirviInvoicePdfService._goldLight
            : GirviInvoicePdfService._surface,
        border: pw.Border.all(
          color: entry.strong
              ? GirviInvoicePdfService._gold
              : GirviInvoicePdfService._line,
          width: 0.65,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildEyebrow(entry.label.toUpperCase(), compact),
          pw.SizedBox(height: compact ? 3 : 4),
          pw.Text(
            entry.value,
            style: pw.TextStyle(
              color: GirviInvoicePdfService._ink,
              fontSize: compact ? 8 : 9.5,
              fontWeight:
                  entry.strong ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBilingualTermRow({
    required int index,
    required String english,
    required String hindi,
    required bool compact,
    required pw.Font? devanagariFont,
    required LotusPdfTextRenderer textRenderer,
  }) {
    final hindiStyle = pw.TextStyle(
      font: devanagariFont,
      color: GirviInvoicePdfService._navySoft,
      fontSize: compact ? 7.2 : 8.5,
      lineSpacing: 2,
    );
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(compact ? 7 : 9),
      decoration: pw.BoxDecoration(
        color: index.isOdd
            ? GirviInvoicePdfService._goldLight
            : GirviInvoicePdfService._surface,
        border: pw.Border.all(
          color: index.isOdd
              ? const PdfColor.fromInt(0xFFEAD6A0)
              : GirviInvoicePdfService._line,
          width: 0.65,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: compact ? 18 : 22,
            height: compact ? 18 : 22,
            alignment: pw.Alignment.center,
            decoration: const pw.BoxDecoration(
              color: GirviInvoicePdfService._navy,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Text(
              index.toString(),
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: compact ? 6.5 : 7.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: compact ? 7 : 9),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (english.isNotEmpty)
                  pw.Text(
                    english,
                    style: pw.TextStyle(
                      color: GirviInvoicePdfService._ink,
                      fontSize: compact ? 7 : 8.2,
                      lineSpacing: 1.8,
                    ),
                  ),
                if (english.isNotEmpty && hindi.isNotEmpty)
                  pw.SizedBox(height: compact ? 3 : 4),
                if (hindi.isNotEmpty)
                  textRenderer.text(
                    hindi,
                    style: hindiStyle,
                    maxWidth: compact ? 430 : 470,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerDeclaration({
    required String number,
    required String english,
    required String hindi,
    required bool compact,
    required pw.Font? devanagariFont,
    required LotusPdfTextRenderer textRenderer,
  }) {
    final hindiStyle = pw.TextStyle(
      font: devanagariFont,
      color: GirviInvoicePdfService._navySoft,
      fontSize: compact ? 7.4 : 8.8,
      lineSpacing: 2.2,
    );
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          number: number,
          title: 'CUSTOMER DECLARATION',
          subtitle: 'Bilingual acknowledgement before signing',
          compact: compact,
        ),
        pw.SizedBox(height: compact ? 7 : 9),
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(compact ? 8 : 11),
          decoration: pw.BoxDecoration(
            color: GirviInvoicePdfService._surface,
            border:
                pw.Border.all(color: GirviInvoicePdfService._line, width: 0.7),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (english.trim().isNotEmpty)
                pw.Text(
                  english.trimRight(),
                  style: pw.TextStyle(
                    color: GirviInvoicePdfService._ink,
                    fontSize: compact ? 7.2 : 8.5,
                    lineSpacing: 2,
                  ),
                ),
              if (english.trim().isNotEmpty && hindi.trim().isNotEmpty)
                pw.SizedBox(height: compact ? 5 : 7),
              if (hindi.trim().isNotEmpty)
                textRenderer.text(
                  hindi.trimRight(),
                  style: hindiStyle,
                  maxWidth: compact ? 430 : 500,
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget? _buildKycSection(
    GirviInvoiceDraft draft,
    GirviBillingModel settings,
    bool compact,
  ) {
    final showDetails = settings.showKycDetails &&
        ((draft.idProofType?.trim().isNotEmpty ?? false) ||
            (draft.idProofNumber?.trim().isNotEmpty ?? false));
    pw.MemoryImage? image;
    if (settings.showKycPhoto &&
        (draft.idProofImagePath?.trim().isNotEmpty ?? false)) {
      final file = File(draft.idProofImagePath!.trim());
      if (file.existsSync()) {
        try {
          image = pw.MemoryImage(file.readAsBytesSync());
        } catch (_) {
          image = null;
        }
      }
    }
    if (!showDetails && image == null) return null;

    final details = pw.Container(
      padding: pw.EdgeInsets.all(compact ? 8 : 11),
      decoration: pw.BoxDecoration(
        color: GirviInvoicePdfService._surface,
        border: pw.Border.all(color: GirviInvoicePdfService._line),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (showDetails) ...[
            _buildCustomerMeta(
              label: 'DOCUMENT TYPE',
              value: draft.idProofType?.trim().isEmpty ?? true
                  ? '-'
                  : draft.idProofType!.trim(),
              compact: compact,
            ),
            pw.SizedBox(height: compact ? 7 : 9),
            _buildCustomerMeta(
              label: 'DOCUMENT NUMBER',
              value: draft.idProofNumber?.trim().isEmpty ?? true
                  ? '-'
                  : draft.idProofNumber!.trim(),
              compact: compact,
            ),
          ] else
            pw.Text(
              'KYC document photo attached',
              style: pw.TextStyle(
                color: GirviInvoicePdfService._ink,
                fontSize: compact ? 8 : 9.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
        ],
      ),
    );

    if (image == null) return details;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(flex: 5, child: details),
        pw.SizedBox(width: compact ? 8 : 11),
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            height: compact ? 80 : 110,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: GirviInvoicePdfService._line),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTextSection({
    required String number,
    required String title,
    required String subtitle,
    required String body,
    required bool compact,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          number: number,
          title: title,
          subtitle: subtitle,
          compact: compact,
        ),
        pw.SizedBox(height: compact ? 7 : 9),
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(compact ? 8 : 11),
          decoration: pw.BoxDecoration(
            color: GirviInvoicePdfService._surface,
            border: pw.Border.all(color: GirviInvoicePdfService._line),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Text(
            body,
            style: pw.TextStyle(
              color: GirviInvoicePdfService._ink,
              fontSize: compact ? 7.5 : 8.8,
              lineSpacing: compact ? 2 : 3,
            ),
          ),
        ),
      ],
    );
  }
}

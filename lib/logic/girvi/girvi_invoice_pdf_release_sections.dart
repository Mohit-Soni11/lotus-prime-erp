part of 'girvi_invoice_pdf_service.dart';

pw.Widget _girviReleaseSettlement(
  GirviInvoiceDraft draft,
  GirviReceiptFinancialSummary summary,
  PrintTemplatePdfProfile profile,
) {
  final rows = <List<String>>[
    if ((draft.releasePenalty ?? 0) > 0)
      [
        'Penalty / Charges',
        GirviInvoicePdfService._formatAmount(draft.releasePenalty!)
      ],
    if (summary.discount > 0.005)
      [
        'Discount / Waiver',
        GirviInvoicePdfService._formatAmount(summary.discount),
      ],
    if (summary.settlementModes.isNotEmpty)
      ['Collection Mode', summary.settlementModes],
  ];

  return _girviSection(
    title: 'FINAL SETTLEMENT',
    profile: profile,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.TableHelper.fromTextArray(
          headers: const [
            'Collection Stage',
            'Principal Received',
            'Interest Received',
            'Total Collected',
          ],
          data: [
            [
              'Paid Before Release',
              GirviInvoicePdfService._formatAmount(summary.priorPrincipal),
              GirviInvoicePdfService._formatAmount(summary.priorInterest),
              GirviInvoicePdfService._formatAmount(summary.previouslyCollected),
            ],
            [
              'Paid at Release',
              GirviInvoicePdfService._formatAmount(summary.settlementPrincipal),
              GirviInvoicePdfService._formatAmount(summary.settlementInterest),
              GirviInvoicePdfService._formatAmount(
                  summary.collectedAtSettlement),
            ],
          ],
          headerStyle: pw.TextStyle(
            color: profile.tableHeaderTextColor,
            fontSize: profile.tableFontSize + 1,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: pw.TextStyle(
            color: profile.bodyTextColor,
            fontSize: profile.tableFontSize + 1.2,
            fontWeight: pw.FontWeight.bold,
          ),
          headerDecoration: pw.BoxDecoration(color: profile.tableHeaderColor),
          border: pw.TableBorder.all(
            color: profile.tableBorderColor,
            width: profile.tableBorderWidth,
          ),
          cellAlignment: pw.Alignment.centerLeft,
          headerAlignment: pw.Alignment.centerLeft,
          cellPadding: pw.EdgeInsets.symmetric(
            horizontal: profile.tableCellPadding + 2,
            vertical: profile.tableCellPadding + 3,
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.4),
            1: pw.FlexColumnWidth(1.15),
            2: pw.FlexColumnWidth(1.15),
            3: pw.FlexColumnWidth(1.1),
          },
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.symmetric(
            horizontal: profile.panelPadding + 4,
            vertical: profile.panelPadding + 3,
          ),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFEAF8F1),
            border: pw.Border.all(color: _receiptGreen, width: 1.1),
            borderRadius: pw.BorderRadius.circular(profile.radius),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TOTAL RECEIVED',
                style: pw.TextStyle(
                  color: profile.bodyTextColor,
                  fontSize: profile.bodyFontSize + 2,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                GirviInvoicePdfService._formatAmount(summary.totalReceived),
                style: pw.TextStyle(
                  color: _receiptGreen,
                  fontSize: profile.titleFontSize + 1,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (rows.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          _girviKeyValueTable(rows, profile),
        ],
      ],
    ),
  );
}

pw.Widget _girviDeliveryStatus(
  GirviInvoiceDraft draft,
  PrintTemplatePdfProfile profile,
) {
  final delivered = draft.deliveredAt != null;
  final status = delivered ? 'Delivered' : 'Ready for Delivery';
  final rows = <List<String>>[
    if (draft.releaseDate != null)
      [
        'Release Date',
        GirviInvoicePdfService._dateFormat.format(draft.releaseDate!),
      ],
    if (draft.expectedDeliveryDate != null)
      [
        'Expected Pickup Date',
        GirviInvoicePdfService._dateFormat.format(
          draft.expectedDeliveryDate!,
        ),
      ],
    if (draft.deliveredAt != null)
      [
        'Delivered At',
        GirviInvoicePdfService._dateFormat.format(draft.deliveredAt!),
      ],
    if ((draft.releaseNotes ?? '').trim().isNotEmpty)
      ['Release Notes', draft.releaseNotes!.trim()],
  ];

  return _girviSection(
    title: 'RELEASE SUMMARY',
    profile: profile,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            _girviStatusPill(
              status.toUpperCase(),
              _receiptGreen,
              profile: profile,
              width: 128,
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              delivered
                  ? 'Pledged items handed over to the customer.'
                  : 'Pledged items cleared for handover.',
              style: pw.TextStyle(
                color: profile.bodyTextColor,
                fontSize: profile.bodyFontSize + 1,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        if (rows.isNotEmpty) _girviKeyValueTable(rows, profile),
      ],
    ),
  );
}

pw.Widget _girviReleaseAcknowledgement(PrintTemplatePdfProfile profile) {
  return pw.Container(
    width: double.infinity,
    padding: pw.EdgeInsets.all(profile.panelPadding + 3),
    decoration: pw.BoxDecoration(
      color: profile.panelColor,
      border: pw.Border.all(
        color: profile.borderColor,
        width: profile.borderWidth,
      ),
      borderRadius: pw.BorderRadius.circular(profile.radius),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ACKNOWLEDGEMENT',
          style: pw.TextStyle(
            color: profile.bodyTextColor,
            fontSize: profile.documentTitleFontSize - 2,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Expanded(
              child: _girviSignatureBox('Customer Signature', profile),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _girviSignatureBox('Shop Stamp', profile),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _girviSignatureBox('Authorised Signature', profile),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _girviSignatureBox(
  String label,
  PrintTemplatePdfProfile profile,
) {
  return pw.Container(
    height: 44,
    padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
    decoration: pw.BoxDecoration(
      color: profile.panelColor,
      border: pw.Border.all(
        color: profile.borderColor,
        width: profile.borderWidth,
      ),
      borderRadius: pw.BorderRadius.circular(profile.radius),
    ),
    child: pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          height: 0.8,
          color: profile.bodyTextColor,
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          label,
          style: pw.TextStyle(
            color: profile.bodyTextColor,
            fontSize: profile.labelFontSize + 0.6,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

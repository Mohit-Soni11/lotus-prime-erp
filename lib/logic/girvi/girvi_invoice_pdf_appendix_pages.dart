part of 'girvi_invoice_pdf_service.dart';

void _appendLifecycleReceiptPages({
  required pw.Document pdf,
  required GirviInvoiceDraft draft,
  required PrintTemplatePdfProfile profile,
  required bool duplicateCopy,
}) {
  final summary = GirviReceiptFinancialSummary.fromDraft(draft);
  final interestEntries = summary.interestEntries;
  if (interestEntries.isNotEmpty) {
    final interestQuote = draft.interestQuote;
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(30, 30, 30, 26),
          buildForeground: draft.recoveryDisposition != null
              ? (_) => girviRecoveryWatermark(draft.recoveryDisposition!)
              : draft.isReleaseReceipt
                  ? (_) => _girviStatusWatermark(
                        label: 'Released',
                        subtitle: 'Account settled',
                        color: _receiptGreen,
                        opacity: 0.11,
                      )
                  : null,
        ),
        footer: (context) => _girviAppendixFooter(
          context,
          duplicateCopy,
          profile,
          'Girvi interest receipt',
        ),
        build: (_) => [
          _girviAppendixHeader(
            title: 'INTEREST RECEIPT',
            subtitle: 'Interest calculation, collections and account balance',
            draft: draft,
            profile: profile,
            duplicateCopy: duplicateCopy,
          ),
          pw.SizedBox(height: 18),
          if (interestQuote.interestType ==
              GirviInterestCalculationType.compound) ...[
            _girviCompoundInterestCalculation(draft, interestQuote, profile),
            pw.SizedBox(height: 16),
          ],
          _girviInterestLedgerTable(interestEntries, profile),
          pw.SizedBox(height: 16),
          _girviInterestSummary(
            draft,
            summary,
            interestQuote,
            profile,
          ),
        ],
      ),
    );
  }

  if (draft.isReleaseReceipt) {
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(30, 30, 30, 26),
          buildForeground: (_) => _girviStatusWatermark(
            label:
                draft.deliveredAt == null ? 'Ready for Delivery' : 'Delivered',
            subtitle: draft.deliveredAt == null
                ? 'Settlement complete'
                : 'Item handover complete',
            color: _receiptGreen,
            opacity: 0.11,
          ),
        ),
        footer: (context) => _girviAppendixFooter(
          context,
          duplicateCopy,
          profile,
          'Girvi release receipt',
        ),
        build: (_) => [
          _girviAppendixHeader(
            title: 'RELEASE RECEIPT',
            subtitle: 'Final settlement and item handover status',
            draft: draft,
            profile: profile,
            duplicateCopy: duplicateCopy,
          ),
          pw.SizedBox(height: 14),
          _girviReleaseSettlement(draft, summary, profile),
          pw.SizedBox(height: 12),
          _girviDeliveryStatus(draft, profile),
          pw.SizedBox(height: 12),
          _girviReleaseAcknowledgement(profile),
        ],
      ),
    );
  }
}

bool _shouldShowReleasedWatermark(GirviInvoiceDraft draft) {
  if (draft.isReleaseReceipt) return true;
  final status = draft.accountStatus.toLowerCase();
  return status.contains('released') ||
      status.contains('ready for delivery') ||
      draft.deliveredAt != null ||
      draft.releaseDate != null;
}

const _receiptGreen = PdfColor.fromInt(0xFF059669);
const _receiptRed = PdfColor.fromInt(0xFFDC2626);

pw.Widget _girviAppendixHeader({
  required String title,
  required String subtitle,
  required GirviInvoiceDraft draft,
  required PrintTemplatePdfProfile profile,
  required bool duplicateCopy,
}) {
  final accent = profile.accentColor;
  return pw.Container(
    padding: pw.EdgeInsets.all(profile.headerPadding),
    decoration: pw.BoxDecoration(
      color: profile.headerColor,
      border: pw.Border.all(
        color: profile.headerBorderColor,
        width:
            profile.headerBorderWidth <= 0 ? 0.85 : profile.headerBorderWidth,
      ),
      borderRadius: pw.BorderRadius.circular(profile.radius),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 44,
              height: 44,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: profile.summaryColor,
                border: pw.Border.all(
                  color: accent,
                  width: profile.borderWidth,
                ),
                borderRadius: pw.BorderRadius.circular(profile.radius),
              ),
              child: pw.Text(
                title == 'INTEREST RECEIPT' ? '%' : 'REL',
                style: pw.TextStyle(
                  color: accent,
                  fontSize: title == 'INTEREST RECEIPT' ? 18 : 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          title,
                          style: pw.TextStyle(
                            color: profile.headerPrimaryTextColor,
                            fontSize: profile.titleFontSize + 2,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      if (duplicateCopy)
                        _girviStatusPill(
                          'DUPLICATE',
                          accent,
                          profile: profile,
                        ),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    subtitle,
                    style: pw.TextStyle(
                      color: profile.headerPrimaryTextColor,
                      fontSize: profile.bodyFontSize + 2.4,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _girviHeaderMetric('Invoice No.', draft.ticketNo, profile),
            _girviHeaderMetric(
              'Customer',
              GirviInvoicePdfService._fallback(
                draft.customerName,
                'Walk-in Customer',
              ),
              profile,
            ),
            _girviHeaderMetric(
                'Start Date',
                GirviInvoicePdfService._dateFormat.format(draft.startDate),
                profile),
            _girviHeaderMetric(
                'Maturity Date',
                GirviInvoicePdfService._dateFormat.format(draft.maturityDate),
                profile),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _girviHeaderMetric(
  String label,
  String value,
  PrintTemplatePdfProfile profile,
) {
  return pw.Container(
    width: 120,
    padding: const pw.EdgeInsets.symmetric(horizontal: 11, vertical: 9),
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
          label,
          style: pw.TextStyle(
            color: profile.bodyTextColor,
            fontSize: profile.labelFontSize + 0.8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          maxLines: 2,
          style: pw.TextStyle(
            color: profile.bodyTextColor,
            fontSize: profile.bodyFontSize + 1.8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _girviStatusPill(
  String label,
  PdfColor color, {
  required PrintTemplatePdfProfile profile,
  double? width,
}) {
  return pw.Container(
    width: width,
    alignment: pw.Alignment.center,
    padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(color.toInt()).shade(0.08),
      border: pw.Border.all(color: color, width: profile.borderWidth),
      borderRadius:
          pw.BorderRadius.circular(width == null ? 30 : profile.radius),
    ),
    child: pw.Text(
      label,
      style: pw.TextStyle(
        color: width == null ? color : profile.bodyTextColor,
        fontSize:
            width == null ? profile.labelFontSize : profile.labelFontSize - 1,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

pw.Widget _girviSection({
  required String title,
  required PrintTemplatePdfProfile profile,
  required pw.Widget child,
}) {
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
          title,
          style: pw.TextStyle(
            color: profile.bodyTextColor,
            fontSize: profile.documentTitleFontSize - 2,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        child,
      ],
    ),
  );
}

pw.Widget _girviKeyValueTable(
  List<List<String>> rows,
  PrintTemplatePdfProfile profile,
) {
  return pw.Table(
    border: pw.TableBorder.all(
      color: profile.tableBorderColor,
      width: profile.tableBorderWidth,
    ),
    columnWidths: const {
      0: pw.FlexColumnWidth(1),
      1: pw.FlexColumnWidth(1.4),
    },
    children: [
      for (final row in rows)
        pw.TableRow(
          children: [
            _girviKeyValueCell(row[0], strong: false, profile: profile),
            _girviKeyValueCell(row[1], strong: true, profile: profile),
          ],
        ),
    ],
  );
}

pw.Widget _girviKeyValueCell(
  String text, {
  required bool strong,
  required PrintTemplatePdfProfile profile,
}) {
  return pw.Padding(
    padding: pw.EdgeInsets.symmetric(
      horizontal: profile.tableCellPadding + 3,
      vertical: profile.tableCellPadding + 2,
    ),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        color: profile.bodyTextColor,
        fontSize: profile.bodyFontSize + 1.3,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

pw.Widget _girviAppendixFooter(
  pw.Context context,
  bool duplicateCopy,
  PrintTemplatePdfProfile profile,
  String label,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(top: 8),
    decoration: pw.BoxDecoration(
      border: pw.Border(
        top: pw.BorderSide(
          color: profile.borderColor,
          width: profile.borderWidth,
        ),
      ),
    ),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            duplicateCopy ? '$label - duplicate copy' : label,
            style: pw.TextStyle(
              color: profile.bodyTextColor,
              fontSize: profile.labelFontSize - 0.7,
            ),
          ),
        ),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: pw.TextStyle(
            color: profile.bodyTextColor,
            fontSize: profile.labelFontSize - 0.7,
          ),
        ),
      ],
    ),
  );
}

String _ratePercentLabel(double value) {
  if (value % 1 == 0) return '${value.toStringAsFixed(0)}%';
  final text = value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  return '$text%';
}

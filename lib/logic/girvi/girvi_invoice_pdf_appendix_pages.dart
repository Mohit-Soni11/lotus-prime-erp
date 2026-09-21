part of 'girvi_invoice_pdf_service.dart';

void _appendLifecycleReceiptPages({
  required pw.Document pdf,
  required GirviInvoiceDraft draft,
  required PrintTemplatePdfProfile profile,
  required bool duplicateCopy,
}) {
  final interestEntries = _girviInterestLedgerEntries(draft);
  if (interestEntries.isNotEmpty) {
    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.fromLTRB(30, 30, 30, 26),
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
            subtitle: 'Date-wise interest collection record',
            draft: draft,
            profile: profile,
            duplicateCopy: duplicateCopy,
          ),
          pw.SizedBox(height: 18),
          _girviInterestSummary(draft, interestEntries, profile),
          pw.SizedBox(height: 16),
          _girviInterestLedgerTable(interestEntries, profile),
        ],
      ),
    );
  }

  if (draft.isReleaseReceipt) {
    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.fromLTRB(30, 30, 30, 26),
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
            subtitle: 'Final settlement and item release record',
            draft: draft,
            profile: profile,
            duplicateCopy: duplicateCopy,
          ),
          pw.SizedBox(height: 18),
          _girviReleaseSettlement(draft, profile),
          pw.SizedBox(height: 16),
          _girviDeliveryStatus(draft, profile),
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

const _receiptMuted = PdfColor.fromInt(0xFF4B5563);
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
                  fontSize: title == 'INTEREST RECEIPT' ? 16 : 10,
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
                      color: _receiptMuted,
                      fontSize: profile.bodyFontSize + 1.5,
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
            _girviHeaderMetric('Ticket No.', draft.ticketNo, profile),
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
    width: 118,
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            color: _receiptMuted,
            fontSize: profile.labelFontSize - 0.8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          maxLines: 2,
          style: pw.TextStyle(
            color: profile.bodyTextColor,
            fontSize: profile.bodyFontSize + 1,
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
        color: color,
        fontSize:
            width == null ? profile.labelFontSize : profile.labelFontSize - 1,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

pw.Widget _girviInterestSummary(
  GirviInvoiceDraft draft,
  List<GirviInvoiceLedgerEntry> entries,
  PrintTemplatePdfProfile profile,
) {
  final totalInterest = entries.fold<double>(
    0,
    (sum, entry) =>
        sum + (entry.interestAmount > 0 ? entry.interestAmount : entry.amount),
  );
  final coveredMonths =
      entries.fold<int>(0, (sum, entry) => sum + (entry.monthsCovered ?? 0));
  final interestOutstanding = draft.interestOutstanding ?? 0;
  return pw.Row(
    children: [
      pw.Expanded(
        child: _girviSummaryCard(
          'Interest Received',
          GirviInvoicePdfService._formatAmount(totalInterest),
          profile,
        ),
      ),
      pw.SizedBox(width: 10),
      pw.Expanded(
        child: _girviSummaryCard(
          'Months Covered',
          coveredMonths > 0
              ? '$coveredMonths month${coveredMonths == 1 ? '' : 's'}'
              : '-',
          profile,
        ),
      ),
      pw.SizedBox(width: 10),
      pw.Expanded(
        child: _girviSummaryCard(
          'Interest Outstanding',
          GirviInvoicePdfService._formatAmount(interestOutstanding),
          profile,
          valueColor: interestOutstanding > 0 ? _receiptRed : null,
        ),
      ),
    ],
  );
}

pw.Widget _girviSummaryCard(
  String label,
  String value,
  PrintTemplatePdfProfile profile, {
  PdfColor? valueColor,
}) {
  return pw.Container(
    padding: pw.EdgeInsets.all(profile.panelPadding),
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
            color: _receiptMuted,
            fontSize: profile.labelFontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: valueColor ?? profile.bodyTextColor,
            fontSize: profile.titleFontSize - 2,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _girviInterestLedgerTable(
  List<GirviInvoiceLedgerEntry> entries,
  PrintTemplatePdfProfile profile,
) {
  final rows = entries.map((entry) {
    final amount =
        entry.interestAmount > 0 ? entry.interestAmount : entry.amount;
    return [
      GirviInvoicePdfService._dateFormat.format(entry.date),
      entry.modeLabel,
      _interestCoverageLabel(entry),
      _monthsLabel(entry.monthsCovered),
      GirviInvoicePdfService._formatAmount(amount),
      GirviInvoicePdfService._formatAmount(entry.balanceAfter),
    ];
  }).toList(growable: false);

  return _girviSection(
    title: 'INTEREST RECEIVED LEDGER',
    profile: profile,
    child: pw.TableHelper.fromTextArray(
      headers: const [
        'Date',
        'Mode',
        'Interest Period',
        'Months',
        'Interest Received',
        'Balance',
      ],
      data: rows,
      headerStyle: pw.TextStyle(
        color: profile.tableHeaderTextColor,
        fontSize: profile.tableFontSize,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(
        color: profile.bodyTextColor,
        fontSize: profile.tableFontSize,
      ),
      headerDecoration: pw.BoxDecoration(color: profile.tableHeaderColor),
      border: pw.TableBorder.all(
        color: profile.tableBorderColor,
        width: profile.tableBorderWidth,
      ),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: pw.EdgeInsets.symmetric(
        horizontal: profile.tableCellPadding,
        vertical: profile.tableCellPadding + 1.5,
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(68),
        1: pw.FixedColumnWidth(62),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FixedColumnWidth(58),
        4: pw.FixedColumnWidth(82),
        5: pw.FixedColumnWidth(74),
      },
    ),
  );
}

pw.Widget _girviReleaseSettlement(
  GirviInvoiceDraft draft,
  PrintTemplatePdfProfile profile,
) {
  final releasePrincipal = draft.releasePrincipal ?? draft.loanAmount;
  final interestCollected = _girviInterestLedgerEntries(draft).fold<double>(
    0,
    (sum, entry) =>
        sum + (entry.interestAmount > 0 ? entry.interestAmount : entry.amount),
  );
  final releaseInterest = draft.releaseInterest ?? 0;
  final releasePenalty = draft.releasePenalty ?? 0;
  final releaseDiscount = draft.releaseDiscount ?? 0;
  final releaseTotal = draft.releaseTotalAmount ??
      (releasePrincipal + releaseInterest + releasePenalty - releaseDiscount);
  final totalInterest = interestCollected + releaseInterest;

  final rows = <List<String>>[
    [
      'Principal Received',
      GirviInvoicePdfService._formatAmount(releasePrincipal)
    ],
    [
      'Interest Already Collected',
      GirviInvoicePdfService._formatAmount(interestCollected)
    ],
    [
      'Interest Due at Release',
      GirviInvoicePdfService._formatAmount(releaseInterest)
    ],
    ['Total Interest', GirviInvoicePdfService._formatAmount(totalInterest)],
    if (releasePenalty > 0)
      [
        'Penalty / Charges',
        GirviInvoicePdfService._formatAmount(releasePenalty)
      ],
    if (releaseDiscount > 0)
      [
        'Discount / Waiver',
        '- ${GirviInvoicePdfService._formatAmount(releaseDiscount)}',
      ],
    ['Total Paid', GirviInvoicePdfService._formatAmount(releaseTotal)],
    if ((draft.releasePaymentMode ?? '').trim().isNotEmpty)
      ['Collection Mode', draft.releasePaymentMode!.trim()],
  ];

  return _girviSection(
    title: 'FINAL SETTLEMENT',
    profile: profile,
    child: pw.Column(
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              child: _girviSummaryCard(
                'Principal',
                GirviInvoicePdfService._formatAmount(releasePrincipal),
                profile,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _girviSummaryCard(
                'Total Interest',
                GirviInvoicePdfService._formatAmount(totalInterest),
                profile,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _girviSummaryCard(
                'Total Paid',
                GirviInvoicePdfService._formatAmount(releaseTotal),
                profile,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        _girviKeyValueTable(rows, profile),
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
    ['Delivery Status', status],
    [
      'Release Date',
      GirviInvoicePdfService._dateFormat.format(
        draft.releaseDate ?? draft.createdAt,
      ),
    ],
    [
      'Expected Pickup Date',
      draft.expectedDeliveryDate == null
          ? '-'
          : GirviInvoicePdfService._dateFormat.format(
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
              'Pledged items cleared for handover.',
              style: pw.TextStyle(
                color: _receiptMuted,
                fontSize: profile.bodyFontSize + 1,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        _girviKeyValueTable(rows, profile),
      ],
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
            fontSize: profile.documentTitleFontSize - 4,
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
        color: strong ? profile.bodyTextColor : _receiptMuted,
        fontSize: profile.bodyFontSize,
        fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
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

List<GirviInvoiceLedgerEntry> _girviInterestLedgerEntries(
  GirviInvoiceDraft draft,
) {
  final rows = draft.ledgerEntries.where((entry) {
    final hasInterest = entry.interestAmount > 0;
    final isInterestType = entry.typeLabel.toLowerCase().contains('interest');
    return hasInterest || isInterestType;
  }).toList()
    ..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return a.typeLabel.compareTo(b.typeLabel);
    });
  return rows;
}

String _interestCoverageLabel(GirviInvoiceLedgerEntry entry) {
  final from = entry.interestFromDate;
  final to = entry.interestToDate;
  if (from != null && to != null) {
    return '${GirviInvoicePdfService._dateFormat.format(from)} to '
        '${GirviInvoicePdfService._dateFormat.format(to)}';
  }
  final months = entry.monthsCovered ?? 0;
  if (months > 0) return _monthsLabel(months);
  return 'No interest period';
}

String _monthsLabel(int? months) {
  final value = months ?? 0;
  if (value <= 0) return '-';
  return '$value month${value == 1 ? '' : 's'}';
}

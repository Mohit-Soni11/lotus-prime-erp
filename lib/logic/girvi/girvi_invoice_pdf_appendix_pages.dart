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
          _girviCompoundInterestCalculation(draft, profile),
          if (_hasCompoundInterestCalculation(draft)) pw.SizedBox(height: 16),
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
          pw.SizedBox(height: 14),
          _girviReleaseSettlement(draft, profile),
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
  final interestMonthLabel = coveredMonths > 0
      ? '$coveredMonths month${coveredMonths == 1 ? '' : 's'}'
      : _interestCollectionMonthSummary(entries);
  final interestOutstanding = draft.interestOutstanding ?? 0;
  final cards = <pw.Widget>[
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
        'Interest Months',
        interestMonthLabel,
        profile,
      ),
    ),
    if (interestOutstanding > 0.005) ...[
      pw.SizedBox(width: 10),
      pw.Expanded(
        child: _girviSummaryCard(
          'Interest Outstanding',
          GirviInvoicePdfService._formatAmount(interestOutstanding),
          profile,
          valueColor: _receiptRed,
        ),
      ),
    ],
  ];
  return pw.Row(
    children: cards,
  );
}

pw.Widget _girviSummaryCard(
  String label,
  String value,
  PrintTemplatePdfProfile profile, {
  PdfColor? valueColor,
}) {
  return pw.Container(
    padding: pw.EdgeInsets.all(profile.panelPadding + 2),
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
            fontSize: profile.labelFontSize + 1.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: valueColor ?? profile.bodyTextColor,
            fontSize: profile.titleFontSize,
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
  final showBalance = entries.any((entry) => entry.balanceAfter.abs() > 0.005);
  final rows = entries.map((entry) {
    final amount =
        entry.interestAmount > 0 ? entry.interestAmount : entry.amount;
    final row = [
      GirviInvoicePdfService._dateFormat.format(entry.date),
      entry.modeLabel,
      _interestCoverageLabel(entry),
      _interestMonthLabel(entry),
      GirviInvoicePdfService._formatAmount(amount),
    ];
    if (showBalance) {
      row.add(GirviInvoicePdfService._formatAmount(entry.balanceAfter));
    }
    return row;
  }).toList(growable: false);
  final headers = <String>[
    'Date',
    'Mode',
    'Interest Period',
    'Months',
    'Interest Received',
    if (showBalance) 'Balance',
  ];
  final columnWidths = <int, pw.TableColumnWidth>{
    0: const pw.FixedColumnWidth(72),
    1: const pw.FixedColumnWidth(64),
    2: const pw.FlexColumnWidth(1.7),
    3: const pw.FixedColumnWidth(76),
    4: const pw.FixedColumnWidth(94),
    if (showBalance) 5: const pw.FixedColumnWidth(78),
  };

  return _girviSection(
    title: 'INTEREST RECEIVED LEDGER',
    profile: profile,
    child: pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
        color: profile.tableHeaderTextColor,
        fontSize: profile.tableFontSize + 1.3,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(
        color: profile.bodyTextColor,
        fontSize: profile.tableFontSize + 1.15,
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
        horizontal: profile.tableCellPadding + 1,
        vertical: profile.tableCellPadding + 2.2,
      ),
      columnWidths: columnWidths,
    ),
  );
}

pw.Widget _girviReleaseSettlement(
  GirviInvoiceDraft draft,
  PrintTemplatePdfProfile profile,
) {
  final releasePrincipal = draft.releasePrincipal ?? draft.loanAmount;
  final interestEntries = _girviInterestLedgerEntries(draft);
  final releaseEntryInterest = interestEntries
      .where((entry) => entry.typeLabel.toLowerCase().contains('release'))
      .fold<double>(
        0,
        (sum, entry) =>
            sum +
            (entry.interestAmount > 0 ? entry.interestAmount : entry.amount),
      );
  final ledgerInterestTotal = interestEntries.fold<double>(
    0,
    (sum, entry) =>
        sum + (entry.interestAmount > 0 ? entry.interestAmount : entry.amount),
  );
  final releaseInterest = draft.releaseInterest ?? releaseEntryInterest;
  final interestCollected =
      (ledgerInterestTotal - releaseEntryInterest).clamp(0.0, double.infinity);
  final releasePenalty = draft.releasePenalty ?? 0;
  final releaseDiscount = draft.releaseDiscount ?? 0;
  final releaseTotal = draft.releaseTotalAmount ??
      (releasePrincipal + releaseInterest + releasePenalty - releaseDiscount);
  final totalInterest = interestCollected + releaseInterest;

  final rows = <List<String>>[
    if (interestCollected > 0.005)
      [
        'Interest Already Collected',
        GirviInvoicePdfService._formatAmount(interestCollected)
      ],
    if (releaseInterest > 0.005)
      [
        'Interest Collected at Release',
        GirviInvoicePdfService._formatAmount(releaseInterest)
      ],
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
        if (rows.isNotEmpty) _girviKeyValueTable(rows, profile),
      ],
    ),
  );
}

bool _hasCompoundInterestCalculation(GirviInvoiceDraft draft) {
  final releaseDate = draft.releaseDate ?? draft.createdAt;
  final chargeableMonths = GirviLoanModel.chargeableMonthsBetween(
    draft.startDate,
    releaseDate,
  );
  return chargeableMonths > GirviLoanModel.compoundCycleMonths;
}

pw.Widget _girviCompoundInterestCalculation(
  GirviInvoiceDraft draft,
  PrintTemplatePdfProfile profile,
) {
  final releaseDate = draft.releaseDate ?? draft.createdAt;
  final chargeableMonths = GirviLoanModel.chargeableMonthsBetween(
    draft.startDate,
    releaseDate,
  );
  if (chargeableMonths <= GirviLoanModel.compoundCycleMonths) {
    return pw.SizedBox.shrink();
  }

  final lines = GirviLoanModel.calculateCompoundInterestBreakdown(
    principal: draft.loanAmount,
    monthlyRatePercent: draft.interestRate,
    months: chargeableMonths,
  );
  if (lines.isEmpty) return pw.SizedBox.shrink();

  final rows = lines.map((line) {
    final period = GirviInterestPeriodText.forBreakdownLine(
      loanStartDate: draft.startDate,
      line: line,
    );
    final totalWithInterest = GirviInvoicePdfService._formatAmount(
      line.principalBase + line.interestAmount,
    );

    return <String>[
      line.cycleNumber.toString().padLeft(2, '0'),
      '${period.cycleLabel}\n${period.monthRangeLabel}',
      GirviInvoicePdfService._formatAmount(line.principalBase),
      '${GirviInvoicePdfService._formatAmount(line.monthlyInterest)}\n'
          '${_ratePercentLabel(line.monthlyRatePercent)} monthly',
      GirviInvoicePdfService._formatAmount(line.interestAmount),
      line.capitalizedAfterLine
          ? 'Capitalized\n$totalWithInterest'
          : 'Final cycle\n$totalWithInterest',
    ];
  }).toList();

  return _girviSection(
    title: 'COMPOUND INTEREST CALCULATION',
    profile: profile,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Each completed 12-month cycle is added to the next principal base.',
          style: pw.TextStyle(
            color: profile.bodyTextColor,
            fontSize: profile.bodyFontSize + 1.2,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          context: null,
          headers: const [
            'No.',
            'Interest Cycle',
            'Base Principal',
            'Monthly Interest',
            'Total Interest',
            'Next Base',
          ],
          data: rows,
          headerStyle: pw.TextStyle(
            color: profile.tableHeaderTextColor,
            fontSize: profile.tableFontSize + 1,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: pw.TextStyle(
            color: profile.bodyTextColor,
            fontSize: profile.tableFontSize + 0.75,
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
            horizontal: profile.tableCellPadding,
            vertical: profile.tableCellPadding + 1.5,
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(0.45),
            1: pw.FlexColumnWidth(1.65),
            2: pw.FlexColumnWidth(1.35),
            3: pw.FlexColumnWidth(1.05),
            4: pw.FlexColumnWidth(1.05),
            5: pw.FlexColumnWidth(1.15),
          },
        ),
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
              'Pledged items cleared for handover.',
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
  return 'Recorded on collection date';
}

String _monthsLabel(int? months) {
  final value = months ?? 0;
  if (value <= 0) return '-';
  return '$value month${value == 1 ? '' : 's'}';
}

String _ratePercentLabel(double value) {
  if (value % 1 == 0) return '${value.toStringAsFixed(0)}%';
  final text = value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  return '$text%';
}

String _interestMonthLabel(GirviInvoiceLedgerEntry entry) {
  final months = entry.monthsCovered ?? 0;
  if (months > 0) return _monthsLabel(months);
  return GirviInvoicePdfService._monthFormat.format(entry.date);
}

String _interestCollectionMonthSummary(
  List<GirviInvoiceLedgerEntry> entries,
) {
  if (entries.isEmpty) return '-';
  final months = entries
      .map((entry) => GirviInvoicePdfService._monthFormat.format(entry.date))
      .toSet()
      .toList(growable: false);
  if (months.length == 1) return months.single;
  return '${months.first} +${months.length - 1}';
}

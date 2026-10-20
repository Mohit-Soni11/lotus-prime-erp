part of 'girvi_invoice_pdf_service.dart';

pw.Widget _girviInterestSummary(
  GirviInvoiceDraft draft,
  GirviReceiptFinancialSummary summary,
  GirviInterestQuote quote,
  PrintTemplatePdfProfile profile,
) {
  if (draft.isReleaseReceipt) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _girviSummaryCard(
            'Principal Received',
            GirviInvoicePdfService._formatAmount(summary.principalReceived),
            profile,
            valueColor: _receiptGreen,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _girviSummaryCard(
            'Interest Received',
            GirviInvoicePdfService._formatAmount(summary.interestReceived),
            profile,
            valueColor: _receiptGreen,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _girviSummaryCard(
            'Total Received',
            GirviInvoicePdfService._formatAmount(summary.totalReceived),
            profile,
            valueColor: _receiptGreen,
          ),
        ),
      ],
    );
  }
  final interestOutstanding = draft.interestOutstanding ?? 0;
  final principalOutstanding = draft.principalOutstanding ?? draft.loanAmount;
  final cards = <pw.Widget>[
    pw.Expanded(
      child: _girviSummaryCard(
        'Interest Received',
        GirviInvoicePdfService._formatAmount(summary.interestReceived),
        profile,
        valueColor: _receiptGreen,
      ),
    ),
    pw.SizedBox(width: 10),
    pw.Expanded(
      child: _girviSummaryCard(
        'Monthly ${quote.lastChargedMonthlyInterestType} Interest',
        GirviInvoicePdfService._formatAmount(quote.lastChargedMonthlyInterest),
        profile,
      ),
    ),
    pw.SizedBox(width: 10),
    pw.Expanded(
      child: _girviSummaryCard(
        'Interest Outstanding',
        GirviInvoicePdfService._formatAmount(interestOutstanding),
        profile,
        valueColor: _receiptRed,
      ),
    ),
  ];
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(children: cards),
      pw.SizedBox(height: 8),
      pw.Row(
        children: [
          pw.Expanded(
            child: _girviSummaryCard(
              'Principal Outstanding',
              GirviInvoicePdfService._formatAmount(principalOutstanding),
              profile,
              valueColor: _receiptRed,
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: _girviSummaryCard(
              'Total Outstanding',
              GirviInvoicePdfService._formatAmount(
                principalOutstanding + interestOutstanding,
              ),
              profile,
              valueColor: _receiptRed,
            ),
          ),
        ],
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
  final rows = entries.map((entry) {
    final amount = GirviReceiptFinancialSummary.interestFromEntry(entry);
    return [
      GirviInvoicePdfService._dateFormat.format(entry.date),
      entry.modeLabel,
      GirviInvoicePdfService._formatAmount(amount),
    ];
  }).toList(growable: false);
  final headers = <String>[
    'Date',
    'Mode',
    'Interest Received',
  ];
  final columnWidths = <int, pw.TableColumnWidth>{
    0: const pw.FixedColumnWidth(72),
    1: const pw.FixedColumnWidth(64),
    2: const pw.FlexColumnWidth(1.7),
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

pw.Widget _girviCompoundInterestCalculation(
  GirviInvoiceDraft draft,
  GirviInterestQuote quote,
  PrintTemplatePdfProfile profile,
) {
  final lines = quote.cycles;
  if (lines.isEmpty) return pw.SizedBox.shrink();

  final rows = lines.map((line) {
    final period = GirviInterestPeriodText.forBreakdownLine(
      loanStartDate: draft.startDate,
      line: line,
    );
    final totalWithInterest = GirviInvoicePdfService._formatAmount(
      line.grossClosingAmount,
    );

    return <String>[
      '${period.cycleLabel}\n${period.monthRangeLabel}',
      GirviInvoicePdfService._formatAmount(line.principalBase),
      '${_ratePercentLabel(line.monthlyRatePercent)} monthly',
      GirviInvoicePdfService._formatAmount(line.monthlyInterest),
      period.monthsLabel,
      GirviInvoicePdfService._formatAmount(line.interestAmount),
      totalWithInterest,
    ];
  }).toList();

  return _girviSection(
    title: 'COMPOUND INTEREST CALCULATION',
    profile: profile,
    child: pw.TableHelper.fromTextArray(
      context: null,
      headers: const [
        'Period',
        'Opening Amount',
        'Monthly Rate',
        'Interest / Month',
        'Months',
        'Period Interest',
        'Closing Amount',
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
        0: pw.FlexColumnWidth(1.45),
        1: pw.FlexColumnWidth(1.1),
        2: pw.FlexColumnWidth(0.9),
        3: pw.FlexColumnWidth(1.05),
        4: pw.FlexColumnWidth(0.95),
        5: pw.FlexColumnWidth(1.0),
        6: pw.FlexColumnWidth(1.25),
      },
    ),
  );
}

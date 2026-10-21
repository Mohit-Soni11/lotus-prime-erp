part of '../girvi_notice_pdf_service.dart';

extension _NoticeStatementFinance on _NoticeStatementLayout {
  pw.Widget _interestCard() {
    final periods = statement.periods;
    final rows = <pw.TableRow>[];
    final asOf = statement.financialAsOf ??
        NoticePeriodDisplay.parseNoticeDate(statement.noticeDate);
    var priorMonths = 0;
    for (var index = 0; index < periods.length; index++) {
      final period = periods[index];
      final months = int.tryParse(
        period.value('Chargeable Months', 'चार्जेबल माह', language) ?? '',
      );
      final display = NoticePeriodDisplay.fromRecord(
        period: period.value('Period', 'अवधि', language),
        months: months,
        priorMonths: priorMonths,
        cycleNumber: index + 1,
        compound: statement.isCompound,
        asOf: asOf,
      );
      if (months != null && months > 0) priorMonths += months;
      rows.add(pw.TableRow(children: [
        _periodCell(display),
        _interestCell(
            period.value('Opening Amount', 'ओपनिंग राशि', language) ?? '—'),
        _interestCell(
            period.value('Monthly Interest Rate', 'मासिक ब्याज दर', language) ??
                '—'),
        _interestCell(
            period.value('Interest for Period', 'इस अवधि का ब्याज', language) ??
                '—'),
        _interestCell(
            period.value('Closing Amount', 'क्लोजिंग राशि', language) ??
                period.value('Closing / Outstanding Amount',
                    'क्लोजिंग / बकाया राशि', language) ??
                '—'),
      ]));
    }
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _noticeBorder, width: 0.8),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: _noticePaleGold,
              border: pw.Border.all(color: _noticeGold, width: 0.65),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              statement.isCompound
                  ? 'Compound Interest Breakdown'
                  : statement.isSimple
                      ? 'Simple Interest Breakdown'
                      : 'Approved Interest Details',
              style: _style(10, bold: true),
            ),
          ),
          if (rows.isNotEmpty)
            pw.Table(
              border: pw.TableBorder.all(color: _noticeBorder, width: 0.55),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.9),
                1: pw.FlexColumnWidth(1.35),
                2: pw.FlexColumnWidth(1.15),
                3: pw.FlexColumnWidth(1.25),
                4: pw.FlexColumnWidth(1.4),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _noticeBlueTint),
                  children: [
                    for (final label in [
                      'Period',
                      'Opening Balance (₹)',
                      'Rate (p.m.)',
                      'Interest (₹)',
                      'Closing Balance (₹)',
                    ])
                      _interestCell(label, header: true),
                  ],
                ),
                ...rows,
              ],
            )
          else
            pw.Padding(
              padding: const pw.EdgeInsets.all(7),
              child: pw.Text(
                  'See the approved notice details on the next page.',
                  style: _style(9, bold: true)),
            ),
          pw.SizedBox(height: 5),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _interestDetailBox(
                  statement.isCompound
                      ? 'Compound Interest Period'
                      : statement.isSimple
                          ? 'Simple Interest Period'
                          : 'Interest Period',
                  [
                    _interestDetailRow('From', statement.interestPeriodFrom),
                    _interestDetailRow('To', statement.interestPeriodTo),
                    _interestDetailRow(
                        'Total Months', statement.chargeablePeriod),
                    if (statement.isCompound)
                      _interestDetailRow(
                          'Compounding', statement.compoundingCycle),
                  ],
                ),
              ),
              pw.SizedBox(width: 7),
              pw.Expanded(
                child: _interestDetailBox('Interest Calculation Summary', [
                  _interestDetailRow(
                      'Principal Amount', statement.originalPrincipal),
                  _interestDetailRow('Monthly Rate', statement.monthlyRate),
                  _interestDetailRow('Gross Interest', statement.grossInterest),
                  if (statement.hasInterestPayment)
                    _interestDetailRow(
                        'Interest Paid', statement.interestPaidTotal),
                  if (statement.hasInterestAdjustment)
                    _interestDetailRow(
                        'Interest Adjusted', statement.interestAdjustmentTotal),
                  _interestDetailRow(
                      'Interest Outstanding', statement.interestOutstanding,
                      outstanding: true),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _periodCell(NoticePeriodDisplay display) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        child: pw.Column(
          children: [
            pw.Text(display.monthLabel,
                textAlign: pw.TextAlign.center, style: _style(8.5, bold: true)),
            if (display.dateRange != null) ...[
              pw.Text(display.dateRange!,
                  textAlign: pw.TextAlign.center,
                  style: _style(8.1, bold: true)),
            ],
            if (display.chargeableLabel != null) ...[
              pw.Text(display.chargeableLabel!,
                  textAlign: pw.TextAlign.center,
                  style: _style(8.1, bold: true)),
            ],
          ],
        ),
      );

  pw.Widget _interestCell(String value, {bool header = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: pw.Text(printText(value),
            textAlign: pw.TextAlign.center,
            style: _style(header ? 8.1 : 8.6, bold: true)),
      );

  pw.Widget _interestDetailBox(String title, List<pw.Widget> rows) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(5),
        decoration: pw.BoxDecoration(
          color: _noticeBlueTint,
          border: pw.Border.all(color: _noticeBorder, width: 0.7),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: _style(9.5, bold: true)),
            pw.SizedBox(height: 3),
            ...rows,
          ],
        ),
      );

  pw.Widget _interestDetailRow(String label, String? value,
          {bool outstanding = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
                width: 105,
                child: pw.Text(label, style: _style(8.4, bold: true))),
            pw.Text(':', style: _style(8.4, bold: true)),
            pw.SizedBox(width: 4),
            pw.Expanded(
              child: pw.Text(printText(value ?? 'Not recorded'),
                  style: _style(8.6,
                      bold: true,
                      color: outstanding ? _noticeOutstanding : _noticeInk)),
            ),
          ],
        ),
      );

  pw.Widget _outstandingCard() => _card(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (statement.originalPrincipal != null)
              _summaryLine('Principal Amount', statement.originalPrincipal!),
            if (statement.grossInterest != null)
              _summaryLine('Total Interest', statement.grossInterest!),
            _summaryDivider(),
            if (statement.totalAccountCharges != null)
              _summaryLine('Total Amount', statement.totalAccountCharges!,
                  highlighted: true),
            if (statement.hasPayments && statement.totalReceived != null)
              _summaryLine('Less: Payments Received', statement.totalReceived!,
                  color: _noticeReceived, subtract: true),
            if (statement.hasAdjustments && statement.totalAdjustments != null)
              _summaryLine(
                  'Less: Approved Discount', statement.totalAdjustments!,
                  color: _noticeReceived, subtract: true),
            _summaryDivider(),
            pw.SizedBox(height: 2),
            pw.Container(
              width: double.infinity,
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 11, vertical: 3),
              color: _noticeDeepNavy,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Final Outstanding',
                      style: _style(10, bold: true, color: PdfColors.white)),
                  pw.Text(printText(statement.totalPayable ?? '-'),
                      style: _style(15, bold: true, color: _noticeGold)),
                ],
              ),
            ),
          ],
        ),
        padding: 3,
      );

  pw.Widget _summaryLine(String label, String value,
          {PdfColor color = _noticeInk,
          bool highlighted = false,
          bool subtract = false}) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 1.5),
        color: highlighted ? _noticePaleGold : PdfColors.white,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(label,
                  style: _style(highlighted ? 9.7 : 9.2, bold: true)),
            ),
            pw.Text('${subtract ? '- ' : ''}${printText(value)}',
                style:
                    _style(highlighted ? 11 : 10.3, bold: true, color: color)),
          ],
        ),
      );

  pw.Widget _summaryDivider() =>
      pw.Container(height: 0.65, color: _noticeBorder);

  pw.Widget _actionCard() {
    final isFinalNotice =
        statement.lines.firstOrNull?.startsWith('FINAL NOTICE:') == true;
    final settlementDate = deadline ??
        _settlementDateInApprovedText() ??
        (isFinalNotice && noticePeriodDays != null
            ? DateTime(
                savedAt.year, savedAt.month, savedAt.day + noticePeriodDays!)
            : null);
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: pw.BoxDecoration(
        color: _noticePaleGold,
        border: pw.Border.all(color: _noticeGold, width: 1),
        borderRadius: pw.BorderRadius.circular(9),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
            width: 31,
            height: 31,
            child: pw.SvgImage(
              svg:
                  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">'
                  '<path d="M13.2 3.8a3.2 3.2 0 0 1 5.6 0l12 21.4a3.2 3.2 0 0 1-2.8 4.8H4a3.2 3.2 0 0 1-2.8-4.8z" fill="#C99C38"/>'
                  '<path d="M16 10v9" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round"/>'
                  '<circle cx="16" cy="24" r="1.5" fill="#FFFFFF"/>'
                  '</svg>',
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Required Action', style: _style(10.5, bold: true)),
                pw.SizedBox(height: 3),
                pw.Text(
                  settlementDate != null
                      ? 'Kindly visit the shop or contact us by the date shown to settle the outstanding amount. You may collect your pledged item after full payment.'
                      : 'Kindly visit the shop or contact us to settle the outstanding amount. You may collect your pledged item after full payment.',
                  style: _style(8.8),
                ),
              ],
            ),
          ),
          if (settlementDate != null || noticePeriodDays != null) ...[
            pw.SizedBox(width: 10),
            pw.Container(width: 0.8, height: 38, color: _noticeGold),
            pw.SizedBox(width: 10),
            pw.SizedBox(
              width: 18,
              height: 18,
              child: pw.SvgImage(
                svg:
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">'
                    '<rect x="2" y="4" width="16" height="14" rx="1.5" fill="none" stroke="#063562" stroke-width="1.8"/>'
                    '<path d="M2 8h16M6 2v4M14 2v4" fill="none" stroke="#063562" stroke-width="1.8" stroke-linecap="round"/>'
                    '<path d="M6 11h2M11 11h2M6 14h2M11 14h2" stroke="#063562" stroke-width="1.5" stroke-linecap="round"/>'
                    '</svg>',
              ),
            ),
            pw.SizedBox(width: 7),
            pw.SizedBox(
              width: 107,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    settlementDate == null
                        ? 'Time to Respond'
                        : 'Last Date to Settle',
                    style: _style(8.2, bold: true),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    settlementDate == null
                        ? 'Within $noticePeriodDays days of delivery'
                        : DateFormat('dd MMM yyyy').format(settlementDate),
                    style: _style(10.2, bold: true),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  DateTime? _settlementDateInApprovedText() {
    final pattern =
        RegExp(r'on or before (\d{1,2} [A-Za-z]+ \d{4})', caseSensitive: false);
    for (final line in statement.importantLines) {
      final match = pattern.firstMatch(line);
      if (match == null) continue;
      for (final format in ['d MMMM yyyy', 'd MMM yyyy']) {
        final date = DateFormat(format).tryParseStrict(match.group(1)!);
        if (date != null) return date;
      }
    }
    return null;
  }
}

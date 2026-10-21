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
              _summaryLine(
                'Total Amount (Principal + Interest)',
                statement.totalAccountCharges!,
                highlighted: true,
              ),
            if (statement.hasPayments && statement.totalReceived != null)
              _summaryLine(
                'Less: Total Received',
                statement.totalReceived!,
                color: _noticeReceived,
                subtract: true,
              ),
            if (statement.hasAdjustments && statement.totalAdjustments != null)
              _summaryLine(
                'Less: Approved Discount',
                statement.totalAdjustments!,
                color: _noticeReceived,
                subtract: true,
              ),
            _summaryDivider(),
            if (statement.principalOutstanding != null)
              _summaryLine(
                'Principal Outstanding',
                statement.principalOutstanding!,
                color: _noticeOutstanding,
              ),
            if (statement.interestOutstanding != null)
              _summaryLine(
                'Interest Outstanding',
                statement.interestOutstanding!,
                color: _noticeOutstanding,
              ),
            pw.SizedBox(height: 2),
            pw.Container(
              width: double.infinity,
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 11, vertical: 3),
              color: _noticeDeepNavy,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(t('Final Outstanding', 'अंतिम बकाया राशि'),
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

  pw.Widget _summaryLine(
    String label,
    String value, {
    PdfColor color = _noticeInk,
    bool highlighted = false,
    bool subtract = false,
  }) =>
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

  pw.Widget _actionCard() => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: pw.BoxDecoration(
          color: _noticePaleGold,
          border: pw.Border.all(color: _noticeGold, width: 0.8),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(t('Required Action', 'आवश्यक कार्रवाई'),
                      style: _style(9.5, bold: true)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    t('Please review the approved notice and contact the shop to settle or reconcile this account.',
                        'कृपया स्वीकृत सूचना देखें और भुगतान या खाते के मिलान के लिए दुकान से संपर्क करें।'),
                    style: _style(8),
                  ),
                ],
              ),
            ),
            if (deadline != null || noticePeriodDays != null) ...[
              pw.SizedBox(width: 11),
              pw.Container(width: 0.7, height: 28, color: _noticeGold),
              pw.SizedBox(width: 11),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                      noticePeriodDays != null
                          ? t('Time to Respond', 'उत्तर देने का समय')
                          : t('Last Date to Settle', 'भुगतान की अंतिम तारीख'),
                      style: _style(7.5, bold: true)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                      noticePeriodDays != null
                          ? 'Within $noticePeriodDays days of delivery'
                          : DateFormat('dd MMM yyyy').format(deadline!),
                      style: _style(9, bold: true)),
                ],
              ),
            ],
          ],
        ),
      );
}

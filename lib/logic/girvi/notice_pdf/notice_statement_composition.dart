part of '../girvi_notice_pdf_service.dart';

extension _NoticeStatementComposition on _NoticeStatementLayout {
  bool get _isFinalNotice =>
      statement.lines.firstOrNull?.startsWith('FINAL NOTICE:') == true;

  List<pw.Widget> summaryPage() => [
        _title(),
        _identityCard(),
        pw.SizedBox(height: 3),
        _section(1, t('Pledge Account Details', 'गिरवी खाता विवरण')),
        _accountCard(),
        pw.SizedBox(height: 3),
        _section(
          2,
          statement.hasInterestMethod
              ? 'Interest Calculation (${statement.isCompound ? 'Compound Interest' : 'Simple Interest'})'
              : 'Interest Calculation',
        ),
        _interestCard(),
        if (statement.periods.length >= 4) ...[
          pw.NewPage(),
          pw.Text('Interest Calculation (continued)',
              style: _style(13, bold: true)),
          pw.SizedBox(height: 5),
        ] else
          pw.SizedBox(height: 3),
        _interestDetailsCard(),
        pw.SizedBox(height: 3),
        pw.Inseparable(
          child: pw.Column(
            children: [
              _section(3, t('Account Summary', 'खाते का सारांश')),
              _outstandingCard(),
            ],
          ),
        ),
      ];

  List<pw.Widget> informationPage() {
    final draft = _noticeDraft();
    return [
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _actionCard(),
            pw.SizedBox(height: 8),
            _section(4, _isFinalNotice ? 'Final Notice' : 'Formal Notice'),
            pw.SizedBox(height: 8),
            if (statement.financialAsOf != null) ...[
              _verifiedFinancialNote(),
              pw.SizedBox(height: 4),
            ],
            pw.Text(branding.printShopName.toUpperCase(),
                style: _style(11, bold: true)),
            if (branding.printShopAddress.isNotEmpty)
              pw.Text(branding.printShopAddress, style: _style(9)),
            if (_headerPhones.isNotEmpty)
              pw.Text('Phone: ${_headerPhones.join('  |  ')}',
                  style: _style(9)),
            pw.SizedBox(height: 7),
            pw.Text(
                '${_isFinalNotice ? 'FINAL' : 'FORMAL'} NOTICE: PLEDGE ACCOUNT $ticketNo',
                style: _style(12, bold: true)),
            pw.SizedBox(height: 5),
            pw.Row(children: [
              pw.Expanded(
                child: pw.Text('Invoice No.: $ticketNo',
                    style: _style(9, bold: true)),
              ),
              pw.Text('Date: $dateText', style: _style(9, bold: true)),
            ]),
            pw.SizedBox(height: 6),
            if (draft.isNotEmpty) draft.first,
          ],
        ),
      ),
      ...draft.skip(1),
    ];
  }

  pw.Widget _verifiedFinancialNote() => pw.Text(
        'Financial figures recalculated from the verified pledge ledger '
        'as of ${DateFormat('dd MMMM yyyy').format(statement.financialAsOf!)}. '
        'The original approved notice remains in the audit record.',
        style: _style(8.7),
      );

  pw.Widget _title() => pw.Column(
        children: [
          pw.Center(
            child: pw.Text(t('GIRVI NOTICE', 'गिरवी सूचना'),
                style: _style(24, bold: true)),
          ),
          pw.Center(
            child: pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 17, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _noticeGold,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Text(_isFinalNotice ? 'FINAL NOTICE' : 'FORMAL NOTICE',
                  style: _style(10, bold: true)),
            ),
          ),
          pw.SizedBox(height: 5),
        ],
      );

  pw.Widget _identityCard() => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: _noticeGold, width: 1),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            _noticeDocumentIcon(),
            pw.SizedBox(width: 11),
            pw.Expanded(
              flex: 10,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _identityFact('Invoice No.', ticketNo),
                  _identityFact('Notice Date', dateText),
                ],
              ),
            ),
            pw.SizedBox(width: 9),
            pw.Container(width: 1, height: 44, color: _noticeGold),
            pw.SizedBox(width: 12),
            pw.Expanded(
              flex: 13,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Subject',
                      style: _style(10.3, bold: true, color: _noticeDarkGold)),
                  pw.SizedBox(height: 4),
                  pw.Text(statement.subject ?? noticeType.subtitle,
                      style: _style(10.2, bold: true, color: _noticeBlack)),
                ],
              ),
            ),
          ],
        ),
      );

  pw.Widget _identityFact(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2.3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 90,
              child: pw.Text(label,
                  style: _style(9.8, bold: true, color: _noticeBlack)),
            ),
            pw.Text(':',
                style: _style(9.8, bold: true, color: _noticeDarkGold)),
            pw.SizedBox(width: 5),
            pw.Expanded(
              child: pw.Text(printText(value),
                  style: _style(10.1, bold: true, color: _noticeBlack)),
            ),
          ],
        ),
      );

  pw.Widget _noticeDocumentIcon() => pw.Container(
        width: 38,
        height: 44,
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          color: _noticeDeepNavy,
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.SvgImage(
          svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 28 32">'
              '<path d="M5 2h12l6 6v22H5z" fill="none" stroke="#F1C96A" stroke-width="1.8"/>'
              '<path d="M17 2v6h6M9 13h10M9 18h10M9 23h8" fill="none" stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round"/>'
              '</svg>',
        ),
      );

  pw.Widget _section(int number, String title) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: pw.BoxDecoration(
          color: _noticeNavy,
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Row(
          children: [
            pw.Container(
              width: 21,
              height: 21,
              decoration: const pw.BoxDecoration(
                color: _noticeGold,
                shape: pw.BoxShape.circle,
              ),
              child: pw.Center(
                child: pw.Text('$number', style: _style(10, bold: true)),
              ),
            ),
            pw.SizedBox(width: 9),
            pw.Text(title,
                style: _style(11, bold: true, color: PdfColors.white)),
          ],
        ),
      );

  pw.Widget _accountCard() => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(3),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: _noticeBorder, width: 0.8),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  color: _noticeBlueTint,
                  border: pw.Border.all(color: _noticeBorder, width: 0.7),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (itemPhoto != null) ...[
                      pw.Container(
                        width: 67,
                        height: 73,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: _noticeBorder),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.ClipRRect(
                          horizontalRadius: 4,
                          verticalRadius: 4,
                          child: pw.Image(
                            itemPhoto!,
                            width: 67,
                            height: 73,
                            fit: pw.BoxFit.cover,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                    ],
                    pw.Expanded(
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          if (statement.itemName != null)
                            _accountFact('Item Name', statement.itemName!),
                          if (statement.purity != null)
                            _accountFact('Purity', statement.purity!),
                          if (statement.netWeight != null)
                            _accountFact('Net Weight', statement.netWeight!),
                          if (statement.originalPrincipal != null)
                            _accountFact('Original Principal',
                                statement.originalPrincipal!),
                          if (statement.pledgeDate != null)
                            _accountFact('Pledge Date', statement.pledgeDate!),
                          if (statement.maturityDate != null)
                            _accountFact(
                                'Maturity Date', statement.maturityDate!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 6),
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  color: _noticeBlueTint,
                  border: pw.Border.all(color: _noticeBorder, width: 0.7),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('Duration Details', style: _style(10, bold: true)),
                    pw.SizedBox(height: 3),
                    pw.Table(
                      border:
                          pw.TableBorder.all(color: _noticeBorder, width: 0.7),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(1.6),
                        1: pw.FlexColumnWidth(1),
                      },
                      children: [
                        _durationRow(
                          'Agreed Loan Term',
                          statement.originalLoanPeriodLabel(
                              originalLoanDurationMonths),
                        ),
                        _durationRow('Current Period',
                            statement.elapsedLoanPeriod ?? 'Not recorded'),
                        _durationRow('Chargeable Months',
                            statement.chargeablePeriod ?? 'Not recorded'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  pw.Widget _accountFact(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 0.7),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
                width: 110,
                child: pw.Text(label, style: _style(9, bold: true))),
            pw.Text(':', style: _style(9, bold: true)),
            pw.SizedBox(width: 5),
            pw.Expanded(
                child:
                    pw.Text(printText(value), style: _style(9.2, bold: true))),
          ],
        ),
      );

  pw.TableRow _durationRow(String label, String value) => pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: pw.Text(label, style: _style(8.7, bold: true)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: pw.Text(value, style: _style(9.2, bold: true)),
          ),
        ],
      );
}

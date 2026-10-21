part of '../girvi_notice_pdf_service.dart';

extension _NoticeStatementComposition on _NoticeStatementLayout {
  bool get _actionOnInformationPage => (statement.hasPayments ||
      statement.hasAdjustments ||
      (statement.isCompound && statement.periods.length >= 4));

  bool get _hasApprovedActionSection => statement.importantLines
      .contains(t('Required Action', 'आवश्यक कार्रवाई'));

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
        pw.SizedBox(height: 3),
        pw.Inseparable(
          child: pw.Column(
            children: [
              _section(3, t('Final Outstanding Summary', 'अंतिम बकाया सारांश')),
              _outstandingCard(),
            ],
          ),
        ),
        if (!_actionOnInformationPage && !_hasApprovedActionSection) ...[
          pw.SizedBox(height: 3),
          _actionCard(),
        ],
      ];

  List<pw.Widget> informationPage() => [
        if (_actionOnInformationPage && !_hasApprovedActionSection) ...[
          _actionCard(),
          pw.SizedBox(height: 4),
        ],
        _section(4, t('Notice to Customer', 'ग्राहक के लिए सूचना')),
        pw.SizedBox(height: 8),
        if (statement.financialAsOf != null) ...[
          _verifiedFinancialNote(),
          pw.SizedBox(height: 4),
        ],
        ..._noticeDraft(),
        pw.SizedBox(height: 13),
        pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(height: 0.8, color: _noticeBorder),
              pw.SizedBox(height: 8),
              _contactDetails(),
              pw.SizedBox(height: 12),
              _signatureBlock(),
            ],
          ),
        ),
      ];

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
              child: pw.Text(noticeLabel.toUpperCase(),
                  style: _style(10, bold: true)),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Center(
            child: pw.Text(
              statement.subject ?? noticeType.subtitle,
              textAlign: pw.TextAlign.center,
              style: _style(9),
            ),
          ),
          pw.SizedBox(height: 7),
        ],
      );

  pw.Widget _identityCard() => _card(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                children: [
                  _pair(t('Notice No.', 'सूचना नंबर'),
                      statement.noticeNumber ?? '$ticketNo-NOTICE'),
                  _pair(t('Notice Date', 'सूचना दिनांक'), dateText),
                  _pair(t('Pledge Reference', 'गिरवी संदर्भ'),
                      statement.pledgeReference ?? ticketNo),
                ],
              ),
            ),
            pw.Container(width: 0.7, height: 36, color: _noticeBorder),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(t('Subject', 'विषय'), style: _style(8.5, bold: true)),
                  pw.SizedBox(height: 4),
                  pw.Text(statement.subject ?? noticeType.subtitle,
                      style: _style(8.5)),
                ],
              ),
            ),
          ],
        ),
      );

  pw.Widget _section(int number, String title) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
        padding: const pw.EdgeInsets.all(5),
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
                          'Original Loan Period',
                          statement.originalLoanPeriodLabel(
                              originalLoanDurationMonths),
                        ),
                        _durationRow('Current Loan Period',
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
                width: 92, child: pw.Text(label, style: _style(9, bold: true))),
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

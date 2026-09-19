part of 'girvi_invoice_pdf_service.dart';

extension _GirviInvoicePdfRenderSections on GirviInvoicePdfService {
  pw.Widget _buildHeroHeader(
    GirviInvoiceDraft draft,
    bool compact,
    String copyLabel,
    GirviBillingModel settings,
    GirviInvoiceBranding branding,
    pw.MemoryImage? brandLogo,
  ) {
    final issueDateMatchesStartDate = GirviInvoicePdfService.sameCalendarDate(
      draft.createdAt,
      draft.startDate,
    );
    final metadata = <({String label, String value})>[
      (label: 'INVOICE NUMBER', value: draft.ticketNo),
      if (settings.showStartDate)
        (
          label: 'START DATE',
          value: GirviInvoicePdfService._dateFormat.format(draft.startDate)
        ),
      if (settings.showMaturityDate || settings.showDuration)
        (
          label: settings.showMaturityDate ? 'MATURITY / DUE' : 'LOAN TENURE',
          value: settings.showMaturityDate
              ? '${GirviInvoicePdfService._dateFormat.format(draft.maturityDate)}'
                  '${settings.showDuration ? ' | ${draft.durationMonths} months' : ''}'
              : '${draft.durationMonths} months',
        ),
      if (draft.isReleaseReceipt && draft.deliveredAt != null)
        (
          label: 'DELIVERED AT',
          value: GirviInvoicePdfService._dateFormat.format(draft.deliveredAt!)
        ),
    ];
    if (!settings.showStartDate && issueDateMatchesStartDate) {
      metadata.removeWhere((entry) => entry.label == 'START DATE');
    }

    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: GirviInvoicePdfService._navy,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Padding(
            padding: pw.EdgeInsets.fromLTRB(
              compact ? 12 : 16,
              compact ? 11 : 15,
              compact ? 12 : 16,
              compact ? 9 : 12,
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                _buildBrandMark(
                  branding,
                  brandLogo,
                  compact,
                ),
                pw.SizedBox(width: compact ? 10 : 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        branding.printShopName.toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: compact ? 14 : 19,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      for (final line
                          in GirviInvoicePdfService._girviHeaderLines(branding)
                              .take(compact ? 2 : 4))
                        if (line.trim().isNotEmpty) ...[
                          pw.SizedBox(height: compact ? 2 : 3),
                          pw.Text(
                            line.trim(),
                            maxLines: 1,
                            overflow: pw.TextOverflow.clip,
                            style: pw.TextStyle(
                              color: GirviInvoicePdfService._gold,
                              fontSize: compact ? 6.2 : 7.2,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 0.25,
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
                pw.SizedBox(width: compact ? 8 : 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: pw.EdgeInsets.symmetric(
                        horizontal: compact ? 8 : 11,
                        vertical: compact ? 5 : 7,
                      ),
                      decoration: const pw.BoxDecoration(
                        color: GirviInvoicePdfService._goldLight,
                        borderRadius:
                            pw.BorderRadius.all(pw.Radius.circular(5)),
                      ),
                      child: pw.Text(
                        'GIRVI INVOICE',
                        style: pw.TextStyle(
                          color: GirviInvoicePdfService._navy,
                          fontSize: compact ? 7 : 8.5,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: compact ? 4 : 5),
                    pw.Text(
                      copyLabel,
                      style: pw.TextStyle(
                        color: GirviInvoicePdfService._gold,
                        fontSize: compact ? 5.5 : 6.5,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.Container(
            height: 1.4,
            color: GirviInvoicePdfService._gold,
          ),
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 7 : 9,
            ),
            child: pw.Row(
              children: [
                for (var index = 0; index < metadata.length; index++) ...[
                  if (index > 0) _buildHeaderDivider(compact),
                  pw.Expanded(
                    child: _buildHeaderMeta(
                      label: metadata[index].label,
                      value: metadata[index].value,
                      compact: compact,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBrandMark(
    GirviInvoiceBranding branding,
    pw.MemoryImage? brandLogo,
    bool compact,
  ) {
    final size = compact ? 40.0 : 52.0;
    final content = brandLogo == null
        ? pw.Container(
            alignment: pw.Alignment.center,
            color: GirviInvoicePdfService._gold,
            child: pw.Text(
              branding.initial,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: compact ? 17 : 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          )
        : pw.Container(
            color: PdfColors.white,
            child: pw.Image(
              brandLogo,
              fit: pw.BoxFit.cover,
            ),
          );
    final clipped = branding.logoShape == 'square'
        ? pw.ClipRRect(
            horizontalRadius: compact ? 5 : 7,
            verticalRadius: compact ? 5 : 7,
            child: content,
          )
        : pw.ClipOval(child: content);

    return pw.Container(
      width: size,
      height: size,
      padding: pw.EdgeInsets.all(compact ? 1.5 : 2),
      decoration: pw.BoxDecoration(
        color: GirviInvoicePdfService._gold,
        shape: branding.logoShape == 'square'
            ? pw.BoxShape.rectangle
            : pw.BoxShape.circle,
        borderRadius: branding.logoShape == 'square'
            ? const pw.BorderRadius.all(pw.Radius.circular(8))
            : null,
      ),
      child: clipped,
    );
  }

  pw.Widget _buildHeaderDivider(bool compact) {
    return pw.Container(
      width: 0.7,
      height: compact ? 22 : 27,
      margin: pw.EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
      ),
      color: GirviInvoicePdfService._gold,
    );
  }

  pw.Widget _buildHeaderMeta({
    required String label,
    required String value,
    required bool compact,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: compact ? 6.5 : 7.5,
            letterSpacing: 0.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: compact ? 8.5 : 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCustomerAndLoanPanel(
    GirviInvoiceDraft draft,
    bool compact,
    GirviBillingModel settings,
  ) {
    final panelHeight = compact ? 90.0 : 112.0;
    final showLoanPanel = settings.showLoanAmount ||
        settings.showInterestRate ||
        settings.showMonthlyInterest;
    final customerMeta = <pw.Widget>[
      if (settings.showCustomerMobile)
        pw.Expanded(
          flex: 4,
          child: _buildCustomerMeta(
            label: 'MOBILE',
            value: draft.customerMobile.trim().isEmpty
                ? '--'
                : draft.customerMobile.trim(),
            compact: compact,
          ),
        ),
      if (settings.showCustomerMobile && settings.showCustomerCity)
        pw.SizedBox(width: compact ? 8 : 12),
      if (settings.showCustomerCity)
        pw.Expanded(
          flex: 6,
          child: _buildCustomerMeta(
            label: 'ADDRESS',
            value: draft.displayCustomerAddress,
            compact: compact,
            maxLines: 2,
            fontSize: compact ? 7.2 : 8.5,
          ),
        ),
    ];
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: showLoanPanel ? 5 : 1,
          child: pw.Container(
            height: panelHeight,
            padding: pw.EdgeInsets.all(compact ? 10 : 13),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: GirviInvoicePdfService._line),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildEyebrow('CUSTOMER DETAILS', compact),
                pw.SizedBox(height: compact ? 5 : 7),
                pw.Text(
                  draft.customerName,
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    color: GirviInvoicePdfService._ink,
                    fontSize: compact ? 11 : 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (customerMeta.isNotEmpty) ...[
                  pw.Spacer(),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: customerMeta,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showLoanPanel) ...[
          pw.SizedBox(width: compact ? 9 : 12),
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              height: panelHeight,
              padding: pw.EdgeInsets.all(compact ? 10 : 13),
              decoration: pw.BoxDecoration(
                color: GirviInvoicePdfService._goldLight,
                border: pw.Border.all(
                  color: GirviInvoicePdfService._gold,
                  width: 0.8,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildEyebrow(
                    settings.showLoanAmount
                        ? 'LOAN AMOUNT'
                        : settings.showMonthlyInterest
                            ? 'MONTHLY INTEREST'
                            : 'INTEREST RATE',
                    compact,
                    color: GirviInvoicePdfService._gold,
                  ),
                  pw.SizedBox(height: compact ? 4 : 6),
                  pw.Text(
                    settings.showLoanAmount
                        ? _amount(draft.loanAmount)
                        : settings.showMonthlyInterest
                            ? _amount(draft.monthlyInterest)
                            : '${draft.interestRate.toStringAsFixed(2)}% monthly',
                    style: pw.TextStyle(
                      color: GirviInvoicePdfService._navy,
                      fontSize: compact ? 14 : 19,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if ((settings.showLoanAmount &&
                          (settings.showInterestRate ||
                              settings.showMonthlyInterest)) ||
                      (!settings.showLoanAmount &&
                          settings.showInterestRate &&
                          settings.showMonthlyInterest)) ...[
                    pw.Spacer(),
                    pw.Container(
                      width: double.infinity,
                      padding: pw.EdgeInsets.symmetric(
                        horizontal: compact ? 7 : 9,
                        vertical: compact ? 5 : 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(4)),
                        border: pw.Border.all(
                          color: const PdfColor.fromInt(0xFFEAD6A0),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          pw.Row(
                            children: [
                              pw.Text(
                                'MONTHLY INTEREST',
                                style: pw.TextStyle(
                                  color: GirviInvoicePdfService._muted,
                                  fontSize: compact ? 5.5 : 6.5,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              pw.Spacer(),
                              if (settings.showInterestRate)
                                pw.Text(
                                  '${draft.interestRate.toStringAsFixed(2)}% monthly',
                                  style: pw.TextStyle(
                                    color: GirviInvoicePdfService._navy,
                                    fontSize: compact ? 7 : 8.2,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          if (settings.showMonthlyInterest) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Rs ${GirviInvoicePdfService._compactAmountFormat.format(draft.monthlyInterest)} per month',
                              maxLines: 1,
                              overflow: pw.TextOverflow.clip,
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                color: GirviInvoicePdfService._gold,
                                fontSize: compact ? 7 : 8.4,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildEyebrow(
    String value,
    bool compact, {
    PdfColor color = GirviInvoicePdfService._muted,
  }) {
    return pw.Text(
      value,
      style: pw.TextStyle(
        color: color,
        fontSize: compact ? 7 : 8.2,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.7,
      ),
    );
  }

  pw.Widget _buildCustomerMeta({
    required String label,
    required String value,
    required bool compact,
    int maxLines = 1,
    double? fontSize,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildEyebrow(label, compact),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          maxLines: maxLines,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(
            color: PdfColors.black,
            fontSize: fontSize ?? (compact ? 8.5 : 10.2),
            fontWeight: pw.FontWeight.bold,
            lineSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSectionHeading({
    required String number,
    required String title,
    required String subtitle,
    required bool compact,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: compact ? 24 : 29,
          height: compact ? 24 : 29,
          alignment: pw.Alignment.center,
          decoration: const pw.BoxDecoration(
            color: GirviInvoicePdfService._navy,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Text(
            number,
            style: pw.TextStyle(
              color: GirviInvoicePdfService._gold,
              fontSize: compact ? 7 : 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: compact ? 8 : 10),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                color: GirviInvoicePdfService._ink,
                fontSize: compact ? 9.5 : 11.5,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                color: GirviInvoicePdfService._muted,
                fontSize: compact ? 6.8 : 8,
              ),
            ),
          ],
        ),
        pw.SizedBox(width: compact ? 10 : 14),
        pw.Expanded(
          child: pw.Container(
            height: 0.7,
            color: GirviInvoicePdfService._line,
          ),
        ),
      ],
    );
  }

  GirviInvoiceFieldSettings _combinedItemSettings(
    List<GirviInvoiceItemDraft> items,
    GirviBillingModel settings,
  ) {
    final metals =
        items.map((item) => GirviBillingMetal.normalize(item.metal)).toSet();
    if (metals.isEmpty) return const GirviInvoiceFieldSettings();

    final metalSettings = [
      for (final metal in metals) settings.settingsForMetal(metal),
    ];
    bool enabled(bool Function(GirviInvoiceFieldSettings value) read) =>
        metalSettings.any(read);

    return GirviInvoiceFieldSettings(
      showSerialNumber: enabled((value) => value.showSerialNumber),
      showMetal: enabled((value) => value.showMetal),
      showItemName: enabled((value) => value.showItemName),
      showPieces: enabled((value) => value.showPieces),
      showHuid: enabled((value) => value.showHuid),
      showPurity: enabled((value) => value.showPurity),
      showGrossWeight: enabled((value) => value.showGrossWeight),
      showLessWeight: enabled((value) => value.showLessWeight),
      showNetWeight: enabled((value) => value.showNetWeight),
      showValuationPurity: enabled((value) => value.showValuationPurity),
      showFineWeight: enabled((value) => value.showFineWeight),
      showRatePerGram: enabled((value) => value.showRatePerGram),
      showValuationAmount: enabled((value) => value.showValuationAmount),
      showItemPhotos: enabled((value) => value.showItemPhotos),
    );
  }
}

part of '../girvi_notice_pdf_service.dart';

extension _NoticeStatementInformation on _NoticeStatementLayout {
  List<pw.Widget> _informationCards() {
    final responseHeading = t('Previous Contact and Customer Response',
        'पूर्व संपर्क और ग्राहक प्रतिक्रिया');
    final paymentHeading = t('Payments and Adjustments', 'भुगतान और समायोजन');
    final actionHeading = t('Required Action', 'आवश्यक कार्रवाई');
    final headings = {responseHeading, paymentHeading, actionHeading};
    final groups = <(String, List<String>)>[];
    var title = t('Account Notice', 'खाता सूचना');
    var content = <String>[];
    for (final line in statement.importantLines) {
      if (headings.contains(line)) {
        if (content.isNotEmpty) groups.add((title, content));
        title = line;
        content = <String>[];
      } else if (line.isNotEmpty &&
          line != t('Authorised Signatory', 'अधिकृत हस्ताक्षर')) {
        content.add(line);
      }
    }
    if (content.isNotEmpty) groups.add((title, content));
    return [
      for (final (heading, lines) in groups)
        for (var start = 0; start < lines.length; start += 10) ...[
          _informationCard(
            start == 0 ? heading : '$heading (continued)',
            lines.skip(start).take(10).toList(growable: false),
          ),
          pw.SizedBox(height: 5),
        ],
    ];
  }

  pw.Widget _informationCard(String title, List<String> lines) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: _noticeBlueTint,
          border: pw.Border.all(color: _noticeBorder, width: 0.8),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 7,
              height: 24,
              decoration: pw.BoxDecoration(
                color: _noticeGold,
                borderRadius: pw.BorderRadius.circular(3),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(title, style: _style(10, bold: true)),
                  pw.SizedBox(height: 3),
                  for (final line in lines)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(printText(line), style: _style(8.5)),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  pw.Widget _contactCard() => _card(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(t('Contact Details', 'संपर्क विवरण'),
                style: _style(10, bold: true)),
            pw.SizedBox(height: 5),
            pw.Text(branding.printShopName, style: _style(8.5, bold: true)),
            if (branding.shopMobile.trim().isNotEmpty)
              pw.Text(branding.shopMobile.trim(), style: _style(8.5)),
            if (branding.shopAlternateMobile.trim().isNotEmpty)
              pw.Text(branding.shopAlternateMobile.trim(), style: _style(8.5)),
            if (branding.printShopAddress.isNotEmpty)
              pw.Text(branding.printShopAddress, style: _style(8.5)),
          ],
        ),
      );

  pw.Widget _signatureBlock() => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('${t('For', 'की ओर से')} ${branding.printShopName}',
              style: _style(9, bold: true)),
          pw.SizedBox(height: 5),
          if (signature != null)
            pw.Image(signature!, width: 110, height: 42, fit: pw.BoxFit.contain)
          else
            pw.SizedBox(height: 32),
          pw.Container(width: 150, height: 0.7, color: _noticeInk),
          pw.SizedBox(height: 4),
          pw.Text(t('Authorised Signatory', 'अधिकृत हस्ताक्षर'),
              style: _style(8.5, bold: true)),
        ],
      );
}

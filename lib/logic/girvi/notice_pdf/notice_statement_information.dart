part of '../girvi_notice_pdf_service.dart';

extension _NoticeStatementInformation on _NoticeStatementLayout {
  List<pw.Widget> _noticeDraft() {
    final actionHeading = t('Required Action', 'आवश्यक कार्रवाई');
    final headings = {
      t('Previous Contact and Customer Response',
          'पूर्व संपर्क और ग्राहक प्रतिक्रिया'),
      t('Payments and Adjustments', 'भुगतान और समायोजन'),
      t('Payments Received', 'प्राप्त भुगतान'),
      actionHeading,
    };
    final sections = <(String?, List<String>)>[];
    String? heading;
    var lines = <String>[];
    for (final line in statement.importantLines) {
      if (headings.contains(line)) {
        if (lines.isNotEmpty) sections.add((heading, lines));
        heading = line;
        lines = <String>[];
      } else if (line.isNotEmpty &&
          line != t('Authorised Signatory', 'अधिकृत हस्ताक्षर')) {
        lines.add(line);
      }
    }
    if (lines.isNotEmpty) sections.add((heading, lines));

    final result = <pw.Widget>[];
    var subjectAdded = false;
    void addSubject() {
      if (subjectAdded) return;
      result.add(pw.SizedBox(height: 8));
      result.add(pw.RichText(
        text: pw.TextSpan(children: [
          pw.TextSpan(text: 'Subject: ', style: _style(10, bold: true)),
          pw.TextSpan(
              text: statement.subject ?? noticeType.subtitle,
              style: _style(10)),
        ]),
      ));
      subjectAdded = true;
    }

    for (final (title, content) in sections) {
      if (title == null) {
        final recipientCount = content
            .takeWhile((line) =>
                line.startsWith('To:') ||
                line.startsWith('Customer Address:') ||
                line.startsWith('Customer Mobile:'))
            .length;
        for (final line in content.take(recipientCount)) {
          result.add(_draftLine(line.startsWith('Customer Address:')
              ? line.substring('Customer Address:'.length).trim()
              : line.startsWith('Customer Mobile:')
                  ? 'Mobile: ${line.substring('Customer Mobile:'.length).trim()}'
                  : line));
        }
        addSubject();
        for (final line in content.skip(recipientCount)) {
          result.add(_draftLine(line));
        }
        continue;
      }
      if (title == t('Payments Received', 'प्राप्त भुगतान') ||
          title == t('Payments and Adjustments', 'भुगतान और समायोजन')) {
        continue;
      }
      addSubject();
      result.add(pw.SizedBox(height: 9));
      if (title == actionHeading && content.join().length <= 900) {
        result.add(pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final line in content) _draftLine(line),
              _noticeSignoff(),
            ],
          ),
        ));
      } else {
        result.add(pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (title != actionHeading) _draftHeading(title),
              if (content.isNotEmpty) _draftLine(content.first),
            ],
          ),
        ));
        for (final line in content.skip(1)) {
          result.add(_draftLine(line));
        }
        if (title == actionHeading) {
          result.add(pw.Inseparable(child: _noticeSignoff()));
        }
      }
    }
    if (!subjectAdded) addSubject();
    if (!sections.any((section) => section.$1 == actionHeading)) {
      result.add(pw.Inseparable(child: _noticeSignoff()));
    }
    return result;
  }

  pw.Widget _noticeSignoff() => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.SizedBox(height: 8),
          pw.Text(t('Yours faithfully,', 'सादर,'), style: _style(9.5)),
          pw.SizedBox(height: 3),
          _signatureBlock(),
        ],
      );

  pw.Widget _draftHeading(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: _style(10.5, bold: true)),
            pw.SizedBox(height: 3),
            pw.Container(width: 53, height: 1.5, color: _noticeGold),
          ],
        ),
      );

  pw.Widget _draftLine(String value) {
    final subheading = value.startsWith('Contact · ') ||
        value == t('Applicable Adjustments', 'लागू समायोजन') ||
        RegExp(r'^\d{1,2} [A-Za-z]+ \d{4}$').hasMatch(value);
    final salutation = value.startsWith('Dear ') || value.startsWith('प्रिय ');
    return pw.Padding(
      padding: pw.EdgeInsets.only(
        left: subheading ? 7 : 0,
        top: salutation ? 9 : (subheading ? 5 : 1.5),
        bottom: salutation ? 5 : 3,
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children:
              _draftSpans(printText(value), bold: subheading || salutation),
        ),
      ),
    );
  }

  List<pw.TextSpan> _draftSpans(String value, {bool bold = false}) {
    if (bold) return [pw.TextSpan(text: value, style: _style(10, bold: true))];
    final emphasis = RegExp(
      r'₹\s*[\d,]+(?:\.\d+)?|\b(?:GRV|PLD)-[A-Za-z0-9-]+\b|\b\d{1,2} [A-Za-z]+ \d{4}\b|\bwithin \d+ days?\b',
      caseSensitive: false,
    );
    final spans = <pw.TextSpan>[];
    var position = 0;
    final labelEnd = value.indexOf(':');
    if (labelEnd > 0 && labelEnd < 32) {
      spans.add(pw.TextSpan(
          text: value.substring(0, labelEnd + 1),
          style: _style(9.7, bold: true)));
      position = labelEnd + 1;
    }
    for (final match in emphasis.allMatches(value, position)) {
      if (match.start > position) {
        spans.add(pw.TextSpan(
            text: value.substring(position, match.start), style: _style(9.7)));
      }
      spans.add(pw.TextSpan(
          text: value.substring(match.start, match.end),
          style: _style(9.7, bold: true)));
      position = match.end;
    }
    if (position < value.length) {
      spans.add(
          pw.TextSpan(text: value.substring(position), style: _style(9.7)));
    }
    return spans;
  }

  pw.Widget _signatureBlock() => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('${t('For', 'की ओर से')} ${branding.printShopName}',
              style: _style(9, bold: true)),
          pw.SizedBox(height: 5),
          if (signature != null)
            pw.Image(signature!, width: 110, height: 30, fit: pw.BoxFit.contain)
          else
            pw.SizedBox(height: 16),
          pw.Container(width: 150, height: 0.7, color: _noticeInk),
          pw.SizedBox(height: 4),
          pw.Text(t('Authorised Signatory', 'अधिकृत हस्ताक्षर'),
              style: _style(8.5, bold: true)),
          pw.SizedBox(height: 3),
          pw.Text('Date & Stamp', style: _style(8.5)),
        ],
      );
}

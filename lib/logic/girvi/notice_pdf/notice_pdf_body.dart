part of '../girvi_notice_pdf_service.dart';

List<pw.Widget> _noticeBodyWidgets(
  String noticeText,
  GirviNoticeLanguage language,
  pw.Font? devanagariFont,
) {
  final serialLabel =
      language == GirviNoticeLanguage.hindi ? 'क्रमांक' : 'Serial Number';
  final paragraphs = noticeText
      .replaceAllMapped(
        RegExp(r'#\s*(\d+)'),
        (match) => '$serialLabel ${match.group(1)}',
      )
      .split('\n')
      .map((line) => line.trimRight())
      .toList(growable: false);
  return [
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _line, width: 0.6),
      ),
      child: pw.Text(
        _label('Notice Text', language),
        textDirection: pw.TextDirection.ltr,
        style: _textStyle(
          language,
          devanagariFont,
          color: _ink,
          fontSize: 11.2,
          bold: true,
        ),
      ),
    ),
    pw.SizedBox(height: 6),
    for (final paragraph in paragraphs)
      paragraph.trim().isEmpty
          ? pw.SizedBox(height: 4)
          : pw.Padding(
              padding: const pw.EdgeInsets.only(left: 6, right: 6, bottom: 3),
              child: pw.Text(
                paragraph,
                textDirection: pw.TextDirection.ltr,
                style: _textStyle(
                  language,
                  devanagariFont,
                  color: _ink,
                  fontSize: 10.8,
                  lineSpacing: 1.2,
                ),
              ),
            ),
  ];
}

String _noticeTextWithoutValuation(String noticeText) {
  const hiddenPrefixes = <String>[
    'Pledged Valuation:',
    'Pledged Value:',
    'Valuation:',
    'गिरवी मूल्यांकन:',
    'गिरवी मूल्य:',
    'मूल्यांकन:',
  ];
  return noticeText
      .split('\n')
      .where((line) {
        final trimmed = line.trim();
        return !hiddenPrefixes.any(trimmed.startsWith);
      })
      .join('\n')
      .trim();
}

part of '../girvi_notice_pdf_service.dart';

pw.Widget _signatureBlock(
  GirviNoticeLanguage language,
  pw.Font? devanagariFont,
) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      _signature(
        _label('Customer Acknowledgement', language),
        language,
        devanagariFont,
      ),
      _signature(
        _label('Authorised Signatory', language),
        language,
        devanagariFont,
      ),
    ],
  );
}

pw.Widget _signature(
  String label,
  GirviNoticeLanguage language,
  pw.Font? devanagariFont,
) {
  return pw.Container(
    width: 238,
    padding: const pw.EdgeInsets.only(top: 22),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _line, width: 0.8)),
    ),
    child: pw.Text(
      label,
      textDirection: pw.TextDirection.ltr,
      style: _textStyle(
        language,
        devanagariFont,
        color: _ink,
        fontSize: 10.2,
        bold: true,
      ),
    ),
  );
}

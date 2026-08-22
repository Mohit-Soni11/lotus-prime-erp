import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'pos_invoice_pdf_text_renderer.dart';

class PosInvoiceShopPrintBlocks {
  PosInvoiceShopPrintBlocks._();

  static const socialFieldIds = <String>{
    'website',
    'instagram',
    'facebook',
    'youtube',
    'whatsapp_channel',
  };

  static String bisRegistrationNumber(PosInvoiceModel invoice) {
    final rawValue = invoice.shopPrintValue('bis_license').trim();
    if (rawValue.isEmpty) return '';

    final metalNames = invoice.saleItems
        .map((item) => item.metal.displayName)
        .toSet()
        .toList(growable: false);
    if (metalNames.length == 1) {
      final metalValue = _metalMappedValue(rawValue, metalNames.single);
      if (metalValue != null) return metalValue;
      if (_hasMetalMappedEntries(rawValue)) return '';
    }

    return rawValue;
  }

  static const _socialPlatforms = <_SocialPlatform>[
    _SocialPlatform(
      id: 'website',
      label: 'Website',
      svg: '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#111827" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="9"/>
  <path d="M3 12h18"/>
  <path d="M12 3c2.3 2.5 3.5 5.5 3.5 9s-1.2 6.5-3.5 9"/>
  <path d="M12 3c-2.3 2.5-3.5 5.5-3.5 9s1.2 6.5 3.5 9"/>
</svg>
''',
    ),
    _SocialPlatform(
      id: 'instagram',
      label: 'Instagram',
      svg: '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#C13584" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <rect x="3" y="3" width="18" height="18" rx="5"/>
  <circle cx="12" cy="12" r="4"/>
  <circle cx="17" cy="7" r="1"/>
</svg>
''',
    ),
    _SocialPlatform(
      id: 'facebook',
      label: 'Facebook',
      svg: '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="#1877F2">
  <path d="M22 12.06C22 6.5 17.52 2 12 2S2 6.5 2 12.06C2 17.08 5.66 21.24 10.44 22v-7.03H7.9v-2.91h2.54V9.84c0-2.52 1.5-3.91 3.78-3.91 1.1 0 2.24.2 2.24.2v2.48H15.2c-1.24 0-1.63.78-1.63 1.57v1.88h2.78l-.44 2.91h-2.34V22C18.34 21.24 22 17.08 22 12.06z"/>
</svg>
''',
    ),
    _SocialPlatform(
      id: 'youtube',
      label: 'YouTube',
      svg: '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="#FF0000">
  <path d="M22 12s0-3.2-.41-4.74a3.05 3.05 0 0 0-2.15-2.16C17.9 4.69 12 4.69 12 4.69s-5.9 0-7.44.41a3.05 3.05 0 0 0-2.15 2.16C2 8.8 2 12 2 12s0 3.2.41 4.74a3.05 3.05 0 0 0 2.15 2.16c1.54.41 7.44.41 7.44.41s5.9 0 7.44-.41a3.05 3.05 0 0 0 2.15-2.16C22 15.2 22 12 22 12z"/>
  <path d="M10 15.2V8.8L15.5 12 10 15.2z" fill="#FFFFFF"/>
</svg>
''',
    ),
    _SocialPlatform(
      id: 'whatsapp_channel',
      label: 'WhatsApp Channel',
      svg: '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="#25D366">
  <path d="M12.04 2C6.54 2 2.08 6.46 2.08 11.96c0 1.76.46 3.48 1.34 4.99L2 22l5.19-1.36a9.9 9.9 0 0 0 4.85 1.24h.01c5.49 0 9.96-4.46 9.96-9.96C22 6.46 17.54 2 12.04 2z"/>
  <path d="M9.25 7.3c-.22-.5-.45-.51-.66-.52h-.56c-.2 0-.51.07-.78.36-.27.3-1.03 1-1.03 2.44s1.06 2.84 1.2 3.03c.15.2 2.05 3.28 5.1 4.47 2.53.99 3.05.8 3.6.75.55-.05 1.78-.73 2.03-1.43.25-.7.25-1.3.18-1.43-.08-.12-.27-.2-.57-.35-.3-.15-1.78-.88-2.06-.98-.27-.1-.47-.15-.67.15-.2.3-.77.98-.95 1.18-.17.2-.35.22-.65.07-.3-.15-1.27-.47-2.42-1.5-.9-.8-1.5-1.78-1.67-2.08-.18-.3-.02-.46.13-.61.13-.13.3-.35.45-.52.15-.18.2-.3.3-.5.1-.2.05-.37-.03-.52-.07-.15-.65-1.6-.94-2.18z" fill="#FFFFFF"/>
</svg>
''',
    ),
  ];

  static Iterable<String> printableTextLines(PosInvoiceModel invoice) sync* {
    final shopName = _shopName(invoice);
    if (shopName.isNotEmpty) {
      yield 'Connect with $shopName';
    }

    for (final field in invoice.shopPrintFields) {
      if (field.group != ShopPrintFieldGroup.social) continue;
      if (field.id == 'social_media_qr') continue;
      final platform = _platformFor(field.id);
      if (platform == null || field.value.trim().isEmpty) continue;
      yield field.value.trim();
    }

    final qrEntries = _qrEntries(invoice);
    for (final entry in qrEntries) {
      if (entry.value.trim().isNotEmpty) {
        yield entry.value.trim();
      }
    }
  }

  static pw.Widget? socialSection(
    PosInvoiceModel invoice, {
    required PosInvoicePdfTextRenderer? textRenderer,
    required PdfColor borderColor,
    required PdfColor accentColor,
    bool compact = false,
  }) {
    if (_isQrEnabled(invoice)) {
      final entries = _qrEntries(invoice);
      if (entries.isEmpty) return null;
      return _qrSection(
        invoice,
        entries: entries,
        textRenderer: textRenderer,
        borderColor: borderColor,
        accentColor: accentColor,
        compact: compact,
      );
    }

    final entries = _enabledSocialEntries(invoice);
    if (entries.isEmpty) return null;
    return _linksSection(
      entries,
      textRenderer: textRenderer,
      borderColor: borderColor,
      compact: compact,
    );
  }

  static bool hasPrintableSocialSection(PosInvoiceModel invoice) {
    if (_isQrEnabled(invoice)) {
      return _qrEntries(invoice).isNotEmpty;
    }
    return _enabledSocialEntries(invoice).isNotEmpty;
  }

  static pw.Widget? compactSocialStrip(
    PosInvoiceModel invoice, {
    required PosInvoicePdfTextRenderer? textRenderer,
    required PdfColor borderColor,
    required PdfColor accentColor,
  }) {
    final useQr = _isQrEnabled(invoice);
    final entries =
        useQr ? _qrEntries(invoice) : _enabledSocialEntries(invoice);
    if (entries.isEmpty) return null;

    final shopName = _shopName(invoice);
    final payload = qrPayloadForInvoice(invoice);
    final filledEntries = entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .take(3)
        .toList(growable: false);
    final detail = filledEntries.isEmpty
        ? 'Scan for official social channels.'
        : filledEntries
            .map((entry) => '${entry.platform.label}: ${entry.value.trim()}')
            .join('  |  ');

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: 0.55),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (useQr && payload.isNotEmpty) ...[
            pw.Container(
              width: 34,
              height: 34,
              padding: const pw.EdgeInsets.all(2),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: accentColor, width: 0.55),
              ),
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: payload,
                drawText: false,
                color: PdfColors.black,
                backgroundColor: PdfColors.white,
              ),
            ),
            pw.SizedBox(width: 8),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _safeText(
                  shopName.isEmpty
                      ? 'Connect with us'
                      : 'Connect with $shopName',
                  textRenderer: textRenderer,
                  maxWidth: 390,
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    fontSize: 8.2,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 2),
                _safeText(
                  detail,
                  textRenderer: textRenderer,
                  maxWidth: 430,
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    fontSize: 7.2,
                    color: PdfColors.black,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget? policySocialPanel(
    PosInvoiceModel invoice, {
    required PosInvoicePdfTextRenderer? textRenderer,
    required PdfColor borderColor,
    required PdfColor accentColor,
  }) {
    final useQr = _isQrEnabled(invoice);
    final entries =
        useQr ? _qrEntries(invoice) : _enabledSocialEntries(invoice);
    if (entries.isEmpty) return null;

    if (!useQr) {
      return _linksSection(
        entries,
        textRenderer: textRenderer,
        borderColor: borderColor,
        compact: false,
      );
    }

    final shopName = _shopName(invoice);
    final payload = qrPayloadForInvoice(invoice);
    if (payload.isEmpty) return null;

    final filledEntries = entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .take(4)
        .toList(growable: false);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: borderColor, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 78,
            height: 78,
            padding: const pw.EdgeInsets.all(3),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: accentColor, width: 0.8),
            ),
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: payload,
              drawText: false,
              color: PdfColors.black,
              backgroundColor: PdfColors.white,
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                _safeText(
                  shopName.isEmpty
                      ? 'Connect with us'
                      : 'Connect with $shopName',
                  textRenderer: textRenderer,
                  maxWidth: 390,
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    fontSize: 12.8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Scan for official online channels.',
                  style: pw.TextStyle(
                    fontSize: 11.4,
                    color: PdfColors.black,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (filledEntries.isNotEmpty) ...[
                  pw.SizedBox(height: 7),
                  pw.Wrap(
                    spacing: 7,
                    runSpacing: 5,
                    children: [
                      for (final entry in filledEntries)
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: pw.BoxDecoration(
                            border:
                                pw.Border.all(color: accentColor, width: 0.5),
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(3),
                            ),
                          ),
                          child: pw.Text(
                            entry.platform.label,
                            style: pw.TextStyle(
                              fontSize: 9.2,
                              color: PdfColors.black,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String qrPayloadForInvoice(PosInvoiceModel invoice) {
    final entries = _qrEntries(invoice);
    if (entries.isEmpty) return '';

    final website = entries.where((entry) => entry.platform.id == 'website');
    final preferred = [
      ...website,
      ...entries.where((entry) => entry.platform.id != 'website'),
    ].where((entry) => entry.value.trim().isNotEmpty);

    if (preferred.isNotEmpty) {
      return _normalizedSocialUrl(preferred.first);
    }

    final shopName = _shopName(invoice);
    return shopName.isEmpty ? 'Connect with us' : 'Connect with $shopName';
  }

  static pw.Widget _linksSection(
    List<_SocialEntry> entries, {
    required PosInvoicePdfTextRenderer? textRenderer,
    required PdfColor borderColor,
    required bool compact,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 6 : 8,
      ),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Wrap(
        spacing: compact ? 8 : 12,
        runSpacing: 6,
        children: [
          for (final entry in entries)
            _socialChip(
              entry,
              textRenderer: textRenderer,
              compact: compact,
            ),
        ],
      ),
    );
  }

  static pw.Widget _qrSection(
    PosInvoiceModel invoice, {
    required List<_SocialEntry> entries,
    required PosInvoicePdfTextRenderer? textRenderer,
    required PdfColor borderColor,
    required PdfColor accentColor,
    required bool compact,
  }) {
    final shopName = _shopName(invoice);
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 6 : 8,
      ),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: compact ? 42 : 50,
            height: compact ? 42 : 50,
            padding: const pw.EdgeInsets.all(3),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderColor, width: 0.6),
            ),
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: qrPayloadForInvoice(invoice),
              drawText: false,
              color: PdfColors.black,
              backgroundColor: PdfColors.white,
            ),
          ),
          pw.SizedBox(width: compact ? 8 : 11),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _safeText(
                  shopName.isEmpty
                      ? 'Connect with us'
                      : 'Connect with $shopName',
                  textRenderer: textRenderer,
                  maxWidth: 360,
                  style: pw.TextStyle(
                    fontSize: compact ? 8.2 : 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Scan for official website and social channels.',
                  style: pw.TextStyle(
                    fontSize: compact ? 7.2 : 7.8,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final entry in entries.take(5))
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2.5,
                        ),
                        decoration: pw.BoxDecoration(
                          border:
                              pw.Border.all(color: accentColor, width: 0.45),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        child: pw.Text(
                          entry.platform.label,
                          style: pw.TextStyle(
                            fontSize: compact ? 6.6 : 7,
                            color: PdfColors.black,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _socialChip(
    _SocialEntry entry, {
    required PosInvoicePdfTextRenderer? textRenderer,
    required bool compact,
  }) {
    return pw.Container(
      constraints: pw.BoxConstraints(maxWidth: compact ? 158 : 205),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: compact ? 13 : 15,
            height: compact ? 13 : 15,
            child: pw.SvgImage(svg: entry.platform.svg),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            '${entry.platform.label}: ',
            style: pw.TextStyle(
              fontSize: compact ? 6.8 : 7.4,
              color: PdfColors.black,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Flexible(
            child: _safeText(
              entry.value,
              textRenderer: textRenderer,
              maxWidth: compact ? 96 : 130,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                fontSize: compact ? 6.8 : 7.4,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<_SocialEntry> _enabledSocialEntries(PosInvoiceModel invoice) {
    final entries = <_SocialEntry>[];
    for (final field in invoice.shopPrintFields) {
      if (!socialFieldIds.contains(field.id)) continue;
      final platform = _platformFor(field.id);
      final value = field.value.trim();
      if (platform == null || value.isEmpty) continue;
      entries.add(_SocialEntry(platform: platform, value: value));
    }
    return entries;
  }

  static List<_SocialEntry> _qrEntries(PosInvoiceModel invoice) {
    if (!_isQrEnabled(invoice)) return const [];

    final payload = invoice.shopPrintValue('social_media_qr').trim();
    final linksByPlatform = <String, String>{};
    for (final rawLine in payload.replaceAll('\r\n', '\n').split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final separator = line.indexOf(':');
      if (separator <= 0) continue;
      final label = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      if (value.isEmpty) continue;
      final platform = _platformForLabel(label);
      if (platform == null) continue;
      linksByPlatform[platform.id] = value;
    }

    return [
      for (final platform in _socialPlatforms)
        _SocialEntry(
          platform: platform,
          value: linksByPlatform[platform.id] ?? '',
        ),
    ];
  }

  static pw.Widget _safeText(
    String value, {
    required PosInvoicePdfTextRenderer? textRenderer,
    required pw.TextStyle style,
    required double maxWidth,
    int? maxLines,
    pw.TextOverflow? overflow,
  }) {
    final renderer = textRenderer;
    if (renderer == null) {
      return pw.Text(
        value,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }
    return renderer.text(
      value,
      style: style,
      maxWidth: maxWidth,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  static String _normalizedSocialUrl(_SocialEntry entry) {
    final text = entry.value.trim();
    if (text.isEmpty) return text;
    if (text.startsWith(RegExp(r'https?://', caseSensitive: false))) {
      return text;
    }

    final handle = text.startsWith('@') ? text.substring(1) : text;
    switch (entry.platform.id) {
      case 'instagram':
        return 'https://instagram.com/$handle';
      case 'facebook':
        return 'https://facebook.com/$handle';
      case 'youtube':
        return text.startsWith('@')
            ? 'https://youtube.com/$text'
            : 'https://youtube.com/@$handle';
      case 'whatsapp_channel':
        if (text.startsWith(RegExp(r'whatsapp:', caseSensitive: false))) {
          return text;
        }
        if (text.startsWith('wa.me/') ||
            text.startsWith('chat.whatsapp.com/')) {
          return 'https://$text';
        }
        return text;
    }
    return _normalizedUrl(text);
  }

  static String _normalizedUrl(String value) {
    final text = value.trim();
    if (text.startsWith(RegExp(r'https?://', caseSensitive: false))) {
      return text;
    }
    if (text.startsWith('www.')) return 'https://$text';
    return text;
  }

  static String _shopName(PosInvoiceModel invoice) {
    final printName = invoice.printShopName.trim();
    if (printName.isNotEmpty) return printName;
    return invoice.shopName.trim();
  }

  static bool _isQrEnabled(PosInvoiceModel invoice) {
    return invoice.shopPrintFields
        .any((field) => field.id == 'social_media_qr');
  }

  static _SocialPlatform? _platformFor(String id) {
    for (final platform in _socialPlatforms) {
      if (platform.id == id) return platform;
    }
    return null;
  }

  static _SocialPlatform? _platformForLabel(String label) {
    final normalized = label.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    if (normalized == 'whatsapp_channel') {
      return _platformFor('whatsapp_channel');
    }
    for (final platform in _socialPlatforms) {
      if (platform.label.toLowerCase() == label.toLowerCase() ||
          platform.id == normalized) {
        return platform;
      }
    }
    return null;
  }

  static String? _metalMappedValue(String rawValue, String metalName) {
    final normalizedMetal = _normalizeKey(metalName);
    for (final part in rawValue.split('|')) {
      final separator = part.indexOf(':');
      if (separator <= 0) continue;
      final key = _normalizeKey(part.substring(0, separator));
      final value = part.substring(separator + 1).trim();
      if (key == normalizedMetal && value.isNotEmpty) return value;
    }
    return null;
  }

  static bool _hasMetalMappedEntries(String rawValue) {
    return rawValue.split('|').any((part) => part.trim().contains(':'));
  }

  static String _normalizeKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}

class _SocialEntry {
  final _SocialPlatform platform;
  final String value;

  const _SocialEntry({
    required this.platform,
    required this.value,
  });
}

class _SocialPlatform {
  final String id;
  final String label;
  final String svg;

  const _SocialPlatform({
    required this.id,
    required this.label,
    required this.svg,
  });
}

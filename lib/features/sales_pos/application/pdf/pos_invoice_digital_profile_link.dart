import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';

class PosInvoiceDigitalProfileLink {
  PosInvoiceDigitalProfileLink._();

  static const productionBaseUrl = 'https://scan.anjalijewellers.com';

  static const _channelLabels = <String, String>{
    'website': 'Website',
    'instagram': 'Instagram',
    'facebook': 'Facebook',
    'youtube': 'YouTube',
    'whatsapp_channel': 'WhatsApp Channel',
  };

  static String urlForInvoice(
    PosInvoiceModel invoice, {
    String baseUrl = productionBaseUrl,
  }) {
    final normalizedBaseUrl = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (normalizedBaseUrl.isEmpty) return '';

    final payload = payloadForInvoice(invoice);
    if (payload.isEmpty) return '';
    return normalizedBaseUrl;
  }

  static Map<String, dynamic> payloadForInvoice(PosInvoiceModel invoice) {
    final payload = <String, dynamic>{};

    void addText(String key, String value) {
      final text = value.trim();
      if (text.isNotEmpty) payload[key] = text;
    }

    addText(
      'shopName',
      _firstPresent([invoice.printShopName, invoice.shopName]),
    );
    addText('tagline', invoice.shopPrintValue('tagline'));
    addText(
      'address',
      _firstPresent([invoice.printShopAddress, invoice.shopAddress]),
    );
    addText(
      'phone',
      _firstPresent([
        invoice.shopPrintValue('mobile_number'),
        invoice.printShopPhone,
        invoice.shopPhone,
      ]),
    );
    addText('whatsapp', invoice.shopPrintValue('whatsapp_number'));
    addText('email', invoice.shopPrintValue('business_email'));
    addText('gstin', invoice.printShopGstin);

    final publicLogoUrl = _publicUrl(invoice.shopLogoPath);
    if (publicLogoUrl.isNotEmpty) payload['logoUrl'] = publicLogoUrl;

    final qrDirectoryLinks = _qrDirectoryLinks(invoice);
    final channels = <String, String>{};
    for (final entry in _channelLabels.entries) {
      final rawValue = _firstPresent([
        invoice.shopPrintValue(entry.key),
        qrDirectoryLinks[entry.key] ?? '',
      ]);
      final normalizedUrl = normalizedSocialUrl(entry.key, rawValue);
      if (normalizedUrl.isNotEmpty) channels[entry.key] = normalizedUrl;
    }
    payload['channels'] = channels;

    return payload;
  }

  static String normalizedSocialUrl(String channelId, String value) {
    final text = value.trim();
    if (text.isEmpty) return '';
    if (text.startsWith(RegExp(r'https?://', caseSensitive: false))) {
      return text;
    }

    final handle = text.startsWith('@') ? text.substring(1) : text;
    switch (channelId) {
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
            text.startsWith('chat.whatsapp.com/') ||
            text.startsWith('whatsapp.com/')) {
          return 'https://$text';
        }
        return text;
      default:
        return _normalizedWebUrl(text);
    }
  }

  static String _normalizedWebUrl(String value) {
    final text = value.trim();
    if (text.startsWith(RegExp(r'https?://', caseSensitive: false))) {
      return text;
    }
    if (text.startsWith('www.')) return 'https://$text';
    if (text.contains('.') && !text.contains(' ')) return 'https://$text';
    return text;
  }

  static String _publicUrl(String value) {
    final text = value.trim();
    if (text.startsWith(RegExp(r'https?://', caseSensitive: false))) {
      return text;
    }
    return '';
  }

  static Map<String, String> _qrDirectoryLinks(PosInvoiceModel invoice) {
    final payload = invoice.shopPrintValue('social_media_qr').trim();
    if (payload.isEmpty) return const {};

    final linksByPlatform = <String, String>{};
    for (final rawLine in payload.replaceAll('\r\n', '\n').split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final separator = line.indexOf(':');
      if (separator <= 0) continue;

      final label = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      final platformId = _platformIdForLabel(label);
      if (platformId == null || value.isEmpty) continue;

      linksByPlatform[platformId] = value;
    }
    return linksByPlatform;
  }

  static String? _platformIdForLabel(String label) {
    final normalized = label.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    if (_channelLabels.containsKey(normalized)) return normalized;

    for (final entry in _channelLabels.entries) {
      if (entry.value.toLowerCase() == label.toLowerCase()) return entry.key;
    }
    return null;
  }

  static String _firstPresent(List<String> values) {
    for (final value in values) {
      final text = value.trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}

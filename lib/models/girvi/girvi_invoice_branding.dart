import 'package:flutter/foundation.dart';

@immutable
class GirviInvoiceBranding {
  const GirviInvoiceBranding({
    required this.shopName,
    required this.shopAddress,
    required this.shopMobile,
    this.shopAlternateMobile = '',
    this.shopGstin = '',
    this.logoPath,
    this.logoShape = 'circle',
  });

  static const fallback = GirviInvoiceBranding(
    shopName: 'SHOP PROFILE NOT SET',
    shopAddress: 'Complete Settings > Shop Profile',
    shopMobile: '',
    shopAlternateMobile: '',
    shopGstin: '',
    logoPath: null,
    logoShape: 'circle',
  );

  final String shopName;
  final String shopAddress;
  final String shopMobile;
  final String shopAlternateMobile;
  final String shopGstin;
  final String? logoPath;
  final String logoShape;

  String get initial {
    final value = shopName.trim();
    return value.isEmpty ? 'S' : value.substring(0, 1).toUpperCase();
  }

  String get contactLine {
    final values = <String>[
      if (shopAddress.trim().isNotEmpty) shopAddress.trim(),
      if (shopMobile.trim().isNotEmpty) 'Mobile: ${shopMobile.trim()}',
      if (shopAlternateMobile.trim().isNotEmpty)
        'Alt: ${shopAlternateMobile.trim()}',
      if (shopGstin.trim().isNotEmpty) 'GSTIN: ${shopGstin.trim()}',
    ];
    return values.join('  |  ');
  }

  String get detailLine {
    final values = <String>[
      if (shopMobile.trim().isNotEmpty) 'Mobile: ${shopMobile.trim()}',
      if (shopAlternateMobile.trim().isNotEmpty)
        'Alt: ${shopAlternateMobile.trim()}',
      if (shopGstin.trim().isNotEmpty) 'GSTIN: ${shopGstin.trim()}',
    ];
    return values.join('  |  ');
  }

  factory GirviInvoiceBranding.fromShopSetup(
    Map<String, dynamic> payload,
  ) {
    final basicInfo = _stringMap(payload['basic_info']);
    final branding = _stringMap(payload['branding']);
    final address = _stringMap(payload['address']);
    final tax = _stringMap(payload['tax_compliance']);
    final shopName = _firstValue([
      basicInfo['brand_display_name'],
      basicInfo['display_name'],
      basicInfo['legal_name'],
    ]);
    final mobile = _firstValue([
      basicInfo['shop_phone'],
      basicInfo['owner_phone'],
    ]);
    final alternateMobile = _differentValue(
      mobile,
      [
        branding['support_phone'],
        basicInfo['shop_whatsapp'],
      ],
    );
    final formattedAddress = _joinAddress([
      address['addr1'],
      address['addr2'],
      address['city'],
      address['state'],
      address['pincode'],
    ]);

    return GirviInvoiceBranding(
      shopName:
          shopName.isEmpty ? GirviInvoiceBranding.fallback.shopName : shopName,
      shopAddress: formattedAddress.isEmpty
          ? GirviInvoiceBranding.fallback.shopAddress
          : formattedAddress,
      shopMobile: mobile,
      shopAlternateMobile: alternateMobile,
      shopGstin: tax['gstin']?.toString().trim() ?? '',
      logoPath: _nullablePath(basicInfo['logo_path']),
      logoShape: _shape(basicInfo['logo_shape']),
    );
  }

  static Map<String, dynamic> _stringMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), item),
      );
    }
    return const {};
  }

  static String _firstValue(Iterable<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String _differentValue(
    String primary,
    Iterable<Object?> values,
  ) {
    final normalizedPrimary = _phoneDigits(primary);
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) continue;
      if (_phoneDigits(text) != normalizedPrimary) return text;
    }
    return '';
  }

  static String _phoneDigits(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static String _joinAddress(Iterable<Object?> values) {
    return values
        .map((value) => value?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .join(', ');
  }

  static String? _nullablePath(Object? value) {
    final path = value?.toString().trim() ?? '';
    return path.isEmpty ? null : path;
  }

  static String _shape(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'square' ? 'square' : 'circle';
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import 'girvi_invoice_branding.dart';

/// The shop text and selected asset paths approved with a notice. Later
/// profile edits must not silently change the printed shop identity.
class GirviNoticeBrandingSnapshot {
  const GirviNoticeBrandingSnapshot._();

  /// Freeze the artwork shown in an approved notice. File paths alone can
  /// later point to changed or deleted images.
  static Future<String> capture(
    GirviInvoiceBranding branding, {
    String? itemPhotoPath,
  }) async {
    final data = jsonDecode(encode(branding)) as Map<String, dynamic>;
    data['version'] = 2;
    for (final entry in <String, String?>{
      'logoBytes': branding.logoPath,
      'signatureBytes': branding.signaturePath,
      'itemPhotoBytes': itemPhotoPath,
    }.entries) {
      final bytes = await _imageBytes(entry.value,
          preserveTransparency: entry.key != 'itemPhotoBytes');
      if (bytes != null) data[entry.key] = base64Encode(bytes);
    }
    return jsonEncode(data);
  }

  static Uint8List? assetBytes(String? source, String key) {
    if (source == null) return null;
    try {
      final data = jsonDecode(source);
      if (data is! Map<String, dynamic> || data['version'] != 2) return null;
      final encoded = data[key];
      if (encoded is! String || encoded.isEmpty) return Uint8List(0);
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _imageBytes(String? path,
      {required bool preserveTransparency}) async {
    if (path == null || path.trim().isEmpty) return null;
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final original = img.decodeImage(await file.readAsBytes());
      if (original == null) return null;
      final resized = original.width > 900 || original.height > 900
          ? img.copyResize(original,
              width: original.width >= original.height ? 900 : null,
              height: original.height > original.width ? 900 : null)
          : original;
      return Uint8List.fromList(preserveTransparency
          ? img.encodePng(resized)
          : img.encodeJpg(resized, quality: 85));
    } catch (_) {
      return null;
    }
  }

  static String encode(GirviInvoiceBranding branding) => jsonEncode({
        'version': 1,
        'shopName': branding.shopName,
        'shopAddress': branding.shopAddress,
        'shopMobile': branding.shopMobile,
        'shopAlternateMobile': branding.shopAlternateMobile,
        'shopGstin': branding.shopGstin,
        'logoPath': branding.logoPath,
        'logoShape': branding.logoShape,
        'signaturePath': branding.signaturePath,
        'signatureShape': branding.signatureShape,
        'printFields': [
          for (final field in branding.printFields)
            {
              'id': field.id,
              'label': field.label,
              'value': field.value,
              'group': field.group.name,
            },
        ],
      });

  static GirviInvoiceBranding? decode(String? source) {
    if (source == null || source.trim().isEmpty) return null;
    try {
      final data = jsonDecode(source);
      if (data is! Map<String, dynamic> ||
          (data['version'] != 1 && data['version'] != 2)) {
        return null;
      }
      String value(String key) =>
          data[key] is String ? data[key] as String : '';
      if (value('shopName').trim().isEmpty) return null;
      final fields = <ShopPrintDocumentField>[];
      final rawFields = data['printFields'];
      if (rawFields is List) {
        for (final raw in rawFields) {
          if (raw is! Map<String, dynamic>) continue;
          final group = ShopPrintFieldGroup.values.where(
            (candidate) => candidate.name == raw['group'],
          );
          if (group.isEmpty) continue;
          fields.add(ShopPrintDocumentField(
            id: raw['id']?.toString() ?? '',
            label: raw['label']?.toString() ?? '',
            value: raw['value']?.toString() ?? '',
            group: group.first,
          ));
        }
      }
      return GirviInvoiceBranding(
        shopName: value('shopName'),
        shopAddress: value('shopAddress'),
        shopMobile: value('shopMobile'),
        shopAlternateMobile: value('shopAlternateMobile'),
        shopGstin: value('shopGstin'),
        logoPath:
            data['logoPath'] is String ? data['logoPath'] as String : null,
        logoShape: value('logoShape'),
        printFields: List.unmodifiable(fields),
        signaturePath: data['signaturePath'] is String
            ? data['signaturePath'] as String
            : null,
        signatureShape: value('signatureShape'),
      );
    } catch (_) {
      return null;
    }
  }
}

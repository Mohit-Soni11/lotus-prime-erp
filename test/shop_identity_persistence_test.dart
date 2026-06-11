import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/setting/shop_setup/shop_profile_model.dart';

void main() {
  test('Corporate Identity logo path and shape survive serialization', () {
    const profile = ShopProfileModel(
      displayName: 'Anjali Jewellers',
      ownerName: 'Anjali Kumari',
      ownerPhone: '9876543210',
      shopPhone: '9876543210',
      logoPath: r'D:\shop_identity\shop_logo.png',
      logoShape: 'square',
      signaturePath: r'D:\shop_identity\authorized_signature.png',
      signatureShape: 'square',
    );

    final restored = ShopProfileModel.fromJson(profile.toJson());

    expect(restored.logoPath, r'D:\shop_identity\shop_logo.png');
    expect(restored.logoShape, 'square');
    expect(
      restored.signaturePath,
      r'D:\shop_identity\authorized_signature.png',
    );
    expect(restored.signatureShape, 'square');
  });

  test('invalid Corporate Identity shape safely falls back', () {
    final restored = ShopProfileModel.fromJson(const {
      'logo_shape': 'triangle',
      'signature_shape': '',
    });

    expect(restored.logoShape, 'circle');
    expect(restored.signatureShape, 'square');
  });
}

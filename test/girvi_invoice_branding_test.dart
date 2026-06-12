import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/girvi/girvi_invoice_branding.dart';
import 'package:lotus_erp/repositories/girvi/girvi_invoice_branding_repository.dart';

void main() {
  test('Shop Setup payload becomes Girvi invoice branding', () {
    final branding = GirviInvoiceBranding.fromShopSetup(const {
      'basic_info': {
        'brand_display_name': 'Shree Balaji Jewellers',
        'display_name': 'Balaji Store',
        'shop_phone': '9876543210',
        'shop_whatsapp': '9123456789',
        'logo_path': r'D:\shop\logo.png',
        'logo_shape': 'square',
      },
      'branding': {
        'support_phone': '9000011111',
      },
      'address': {
        'addr1': 'Main Road',
        'addr2': 'Near Tower Chowk',
        'city': 'Gaya',
        'state': 'Bihar',
        'pincode': '823001',
      },
      'tax_compliance': {
        'gstin': '10ABCDE1234F1Z5',
      },
    });

    expect(branding.shopName, 'Shree Balaji Jewellers');
    expect(
      branding.shopAddress,
      'Main Road, Near Tower Chowk, Gaya, Bihar, 823001',
    );
    expect(branding.shopMobile, '9876543210');
    expect(branding.shopAlternateMobile, '9000011111');
    expect(branding.shopGstin, '10ABCDE1234F1Z5');
    expect(branding.logoPath, r'D:\shop\logo.png');
    expect(branding.logoShape, 'square');
    expect(
      branding.contactLine,
      'Main Road, Near Tower Chowk, Gaya, Bihar, 823001  |  '
      'Mobile: 9876543210  |  Alt: 9000011111  |  '
      'GSTIN: 10ABCDE1234F1Z5',
    );
    expect(branding.initial, 'S');
  });

  test('Girvi branding repository falls back to synced Drift profile',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.shopProfiles).insert(
          ShopProfilesCompanion.insert(
            shopName: const Value('Anjali Jewellers'),
            contactNumber: const Value('9000011111'),
            whatsappNumber: const Value('9000022222'),
            address: const Value('Station Road'),
            city: const Value('Gaya'),
            state: const Value('Bihar'),
            pincode: const Value('823001'),
            logoPath: const Value(r'D:\shop\anjali-logo.png'),
            logoShape: const Value('circle'),
            gstin: const Value('10ABCDE1234F1Z5'),
          ),
        );
    final repository = GirviInvoiceBrandingRepository(
      db: db,
      shopSetupLoader: () async => null,
    );

    final branding = await repository.fetch();

    expect(branding.shopName, 'Anjali Jewellers');
    expect(branding.shopAddress, 'Station Road, Gaya, Bihar, 823001');
    expect(branding.shopMobile, '9000011111');
    expect(branding.shopAlternateMobile, '9000022222');
    expect(branding.shopGstin, '10ABCDE1234F1Z5');
    expect(branding.logoPath, r'D:\shop\anjali-logo.png');
    expect(branding.logoShape, 'circle');
  });
}

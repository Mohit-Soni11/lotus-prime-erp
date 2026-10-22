import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/girvi/girvi_invoice_branding.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_branding_snapshot.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import 'package:lotus_erp/repositories/girvi/girvi_invoice_branding_repository.dart';

void main() {
  test('approved notice branding retains the shop identity at approval', () {
    const approved = GirviInvoiceBranding(
      shopName: 'Anjali Jewellers',
      shopAddress: 'Old Road, Patna',
      shopMobile: '9000011111',
      shopAlternateMobile: '9000022222',
      signaturePath: r'D:\shop\signature.png',
      printFields: [
        ShopPrintDocumentField(
          id: 'business_address',
          label: 'Business Address',
          value: 'Approved print address, Patna',
          group: ShopPrintFieldGroup.address,
        ),
      ],
    );
    final snapshot = GirviNoticeBrandingSnapshot.encode(approved);
    final saved = GirviNoticeBrandingSnapshot.decode(snapshot)!;
    final updated = approved.copyWith(
      shopName: 'New Shop Name',
      shopAddress: 'New Road, Patna',
      shopMobile: '9000099999',
    );

    expect(saved.printShopName, 'Anjali Jewellers');
    expect(saved.printShopAddress, 'Approved print address, Patna');
    expect(saved.shopMobile, '9000011111');
    expect(saved.shopAlternateMobile, '9000022222');
    expect(saved.signaturePath, r'D:\shop\signature.png');
    expect(updated.printShopName, 'New Shop Name');
    expect(GirviNoticeBrandingSnapshot.decode('bad JSON'), null);
  });

  test('approved notice keeps artwork after image files change', () async {
    final directory = await Directory.systemTemp.createTemp('notice_art_');
    addTearDown(() => directory.delete(recursive: true));
    final logo = File('${directory.path}/logo.png');
    final item = File('${directory.path}/item.png');
    await logo.writeAsBytes(img.encodePng(img.Image(width: 2, height: 2)));
    await item.writeAsBytes(img.encodePng(img.Image(width: 3, height: 3)));
    final snapshot = await GirviNoticeBrandingSnapshot.capture(
      GirviInvoiceBranding(
          shopName: 'Anjali Jewellers',
          shopAddress: 'Patna',
          shopMobile: '9000011111',
          logoPath: logo.path),
      itemPhotoPath: item.path,
    );
    await logo.delete();
    await item.delete();

    expect(
        img
            .decodeImage(
                GirviNoticeBrandingSnapshot.assetBytes(snapshot, 'logoBytes')!)
            !.width,
        2);
    expect(
        img
            .decodeImage(GirviNoticeBrandingSnapshot.assetBytes(
                snapshot, 'itemPhotoBytes')!)
            !.width,
        3);
    expect(GirviNoticeBrandingSnapshot.decode(snapshot)!.printShopName,
        'Anjali Jewellers');
    expect(GirviNoticeBrandingSnapshot.assetBytes(snapshot, 'signatureBytes'),
        isEmpty);
  });

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
    expect(branding.shopAlternateMobile, '9123456789');
    expect(branding.shopGstin, '10ABCDE1234F1Z5');
    expect(branding.logoPath, r'D:\shop\logo.png');
    expect(branding.logoShape, 'square');
    expect(
      branding.contactLine,
      'Main Road, Near Tower Chowk, Gaya, Bihar, 823001  |  '
      'Mobile: 9876543210  |  Alt: 9123456789  |  '
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
            signaturePath: const Value(r'D:\shop\anjali-signature.png'),
            signatureShape: const Value('square'),
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
    expect(branding.signaturePath, r'D:\shop\anjali-signature.png');
    expect(branding.signatureShape, 'square');
  });
}

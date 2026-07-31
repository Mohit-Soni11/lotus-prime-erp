import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/local_database/shop_database_helper.dart';
import 'package:lotus_erp/database/local_database/shop_database_schema.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<Database> openShopDatabase(String path) {
    return openDatabase(
      path,
      version: ShopDatabaseSchema.currentVersion,
      onConfigure: ShopDatabaseSchema.configure,
      onCreate: ShopDatabaseSchema.create,
      onUpgrade: ShopDatabaseSchema.upgrade,
    );
  }

  test('fresh Shop Profile database contains the current BIS schema', () async {
    final directory =
        await Directory.systemTemp.createTemp('lotus_shop_fresh_');
    final path = join(directory.path, 'erp_master_db.db');

    try {
      final database = await openShopDatabase(path);
      final columns =
          await database.rawQuery('PRAGMA table_info(shop_tax_gst)');
      final names = columns.map((column) => column['name']).toSet();

      expect(
          names,
          containsAll(<String>{
            'gold_bis_license_no',
            'silver_bis_license_no',
            'hallmarking_scope',
            'bis_registration_mode',
            'gst_cert_path',
            'bis_license_path',
          }));

      await database.close();
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('legacy Shop Profile database upgrades to the current BIS schema',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('lotus_shop_upgrade_');
    final path = join(directory.path, 'erp_master_db.db');

    try {
      final legacy = await openDatabase(
        path,
        version: 3,
        onCreate: (database, _) async {
          await database.execute(
            'CREATE TABLE shop_profile (tenant_id TEXT PRIMARY KEY)',
          );
          await database.execute('''
            CREATE TABLE shop_tax_gst (
              tenant_id TEXT PRIMARY KEY,
              bis_license_no TEXT
            )
          ''');
        },
      );
      await legacy.close();

      final upgraded = await openShopDatabase(path);
      final columns =
          await upgraded.rawQuery('PRAGMA table_info(shop_tax_gst)');
      final names = columns.map((column) => column['name']).toSet();

      expect(
          names,
          containsAll(<String>{
            'gold_bis_license_no',
            'silver_bis_license_no',
            'hallmarking_scope',
            'bis_registration_mode',
          }));

      await upgraded.close();
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('Shop Profile data survives a database restart', () async {
    final directory =
        await Directory.systemTemp.createTemp('lotus_shop_restart_');
    final path = join(directory.path, 'erp_master_db.db');

    try {
      final initialDatabase = await openShopDatabase(path);
      final writer = ShopDatabaseHelper.forTesting(initialDatabase);

      final saved = await writer.upsertMasterPayload(<String, dynamic>{
        'tenant_id': 'SHOP-QA-001',
        'basic_info': <String, dynamic>{
          'legal_name': 'Lotus Jewellers Private Limited',
          'display_name': 'Lotus Jewellers',
          'tagline': 'Trusted jewellery',
          'owner_name': 'Quality Assurance',
          'owner_phone': '9876543210',
          'brand_display_name': 'Lotus Jewellers',
          'business_email': 'support@lotusjewellers.com',
          'shop_phone': '9876543210',
          'shop_whatsapp': '9876543210',
          'help_desk_number': '9123456780',
          'logo_path': 'C:/qa/logo.png',
          'logo_shape': 'circle',
          'signature_path': 'C:/qa/signature.png',
          'signature_shape': 'square',
        },
        'address': <String, dynamic>{
          'type': 'Head Office',
          'addr1': 'Main Road',
          'addr2': '',
          'city': 'Patna',
          'state': 'Bihar',
          'pincode': '800001',
          'country': 'India',
        },
        'tax_compliance': <String, dynamic>{
          'gstin': '10ABCDE1234F1Z5',
          'legal_name': 'Lotus Jewellers Private Limited',
          'reg_date': '01/07/2026',
          'taxpayer_type': 'Regular',
          'bis_license_no': 'Gold: HM/C-GOLD | Silver: HM/C-SILVER',
          'gold_bis_license_no': 'HM/C-GOLD',
          'silver_bis_license_no': 'HM/C-SILVER',
          'hallmarking_scope': 'Gold & Silver',
          'bis_registration_mode': 'Separate Registrations',
          'gst_cert_path': 'C:/qa/gst-certificate.pdf',
          'bis_license_path': 'C:/qa/bis-license.pdf',
        },
        'branding_social': <String, dynamic>{
          'website': 'lotusjewellers.com',
          'instagram': '@lotusjewellers',
          'facebook': 'facebook.com/lotusjewellers',
          'youtube': 'youtube.com/@lotusjewellers',
          'whatsapp_channel': 'whatsapp.com/channel/lotus',
        },
        'banking_details': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'bank-qa-001',
            'title': 'Primary Current Account',
            'holder': 'Lotus Jewellers Private Limited',
            'bank': 'Quality Bank',
            'type': 'Current',
            'acc': '1234567890123456',
            'ifsc': 'QALB0000001',
            'branch': 'Patna',
            'upi': 'lotus@qbank',
            'qr_image_path': 'C:/qa/upi-qr.png',
          },
        ],
      });
      expect(saved, isTrue);
      await initialDatabase.close();

      final restartedDatabase = await openShopDatabase(path);
      final reader = ShopDatabaseHelper.forTesting(restartedDatabase);
      final restored = await reader.getMasterPayload('SHOP-QA-001');

      expect(restored, isNotNull);
      expect(restored!['basic_info']['legal_name'],
          'Lotus Jewellers Private Limited');
      expect(restored['basic_info']['help_desk_number'], '9123456780');
      expect(restored['address']['pincode'], '800001');
      expect(restored['tax_compliance']['gold_bis_license_no'], 'HM/C-GOLD');
      expect(
          restored['tax_compliance']['silver_bis_license_no'], 'HM/C-SILVER');
      expect(restored['tax_compliance']['bis_registration_mode'],
          'Separate Registrations');
      expect(restored['tax_compliance']['gst_cert_path'],
          'C:/qa/gst-certificate.pdf');
      expect(restored['branding_social']['instagram'], '@lotusjewellers');
      expect(
        restored['branding_social']['whatsapp_channel'],
        'whatsapp.com/channel/lotus',
      );
      expect(restored['banking_details'], hasLength(1));
      expect(restored['banking_details'].single['acc'], '1234567890123456');

      await restartedDatabase.close();
    } finally {
      await directory.delete(recursive: true);
    }
  });
}

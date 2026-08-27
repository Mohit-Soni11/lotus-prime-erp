import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/data/shop_print_information_repository.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/domain/shop_print_information.dart';

void main() {
  test('shop print state ignores enabled fields that are not configured', () {
    const configuredField = ShopPrintField(
      id: 'shop_name',
      label: 'Shop Name',
      description: 'Primary store name printed in the invoice header.',
      sourceSection: 'Basic Info',
      value: 'Lotus Jewellers',
      group: ShopPrintFieldGroup.identity,
      defaultEnabled: true,
    );
    const missingField = ShopPrintField(
      id: 'website',
      label: 'Website',
      description: 'Official website printed for customer follow-up.',
      sourceSection: 'Branding',
      value: '',
      group: ShopPrintFieldGroup.social,
      defaultEnabled: false,
    );
    const dynamicQrField = ShopPrintField(
      id: 'social_media_qr',
      label: 'Social Media QR',
      description: 'System generated social landing page QR.',
      sourceSection: 'Branding',
      value: '',
      group: ShopPrintFieldGroup.social,
      defaultEnabled: false,
    );

    const state = ShopPrintInformationState(
      tenantId: 'tenant_001',
      fields: [configuredField, missingField, dynamicQrField],
      enabledFieldIds: {'shop_name', 'website', 'social_media_qr'},
    );

    expect(state.configuredCount, 2);
    expect(state.missingCount, 1);
    expect(state.enabledCount, 2);
    expect(state.configuredFieldIds, {'shop_name', 'social_media_qr'});
    expect(state.isEnabled(configuredField), isTrue);
    expect(state.isEnabled(missingField), isFalse);
    expect(state.isEnabled(dynamicQrField), isTrue);
  });

  test('shop print information persists selected fields in Drift', () async {
    SharedPreferences.setMockInitialValues({
      'lotus_erp_permanent_tenant_id': 'tenant_billing_setup_test',
    });
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final repository = ShopPrintInformationRepository(
      db: db,
      shopSetupLoader: (_) async => const {
        'basic_info': {
          'brand_display_name': 'Lotus Jewellers',
          'shop_phone': '9304479436',
          'shop_whatsapp': '9304479436',
          'help_desk_number': '9123456780',
          'logo_path': r'D:\Lotus\logo.png',
          'logo_shape': 'square',
        },
        'address': {
          'addr1': 'Main Road',
          'city': 'Patna',
          'state': 'Bihar',
          'pincode': '800001',
        },
        'tax_compliance': {
          'gstin': '10ABCDE1234F1Z5',
          'bis_license_no': 'BIS-REG-123',
          'hallmarking_scope': 'Gold & Silver',
          'gold_bis_license_no': 'BIS-REG-123',
          'silver_bis_license_no': 'BIS-REG-123',
        },
        'branding_social': {
          'website': 'lotusjewellers.com',
          'instagram': '@lotusjewellers',
          'youtube': 'youtube.com/@lotusjewellers',
        },
        'banking_details': [
          {
            'bank': 'HDFC Bank',
            'acc': '1234567890',
            'ifsc': 'HDFC0001234',
            'upi': 'lotus@upi',
          }
        ],
      },
    );

    final initial = await repository.load();
    await repository.save(
      initial.copyWith(
        enabledFieldIds: {
          'shop_name',
          'mobile_number',
          'whatsapp_number',
          'help_desk_number',
          'business_address',
          'gstin',
          'website',
          'instagram',
          'social_media_qr',
          'upi_id',
          'bis_license',
          'logo',
        },
      ),
    );

    final row = await (db.select(db.shopPrintInformationSettings)
          ..where((tbl) => tbl.tenantId.equals('tenant_billing_setup_test')))
        .getSingle();
    expect(row.enabledFieldIdsJson, contains('mobile_number'));
    expect(row.enabledFieldIdsJson, contains('website'));
    expect(row.enabledFieldIdsJson, contains('instagram'));

    final reloaded = await repository.load();
    expect(reloaded.enabledFieldIds, containsAll({'shop_name', 'gstin'}));
    expect(reloaded.enabledFieldIds, contains('upi_id'));
    expect(reloaded.configuredFieldIds, contains('whatsapp_number'));
    expect(
      reloaded.fields
          .singleWhere((field) => field.id == 'whatsapp_number')
          .value,
      '9304479436',
    );

    final profile = await repository.loadDocumentProfile();
    expect(profile.primaryName, 'Lotus Jewellers');
    expect(profile.logoPath, r'D:\Lotus\logo.png');
    expect(profile.primaryAddress, 'Main Road, Patna, Bihar, 800001');
    expect(profile.headerLines, contains('Business Mobile: 9304479436'));
    expect(
      profile.headerLines.any((line) => line.startsWith('WhatsApp Number:')),
      isFalse,
    );
    expect(profile.headerLines, contains('Help Desk Number: 9123456780'));
    expect(profile.headerLines, contains('GSTIN: 10ABCDE1234F1Z5'));
    expect(
      profile.headerLines,
      contains(
        'BIS Registration Number: Gold: BIS-REG-123 | Silver: BIS-REG-123',
      ),
    );
    expect(
      profile.headerLines.any((line) => line.startsWith('Taxpayer Type:')),
      isFalse,
    );
    expect(
      profile.headerLines.any(
        (line) => line.startsWith('BIS Hallmarking Scope:'),
      ),
      isFalse,
    );
    expect(
      profile.headerLines.any((line) => line.startsWith('Gold BIS License:')),
      isFalse,
    );
    expect(
      profile.headerLines.any((line) => line.startsWith('Silver BIS License:')),
      isFalse,
    );
    expect(profile.headerLines, contains('Website: lotusjewellers.com'));
    expect(profile.headerLines, contains('Instagram: @lotusjewellers'));
    expect(profile.valueOf('social_media_qr'), contains('Instagram:'));
    expect(
      profile.headerLines.any((line) => line.startsWith('Social Media QR:')),
      isFalse,
    );
    expect(profile.headerLines, contains('UPI ID: lotus@upi'));
  });

  test('shop print profile prefers full invoice shop name over short brand',
      () {
    const payload = {
      'basic_info': {
        'brand_display_name': 'ANJALI',
        'display_name': 'ANJALI JEWELLERS',
        'legal_name': 'ANJALI JEWELLERS',
      },
    };
    final fields = ShopPrintInformationCatalog.fromPayload(payload);
    final state = ShopPrintInformationState(
      tenantId: 'tenant_full_shop_name',
      fields: fields,
      enabledFieldIds: {'shop_name', 'legal_name'},
    );

    final profile = ShopPrintDocumentProfile.fromState(state, payload);

    expect(profile.primaryName, 'ANJALI JEWELLERS');
    expect(
      profile.headerLines.any((line) => line == 'Legal Name: ANJALI JEWELLERS'),
      isFalse,
    );
  });
}

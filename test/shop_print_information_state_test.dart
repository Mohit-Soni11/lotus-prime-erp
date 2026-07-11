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
      id: 'instagram',
      label: 'Instagram Channel',
      description: 'Instagram handle or page link.',
      sourceSection: 'Branding',
      value: '',
      group: ShopPrintFieldGroup.social,
      defaultEnabled: false,
    );

    const state = ShopPrintInformationState(
      tenantId: 'tenant_001',
      fields: [configuredField, missingField],
      enabledFieldIds: {'shop_name', 'instagram'},
    );

    expect(state.configuredCount, 1);
    expect(state.missingCount, 1);
    expect(state.enabledCount, 1);
    expect(state.configuredFieldIds, {'shop_name'});
    expect(state.isEnabled(configuredField), isTrue);
    expect(state.isEnabled(missingField), isFalse);
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
          'instagram': '@lotusjewellers',
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
          'gstin',
          'instagram',
          'upi_id',
          'bis_license',
          'bis_hallmarking_scope',
          'logo',
        },
      ),
    );

    final row = await (db.select(db.shopPrintInformationSettings)
          ..where((tbl) => tbl.tenantId.equals('tenant_billing_setup_test')))
        .getSingle();
    expect(row.enabledFieldIdsJson, contains('mobile_number'));
    expect(row.enabledFieldIdsJson, contains('instagram'));

    final reloaded = await repository.load();
    expect(reloaded.enabledFieldIds, containsAll({'shop_name', 'gstin'}));
    expect(reloaded.enabledFieldIds, contains('upi_id'));

    final profile = await repository.loadDocumentProfile();
    expect(profile.primaryName, 'Lotus Jewellers');
    expect(profile.logoPath, r'D:\Lotus\logo.png');
    expect(profile.headerLines, contains('Mobile Number: 9304479436'));
    expect(profile.headerLines, contains('GSTIN: 10ABCDE1234F1Z5'));
    expect(profile.headerLines, contains('BIS Registration No.: BIS-REG-123'));
    expect(
        profile.headerLines, contains('BIS Hallmarking Scope: Gold & Silver'));
    expect(
      profile.headerLines.any((line) => line.startsWith('Gold BIS License:')),
      isFalse,
    );
    expect(
      profile.headerLines.any((line) => line.startsWith('Silver BIS License:')),
      isFalse,
    );
    expect(profile.headerLines, contains('Instagram Channel: @lotusjewellers'));
    expect(profile.headerLines, contains('UPI ID: lotus@upi'));
  });
}

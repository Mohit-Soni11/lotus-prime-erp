import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/helpers/basic_info/basic_info_validators.dart';
import 'package:lotus_erp/helpers/banking/banking_validators.dart';
import 'package:lotus_erp/helpers/branding/branding_validators.dart';
import 'package:lotus_erp/logic/setting/shop_setup/tabs/address/address_logic.dart';
import 'package:lotus_erp/logic/setting/shop_setup/tabs/basic_info/basic_info_logic.dart';
import 'package:lotus_erp/logic/setting/shop_setup/tabs/branding/branding_logic.dart';
import 'package:lotus_erp/logic/setting/shop_setup/tabs/tax_gst/document_crop_logic.dart';
import 'package:lotus_erp/logic/setting/shop_setup/tabs/tax_gst/tax_gst_logic.dart';
import 'package:lotus_erp/theme/settings/shop_setup/tabs/basic_info_tab/basic_info_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'branding final model uses latest controller values without section save',
      () {
    final logic = BrandingLogic();
    addTearDown(logic.dispose);

    logic.instaCtrl.text = 'lotus_jewellers';
    logic.webCtrl.text = 'lotus.example';
    logic.waBizCtrl.text = '9876543210';
    logic.emailCtrl.text = 'support@lotus.com';
    logic.phoneCtrl.text = '9123456780';

    final model = logic.validateAndGenerateFinalModel();

    expect(model, isNotNull);
    expect(model!.instagram, 'lotus_jewellers');
    expect(model.website, 'lotus.example');
    expect(model.whatsappBusiness, '9876543210');
    expect(model.supportEmail, 'support@lotus.com');
    expect(model.supportPhone, '9123456780');
    expect(logic.brandingData, model);
  });

  test('tax GST final validation rejects invalid controller values', () {
    final logic = TaxGstLogic();
    addTearDown(logic.dispose);

    logic.gstinCtrl.text = 'BAD-GST';
    logic.legalNameCtrl.text = 'AB';
    logic.regDateCtrl.text = '';

    expect(logic.validateAndGenerateFinalModel(), isNull);
  });

  test('bank account validator accepts 20 digit account numbers', () {
    expect(BankingValidators.validateAccountNumber('12345678901234567890'),
        isNull);
    expect(BankingValidators.validateAccountNumber('123456789012345678901'),
        isNotNull);
  });

  test('basic info validation requires legal name and valid business hours',
      () {
    final logic = BasicInfoLogic();
    addTearDown(logic.dispose);

    final errors = logic.validateEnterprise(
      legalName: '',
      displayName: 'Anjali Jewellers',
      ownerName: 'Anjali Sharma',
      ownerPhone: '9876543210',
      ownerWa: '',
    );

    expect(errors, contains(BasicInfoStrings.keyLegalName));
    expect(
      BasicInfoValidators.businessHours(
        openTime: '10:00 AM',
        closeTime: '08:00 PM',
      ),
      isNull,
    );
    expect(
      BasicInfoValidators.businessHours(
        openTime: '08:00 PM',
        closeTime: '10:00 AM',
      ),
      isNotNull,
    );
  });

  test('address pincode must be exactly six digits', () {
    final logic = AddressFormLogic();
    addTearDown(logic.dispose);

    expect(
      logic.validateAddress(
        addr1: 'Main Road',
        addr2: '',
        city: 'Patna',
        state: 'Bihar',
        pin: '12345A',
      ),
      contains('keyPin'),
    );
    expect(
      logic.validateAddress(
        addr1: 'Main Road',
        addr2: '',
        city: 'Patna',
        state: 'Bihar',
        pin: '800001',
      ),
      isNot(contains('keyPin')),
    );
  });

  test('branding validators accept production contact formats', () {
    expect(BrandingValidators.validateOptionalPhone('919876543210'), isNull);
    expect(BrandingValidators.validateOptionalPhone('98765'), isNotNull);
    expect(
      BrandingValidators.validateOptionalEmail('support@lotus.jewelry'),
      isNull,
    );
    expect(
      BrandingValidators.validateOptionalWebsite('lotusjewellers.com'),
      isNull,
    );
    expect(BrandingValidators.validateOptionalWebsite('lotus'), isNotNull);
    expect(
      BrandingValidators.validateOptionalWhatsAppChannel(
        'whatsapp.com/channel/lotus',
      ),
      isNull,
    );
    expect(
      BrandingValidators.validateOptionalWhatsAppChannel(
        'telegram.com/channel/lotus',
      ),
      isNotNull,
    );
  });

  test('document logic identifies PDFs without image decoding', () {
    final logic = DocumentCropLogic();

    expect(logic.isPdfDocument(File('gst_certificate.PDF')), isTrue);
    expect(logic.isPdfDocument(File('gst_certificate.png')), isFalse);
  });
}

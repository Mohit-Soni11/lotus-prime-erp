import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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

    logic.webCtrl.text = 'lotus.example';
    logic.instaCtrl.text = '@lotus_jewellers';
    logic.fbCtrl.text = 'facebook.com/lotusjewellers';
    logic.ytCtrl.text = 'youtube.com/@lotusjewellers';
    logic.waChannelCtrl.text = 'whatsapp.com/channel/lotus';

    final model = logic.validateAndGenerateFinalModel();

    expect(model, isNotNull);
    expect(model!.website, 'lotus.example');
    expect(model.instagram, '@lotus_jewellers');
    expect(model.facebook, 'facebook.com/lotusjewellers');
    expect(model.youtube, 'youtube.com/@lotusjewellers');
    expect(model.whatsappChannel, 'whatsapp.com/channel/lotus');
    expect(logic.brandingData, model);
  });

  test('branding validation reports exact invalid fields and unlocks them', () {
    final logic = BrandingLogic();
    addTearDown(logic.dispose);

    logic.webCtrl.text = 'dsaascs';

    expect(logic.validateAndGenerateFinalModel(), isNull);

    expect(logic.isChannelsLocked, isFalse);
    expect(logic.lastValidationError, contains('Official Website'));
    expect(logic.lastValidationError, contains('lotusjewellers.com'));
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

  test('basic info validation requires legal name', () {
    final logic = BasicInfoLogic();
    addTearDown(logic.dispose);

    final errors = logic.validateEnterprise(
      legalName: '',
      displayName: 'Anjali Jewellers',
      ownerName: 'Anjali Sharma',
      ownerPhone: '9876543210',
    );

    expect(errors, contains(BasicInfoStrings.keyLegalName));
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

  test('branding validator accepts production website formats', () {
    expect(
      BrandingValidators.validateOptionalWebsite('lotusjewellers.com'),
      isNull,
    );
    expect(BrandingValidators.validateOptionalWebsite('lotus'), isNotNull);
    expect(BrandingValidators.validateOptionalHandleOrUrl('@lotus'), isNull);
    expect(
      BrandingValidators.validateOptionalHandleOrUrl('@lotus jewellery'),
      isNotNull,
    );
    expect(
      BrandingValidators.validateOptionalWhatsAppChannel(
        'whatsapp.com/channel/lotus',
      ),
      isNull,
    );
  });

  test('document logic identifies PDFs without image decoding', () {
    final logic = DocumentCropLogic();

    expect(logic.isPdfDocument(File('gst_certificate.PDF')), isTrue);
    expect(logic.isPdfDocument(File('gst_certificate.png')), isFalse);
  });
}

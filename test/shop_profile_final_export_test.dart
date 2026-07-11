import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/helpers/banking/banking_validators.dart';
import 'package:lotus_erp/logic/setting/shop_setup/tabs/branding/branding_logic.dart';
import 'package:lotus_erp/logic/setting/shop_setup/tabs/tax_gst/tax_gst_logic.dart';

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
}

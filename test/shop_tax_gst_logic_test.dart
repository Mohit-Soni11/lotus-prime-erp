import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/setting/shop_setup/tabs/tax_gst/tax_gst_logic.dart';
import 'package:lotus_erp/models/setting/shop_setup/enums/tax_gst_enums.dart';
import 'package:lotus_erp/models/setting/shop_setup/tabs/tax_gst_model.dart';

void main() {
  test('final GST model uses latest controller values without section save',
      () {
    final logic = TaxGstLogic();
    addTearDown(logic.dispose);

    logic.gstinCtrl.text = '27aabcu9603r1zm';
    logic.legalNameCtrl.text = '  Lotus Jewellers Pvt Ltd  ';
    logic.regDateCtrl.text = '05/07/2026';
    logic.selectedTaxpayer = TaxpayerType.composition;
    logic.bisLicCtrl.text = ' bis-reg-123 ';

    final model = logic.generateFinalModel();

    expect(model.gstin, '27AABCU9603R1ZM');
    expect(model.legalName, 'Lotus Jewellers Pvt Ltd');
    expect(model.taxpayerType, TaxpayerType.composition);
    expect(model.bisLicenseNo, 'BIS-REG-123');
    expect(model.goldBisLicenseNo, 'BIS-REG-123');
    expect(model.silverBisLicenseNo, 'BIS-REG-123');
    expect(logic.taxData, model);
  });

  test('BIS model serializes registration number without validity dates', () {
    const model = TaxGstModel(
      bisLicenseNo: 'BIS-REG-123',
      goldBisLicenseNo: 'BIS-REG-123',
      silverBisLicenseNo: 'BIS-REG-123',
    );

    final json = model.toJson();
    final restored = TaxGstModel.fromJson(json);

    expect(restored.bisLicenseNo, 'BIS-REG-123');
    expect(restored.goldBisLicenseNo, 'BIS-REG-123');
    expect(restored.silverBisLicenseNo, 'BIS-REG-123');
    expect(json.containsKey('bis_valid_from'), isFalse);
    expect(json.containsKey('bis_valid_upto'), isFalse);
  });

  test('legacy single BIS license loads as BIS registration fallback', () {
    final restored = TaxGstModel.fromJson(const {
      'bis_license_no': 'HM/C-LEGACY',
      'bis_valid_from': '01/07/2026',
    });

    expect(restored.goldBisLicenseNo, 'HM/C-LEGACY');
    expect(restored.silverBisLicenseNo, isEmpty);
    expect(restored.bisLicenseNo, 'HM/C-LEGACY');
  });

  test('taxpayer parser accepts enum names and stored display values', () {
    expect(TaxpayerType.fromString('Composition'), TaxpayerType.composition);
    expect(TaxpayerType.fromString('composition'), TaxpayerType.composition);
    expect(
      TaxpayerType.fromString(TaxpayerType.composition.toString()),
      TaxpayerType.composition,
    );
  });
}

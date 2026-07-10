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
    logic.goldBisLicCtrl.text = ' gold-bis-123 ';
    logic.silverBisLicCtrl.text = ' silver-bis-456 ';
    logic.validFromCtrl.text = '01/07/2026';
    logic.validUptoCtrl.text = '01/07/2027';

    final model = logic.generateFinalModel();

    expect(model.gstin, '27AABCU9603R1ZM');
    expect(model.legalName, 'Lotus Jewellers Pvt Ltd');
    expect(model.taxpayerType, TaxpayerType.composition);
    expect(model.goldBisLicenseNo, 'GOLD-BIS-123');
    expect(model.silverBisLicenseNo, 'SILVER-BIS-456');
    expect(
      model.bisLicenseNo,
      'Gold: GOLD-BIS-123 | Silver: SILVER-BIS-456',
    );
    expect(logic.taxData, model);
  });

  test('BIS model serializes gold and silver license scopes separately', () {
    const model = TaxGstModel(
      bisLicenseNo: 'Gold: HM/C-GOLD | Silver: HM/C-SILVER',
      goldBisLicenseNo: 'HM/C-GOLD',
      silverBisLicenseNo: 'HM/C-SILVER',
      bisValidFrom: '01/07/2026',
      bisValidUpto: '01/07/2027',
    );

    final restored = TaxGstModel.fromJson(model.toJson());

    expect(restored.goldBisLicenseNo, 'HM/C-GOLD');
    expect(restored.silverBisLicenseNo, 'HM/C-SILVER');
    expect(restored.bisLicenseNo, 'Gold: HM/C-GOLD | Silver: HM/C-SILVER');
  });

  test('legacy single BIS license loads as gold BIS fallback', () {
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

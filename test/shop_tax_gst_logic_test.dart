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
    logic.goldBisLicCtrl.text = ' bis-gold-123 ';
    logic.silverBisLicCtrl.text = ' bis-silver-456 ';

    final model = logic.generateFinalModel();

    expect(model.gstin, '27AABCU9603R1ZM');
    expect(model.legalName, 'Lotus Jewellers Pvt Ltd');
    expect(model.taxpayerType, TaxpayerType.composition);
    expect(model.bisLicenseNo, 'Gold: BIS-GOLD-123 | Silver: BIS-SILVER-456');
    expect(model.hallmarkingScope, HallmarkingScope.goldAndSilver);
    expect(model.goldBisLicenseNo, 'BIS-GOLD-123');
    expect(model.silverBisLicenseNo, 'BIS-SILVER-456');
    expect(logic.taxData, model);
  });

  test(
      'legacy BIS controller still fills both metals when metal fields are blank',
      () {
    final logic = TaxGstLogic();
    addTearDown(logic.dispose);

    logic.bisLicCtrl.text = ' bis-reg-123 ';

    final model = logic.generateFinalModel();

    expect(model.bisLicenseNo, 'BIS-REG-123');
    expect(model.hallmarkingScope, HallmarkingScope.goldAndSilver);
    expect(model.goldBisLicenseNo, 'BIS-REG-123');
    expect(model.silverBisLicenseNo, 'BIS-REG-123');
  });

  test('BIS model serializes registration number without validity dates', () {
    const model = TaxGstModel(
      bisLicenseNo: 'BIS-REG-123',
      hallmarkingScope: HallmarkingScope.goldAndSilver,
      goldBisLicenseNo: 'BIS-REG-123',
      silverBisLicenseNo: 'BIS-REG-123',
    );

    final json = model.toJson();
    final restored = TaxGstModel.fromJson(json);

    expect(restored.bisLicenseNo, 'BIS-REG-123');
    expect(restored.hallmarkingScope, HallmarkingScope.goldAndSilver);
    expect(json['hallmarking_scope'], 'Gold & Silver');
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
    expect(restored.silverBisLicenseNo, 'HM/C-LEGACY');
    expect(restored.bisLicenseNo, 'HM/C-LEGACY');
    expect(restored.hallmarkingScope, HallmarkingScope.goldAndSilver);
  });

  test('combined BIS registration restores separate gold and silver numbers',
      () {
    final restored = TaxGstModel.fromJson(const {
      'bis_license_no': 'Gold: HM/C-GOLD | Silver: HM/C-SILVER',
    });

    expect(restored.goldBisLicenseNo, 'HM/C-GOLD');
    expect(restored.silverBisLicenseNo, 'HM/C-SILVER');
    expect(restored.bisLicenseNo, 'Gold: HM/C-GOLD | Silver: HM/C-SILVER');
    expect(restored.hallmarkingScope, HallmarkingScope.goldAndSilver);
  });

  test('BIS scope controls legacy gold and silver compatibility fields', () {
    final logic = TaxGstLogic();
    addTearDown(logic.dispose);

    logic.bisLicCtrl.text = 'HM/C-SILVER';
    logic.setHallmarkingScope('Silver');

    final model = logic.generateFinalModel();

    expect(model.hallmarkingScope, HallmarkingScope.silver);
    expect(model.goldBisLicenseNo, isEmpty);
    expect(model.silverBisLicenseNo, 'HM/C-SILVER');
  });

  test('BIS metal toggles can add gold after silver-only scope', () {
    final logic = TaxGstLogic();
    addTearDown(logic.dispose);

    logic.setHallmarkingScope('Silver');
    expect(logic.selectedHallmarkingScope, HallmarkingScope.silver);

    logic.setHallmarkingMetal(
      metal: HallmarkingScope.gold,
      selected: true,
    );
    expect(logic.selectedHallmarkingScope, HallmarkingScope.goldAndSilver);

    logic.setHallmarkingMetal(
      metal: HallmarkingScope.silver,
      selected: false,
    );
    expect(logic.selectedHallmarkingScope, HallmarkingScope.gold);

    logic.setHallmarkingMetal(
      metal: HallmarkingScope.gold,
      selected: false,
    );
    expect(logic.selectedHallmarkingScope, HallmarkingScope.gold);
  });

  test('taxpayer parser accepts enum names and stored display values', () {
    expect(TaxpayerType.fromString('Composition'), TaxpayerType.composition);
    expect(TaxpayerType.fromString('composition'), TaxpayerType.composition);
    expect(
      TaxpayerType.fromString(TaxpayerType.composition.toString()),
      TaxpayerType.composition,
    );
  });

  test('hallmarking scope parser accepts common stored values', () {
    expect(HallmarkingScope.fromString('Gold'), HallmarkingScope.gold);
    expect(HallmarkingScope.fromString('Silver'), HallmarkingScope.silver);
    expect(HallmarkingScope.fromString('both'), HallmarkingScope.goldAndSilver);
    expect(
      HallmarkingScope.fromString('Gold and Silver'),
      HallmarkingScope.goldAndSilver,
    );
  });
}

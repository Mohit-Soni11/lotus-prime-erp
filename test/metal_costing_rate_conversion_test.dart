import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/setting/metal_costing/metal_costing_controller.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'package:lotus_erp/repositories/setting/metal_rate/metal_rate_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cost analyser reads silver kg rate as the correct per-100g rate',
      () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final rateRepository = MetalRateRepository(db: database);
    final silver = await rateRepository.loadProfile(MetalRateMetal.silver);
    await rateRepository.saveProfile(silver.copyWith(
      physicalMarketRatePer10g: 175000,
      purityPlans: [
        for (final plan in silver.purityPlans)
          plan.label == '999'
              ? plan.copyWith(manualDisplayRatePer10g: 175000)
              : plan,
      ],
    ));

    final controller = MetalCostingController(
      db: database,
      rateRepository: rateRepository,
    );
    addTearDown(controller.dispose);
    await controller.loadData();

    expect(controller.state, MetalCostingState.loaded);
    expect(controller.todayRates['silver'], 17500);
  });
}

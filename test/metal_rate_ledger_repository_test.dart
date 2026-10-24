import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/live_rates/live_rates_model.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'package:lotus_erp/repositories/live_rates/live_rates_repository.dart';
import 'package:lotus_erp/repositories/setting/metal_rate/metal_rate_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late MetalRateRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = MetalRateRepository(db: database);
  });

  tearDown(() => database.close());

  test('imports an existing daily rate into the authoritative ledger',
      () async {
    await database.into(database.dailyRates).insert(
          DailyRatesCompanion.insert(
            rateDate: DateTime(2026, 10, 24),
            gold24k: const Value('75000'),
            gold22k: const Value('68700'),
            gold18k: const Value('56250'),
            oldGold24kBuy: const Value('73500'),
            oldGold22kBuy: const Value('67100'),
            oldGold18kBuy: const Value('54800'),
            silverRateKg: const Value('950000'),
            silverJewellery: const Value('8750'),
            silverIdols: const Value('9500'),
            oldSilverBuy: const Value('9100'),
            source: const Value('Legacy Counter'),
          ),
        );

    final gold = await repository.loadProfile(MetalRateMetal.gold);
    final silver = await repository.loadProfile(MetalRateMetal.silver);

    expect(gold.primaryShopRatePer10g, 75000);
    expect(gold.primaryBuyRatePer10g, 73500);
    expect(silver.primaryShopRatePer10g, 9500);
    expect(silver.primaryBuyRatePer10g, 9100);
    expect((await database.select(database.metalRateProfiles).get()).length, 4);
  });

  test(
      'writes current profile and immutable revision in one ledger transaction',
      () async {
    final initial = await repository.loadProfile(MetalRateMetal.gold);
    final updated = initial.copyWith(
      physicalMarketRatePer10g: 76000,
      marketRatePer10g: 76000,
    );

    await repository.saveProfile(updated, changeReason: 'Morning rate update');

    final current = await repository.loadProfile(MetalRateMetal.gold);
    final history = await repository.loadHistory(MetalRateMetal.gold);
    final record = await (database.select(database.metalRateProfiles)
          ..where((row) => row.metalKey.equals('gold')))
        .getSingle();

    expect(current.marketBaseRatePer10g, 76000);
    expect(record.revision, 2);
    expect(history, hasLength(2));
    expect(history.first.profile.marketBaseRatePer10g, 76000);
  });

  test('dashboard reports an explicit missing state instead of demo prices',
      () async {
    final result = await LiveRatesRepository(repository: repository)
        .watchRates()
        .firstWhere((rate) => rate.state != LiveRateState.loading);

    expect(result.state, LiveRateState.missing);
    expect(result.gold24k, '--');
    expect(result.message, isNotEmpty);
  });

  test('dashboard projects configured ledger profiles', () async {
    final gold = (await repository.loadProfile(MetalRateMetal.gold)).copyWith(
      physicalMarketRatePer10g: 75000,
      marketRatePer10g: 75000,
    );
    final silver =
        (await repository.loadProfile(MetalRateMetal.silver)).copyWith(
      physicalMarketRatePer10g: 9500,
      marketRatePer10g: 9500,
    );
    await repository.saveProfile(gold);
    await repository.saveProfile(silver);

    final result = await LiveRatesRepository(repository: repository)
        .watchRates()
        .firstWhere((rate) => rate.state != LiveRateState.loading);

    expect(result.state, LiveRateState.available);
    expect(result.gold24k, '74,925');
    expect(result.silverRateKg, isNot('--'));
  });
}

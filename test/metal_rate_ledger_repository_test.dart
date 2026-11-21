import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/live_rates/live_rates_model.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'package:lotus_erp/repositories/live_rates/live_rates_repository.dart';
import 'package:lotus_erp/repositories/setting/metal_rate/metal_rate_repository.dart';
import 'package:lotus_erp/repositories/setting/metal_rate/metal_rate_quote_service.dart';

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
    expect(silver.primaryShopRatePer10g, 950000);
    expect(silver.primaryBuyRatePer10g, 910000);
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
    expect(history.first.revision, record.revision);
  });

  test('year history includes every revision and one earlier baseline',
      () async {
    final profile = await repository.loadProfile(MetalRateMetal.gold);
    final payload = jsonEncode(profile.toJson());
    await database.into(database.metalRateRevisions).insert(
          MetalRateRevisionsCompanion.insert(
            metalKey: 'gold',
            revision: 2,
            profileJson: payload,
            source: 'Test',
            effectiveAt: DateTime(2025, 12, 31),
          ),
        );
    for (var index = 0; index < 30; index++) {
      await database.into(database.metalRateRevisions).insert(
            MetalRateRevisionsCompanion.insert(
              metalKey: 'gold',
              revision: index + 3,
              profileJson: payload,
              source: 'Test',
              effectiveAt: DateTime(2026, 1, 1).add(Duration(days: index)),
            ),
          );
    }

    final history = await repository.loadHistory(
      MetalRateMetal.gold,
      from: DateTime(2026),
    );
    expect(history, hasLength(32));
    expect(history.first.changedAt, DateTime(2026, 1, 30));
    expect(history.last.changedAt, DateTime(2025, 12, 31));
  });

  test('dashboard reports an explicit missing state instead of demo prices',
      () async {
    final result = await LiveRatesRepository(repository: repository)
        .watchRates()
        .firstWhere((rate) => rate.state != LiveRateState.loading);

    expect(result.state, LiveRateState.missing);
    expect(result.goldRates, isEmpty);
    expect(result.message, isNotEmpty);
  });

  test('dashboard projects configured ledger profiles', () async {
    final gold = (await repository.loadProfile(MetalRateMetal.gold)).copyWith(
      physicalMarketRatePer10g: 75000,
      marketRatePer10g: 75000,
    );
    final silver =
        (await repository.loadProfile(MetalRateMetal.silver)).copyWith(
      physicalMarketRatePer10g: 950000,
      marketRatePer10g: 950000,
    );
    await repository.saveProfile(gold);
    await repository.saveProfile(silver);

    final result = await LiveRatesRepository(repository: repository)
        .watchRates()
        .firstWhere((rate) => rate.state != LiveRateState.loading);

    expect(result.state, LiveRateState.available);
    expect(result.goldRates, hasLength(5));
    expect(result.silverRates, hasLength(4));
    expect(result.goldRates.first.perBaseUnit, '75,000');
    expect(result.goldRates.first.perGram, '7,500');
    expect(result.silverRates.first.perGram, '950');
    expect(result.silverRates.first.perBaseUnit, '9,50,000');
    expect(result.silverRates[1].perBaseUnit, '8,78,750');
  });

  test('dashboard includes an extra purity even when primary rates are unset',
      () async {
    final gold = await repository.loadProfile(MetalRateMetal.gold);
    await repository.saveProfile(gold.copyWith(
      purityPlans: [
        for (final plan in gold.purityPlans)
          plan.label == '14K'
              ? plan.copyWith(manualDisplayRatePer10g: 89000)
              : plan,
      ],
    ));

    final result = await LiveRatesRepository(repository: repository)
        .watchRates()
        .firstWhere((rate) => rate.state != LiveRateState.loading);

    expect(result.state, LiveRateState.available);
    expect(result.goldRates[3].purity, '14K');
    expect(result.goldRates[3].perBaseUnit, '89,000');
    expect(result.goldRates.first.perBaseUnit, '--');
  });

  test('dashboard follows saved counter selling rates without a restart',
      () async {
    final gold = await repository.loadProfile(MetalRateMetal.gold);
    final silver = await repository.loadProfile(MetalRateMetal.silver);
    await repository.saveProfile(gold.copyWith(
      physicalMarketRatePer10g: 139000,
      purityPlans: [
        for (final plan in gold.purityPlans)
          plan.label == '22K'
              ? plan.copyWith(manualDisplayRatePer10g: 132050)
              : plan,
      ],
    ));
    await repository.saveProfile(silver.copyWith(
      physicalMarketRatePer10g: 175000,
      purityPlans: [
        for (final plan in silver.purityPlans)
          plan.label == '925'
              ? plan.copyWith(manualDisplayRatePer10g: 165000)
              : plan,
      ],
    ));

    final stream = StreamIterator(
      LiveRatesRepository(repository: repository).watchRates(),
    );
    addTearDown(stream.cancel);
    expect(await stream.moveNext(), isTrue);
    expect(stream.current.state, LiveRateState.loading);
    expect(await stream.moveNext(), isTrue);
    expect(stream.current.goldRates[1].perBaseUnit, '1,32,050');
    expect(stream.current.silverRates[1].perBaseUnit, '1,65,000');

    final latestGold = await repository.loadProfile(MetalRateMetal.gold);
    await repository.saveProfile(latestGold.copyWith(
      purityPlans: [
        for (final plan in latestGold.purityPlans)
          plan.label == '22K'
              ? plan.copyWith(manualDisplayRatePer10g: 134000)
              : plan,
      ],
    ));

    expect(await stream.moveNext().timeout(const Duration(seconds: 5)), isTrue);
    expect(stream.current.goldRates[1].perBaseUnit, '1,34,000');
    expect(stream.current.silverRates[1].perBaseUnit, '1,65,000');

    final latestSilver = await repository.loadProfile(MetalRateMetal.silver);
    await repository.saveProfile(latestSilver.copyWith(
      purityPlans: [
        for (final plan in latestSilver.purityPlans)
          plan.label == '925'
              ? plan.copyWith(manualDisplayRatePer10g: 168000)
              : plan,
      ],
    ));

    expect(await stream.moveNext().timeout(const Duration(seconds: 5)), isTrue);
    expect(stream.current.goldRates[1].perBaseUnit, '1,34,000');
    expect(stream.current.silverRates[1].perBaseUnit, '1,68,000');
  });

  test('one saved old-metal rate applies to every gold purity', () async {
    final initial = await repository.loadProfile(MetalRateMetal.gold);
    final savedProfile = initial.copyWith(
      physicalMarketRatePer10g: 139000,
      oldMetalPurchaseRatePer10g: 125000,
      purityPlans: [
        for (final plan in initial.purityPlans)
          plan.copyWith(
            buyRatePer10g: plan.label == '24K' ? 150000 : 145000,
          ),
      ],
    );
    await repository.saveProfile(savedProfile);
    final silver = await repository.loadProfile(MetalRateMetal.silver);
    await repository.saveProfile(silver.copyWith(
      oldMetalPurchaseRatePer10g: 120000,
    ));

    final reloaded = await repository.loadProfile(MetalRateMetal.gold);
    expect(reloaded.marketParityRateFor(reloaded.purityPlans.first), 139000);
    expect(reloaded.primaryBuyRatePer10g, 125000);
    final quotes = MetalRateQuoteService(repository: repository);
    for (final purity in ['24K', '22K', '18K', '14K', '9K']) {
      final quote = await quotes.buyingQuote(
        metal: MetalRateMetal.gold,
        purityLabel: purity,
      );
      expect(quote?.ratePer10g, 125000, reason: purity);
      expect(quote?.billingRate, 12500, reason: purity);
    }
    final dashboard = await LiveRatesRepository(repository: repository)
        .watchRates()
        .firstWhere((rates) => rates.state != LiveRateState.loading);
    expect(dashboard.oldGoldBuy, '1,25,000');
    expect(dashboard.oldSilverBuy, '1,20,000');
  });

  test('partial ledger restores missing metals without changing saved rates',
      () async {
    final gold = MetalRateProfile.defaultFor(MetalRateMetal.gold)
        .copyWith(physicalMarketRatePer10g: 139000);
    await database.into(database.metalRateProfiles).insert(
          MetalRateProfilesCompanion.insert(
            metalKey: 'gold',
            profileJson: jsonEncode(gold.toJson()),
            revision: const Value(4),
          ),
        );

    final profiles = await repository.loadProfiles();
    expect(profiles, hasLength(4));
    expect(profiles.first.marketBaseRatePer10g, 139000);
    expect(
        await database.select(database.metalRateProfiles).get(), hasLength(4));
    final saved = await (database.select(database.metalRateProfiles)
          ..where((row) => row.metalKey.equals('gold')))
        .getSingle();
    expect(saved.revision, 4);
  });

  test('corrupt rate payload is reported instead of replaced with defaults',
      () async {
    await database.into(database.metalRateProfiles).insert(
          MetalRateProfilesCompanion.insert(
            metalKey: 'gold',
            profileJson: '{invalid-json',
          ),
        );

    await expectLater(repository.loadProfiles(), throwsFormatException);
    expect(
        await database.select(database.metalRateProfiles).get(), hasLength(1));
  });

  test('mismatched metal identity cannot overwrite another profile', () async {
    final gold = MetalRateProfile.defaultFor(MetalRateMetal.gold);
    await database.into(database.metalRateProfiles).insert(
          MetalRateProfilesCompanion.insert(
            metalKey: 'silver',
            profileJson: jsonEncode(gold.toJson()),
          ),
        );

    await expectLater(repository.loadProfiles(), throwsFormatException);
  });
}

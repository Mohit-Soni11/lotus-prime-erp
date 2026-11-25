import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/business_day/application/business_day_exit_service.dart';
import 'package:lotus_erp/features/business_day/data/business_day_repository.dart';
import 'package:lotus_erp/features/finance/ledger/data/finance_day_closure_repository.dart';
import 'package:lotus_erp/features/notifications/data/business_day_alert_repository.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'package:lotus_erp/repositories/reports/day_book_balance_verification_repository.dart';

void main() {
  late AppDatabase db;
  late BusinessDayRepository repo;
  final today = DateTime(2026, 11, 20, 9);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BusinessDayRepository(db);
  });
  tearDown(() => db.close());

  Future<void> verify(DateTime day, {double openingCash = 0}) async {
    await DayBookBalanceVerificationRepository(db).verify(
      date: day,
      expectedCash: openingCash,
      actualCash: openingCash,
      expectedBank: 0,
      actualBank: 0,
      verifiedBy: 'test-owner',
    );
  }

  Future<void> close(DateTime day, {double closingCash = 0}) async {
    expect(
        await FinanceDayClosureRepository(db).closeDay(day,
            closingCash: closingCash,
            physicalBank: 0,
            closedBy: 'test-owner',
            requireVerifiedOpening: true),
        isTrue);
  }

  Future<void> saveRate(String metal, DateTime time, int revision,
      {String? reason}) async {
    final profile = MetalRateProfile.defaultFor(MetalRateMetalX.fromKey(metal))
        .copyWith(physicalMarketRatePer10g: 75000, marketRatePer10g: 75000);
    await db.into(db.metalRateRevisions).insert(
          MetalRateRevisionsCompanion.insert(
            metalKey: metal,
            revision: revision,
            profileJson: jsonEncode(profile.toJson()),
            source: 'Manual',
            changeReason: drift.Value(reason),
            effectiveAt: time,
          ),
        );
  }

  test('startup tasks persist across reopening and clear only after completion',
      () async {
    final alerts = BusinessDayAlertRepository(db);
    final initial = await alerts.load(today);
    expect(
        initial.map((a) => a.key),
        containsAll([
          'business:opening:20261120',
          'business:rates:20261120',
        ]));
    expect(await BusinessDayRepository(db).activeDay(today),
        DateTime(2026, 11, 20));
    await verify(today);
    await saveRate('gold', today, 1);
    expect(await repo.pendingRateMetals(today), ['silver']);
    await saveRate('silver', today, 1);
    expect(await alerts.load(today), isEmpty);
    expect(await alerts.load(DateTime(2026, 11, 20, 15)), isEmpty);
  });

  test('migration, defaults and yesterday rates do not clear today reminder',
      () async {
    await saveRate('gold', DateTime(2026, 11, 19), 1);
    await saveRate('gold', today, 2, reason: 'Migrated to rate ledger');
    await saveRate('silver', today, 1, reason: 'Restored default profile');
    expect(await repo.pendingRateMetals(today), ['gold', 'silver']);
    await saveRate('gold', DateTime(2026, 11, 20, 10), 3);
    expect(await repo.pendingRateMetals(today), ['silver']);
    expect(await repo.pendingRateMetals(DateTime(2026, 11, 21)),
        ['gold', 'silver']);
  });

  test('temporary close and next-day startup retain unfinished business day',
      () async {
    await repo.activeDay(today);
    await db.into(db.cashTransactions).insert(
          CashTransactionsCompanion.insert(
            txnId: 'OPEN-DAY-RECEIPT',
            txnDate: today,
            type: 'INCOME',
            category: 'GOLD_REPAIR_INCOME',
            amount: const drift.Value(100),
            paymentMode: const drift.Value('CASH'),
          ),
        );
    final tomorrow = DateTime(2026, 11, 21, 8);
    expect(await BusinessDayRepository(db).activeDay(tomorrow),
        DateTime(2026, 11, 20));
    final alerts = await BusinessDayAlertRepository(db).load(tomorrow);
    expect(alerts.any((a) => a.key == 'business:unfinished:20261120'), isTrue);
    await verify(today);
    await close(today, closingCash: 100);
    expect(await repo.activeDay(tomorrow), DateTime(2026, 11, 21));
    expect(await repo.openingVerified(tomorrow), isFalse);
  });

  test('empty historical app sessions do not block exit after today closes',
      () async {
    for (final day in [21, 22, 23, 24]) {
      await repo.activeDay(DateTime(2026, 11, day, 9));
    }
    final closingDay = DateTime(2026, 11, 24, 18);
    expect(await repo.pendingDays(closingDay), [DateTime(2026, 11, 24)]);
    await verify(closingDay);
    await close(closingDay);

    var exited = false;
    final result = await BusinessDayExitService(repo).requestExit(
      now: closingDay,
      openClosing: (_) async => fail('No closing should reopen'),
      exitApplication: () async => exited = true,
    );
    expect(result, isTrue);
    expect(exited, isTrue);
    expect(await repo.pendingDays(closingDay), isEmpty);
  });

  test('backdated business activity restores a historical closing requirement',
      () async {
    final oldDay = DateTime(2026, 11, 21, 9);
    final today = DateTime(2026, 11, 24, 18);
    await repo.activeDay(oldDay);
    await repo.activeDay(today);
    expect(await repo.pendingDays(today), [DateTime(2026, 11, 24)]);

    await db.into(db.cashTransactions).insert(
          CashTransactionsCompanion.insert(
            txnId: 'LATE-POSTED-RECEIPT',
            txnDate: oldDay,
            type: 'INCOME',
            category: 'GOLD_REPAIR_INCOME',
            amount: const drift.Value(100),
            paymentMode: const drift.Value('CASH'),
          ),
        );
    expect(await repo.pendingDays(today),
        [DateTime(2026, 11, 21), DateTime(2026, 11, 24)]);
  });

  test('day closed at 3pm remains closed when app reopens the same date',
      () async {
    await repo.activeDay(today);
    await verify(today);
    await close(today);
    expect(await repo.isClosed(DateTime(2026, 11, 20, 15)), isTrue);
    expect(
        await BusinessDayAlertRepository(db).load(DateTime(2026, 11, 20, 16)),
        isEmpty);
  });

  test('Exit Application cancellation cannot terminate an open day', () async {
    var exited = false;
    var prompted = false;
    final result = await BusinessDayExitService(repo).requestExit(
      now: DateTime(2026, 11, 20, 15),
      openClosing: (day) async {
        prompted = true;
      },
      exitApplication: () async {
        exited = true;
      },
    );
    expect(prompted, isTrue);
    expect(result, isFalse);
    expect(exited, isFalse);
    expect(await repo.isClosed(today), isFalse);
    final pending = await BusinessDayAlertRepository(db).load(today);
    expect(pending.any((alert) => alert.key == 'business:closing:20261120'),
        isTrue);
    expect(await BusinessDayRepository(db).closingRequested(today), isTrue);
  });

  test('exit after midnight closes all opened days before terminating',
      () async {
    await repo.activeDay(today);
    await db.into(db.cashTransactions).insert(
          CashTransactionsCompanion.insert(
            txnId: 'PREVIOUS-DAY-RECEIPT',
            txnDate: today,
            type: 'INCOME',
            category: 'GOLD_REPAIR_INCOME',
            amount: const drift.Value(100),
            paymentMode: const drift.Value('CASH'),
          ),
        );
    final nextDay = DateTime(2026, 11, 21, 1);
    final closedDays = <DateTime>[];
    var exited = false;
    await BusinessDayExitService(repo).requestExit(
      now: nextDay,
      openClosing: (day) async {
        closedDays.add(day);
        await verify(day,
            openingCash: day.day == nextDay.day ? 100 : 0);
        await close(day, closingCash: 100);
      },
      exitApplication: () async {
        exited = true;
      },
    );
    expect(closedDays, [DateTime(2026, 11, 20), DateTime(2026, 11, 21)]);
    expect(exited, isTrue);
    expect(await repo.pendingDays(nextDay), isEmpty);
  });

  test('Exit Application exits only after persisted verified closing',
      () async {
    var exited = false;
    final service = BusinessDayExitService(repo);
    expect(
        await service.requestExit(
          now: DateTime(2026, 11, 20, 12),
          openClosing: (day) async {
            await verify(day);
            await close(day);
          },
          exitApplication: () async {
            exited = true;
          },
        ),
        isTrue);
    expect(exited, isTrue);
    expect(
        await service.requestExit(
          now: DateTime(2026, 11, 20, 15),
          openClosing: (_) async {
            fail('Closed day must not ask for another count');
          },
          exitApplication: () async {},
        ),
        isTrue);
  });
}

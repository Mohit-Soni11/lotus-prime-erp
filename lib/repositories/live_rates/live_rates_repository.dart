import 'dart:async';

import 'package:drift/drift.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import '../../models/live_rates/live_rates_model.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

class LiveRatesRepository {
  final AppDatabase _db = AppDatabase();

  final _ratesController = StreamController<LiveRatesModel>.broadcast();
  StreamSubscription<DailyRate?>? _dailyRateSub;

  Stream<LiveRatesModel> get ratesStream => _ratesController.stream;

  void init() {
    _watchTodayRates();
  }

  void _watchTodayRates() {
    _dailyRateSub?.cancel();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = _db.select(_db.dailyRates)
      ..where((r) => r.rateDate.isSmallerThanValue(endOfDay))
      ..orderBy([
        (r) => OrderingTerm.desc(r.rateDate),
        (r) => OrderingTerm.desc(r.updatedAt),
      ])
      ..limit(1);

    _dailyRateSub = query.watchSingleOrNull().listen(
      _emitRate,
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.debug('LiveRatesRepository error: $error');
        if (!_ratesController.isClosed) {
          _ratesController.add(LiveRatesModel.demo);
        }
      },
    );
  }

  Future<void> _fetchTodayRates() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final rate = await (_db.select(_db.dailyRates)
          ..where((r) => r.rateDate.isSmallerThanValue(endOfDay))
          ..orderBy([
            (r) => OrderingTerm.desc(r.rateDate),
            (r) => OrderingTerm.desc(r.updatedAt),
          ])
          ..limit(1))
        .getSingleOrNull();
    _emitRate(rate);
  }

  void _emitRate(DailyRate? rate) {
    if (_ratesController.isClosed) {
      return;
    }

    if (rate == null) {
      _ratesController.add(LiveRatesModel.demo);
      return;
    }

    _ratesController.add(
      LiveRatesModel(
        gold24k: _formatRate(rate.gold24k),
        gold22k: _formatRate(rate.gold22k),
        gold18k: _formatRate(rate.gold18k),
        goldChangePercent: rate.goldChangePercent,
        goldIsUp: !rate.goldChangePercent.startsWith('-'),
        silverRateKg: _formatRate(rate.silverRateKg),
        silverJewellery: _formatRate(rate.silverJewellery),
        silverIdols: _formatRate(rate.silverIdols),
        silverChangePercent: rate.silverChangePercent,
        silverIsUp: !rate.silverChangePercent.startsWith('-'),
        oldGold24kBuy: _formatRate(rate.oldGold24kBuy),
        oldGold22kBuy: _formatRate(rate.oldGold22kBuy),
        oldGold18kBuy: _formatRate(rate.oldGold18kBuy),
        oldSilverBuy: _formatRate(rate.oldSilverBuy),
        rateDate: rate.updatedAt ?? rate.rateDate,
        source: rate.source,
        isFromDb: true,
      ),
    );
  }

  Future<void> saveRate(LiveRatesModel model) async {
    try {
      final today = DateTime.now();
      final rateDate = DateTime(today.year, today.month, today.day);

      await _db.customUpdate(
        '''
        INSERT INTO "daily_rates" (
          "rate_date",
          "gold24k",
          "gold22k",
          "gold18k",
          "gold_change_percent",
          "silver_rate_kg",
          "silver_jewellery",
          "silver_idols",
          "silver_change_percent",
          "old_gold24k_buy",
          "old_gold22k_buy",
          "old_gold18k_buy",
          "old_silver_buy",
          "source",
          "updated_at"
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT("rate_date") DO UPDATE SET
          "gold24k" = excluded."gold24k",
          "gold22k" = excluded."gold22k",
          "gold18k" = excluded."gold18k",
          "gold_change_percent" = excluded."gold_change_percent",
          "silver_rate_kg" = excluded."silver_rate_kg",
          "silver_jewellery" = excluded."silver_jewellery",
          "silver_idols" = excluded."silver_idols",
          "silver_change_percent" = excluded."silver_change_percent",
          "old_gold24k_buy" = excluded."old_gold24k_buy",
          "old_gold22k_buy" = excluded."old_gold22k_buy",
          "old_gold18k_buy" = excluded."old_gold18k_buy",
          "old_silver_buy" = excluded."old_silver_buy",
          "source" = excluded."source",
          "updated_at" = excluded."updated_at"
        ''',
        variables: [
          Variable.withDateTime(rateDate),
          Variable.withString(model.gold24k.replaceAll(',', '')),
          Variable.withString(model.gold22k.replaceAll(',', '')),
          Variable.withString(model.gold18k.replaceAll(',', '')),
          Variable.withString(model.goldChangePercent),
          Variable.withString(model.silverRateKg.replaceAll(',', '')),
          Variable.withString(model.silverJewellery.replaceAll(',', '')),
          Variable.withString(model.silverIdols.replaceAll(',', '')),
          Variable.withString(model.silverChangePercent),
          Variable.withString(model.oldGold24kBuy.replaceAll(',', '')),
          Variable.withString(model.oldGold22kBuy.replaceAll(',', '')),
          Variable.withString(model.oldGold18kBuy.replaceAll(',', '')),
          Variable.withString(model.oldSilverBuy.replaceAll(',', '')),
          Variable.withString('Manual'),
          Variable.withDateTime(DateTime.now()),
        ],
        updates: {_db.dailyRates},
      );
      await _fetchTodayRates();
      AppLogger.debug('Rates saved successfully.');
    } catch (e) {
      AppLogger.debug('Error saving rates: $e');
    }
  }

  String _formatRate(String raw) {
    try {
      final value = double.parse(raw.replaceAll(',', '').trim());
      if (value == 0) {
        return '--';
      }
      final rounded = value.toStringAsFixed(0);
      return rounded.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{2})+\d$)'),
        (match) => '${match[1]},',
      );
    } catch (_) {
      return raw;
    }
  }

  void dispose() {
    _dailyRateSub?.cancel();
    _ratesController.close();
  }
}
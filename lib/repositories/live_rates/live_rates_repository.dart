import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../../database/db/app_database.dart';
import '../../models/live_rates/live_rates_model.dart';

// ============================================================
// 🗄️ LIVE RATES REPOSITORY
// Database se rates fetch karta hai.
// Future mein Settings screen se rate save hone par
// ye automatically stream update karega.
// ============================================================

class LiveRatesRepository {
  final AppDatabase _db = AppDatabase();

  // Stream Controller — UI ko real-time update milta hai
  final _ratesController = StreamController<LiveRatesModel>.broadcast();

  Stream<LiveRatesModel> get ratesStream => _ratesController.stream;

  // ✅ Init — Aaj ka rate load karo
  void init() {
    _fetchTodayRates();
  }

  Future<void> _fetchTodayRates() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Today's rate dhundo
      final rate = await (_db.select(_db.dailyRates)
            ..where((r) =>
                r.rateDate.isBetweenValues(startOfDay, endOfDay))
            ..limit(1))
          .getSingleOrNull();

      if (rate != null) {
        // DB mein data mila
        _ratesController.add(LiveRatesModel(
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
          rateDate: rate.rateDate,
          source: rate.source,
          isFromDb: true,
        ));
      } else {
        // No rate set today — show demo
        _ratesController.add(LiveRatesModel.demo);
        debugPrint('⚠️ No rates for today. Showing demo data. Set rates in Settings.');
      }
    } catch (e) {
      debugPrint('❌ LiveRatesRepository error: $e');
      _ratesController.add(LiveRatesModel.demo);
    }
  }

  // ✅ Save Rate (Settings screen se call hoga future mein)
  Future<void> saveRate(LiveRatesModel model) async {
    try {
      final today = DateTime.now();
      final rateDate = DateTime(today.year, today.month, today.day);

      await _db.into(_db.dailyRates).insertOnConflictUpdate(
        DailyRatesCompanion(
          rateDate: Value(rateDate),
          gold24k: Value(model.gold24k.replaceAll(',', '')),
          gold22k: Value(model.gold22k.replaceAll(',', '')),
          gold18k: Value(model.gold18k.replaceAll(',', '')),
          goldChangePercent: Value(model.goldChangePercent),
          silverRateKg: Value(model.silverRateKg.replaceAll(',', '')),
          silverJewellery: Value(model.silverJewellery.replaceAll(',', '')),
          silverIdols: Value(model.silverIdols.replaceAll(',', '')),
          silverChangePercent: Value(model.silverChangePercent),
          oldGold24kBuy: Value(model.oldGold24kBuy.replaceAll(',', '')),
          oldGold22kBuy: Value(model.oldGold22kBuy.replaceAll(',', '')),
          oldGold18kBuy: Value(model.oldGold18kBuy.replaceAll(',', '')),
          oldSilverBuy: Value(model.oldSilverBuy.replaceAll(',', '')),
          source: const Value('Manual'),
        ),
      );
      // Stream ko refresh karo
      await _fetchTodayRates();
      debugPrint('✅ Rates saved successfully!');
    } catch (e) {
      debugPrint('❌ Error saving rates: $e');
    }
  }

  // Helper: "72500" → "72,500"
  String _formatRate(String raw) {
    try {
      final num = double.parse(raw);
      if (num == 0) return '--';
      final parts = num.toStringAsFixed(0).split('');
      final result = StringBuffer();
      for (int i = 0; i < parts.length; i++) {
        if (i > 0 && (parts.length - i) % 3 == 0) result.write(',');
        result.write(parts[i]);
      }
      return result.toString();
    } catch (_) {
      return raw;
    }
  }

  void dispose() {
    _ratesController.close();
  }
}
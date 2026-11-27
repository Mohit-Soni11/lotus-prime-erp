import 'dart:async';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/dashboard/shared/dashboard_day.dart';
import 'package:lotus_erp/models/dashboard/daily_counter_model.dart';
import 'package:lotus_erp/repositories/dashboard/daily_counter_finance_repository.dart';
import 'package:lotus_erp/repositories/dashboard/daily_counter_metal_repository.dart';

class DailyCounterLogic {
  final AppDatabase _db;
  late final DailyCounterMetalRepository _metalRepository;
  late final DailyCounterFinanceRepository _financeRepository;

  DailyCounterLogic({AppDatabase? db}) : _db = db ?? AppDatabase() {
    _metalRepository = DailyCounterMetalRepository(_db);
    _financeRepository = DailyCounterFinanceRepository(_db);
  }

  final _controller = StreamController<DailyCounterModel>.broadcast();
  Stream<DailyCounterModel> get dataStream => _controller.stream;
  final _subscriptions = <StreamSubscription>[];
  Timer? _rolloverTimer;
  Timer? _purchaseRefreshTimer;
  DashboardDay? _day;
  int _refreshVersion = 0;
  bool _started = false;

  void init() {
    if (_started) return;
    _started = true;
    _watchCurrentDay();
  }

  void _watchCurrentDay() {
    final day = DashboardDay(DateTime.now());
    _day = day;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    for (final table in [
      _db.bills.actualTableName,
      _db.billItems.actualTableName,
      _db.billTradeInItems.actualTableName,
      _db.girviLoans.actualTableName,
    ]) {
      _subscriptions.add(
        _db.tableUpdates(TableUpdateQuery.onTableName(table)).listen(
              (_) => _refresh(day),
              onError: (Object error) =>
                  AppLogger.debug('Daily counter $table update failed: $error'),
            ),
      );
    }

    _refresh(day);
    // Customer purchase vouchers use legacy raw SQL tables without Drift change
    // notifications. Refresh those totals while the dashboard is visible.
    _purchaseRefreshTimer?.cancel();
    _purchaseRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refresh(day),
    );
    _rolloverTimer?.cancel();
    _rolloverTimer =
        Timer(day.end.difference(DateTime.now()), _watchCurrentDay);
  }

  Future<void> _refresh(DashboardDay day) async {
    final version = ++_refreshVersion;
    try {
      final (metal, finance) = await (
        _metalRepository.load(day),
        _financeRepository.load(day),
      ).wait;
      if (_controller.isClosed ||
          version != _refreshVersion ||
          !identical(_day, day)) {
        return;
      }
      _controller.add(DailyCounterModel(
        dateStr: DateFormat('MMM dd, yyyy').format(day.start),
        metalMovement: metal,
        financeDue: finance,
      ));
    } catch (error, stack) {
      AppLogger.error('Daily counter refresh failed',
          error: error, stackTrace: stack);
      if (!_controller.isClosed && version == _refreshVersion) {
        _controller.addError(error, stack);
      }
    }
  }

  DailyCounterModel get initialData => DailyCounterModel.loading();

  void dispose() {
    _rolloverTimer?.cancel();
    _purchaseRefreshTimer?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _controller.close();
  }
}

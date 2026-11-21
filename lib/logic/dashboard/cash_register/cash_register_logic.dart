import 'dart:async';

import 'package:intl/intl.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/dashboard/shared/dashboard_day.dart';
import 'package:lotus_erp/models/dashboard/cash_register_model.dart';
import 'package:lotus_erp/repositories/dashboard/cash_register_repository.dart';

class CashRegisterLogic {
  final CashRegisterRepository _repository;
  CashRegisterLogic({AppDatabase? db})
      : _repository = CashRegisterRepository(db ?? AppDatabase());

  final _controller = StreamController<CashRegisterModel>.broadcast();
  Stream<CashRegisterModel> get dataStream => _controller.stream;
  StreamSubscription<CashRegisterTotals>? _subscription;
  Timer? _rolloverTimer;
  bool _started = false;

  void init() {
    if (_started) return;
    _started = true;
    _watchCurrentDay();
  }

  void _watchCurrentDay() {
    final day = DashboardDay(DateTime.now());
    _subscription?.cancel();
    _subscription = _repository.watchDay(day).listen(
      (totals) {
        if (_controller.isClosed) return;
        _controller.add(CashRegisterModel(
          openingBalance: totals.opening,
          moneyIn: totals.moneyIn,
          moneyOut: totals.moneyOut,
          closingBalance: totals.closing,
          openingBalanceStr: _format(totals.opening),
          moneyInStr: _format(totals.moneyIn),
          moneyOutStr: _format(totals.moneyOut),
          closingBalanceStr: _format(totals.closing),
        ));
      },
      onError: (Object error, StackTrace stack) {
        AppLogger.debug('Cash register failed: $error');
        if (!_controller.isClosed) _controller.addError(error, stack);
      },
    );
    _rolloverTimer?.cancel();
    _rolloverTimer =
        Timer(day.end.difference(DateTime.now()), _watchCurrentDay);
  }

  static String _format(double amount) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹ ',
        decimalDigits: 2,
      ).format(amount);

  CashRegisterModel get initialData => CashRegisterModel.loading();

  void dispose() {
    _rolloverTimer?.cancel();
    _subscription?.cancel();
    _controller.close();
  }
}

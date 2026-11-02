import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../models/finance/cash_book/cash_book_period_summary.dart';
import '../../../repositories/finance/cash_book_period_repository.dart';

enum CashBookHistoryView { daily, monthly, yearly }

class CashBookHistoryController extends ChangeNotifier {
  CashBookHistoryController({CashBookPeriodRepository? repository})
      : _repository = repository ?? CashBookPeriodRepository() {
    _startWatch();
  }

  final CashBookPeriodRepository _repository;
  StreamSubscription<CashBookHistorySnapshot>? _subscription;
  CashBookHistorySnapshot _snapshot = const CashBookHistorySnapshot.empty();
  CashBookHistoryView _view = CashBookHistoryView.daily;
  bool _isLoading = true;
  String? _errorMessage;

  CashBookHistorySnapshot get snapshot => _snapshot;
  CashBookHistoryView get view => _view;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void showDaily() => _setView(CashBookHistoryView.daily);
  void showMonthly() => _setView(CashBookHistoryView.monthly);
  void showYearly() => _setView(CashBookHistoryView.yearly);

  void _setView(CashBookHistoryView value) {
    if (_view == value) return;
    _view = value;
    notifyListeners();
  }

  void retry() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    _startWatch();
  }

  void _startWatch() {
    _subscription?.cancel();
    _subscription = _repository.watchHistory().listen(
      (snapshot) {
        _snapshot = snapshot;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error('Cash Book history could not be loaded.',
            error: error, stackTrace: stackTrace);
        _isLoading = false;
        _errorMessage = 'Cash Book history could not be loaded.';
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

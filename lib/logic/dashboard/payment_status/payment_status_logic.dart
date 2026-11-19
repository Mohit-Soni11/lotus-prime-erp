import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../database/db/app_database.dart';
import '../../../models/dashboard/payment_status_model.dart';
import '../../../repositories/dashboard/payment_status_repository.dart';

class PaymentStatusLogic extends ChangeNotifier {
  PaymentStatusLogic({
    PaymentStatusRepository? repository,
    DateTime Function()? clock,
  })  : _repository = repository ?? PaymentStatusRepository(AppDatabase()),
        _clock = clock ?? DateTime.now {
    _watchToday();
  }

  final PaymentStatusRepository _repository;
  final DateTime Function() _clock;
  StreamSubscription<PaymentStatusModel>? _subscription;
  Timer? _dayTimer;

  PaymentStatusModel _data = PaymentStatusModel.loading;
  bool _hasError = false;
  int _visibleCount = 3;

  PaymentStatusModel get data => _data;
  bool get isLoading => _data.isLoading;
  bool get hasError => _hasError;
  int get visibleCount => _visibleCount;
  bool get hasMore => _data.filteredBills.length > _visibleCount;

  void _watchToday() {
    _subscription?.cancel();
    _dayTimer?.cancel();
    final now = _clock();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    _dayTimer = Timer(nextDay.difference(now), () {
      _data = PaymentStatusModel.loading;
      _visibleCount = 3;
      notifyListeners();
      _watchToday();
    });
    _subscription = _repository.watchDay(now).listen(
      (snapshot) {
        _data = PaymentStatusModel(
          summary: snapshot.summary,
          bills: snapshot.bills,
          activeTab: _data.activeTab,
        );
        _hasError = false;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        _hasError = true;
        notifyListeners();
      },
    );
  }

  void setTab(PaymentFilterTab tab) {
    if (_data.activeTab == tab) return;
    _data = _data.withTab(tab);
    _visibleCount = 3;
    notifyListeners();
  }

  void toggleExpanded() {
    _visibleCount = hasMore ? _visibleCount + 10 : 3;
    notifyListeners();
  }

  void retry() {
    _hasError = false;
    _data = PaymentStatusModel.loading;
    notifyListeners();
    _watchToday();
  }

  static String formatAmountFull(double amount) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 2,
      ).format(amount);

  @override
  void dispose() {
    _dayTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
